//
//  ViewController.swift
//  QRScanner
//
//  Created by xzysun on 15/11/23.
//  Copyright © 2015年 netease. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate, ScannerViewDelegate {
    @IBOutlet weak var scannerView: ScannerView!
    
    @IBOutlet weak var resultLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        scannerView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func scanButtonAction(sender: AnyObject) {
        if scannerView.isReading() {
            scannerView.stopReading()
        } else {
            scannerView.startReading()
        }
    }

    //MARK: - Image Picker Delegate
    @IBAction func imageButtonAction(sender: AnyObject) {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        picker.delegate = self
        self.presentViewController(picker, animated: true) { () -> Void in
            //
        }
        
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let image:UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        let result = scannerView.readFromImage(image)
        resultLabel.text = result
        self.dismissViewControllerAnimated(true) { () -> Void in
            //
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true) { () -> Void in
            //
        }
    }
    
    //MARK: - Scanner View Delegate
    func scannerDidReadFromDevice(result: String) {
        resultLabel.text = result
    }
}

