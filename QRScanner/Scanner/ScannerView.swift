//
//  ScannerView.swift
//  QRScanner
//
//  Created by xzysun on 15/11/23.
//  Copyright © 2015年 netease. All rights reserved.
//

import UIKit
import AVFoundation

protocol ScannerViewDelegate : NSObjectProtocol {
    func scannerDidReadFromDevice(result:String)
}

class ScannerView: UIView, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var delegate:ScannerViewDelegate?
    
    func startReading() ->Bool {
        //check permission
        let permission = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        if permission == AVAuthorizationStatus.NotDetermined {
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (granted) -> Void in
                if granted {
                    self.startReading()
                }
            })
            return false
        } else if permission == AVAuthorizationStatus.Denied || permission == AVAuthorizationStatus.Restricted {
            return false
        }
        //check device
        let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        if devices.count <= 0 {
            print("no device supported")
            return false
        }
        //setup capture session
        let captureDevice:AVCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        let captureDeviceInput:AVCaptureDeviceInput?
        do {
            try captureDeviceInput = AVCaptureDeviceInput(device: captureDevice)
        } catch (let error) {
            print("init capture input error:%@", error)
            return false
        }
        captureSession = AVCaptureSession()
        captureSession?.addInput(captureDeviceInput!)
        //setup output
        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession?.addOutput(captureMetadataOutput)
        let dispatchQueue = dispatch_queue_create("ScannerHandlerQueue", DISPATCH_QUEUE_SERIAL)
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: dispatchQueue)
        captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode, AVMetadataObjectTypeUPCECode, AVMetadataObjectTypeCode39Code]
        //setup preview layer
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        videoPreviewLayer?.frame = self.bounds
        self.layer.addSublayer(videoPreviewLayer!)
        //start
        captureSession?.startRunning()
        return true
    }
    
    func stopReading () {
        captureSession?.stopRunning()
        captureSession = nil
        videoPreviewLayer?.removeFromSuperlayer()
    }
    
    func isReading() ->Bool {
        if let session = captureSession {
            return session.running
        }
        return false
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        let dataObject:AVMetadataObject = metadataObjects.first as! AVMetadataObject
        if dataObject.isKindOfClass(AVMetadataMachineReadableCodeObject) {
            let codeObject = dataObject as! AVMetadataMachineReadableCodeObject
            let result = codeObject.stringValue
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                print("scan result:%@", result)
                if let aDelegate = self.delegate {
                    if aDelegate.respondsToSelector(Selector("scannerDidReadFromDevice:")) {
                        self.delegate?.scannerDidReadFromDevice(result)
                    }
                }
            })
        }
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.stopReading()
        })
    }
    
    func readFromImage(image:UIImage) ->String? {
        let context = CIContext(options: nil)
        let dector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: nil)
        let ciImage = CIImage(CGImage: image.CGImage!)
        let features = dector.featuresInImage(ciImage)
        if features.count == 0 {
            return nil
        }
        let feature:CIQRCodeFeature = features.first as! CIQRCodeFeature
        let result = feature.messageString
        return result
    }
}
