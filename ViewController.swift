//
//  ViewController.swift
//  PenguinCam
//
//  Created by peidong yuan on 01/09/2016.
//  Copyright © 2016 peidong yuan. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import CoreMotion

class ViewController: UIViewController {
  let captureSession = AVCaptureSession()
  var previewLayer: AVCaptureVideoPreviewLayer!
  var activeInput: AVCaptureDeviceInput!
  let imageOutput = AVCaptureStillImageOutput()
    
  let motionManager = CMMotionManager()
    var imageArray:[UIImage?] = []
    var picsNameArray:[String] =  []
    var panoramaImage: UIImage!
    // initial configuration
    var initialBolleam = true
    var initialAttitude: CMAttitude!
    var showingPrompt = false
    
    // trigger values - a gap so there isn't a flicker zone
    let showPromptTrigger = 1.0
    let showAnswerTrigger = 0.8
    var currentMaxRotX: Double = 0.0
    var currentMaxRotY: Double = 0.0
    var currentMaxRotZ: Double = 0.0
  
  var focusMarker: UIImageView!
  var exposureMarker: UIImageView!
  var resetMarker: UIImageView!
  var bgImage: UIImageView!
  var corssImage: UIImageView!
  var bgImageStill: UIImageView!
    
  fileprivate var adjustingExposureContext: String = ""
  
  @IBOutlet weak var camPreview: UIView!
  @IBOutlet weak var thumbnail: UIButton!
  @IBOutlet weak var flashLabel: UILabel!
    
  
  override func viewDidLoad() {
    super.viewDidLoad()

    setupSession()
    setupPreview()
    startSession()
    
    setMotionManager()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
    
    func magnitudeFromAttitude(_ attitude: CMAttitude) -> Double {
        print("Y: \(attitude.quaternion.y), X: \(attitude.quaternion.x), Z: \(attitude.quaternion.z), W: \(attitude.quaternion.w)")
        return attitude.roll
    }
    
    func setMotionManager()  {
        
        let imageStill: UIImage = UIImage(named: "Frame")!
        bgImageStill = UIImageView(image: imageStill)
        let centrelX = (camPreview.frame.size.width - 100)/2
        let centrelY = (camPreview.frame.size.height - 100)/2
        bgImageStill!.frame = CGRect(x: centrelX, y: centrelY, width: 100, height: 100)
        self.view.addSubview(bgImageStill!)
        
        let image: UIImage = UIImage(named: "stillFocus_Point")!
        bgImage = UIImageView(image: image)
        bgImage!.frame = CGRect(x: centrelX, y: centrelY, width: 100, height: 100)
        self.view.addSubview(bgImage!)
        
        let corsspng: UIImage = UIImage(named: "Corss_Point")!
        corssImage = UIImageView(image: corsspng)
        corssImage!.frame = CGRect(x: centrelX, y: centrelY, width: 100, height: 100)
        self.view.addSubview(corssImage!)
        
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.01

            motionManager.stopDeviceMotionUpdates()

            motionManager.startDeviceMotionUpdates(
                to: OperationQueue.current!, withHandler: {
                    (deviceMotion, error) -> Void in
                    
                    if(self.initialBolleam){
                        self.initialAttitude = deviceMotion!.attitude
                        self.initialBolleam = false
                    }
                    
                    if(error == nil) {
                        self.handleDeviceMotionUpdate(deviceMotion!)

                    } else {
                        //handle the error
                    }
            })
        }
        
    }
    
    
    func handleDeviceMotionUpdate(_ deviceMotion:CMDeviceMotion) {
        
         let data = deviceMotion
        
        //translate the attitude
        data.attitude.multiply(byInverseOf: initialAttitude)
        
        let gravity = deviceMotion.gravity
        let rotationx = atan2(gravity.x, gravity.y) - M_PI
        bgImage.transform = CGAffineTransform(rotationAngle: CGFloat(rotationx))
        
        let rotationy = atan2(gravity.y, gravity.z) + 1.5
        corssImage.transform = CGAffineTransform(translationX: 0, y: CGFloat(rotationy)*12)
        
    }
    
    func degrees(_ radians:Double) -> Double {
        return 180 / M_PI * radians
    }
    
    
  
  // MARK: - Setup session and preview
  
  func setupSession() {
    captureSession.sessionPreset = AVCaptureSessionPresetPhoto
    let camera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
    
    do {
      let input = try AVCaptureDeviceInput(device: camera)
      if captureSession.canAddInput(input) {
        captureSession.addInput(input)
        activeInput = input
      }
    } catch {
      print("Error setting device input: \(error)")
    }
    
    imageOutput.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
    
    if captureSession.canAddOutput(imageOutput) {
      captureSession.addOutput(imageOutput)
    }
  }
  
  func setupPreview() {
    // Configure previewLayer
    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    previewLayer.frame = camPreview.bounds
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
    camPreview.layer.addSublayer(previewLayer)
    
    // Attach tap recognizer for focus & exposure.
    let tapForFocus = UITapGestureRecognizer(target: self, action: #selector(ViewController.tapToFocus(_:)))
    tapForFocus.numberOfTapsRequired = 1
    
    let tapForExposure = UITapGestureRecognizer(target: self, action: #selector(ViewController.tapToExpose(_:)))
    tapForExposure.numberOfTapsRequired = 2
    
    let tapForReset = UITapGestureRecognizer(target: self, action: #selector(ViewController.resetFocusAndExposure))
    tapForReset.numberOfTapsRequired = 2
    tapForReset.numberOfTouchesRequired = 2
    
    camPreview.addGestureRecognizer(tapForFocus)
    camPreview.addGestureRecognizer(tapForExposure)
    camPreview.addGestureRecognizer(tapForReset)
    tapForFocus.require(toFail: tapForExposure)
    
    // Create marker views.
    focusMarker = imageViewWithImage("Focus_Point")
    exposureMarker = imageViewWithImage("Exposure_Point")
    resetMarker = imageViewWithImage("Reset_Point")
    camPreview.addSubview(focusMarker)
    camPreview.addSubview(exposureMarker)
    camPreview.addSubview(resetMarker)
  }
  
  func startSession() {
    if !captureSession.isRunning {
      videoQueue().async {
        self.captureSession.startRunning()
      }
    }
  }
  
  func stopSession() {
    if captureSession.isRunning {
      videoQueue().async {
        self.captureSession.stopRunning()
      }
    }
  }
  
  func videoQueue() -> DispatchQueue {
    return DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default)
  }
  
  // MARK: - Configure
  @IBAction func switchCameras(_ sender: AnyObject) {
    // Make sure the device has more than 1 camera.
    if AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo).count > 1 {
      // Check which position the active camera is.
      var newPosition: AVCaptureDevicePosition!
      if activeInput.device.position == AVCaptureDevicePosition.back {
        newPosition = AVCaptureDevicePosition.front
      } else {
        newPosition = AVCaptureDevicePosition.back
      }
      
      // Get camera at new position.
      var newCamera: AVCaptureDevice!
      let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
      for device in devices! {
        if (device as AnyObject).position == newPosition {
          newCamera = device as! AVCaptureDevice
        }
      }
      
      // Create new input and update capture session.
      do {
        let input = try AVCaptureDeviceInput(device: newCamera)
        captureSession.beginConfiguration()
        // Remove input for active camera.
        captureSession.removeInput(activeInput)
        // Add input for new camera.
        if captureSession.canAddInput(input) {
          captureSession.addInput(input)
          activeInput = input
        } else {
          captureSession.addInput(activeInput)
        }
        captureSession.commitConfiguration()
      } catch {
        print("Error switching cameras: \(error)")
      }
    }
  }
  
  // MARK: Focus Methods
  func tapToFocus(_ recognizer: UIGestureRecognizer) {
    if activeInput.device.isFocusPointOfInterestSupported {
      let point = recognizer.location(in: camPreview)
      let pointOfInterest = previewLayer.captureDevicePointOfInterest(for: point)
      showMarkerAtPoint(point, marker: focusMarker)
      focusAtPoint(pointOfInterest)
    }
  }
  
  func focusAtPoint(_ point: CGPoint) {
    let device = activeInput.device
    // Make sure the device supports focus on POI and Auto Focus.
    if (device?.isFocusPointOfInterestSupported)! &&
      (device?.isFocusModeSupported(AVCaptureFocusMode.autoFocus))! {
        do {
          try device?.lockForConfiguration()
          device?.focusPointOfInterest = point
          device?.focusMode = AVCaptureFocusMode.autoFocus
          device?.unlockForConfiguration()
        } catch {
          print("Error focusing on POI: \(error)")
        }
    }
  }
  
  // MARK: Exposure Methods
  func tapToExpose(_ recognizer: UIGestureRecognizer) {
    if activeInput.device.isExposurePointOfInterestSupported {
      let point = recognizer.location(in: camPreview)
      let pointOfInterest = previewLayer.captureDevicePointOfInterest(for: point)
      showMarkerAtPoint(point, marker: exposureMarker)
      exposeAtPoint(pointOfInterest)
    }
  }

  func exposeAtPoint(_ point: CGPoint) {
    let device = activeInput.device
    if (device?.isExposurePointOfInterestSupported)! &&
      (device?.isExposureModeSupported(AVCaptureExposureMode.continuousAutoExposure))! {
        do {
          try device?.lockForConfiguration()
          device?.exposurePointOfInterest = point
          device?.exposureMode = AVCaptureExposureMode.continuousAutoExposure
          
          if (device?.isExposureModeSupported(AVCaptureExposureMode.locked))! {
            device?.addObserver(self,
              forKeyPath: "adjustingExposure",
              options: NSKeyValueObservingOptions.new,
              context: &adjustingExposureContext)
            
            device?.unlockForConfiguration()
          }
        } catch {
          print("Error exposing on POI: \(error)")
        }
    }
  }
  
  override func observeValue(forKeyPath keyPath: String?,
    of object: Any?,
    change: [NSKeyValueChangeKey : Any]?,
    context: UnsafeMutableRawPointer?) {
      
      if context == &adjustingExposureContext {
        let device = object as! AVCaptureDevice
        if !device.isAdjustingExposure &&
          device.isExposureModeSupported(AVCaptureExposureMode.locked) {
            (object as AnyObject).removeObserver(self,
              forKeyPath: "adjustingExposure",
              context: &adjustingExposureContext)
            
            DispatchQueue.main.async(execute: { () -> Void in
              do {
                try device.lockForConfiguration()
                device.exposureMode = AVCaptureExposureMode.locked
                device.unlockForConfiguration()
              } catch {
                print("Error exposing on POI: \(error)")
              }
            })
            
        }
      } else {
        super.observeValue(forKeyPath: keyPath,
          of: object,
          change: change,
          context: context)
      }
  }
  
  // MARK: Reset Focus and Exposure
  func resetFocusAndExposure() {
    
  }
    
    func createDirectory(){
        let fileManager = FileManager.default
        let paths = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("ImgsDirectory")
        if !fileManager.fileExists(atPath: paths){
            try! fileManager.createDirectory(atPath: paths, withIntermediateDirectories: true, attributes: nil)
        }else{
            print("createDirectory: Already dictionary created.")
        }
    }
    
    func deleteDirectory(){
        let fileManager = FileManager.default
        let paths = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("ImgsDirectory")
        if fileManager.fileExists(atPath: paths){
            try! fileManager.removeItem(atPath: paths)
        }else{
            print("Something wronge.")
        }
    }
    
    func getDirectoryPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        print("getDirectoryPath: ", paths)
        return documentsDirectory
    }
    
    func getImage(picName: String) -> UIImage{
        let fileManager = FileManager.default
        let imagePAth = (self.getDirectoryPath() as NSString).appendingPathComponent(picName)
        if fileManager.fileExists(atPath: imagePAth){
//            self.imageView.image = UIImage(contentsOfFile: imagePAth)
            print("getImage: ", imagePAth)
            return UIImage(contentsOfFile: imagePAth)!
        }else{
            print("No Image")
            return UIImage()
        }
    }
    
    func saveImageDocumentDirectory(picsName: String, pics: UIImage){
        let fileManager = FileManager.default
        let paths = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(picsName)
//        let image = UIImage(named: "result.jpg")
        print("saveImageDocumentDirectory: " + paths)
        let imageData = UIImageJPEGRepresentation(pics, 0.5)
        fileManager.createFile(atPath: paths as String, contents: imageData, attributes: nil)
    }
  
  // MARK: Flash Modes
  @IBAction func setFlashMode(_ sender: AnyObject) {
    
  }

    @IBAction func panoramaStich(_ sender: AnyObject) {
        
        for pic in self.picsNameArray {
            self.getImage(picName: pic)
        }

 
        let stitchedImage:UIImage = CVWrapper.processImagesTest(picsNameArray)

        print("Panorama Image: \(stitchedImage)")
//
//        self.savePhotoToLibrary(stitchedImage)
    }

  // MARK: - Capture photo
  @IBAction func capturePhoto(_ sender: AnyObject) {
//    let connection = imageOutput.connection(withMediaType: AVMediaTypeVideo)
//    if (connection?.isVideoOrientationSupported)! {
//      connection?.videoOrientation = currentVideoOrientation()
//    }
    
    if let videoConnection = imageOutput.connection(withMediaType: AVMediaTypeVideo){
        imageOutput.captureStillImageAsynchronously(from: videoConnection, completionHandler: {
            (sampleBuffer, error) in
            if sampleBuffer != nil {
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                let image = UIImage(data: imageData!)
                let picName = String(self.picsNameArray.count) + ".jpg"
                self.picsNameArray.append((self.getDirectoryPath() as NSString).appendingPathComponent(picName))
                print("image: \(image! as UIImage)")
                
                self.createDirectory()
                self.saveImageDocumentDirectory(picsName: picName, pics: image!)

                self.imageArray.append(image! as UIImage)
                //        let photoBomb = self.penguinPhotoBomb(image!)
                self.savePhotoToLibrary(image!)
                print("Token Image: \(image!)")

            } else {
                print("Error capturing photo: \(error?.localizedDescription)")
            }
            
        })
    }
    
  }
  
  // MARK: - Helpers
  func savePhotoToLibrary(_ image: UIImage) {
    let photoLibrary = PHPhotoLibrary.shared()
    
    photoLibrary.performChanges({
         PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { (success, error) in
            if success {
                // Set thumbnail
                self.setPhotoThumbnail(image)
            } else {
                print("Error writing to photo library: \(error!.localizedDescription)")
            }
    }
  }
  
  func setPhotoThumbnail(_ image: UIImage) {
    DispatchQueue.main.async { () -> Void in
      self.thumbnail.setBackgroundImage(image, for: UIControlState())
      self.thumbnail.layer.borderColor = UIColor.white.cgColor
      self.thumbnail.layer.borderWidth = 1.0
    }
  }
  
  func penguinPhotoBomb(_ image: UIImage) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(image.size, true, 0.0)
    image.draw(at: CGPoint(x: 0, y: 0))
    
    // Composite Penguin
    let penguinImage = UIImage(named: "Focus_Point")
    
    var xFactor: CGFloat
    if randomFloat(0.0, to: 1.0) >= 0.5 {
      xFactor = randomFloat(0.0, to: 0.25)
    } else {
      xFactor = randomFloat(0.75, to: 1.0)
    }
    
    var yFactor: CGFloat
    if image.size.width < image.size.height {
      yFactor = 0.0
    } else {
      yFactor = 0.35
    }
    
    let penguinX = (image.size.width * xFactor) - (penguinImage!.size.width / 2)
    let penguinY = (image.size.height * 0.5) - (penguinImage!.size.height * yFactor)
    let penguinOrigin = CGPoint(x: penguinX, y: penguinY)
    
    penguinImage?.draw(at: penguinOrigin)
    
    let finalImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return finalImage!
  }
  
  func imageViewWithImage(_ name: String) -> UIImageView {
    let view = UIImageView()
    let image = UIImage(named: name)
    view.image = image
    view.sizeToFit()
    view.isHidden = true
    
    return view
  }
  
  func showMarkerAtPoint(_ point: CGPoint, marker: UIImageView) {
    marker.center = point
    marker.isHidden = false
    
    UIView.animate(withDuration: 0.15,
      delay: 0.0,
      options: UIViewAnimationOptions(),
      animations: { () -> Void in
        marker.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1.0)
      }) { (Bool) -> Void in
        let delay = 0.5
        let popTime = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: popTime, execute: { () -> Void in
          marker.isHidden = true
          marker.transform = CGAffineTransform.identity
        })
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "QuickLookSegue" {
      let quickLook = segue.destination as! QuickLookViewController
      
      if let image = thumbnail.backgroundImage(for: UIControlState()) {
        quickLook.photoImage = image
      } else {
        quickLook.photoImage = UIImage(named: "Penguin")
      }
    }
  }
  
  func currentVideoOrientation() -> AVCaptureVideoOrientation {
    var orientation: AVCaptureVideoOrientation
    
    switch UIDevice.current.orientation {
    case .portrait:
      orientation = AVCaptureVideoOrientation.portrait
    case .landscapeRight:
      orientation = AVCaptureVideoOrientation.landscapeLeft
    case .portraitUpsideDown:
      orientation = AVCaptureVideoOrientation.portraitUpsideDown
    default:
      orientation = AVCaptureVideoOrientation.landscapeRight
    }
    
    return orientation
  }
  
  func randomFloat(_ from:CGFloat, to:CGFloat) -> CGFloat {
    let rand:CGFloat = CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    return (rand) * (to - from) + from
  }
  
  func randomInt(_ n: Int) -> Int {
    return Int(arc4random_uniform(UInt32(n)))
  }

  deinit {
    stopSession()
  }
  
}

