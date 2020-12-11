//
//  WQCameraForPhotoView.swift
//  WQCameraControllerforSwift_Example
//
//  Created by 祺祺 on 2020/12/11.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary

@objc protocol WQCameraForPhotoViewDelegate : NSObjectProtocol {
    
    func cameraForPhoto(image:UIImage?,imageData:Data?,error:Error?)
}



class WQCameraForPhotoView: UIView {

    var captureSession:AVCaptureSession!
    var captureDeviceInput:AVCaptureDeviceInput!
    var captureStillImageOutput:AVCaptureStillImageOutput!
    var captureVideoPreviewLayer:AVCaptureVideoPreviewLayer!
    
    var isBackCameraSupported:Bool!
    var isFlashSupported:Bool!
    var isFrontCameraSupported:Bool!
    
    var focusView:UIView!
    
    public weak var delegate:WQCameraForPhotoViewDelegate?
    
    
    
    class func createCameraForPhotoView(frame:CGRect,defaultDevicePosition:AVCaptureDevice.Position) -> WQCameraForPhotoView {
        let photoView = WQCameraForPhotoView.init(frame: frame)
        photoView.initCapture(devicePostion: defaultDevicePosition)
        photoView.addGenstureRecognizer()
        return photoView
    }
    
    func initCapture(devicePostion:AVCaptureDevice.Position) {
        captureSession = AVCaptureSession.init()
        captureSession.startRunning()
        captureSession.sessionPreset = .high
        var frontCamera:AVCaptureDevice!
        var backCamera:AVCaptureDevice!
        let cameras = AVCaptureDevice.devices(for: .video)
        for camera:AVCaptureDevice in cameras{
            if camera.position == AVCaptureDevice.Position.front{
                frontCamera = camera
            }else{
                backCamera = camera
            }
        }
        
        if backCamera == nil{
            isBackCameraSupported = false
            return
        }else{
            isBackCameraSupported = true
            if backCamera.hasFlash{
                isFlashSupported = true
            }else{
                isFlashSupported = false
            }
        }
        
        if frontCamera == nil{
            isFrontCameraSupported = false
        }else{
            isFrontCameraSupported = true
        }
        
        if devicePostion == .front{
            do {
                try captureDeviceInput = AVCaptureDeviceInput.init(device: frontCamera)
            } catch  {
                
            }
            
        }else{
            do {
                try captureDeviceInput = AVCaptureDeviceInput.init(device: backCamera)
            } catch {
            
            }
        }
        
        captureStillImageOutput = AVCaptureStillImageOutput.init()
        let outpuSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
        captureStillImageOutput.outputSettings = outpuSettings
        
        if captureSession.canAddInput(captureDeviceInput){
            captureSession.addInput(captureDeviceInput)
        }
        if captureSession.canAddOutput(captureStillImageOutput){
            captureSession.addOutput(captureStillImageOutput)
        }
        captureVideoPreviewLayer = AVCaptureVideoPreviewLayer.init(session: captureSession)
        captureVideoPreviewLayer.frame = self.bounds
        captureVideoPreviewLayer.videoGravity = .resizeAspectFill
        self.layer.addSublayer(captureVideoPreviewLayer)
        
        focusView = UIView.init(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        focusView.layer.borderColor = UIColor.white.cgColor
        focusView.layer.borderWidth = 2
        focusView.layer.cornerRadius = 5
        focusView.alpha = 0
        self.addSubview(focusView)
        
    }
    
    func addGenstureRecognizer() {
        let tapGes = UITapGestureRecognizer.init(target: self, action: #selector(tapScreen(tapGes:)))
        self.addGestureRecognizer(tapGes)
    }
    
    
    public func changeCaptureDevice() {
        let currentDevice = self.captureDeviceInput.device
        let currentPosition = currentDevice.position
        
        let toChangeDevice:AVCaptureDevice!
        var toChangePostion:AVCaptureDevice.Position = .front
        if currentPosition == .unspecified || currentPosition == .front{
            toChangePostion = .back
        }
        toChangeDevice = self.getCameraDeviceWithPosition(position: toChangePostion)
        do {
            try currentDevice.lockForConfiguration()
            let toChangeDeviceInput = try AVCaptureDeviceInput.init(device: toChangeDevice)
            captureSession.beginConfiguration()
            captureSession.removeInput(captureDeviceInput)
            if captureSession.canAddInput(toChangeDeviceInput){
                captureSession.addInput(toChangeDeviceInput)
                captureDeviceInput = toChangeDeviceInput
            }
            captureSession.commitConfiguration()
            currentDevice.unlockForConfiguration()
        } catch {
            
        }
    }
    
    
    public func openFlash() {
        let currentDevice = captureDeviceInput.device
        let currentPosition = currentDevice.position
        if currentPosition == .back && currentDevice.isFlashModeSupported(.on){
            do {
                try currentDevice.lockForConfiguration()
                currentDevice.flashMode = .on
                currentDevice.unlockForConfiguration()
            } catch {
                
            }
        }
        
    }
    
    public func closeFlash() {
        let currentDevice = captureDeviceInput.device
        let currentPosition = currentDevice.position
        if currentPosition == .back && currentDevice.isFlashModeSupported(.on){
            do {
                try currentDevice.lockForConfiguration()
                currentDevice.flashMode = .off
                currentDevice.unlockForConfiguration()
            } catch {
                
            }
        }
        
    }
    
    public func start() {
        if captureSession != nil{
            captureSession.startRunning()
        }
    }
    public func stop() {
        if captureSession != nil{
            captureSession.stopRunning()
        }
    }
    
    public func takePhoto() {
        if captureSession.isRunning == false{
            return
        }
        
        let videoConnection = captureStillImageOutput.connection(with: .video)!
        captureStillImageOutput.captureStillImageAsynchronously(from: videoConnection) { (buffer, error) in
            if buffer != nil{
                self.stop()
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer!)!
                let image = UIImage.init(data: imageData)!
                if self.delegate != nil{
                    self.delegate?.cameraForPhoto(image: image, imageData: imageData, error: error)
                    
                }
                
            }
        }
        
    }
    
    public func flashSupported() -> Bool {
        if captureDeviceInput.device.position == .back && isFlashSupported == true{
            return true
        }
        return false
    }
    
    public func flashActiving() -> Bool {
        return captureDeviceInput.device.isFlashActive
    }
    
    public func running() -> Bool {
        return captureSession.isRunning
    }
    public func backCameraSupported() -> Bool {
        return isBackCameraSupported
    }
    public func frontCameraSupported() -> Bool {
        return isFrontCameraSupported
    }
    
    func setFocusCursorWithPoint(point:CGPoint) {
        focusView.center = point
        focusView.transform = .identity
        focusView.alpha = 0
        
        UIView.animate(withDuration: 0.5) {
            self.focusView.transform = CGAffineTransform.init(scaleX: 0.8, y: 0.8)
        } completion: { (success) in
            self.focusView.alpha = 0
        }

    }
    
    func focusWithMode(focusMode:AVCaptureDevice.FocusMode,exposureMode:AVCaptureDevice.ExposureMode,atPoint:CGPoint) {
        let captureDevice = self.captureDeviceInput.device
        do {
            try captureDevice.lockForConfiguration()
            if captureDevice.isFocusModeSupported(focusMode){
                captureDevice.focusMode = focusMode
            }
            if captureDevice.isFocusPointOfInterestSupported{
                captureDevice.focusPointOfInterest = atPoint
            }
            if captureDevice.isExposureModeSupported(exposureMode){
                captureDevice.exposureMode = exposureMode
            }
        } catch {
            
        }
    }
    
    
    
    
    @objc func tapScreen(tapGes:UITapGestureRecognizer) {
        let point = tapGes.location(in: self)
        let cameraPoint = captureVideoPreviewLayer.captureDevicePointConverted(fromLayerPoint: point)
        self.setFocusCursorWithPoint(point: point)
        self.focusWithMode(focusMode: .autoFocus, exposureMode: .autoExpose, atPoint: cameraPoint)
    }
    
    
    func getCameraDeviceWithPosition(position:AVCaptureDevice.Position) -> AVCaptureDevice? {
        let cameras = AVCaptureDevice.devices(for: .video)
        for camera:AVCaptureDevice in cameras{
            if camera.position == position{
                return camera
            }
        }
        
        return nil
    }
    

    
}
