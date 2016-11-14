//
//  QuickLookViewController.swift
//  PenguinCam
//
//  Created by peidong yuan on 01/09/2016.
//  Copyright © 2016 peidong yuan. All rights reserved.
//

import UIKit

class QuickLookViewController: UIViewController {
  
  @IBOutlet weak var quickLookImage: UIImageView!
  var photoImage: UIImage!
  
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override var prefersStatusBarHidden : Bool {
    return true
  }

  
  override func viewDidLoad() {
    super.viewDidLoad()
    if photoImage != nil {
      quickLookImage.image = photoImage
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  @IBAction func closeQuickLook(_ sender: AnyObject) {
    dismiss(animated: true, completion: nil)
  }
  
}
