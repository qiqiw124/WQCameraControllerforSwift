//
//  WQCameraForVideoView.swift
//  WQCameraControllerforSwift_Example
//
//  Created by 祺祺 on 2020/12/11.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary

protocol WQCameraForVideoViewDelegate:NSObjectProtocol {
    func cameraForVideo(videoView:WQCameraForVideoView,timeCount:NSInteger)
    func cameraForVideoEndRecording(videoView:WQCameraForVideoView,videoURL:URL,error:Error?)
}



class WQCameraForVideoView: UIView ,AVCaptureFileOutputRecordingDelegate{

    var captureSession:AVCaptureSession!
    var videoDeviceInput:AVCaptureDeviceInput!
    var movieFileOutput:AVCaptureMovieFileOutput!
    var preViewLayer:AVCaptureVideoPreviewLayer!
    
    var isBackCameraSupported:Bool!
    var isTorchSupported:Bool!
    var isFrontCameraSupported:Bool!
    
    weak var recordTimer:Timer!
    
    var frameRate:Int32!
    var timeCount:NSInteger! = 0
    
    public weak var delegate:WQCameraForVideoViewDelegate!
    
    
    
    public class func createCameraForVideoView(frame:CGRect,defaultDevicePosition:AVCaptureDevice.Position,frameRate:Int32) -> WQCameraForVideoView {
        let photoView = WQCameraForVideoView.init(frame: frame)
        photoView.frameRate = frameRate
        if(photoView.frameRate == 0){
            photoView.frameRate = 25
        }
        photoView.initCapture(devicePostion: defaultDevicePosition)
        
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
            if backCamera.hasTorch{
                isTorchSupported = true
            }else{
                isTorchSupported = false
            }
        }
        
        if frontCamera == nil{
            isFrontCameraSupported = false
        }else{
            isFrontCameraSupported = true
        }
        
        if devicePostion == .front{
            do {
                try videoDeviceInput = AVCaptureDeviceInput.init(device: frontCamera)
            } catch  {
                
            }
            
        }else{
            do {
                try videoDeviceInput = AVCaptureDeviceInput.init(device: backCamera)
            } catch {
            
            }
        }
        do {
            try backCamera.lockForConfiguration()
            if backCamera.isExposureModeSupported(.autoExpose){
                backCamera.exposureMode = .autoExpose
                backCamera.unlockForConfiguration()
            }
        } catch {
            
        }
        
        do {
            let audioInput = try AVCaptureDeviceInput.init(device: AVCaptureDevice.default(for: .audio)!)
            captureSession.addInput(audioInput)
        } catch  {
            
        }
        captureSession.addInput(videoDeviceInput)
        
        movieFileOutput = AVCaptureMovieFileOutput.init()
        captureSession.addOutput(movieFileOutput)
        
        preViewLayer = AVCaptureVideoPreviewLayer.init(session: captureSession)
        preViewLayer.videoGravity = .resizeAspectFill
        
        captureSession.startRunning()
        
        preViewLayer.frame = self.bounds
        self.layer.addSublayer(preViewLayer)
        
    }
    
    public func startRecord() {
        movieFileOutput.startRecording(to: NSURL.fileURL(withPath: self.tmpPath()), recordingDelegate: self)
    }
    
    public func stopRecord() {
        movieFileOutput.stopRecording()
    }
    
    public func openTorch() {
        let device = videoDeviceInput.device
        if isTorchSupported == true && device.position == .back{
            do {
                try device.lockForConfiguration()
                device.torchMode = .on
                device.unlockForConfiguration()
            } catch {
                
            }
        }
        
    }
    public func closeTorch() {
        let device = videoDeviceInput.device
        if isTorchSupported == true && device.position == .back{
            do {
                try device.lockForConfiguration()
                device.torchMode = .off
                device.unlockForConfiguration()
            } catch {
                
            }
        }
        
    }
    
    public func changeCaptureDevice() {
        if movieFileOutput.isRecording == true{
            return
        }
        
        let currentDevice = self.videoDeviceInput.device
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
            captureSession.removeInput(videoDeviceInput)
            if captureSession.canAddInput(toChangeDeviceInput){
                captureSession.addInput(toChangeDeviceInput)
                videoDeviceInput = toChangeDeviceInput
            }
            captureSession.commitConfiguration()
            currentDevice.unlockForConfiguration()
        } catch {
            
        }
    }
    
    
    func changeCaptureRate() {
        let currentDevice = videoDeviceInput.device
        do {
            try currentDevice.lockForConfiguration()
            currentDevice.activeVideoMinFrameDuration = CMTimeMake(1, frameRate)
            currentDevice.activeVideoMaxFrameDuration = CMTimeMake(1, frameRate)
            currentDevice.unlockForConfiguration()
        } catch  {
            
        }
    }
    
    @objc func recordTimerEvent(timer:Timer) {
        timeCount = timeCount + 1
        if self.delegate != nil{
            self.delegate.cameraForVideo(videoView: self, timeCount: timeCount)
        }
        
    }
    
    func startTimer() {
        if self.recordTimer != nil{
            self.recordTimer.invalidate()
            self.recordTimer = nil
        }
        self.recordTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(recordTimerEvent(timer:)), userInfo: nil, repeats: true)
    }
    func endTimer() {
        if self.recordTimer != nil{
            self.recordTimer.invalidate()
            self.recordTimer = nil
        }
        
    }
    
    
    public func recording() -> Bool{
        return movieFileOutput.isRecording
    }
    public func backCameraSupported() -> Bool {
        return isBackCameraSupported
    }
    public func frontCameraSupported() -> Bool {
        return isFrontCameraSupported
    }
    public func torchSupported() -> Bool {
        if videoDeviceInput.device.position == .back && isTorchSupported == true{
            return true
        }
        return false
    }
    
    public func torchActiving() -> Bool {
        return videoDeviceInput.device.isTorchActive
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        self.startTimer()
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        self.endTimer()
        timeCount = 0
        if self.delegate != nil{
            if error != nil && error?.localizedDescription == "Recording Stopped"{
                self.delegate.cameraForVideoEndRecording(videoView: self, videoURL: outputFileURL, error: nil)
            }else{
                self.delegate.cameraForVideoEndRecording(videoView: self, videoURL: outputFileURL, error: error)
            }
        }
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
    func tmpPath() ->String {
        return NSTemporaryDirectory().appendingFormat("/cameraVideoTmp.mp4")
    }
}
