//
//  ViewController.swift
//  PenguinCam
//
//  Created by Michael Briscoe on 1/8/16.
//  Copyright © 2016 Razeware LLC. All rights reserved.
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
    var bgImageStill: UIImageView!
    
    private var adjustingExposureContext: String = ""
    
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
    
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func magnitudeFromAttitude(attitude: CMAttitude) -> Double {
        print("Y: \(attitude.quaternion.y), X: \(attitude.quaternion.x), Z: \(attitude.quaternion.z)")
        return attitude.roll
    }
    
    func setMotionManager()  {
        
        let imageStill: UIImage = UIImage(named: "Focus_Point")!
        bgImageStill = UIImageView(image: imageStill)
        let centrelXStill = (camPreview.frame.size.width - 100)/2
        let centrelYStill = (camPreview.frame.size.height - 100)/2
        bgImageStill!.frame = CGRectMake(centrelXStill,centrelYStill,100,100)
        self.view.addSubview(bgImageStill!)
        
        let image: UIImage = UIImage(named: "stillFocus_Point")!
        bgImage = UIImageView(image: image)
        let centrelX = (camPreview.frame.size.width - 100)/2
        let centrelY = (camPreview.frame.size.height - 100)/2
        bgImage!.frame = CGRectMake(centrelX,centrelY,100,100)
        self.view.addSubview(bgImage!)
        
        if motionManager.deviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.01
            
            motionManager.stopDeviceMotionUpdates()
            
            motionManager.startDeviceMotionUpdatesToQueue(
                NSOperationQueue.currentQueue()!, withHandler: {
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
    
    
    func handleDeviceMotionUpdate(deviceMotion:CMDeviceMotion) {
        
        let data = deviceMotion
        
        //translate the attitude
        data.attitude.multiplyByInverseOfAttitude(initialAttitude)
        
        // calculate magnitude of the change from our initial attitude
        let magnitude = magnitudeFromAttitude(data.attitude) ?? 0
        
        
        // show the prompt
        if !showingPrompt && magnitude > showPromptTrigger {
            showingPrompt = true
            print("Show")
        }
        
        // hide the prompt
        if showingPrompt && magnitude < showAnswerTrigger {
            showingPrompt = false
            print("Hide")
        }
        
        let gravity = deviceMotion.gravity
        let rotation = atan2(gravity.x, gravity.y) - M_PI
        bgImage.transform = CGAffineTransformMakeRotation(CGFloat(rotation))
        
    }
    
    func degrees(radians:Double) -> Double {
        return 180 / M_PI * radians
    }
    
    
    
    // MARK: - Setup session and preview
    
    func setupSession() {
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        let camera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
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
        tapForFocus.requireGestureRecognizerToFail(tapForExposure)
        
        // Create marker views.
        focusMarker = imageViewWithImage("Focus_Point")
        exposureMarker = imageViewWithImage("Exposure_Point")
        resetMarker = imageViewWithImage("Reset_Point")
        camPreview.addSubview(focusMarker)
        camPreview.addSubview(exposureMarker)
        camPreview.addSubview(resetMarker)
    }
    
    func startSession() {
        if !captureSession.running {
            dispatch_async(videoQueue()) {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stopSession() {
        if captureSession.running {
            dispatch_async(videoQueue()) {
                self.captureSession.stopRunning()
            }
        }
    }
    
    func videoQueue() -> dispatch_queue_t {
        return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    }
    
    // MARK: - Configure
    @IBAction func switchCameras(sender: AnyObject) {
        // Make sure the device has more than 1 camera.
        if AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo).count > 1 {
            // Check which position the active camera is.
            var newPosition: AVCaptureDevicePosition!
            if activeInput.device.position == AVCaptureDevicePosition.Back {
                newPosition = AVCaptureDevicePosition.Front
            } else {
                newPosition = AVCaptureDevicePosition.Back
            }
            
            // Get camera at new position.
            var newCamera: AVCaptureDevice!
            let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
            for device in devices {
                if device.position == newPosition {
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
    func tapToFocus(recognizer: UIGestureRecognizer) {
        if activeInput.device.focusPointOfInterestSupported {
            let point = recognizer.locationInView(camPreview)
            let pointOfInterest = previewLayer.captureDevicePointOfInterestForPoint(point)
            showMarkerAtPoint(point, marker: focusMarker)
            focusAtPoint(pointOfInterest)
        }
    }
    
    func focusAtPoint(point: CGPoint) {
        let device = activeInput.device
        // Make sure the device supports focus on POI and Auto Focus.
        if device.focusPointOfInterestSupported &&
            device.isFocusModeSupported(AVCaptureFocusMode.AutoFocus) {
            do {
                try device.lockForConfiguration()
                device.focusPointOfInterest = point
                device.focusMode = AVCaptureFocusMode.AutoFocus
                device.unlockForConfiguration()
            } catch {
                print("Error focusing on POI: \(error)")
            }
        }
    }
    
    // MARK: Exposure Methods
    func tapToExpose(recognizer: UIGestureRecognizer) {
        if activeInput.device.exposurePointOfInterestSupported {
            let point = recognizer.locationInView(camPreview)
            let pointOfInterest = previewLayer.captureDevicePointOfInterestForPoint(point)
            showMarkerAtPoint(point, marker: exposureMarker)
            exposeAtPoint(pointOfInterest)
        }
    }
    
    func exposeAtPoint(point: CGPoint) {
        let device = activeInput.device
        if device.exposurePointOfInterestSupported &&
            device.isExposureModeSupported(AVCaptureExposureMode.ContinuousAutoExposure) {
            do {
                try device.lockForConfiguration()
                device.exposurePointOfInterest = point
                device.exposureMode = AVCaptureExposureMode.ContinuousAutoExposure
                
                if device.isExposureModeSupported(AVCaptureExposureMode.Locked) {
                    device.addObserver(self,
                                       forKeyPath: "adjustingExposure",
                                       options: NSKeyValueObservingOptions.New,
                                       context: &adjustingExposureContext)
                    
                    device.unlockForConfiguration()
                }
            } catch {
                print("Error exposing on POI: \(error)")
            }
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?,
                                         ofObject object: AnyObject?,
                                                  change: [String : AnyObject]?,
                                                  context: UnsafeMutablePointer<Void>) {
        
        if context == &adjustingExposureContext {
            let device = object as! AVCaptureDevice
            if !device.adjustingExposure &&
                device.isExposureModeSupported(AVCaptureExposureMode.Locked) {
                object?.removeObserver(self,
                                       forKeyPath: "adjustingExposure",
                                       context: &adjustingExposureContext)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    do {
                        try device.lockForConfiguration()
                        device.exposureMode = AVCaptureExposureMode.Locked
                        device.unlockForConfiguration()
                    } catch {
                        print("Error exposing on POI: \(error)")
                    }
                })
                
            }
        } else {
            super.observeValueForKeyPath(keyPath,
                                         ofObject: object,
                                         change: change,
                                         context: context)
        }
    }
    
    // MARK: Reset Focus and Exposure
    func resetFocusAndExposure() {
        
    }
    
    // MARK: Flash Modes
    @IBAction func setFlashMode(sender: AnyObject) {
        
    }
    
    
        func stitch() -> UIImage {
    
            let image1 = UIImage(named:"thumb2.jpg")
            let image2 = UIImage(named:"thumb1.jpg")
            let image3 = UIImage(named:"thumb3.jpg")
    //            let image4 = UIImage(named:"pano_19_25_mid.jpg")
    
            let imageArray:[UIImage!] = [image1,image2, image3]
    
            let stitchedImage:UIImage = CVWrapper.processWithArray(imageArray) as UIImage
            return stitchedImage
        }
    
    
    // MARK: - Capture photo
    @IBAction func capturePhoto(sender: AnyObject) {
        let connection = imageOutput.connectionWithMediaType(AVMediaTypeVideo)
        if connection.supportsVideoOrientation {
            connection.videoOrientation = currentVideoOrientation()
        }
        
        imageOutput.captureStillImageAsynchronouslyFromConnection(connection) {
            (sampleBuffer: CMSampleBuffer!, error: NSError!) -> Void in
            if sampleBuffer != nil {
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
//                let image = UIImage(data: imageData)
                        let image = self.stitch()
                //        let photoBomb = self.penguinPhotoBomb(image!)
                self.savePhotoToLibrary(image)
            } else {
                print("Error capturing photo: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Helpers
    func savePhotoToLibrary(image: UIImage) {
        let photoLibrary = PHPhotoLibrary.sharedPhotoLibrary()
        photoLibrary.performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromImage(image)
        }) { (success: Bool, error: NSError?) -> Void in
            if success {
                // Set thumbnail
                self.setPhotoThumbnail(image)
            } else {
                print("Error writing to photo library: \(error!.localizedDescription)")
            }
        }
    }
    
    func setPhotoThumbnail(image: UIImage) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.thumbnail.setBackgroundImage(image, forState: UIControlState.Normal)
            self.thumbnail.layer.borderColor = UIColor.whiteColor().CGColor
            self.thumbnail.layer.borderWidth = 1.0
        }
    }
    
    func penguinPhotoBomb(image: UIImage) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, true, 0.0)
        image.drawAtPoint(CGPoint(x: 0, y: 0))
        
        // Composite Penguin
        let penguinImage = UIImage(named: "Focus_Point")
        
        var xFactor: CGFloat
        if randomFloat(from: 0.0, to: 1.0) >= 0.5 {
            xFactor = randomFloat(from: 0.0, to: 0.25)
        } else {
            xFactor = randomFloat(from: 0.75, to: 1.0)
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
        
        penguinImage?.drawAtPoint(penguinOrigin)
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return finalImage
    }
    
    func imageViewWithImage(name: String) -> UIImageView {
        let view = UIImageView()
        let image = UIImage(named: name)
        view.image = image
        view.sizeToFit()
        view.hidden = true
        
        return view
    }
    
    func showMarkerAtPoint(point: CGPoint, marker: UIImageView) {
        marker.center = point
        marker.hidden = false
        
        UIView.animateWithDuration(0.15,
                                   delay: 0.0,
                                   options: UIViewAnimationOptions.CurveEaseInOut,
                                   animations: { () -> Void in
                                    marker.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1.0)
        }) { (Bool) -> Void in
            let delay = 0.5
            let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
            dispatch_after(popTime, dispatch_get_main_queue(), { () -> Void in
                marker.hidden = true
                marker.transform = CGAffineTransformIdentity
            })
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "QuickLookSegue" {
            let quickLook = segue.destinationViewController as! QuickLookViewController
            
            if let image = thumbnail.backgroundImageForState(UIControlState.Normal) {
                quickLook.photoImage = image
            } else {
                quickLook.photoImage = UIImage(named: "Penguin")
            }
        }
    }
    
    func currentVideoOrientation() -> AVCaptureVideoOrientation {
        var orientation: AVCaptureVideoOrientation
        
        switch UIDevice.currentDevice().orientation {
        case .Portrait:
            orientation = AVCaptureVideoOrientation.Portrait
        case .LandscapeRight:
            orientation = AVCaptureVideoOrientation.LandscapeLeft
        case .PortraitUpsideDown:
            orientation = AVCaptureVideoOrientation.PortraitUpsideDown
        default:
            orientation = AVCaptureVideoOrientation.LandscapeRight
        }
        
        return orientation
    }
    
    func randomFloat(from from:CGFloat, to:CGFloat) -> CGFloat {
        let rand:CGFloat = CGFloat(Float(arc4random()) / 0xFFFFFFFF)
        return (rand) * (to - from) + from
    }
    
    func randomInt(n: Int) -> Int {
        return Int(arc4random_uniform(UInt32(n)))
    }
    
    deinit {
        stopSession()
    }
    
}

