//
//  WQCameraViewController.swift
//  WQCameraControllerforSwift_Example
//
//  Created by 祺祺 on 2020/12/11.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import AVFoundation

protocol WQCameraViewControllerDelegate:NSObjectProtocol {
    
    /**
     视频或者照片拍摄完毕
     @param cameraView 拍照页面
     @param mediaType 拍照类型 视频还是拍照 1为拍照 2为视频
     @param videoFileUrl 视频情况下会有
     @param photo 照片 拍照情况下会有
     @param imageData 照片的data 拍照情况下会有
     @param error error
     */
    func mediaFinish(mediaType:NSInteger,videoFileURL:URL,photo:UIImage?,photoData:Data?,error:Error?)
}




class WQCameraViewController: UIViewController ,WQCameraForVideoViewDelegate,WQCameraForPhotoViewDelegate{

    var preview:UIView!
    var videoView:WQCameraForVideoView!
    var photoView:WQCameraForPhotoView!
    var cameraBtn:UIButton!
    var changeBtn:UIButton!
    var tropBtn:UIButton!
    var rePhotoBtn:UIButton!
    var segm:UISegmentedControl!
    var timeLab:UILabel!
    
    var devicePosition:AVCaptureDevice.Position! = .back
    
    
    public var frameRate:Int32! = 0
    
    public weak var delegate :WQCameraViewControllerDelegate!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        self.view.addSubview(self.createPreview())
        if self.frameRate == 0{
            self.frameRate = 25
        }
        self.devicePosition = .back
        self.photoView = WQCameraForPhotoView.createCameraForPhotoView(frame: self.preview.bounds, defaultDevicePosition: self.devicePosition)
        self.photoView.delegate = self
        self.preview.addSubview(self.photoView)
        self.createMainView()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActiveNoti(noti:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        
    }
    func createPreview() -> UIView {
        let barHeight = self.navigationController?.navigationBar.frame.height ?? 0
        preview = UIView.init(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height - barHeight - UIApplication.shared.statusBarFrame.height - 100))
        preview.backgroundColor = .black
        return preview
    }
    
    
    func createMainView() {
        self.cameraBtn = UIButton.init(frame: CGRect(x: (self.view.frame.width - 80)/2, y: self.preview.frame.maxY + 10, width: 80, height: 80))
        self.cameraBtn.setImage(self.getImgWithBundleImgName(name: "takePhotoIcon"), for: .normal)
        self.cameraBtn.addTarget(self, action: #selector(cameraBtnClick), for: .touchUpInside)
        self.view.addSubview(self.cameraBtn)
        
        self.changeBtn = UIButton.init(frame: CGRect(x: self.view.frame.width - 55, y: self.cameraBtn.frame.midY - 15, width: 40, height: 40))
        self.changeBtn.setImage(self.getImgWithBundleImgName(name: "changeDevice"), for: .normal)
        self.changeBtn.addTarget(self, action: #selector(changeBtnClick), for: .touchUpInside)
        self.view.addSubview(self.changeBtn)
        
        self.tropBtn = UIButton.init(frame: CGRect(x: 15, y: self.cameraBtn.frame.midY - 15, width: 40, height: 40))
        self.tropBtn.setImage(self.getImgWithBundleImgName(name: "flashclose"), for: .normal)
        self.tropBtn.addTarget(self, action: #selector(tropBtnClick), for: .touchUpInside)
        self.view.addSubview(self.tropBtn)
        
        self.segm = UISegmentedControl.init(items: ["相机","视频"])
        self.segm.frame = CGRect(x: (self.view.frame.width - 100)/2, y: 10, width: 100, height: 40)
        self.segm.selectedSegmentIndex = 0
        self.segm.addTarget(self, action: #selector(segmChangeClick(seg:)), for: .valueChanged)
        self.view.addSubview(self.segm)
        
        let backBtn = UIButton.init(frame: CGRect(x: 10, y: 15, width: 30, height: 30))
        backBtn.setImage(self.getImgWithBundleImgName(name: "backIcon"), for: .normal)
        backBtn.addTarget(self, action: #selector(backBtnClick), for: .touchUpInside)
        self.view.addSubview(backBtn)

    }
    @objc func backBtnClick() {
        self.dismiss(animated: true, completion: nil)
        if self.videoView != nil && self.videoView.recording(){
            self.videoView.stopRecord()
        }
    }
    
    @objc func segmChangeClick(seg:UISegmentedControl){
        if seg.selectedSegmentIndex == 0{
            self.videoView.removeFromSuperview()
            self.videoView = nil
            self.photoView = WQCameraForPhotoView.createCameraForPhotoView(frame: self.preview.bounds, defaultDevicePosition: self.devicePosition)
            self.photoView.delegate = self
            self.preview.addSubview(self.photoView)
        }else{
            self.photoView.removeFromSuperview()
            self.photoView = nil
            self.videoView = WQCameraForVideoView.createCameraForVideoView(frame: self.preview.bounds, defaultDevicePosition: self.devicePosition, frameRate: self.frameRate)
            self.videoView.delegate = self
            self.preview.addSubview(self.videoView)
        }
    }
    
    @objc func tropBtnClick() {
        if self.videoView != nil{
            if self.videoView.torchActiving() == true{
                self.videoView.closeTorch()
                self.tropBtn.setImage(self.getImgWithBundleImgName(name: "flashclose"), for: .normal)
            }else{
                if self.videoView.torchSupported() == true{
                    self.videoView.openTorch()
                    self.tropBtn.setImage(self.getImgWithBundleImgName(name: "flashopen"), for: .normal)
                }
            }
        }else{
            if self.photoView.flashActiving(){
                self.photoView.closeFlash()
                self.tropBtn.setImage(self.getImgWithBundleImgName(name: "flashclose"), for: .normal)
            }else{
                if self.photoView.flashSupported(){
                    self.photoView.openFlash()
                    self.tropBtn.setImage(self.getImgWithBundleImgName(name: "flashopen"), for: .normal)
                }
            }
        }
    }
    
    @objc func cameraBtnClick() {
        if self.videoView != nil{
            if self.videoView.recording(){
                self.videoView.stopRecord()
                self.segm.isHidden = false
                self.tropBtn.isHidden = false
                self.changeBtn.isHidden = false
                self.timeLab.removeFromSuperview()
                self.cameraBtn.setImage(self.getImgWithBundleImgName(name: "takePhotoIcon"), for: .normal)
            }else{
                self.videoView.startRecord()
                self.segm.isHidden = true
                self.tropBtn.isHidden = true
                self.changeBtn.isHidden = true
                self.view.addSubview(self.createTimeLab())
                self.cameraBtn.setImage(self.getImgWithBundleImgName(name: "recordingIcon"), for: .normal)
                
            }
        }else{
            self.photoView.takePhoto()
            self.segm.isHidden = true
        }
    }
    
    @objc func changeBtnClick() {
        if self.videoView != nil{
            self.videoView.changeCaptureDevice()
        }else{
            self.photoView.changeCaptureDevice()
        }
        
        if self.devicePosition == AVCaptureDevice.Position.back{
            self.devicePosition = AVCaptureDevice.Position.front
        }else{
            self.devicePosition = AVCaptureDevice.Position.back
        }
        
    }
    
    @objc func rePhotoBtnClick() {
        if self.photoView != nil{
            self.photoView.start()
            self.tropBtn.isHidden = false
            self.rePhotoBtn.removeFromSuperview()
            self.rePhotoBtn = nil
            self.segm.isHidden = false
        }
    }
    
    
    func createRePhotoBtn() -> UIButton {
        if self.rePhotoBtn != nil{
            return self.rePhotoBtn
        }
        self.rePhotoBtn = UIButton.init(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        self.rePhotoBtn.setTitle("重拍", for: .normal)
        self.rePhotoBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        self.rePhotoBtn.addTarget(self, action: #selector(rePhotoBtnClick), for: .touchUpInside)
        return self.rePhotoBtn
    }
    
    
    func createTimeLab() -> UILabel {
        if self.timeLab != nil{
            return self.timeLab
        }
        self.timeLab = UILabel.init(frame: CGRect(x: (self.view.frame.width - 100)/2, y: self.preview.frame.maxY - 30, width: 100, height: 30))
        self.timeLab.textColor = .white
        self.timeLab.textAlignment = .center
        return self.timeLab
    }
    
    func getTimeStrWithCount(count:NSInteger) -> String {
        var timeStr = "00:00"
        let ss = count % 60
        let mm = count / 60 % 60
        let hh = count / 60 / 60
        timeStr = NSString.init(format: "%02ld:%02ld:%02ld", hh,mm,ss) as String
        return timeStr
    }
    
    
    
    
    
    
    
    
    
    
    
    @objc func applicationWillResignActiveNoti(noti:Notification) {
        if self.videoView != nil && self.videoView.recording(){
            self.cameraBtnClick()
        }
    }

    
    
    func cameraForPhoto(image: UIImage?, imageData: Data?, error: Error?) {
        self.tropBtn.isHidden = true
        self.createRePhotoBtn().frame = self.tropBtn.frame
        self.view.addSubview(self.rePhotoBtn)
        if self.delegate != nil{
            let ur:URL! = URL.init(string: "")
            self.delegate.mediaFinish(mediaType: 1, videoFileURL: ur, photo: image, photoData: imageData, error: error)
        }
    }
    func cameraForVideo(videoView: WQCameraForVideoView, timeCount: NSInteger) {
        
        self.createTimeLab().text = self.getTimeStrWithCount(count: timeCount)
    }
    func cameraForVideoEndRecording(videoView: WQCameraForVideoView, videoURL: URL, error: Error?) {
        
        self.createTimeLab().text = self.getTimeStrWithCount(count: 0)
        if self.delegate != nil{
            self.delegate.mediaFinish(mediaType: 2, videoFileURL: videoURL, photo: nil, photoData: nil, error: error)
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    func getImgWithBundleImgName(name:String) -> UIImage? {
//        let clas = NSClassFromString("WQCameraViewController") ?? nil
//        if clas == nil{
//            return nil
//        }
//        let bundle = Bundle.init(for: clas!)
//        let scale:NSInteger = NSInteger(UIScreen.main.scale)
//        let imgName = "\(name)@\(scale)x"
        
//        var path = bundle.path(forResource: imgName, ofType: "png")
//        if path == nil{
//            path = bundle.path(forResource: name, ofType: "png")
//        }
        return UIImage.init(named: name)
    }

    deinit {
        if self.videoView != nil && self.videoView.recording(){
            self.videoView.stopRecord()
        }
    }
}
