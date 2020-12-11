//
//  ViewController.swift
//  WQCameraControllerforSwift
//
//  Created by 01810452 on 12/11/2020.
//  Copyright (c) 2020 01810452. All rights reserved.
//

import UIKit
import Photos
class ViewController: UIViewController ,WQCameraViewControllerDelegate{

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let controller = WQCameraViewController.init()
        controller.modalPresentationStyle = .fullScreen
        controller.delegate = self
        
        self.present(controller, animated: true, completion: nil)
    }
    
    func mediaFinish(mediaType: NSInteger, videoFileURL: URL, photo: UIImage?, photoData: Data?, error: Error?) {
        if(mediaType == 2 && error == nil){
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoFileURL)
            } completionHandler: { (success, erro) in
                if(success){
                    NSLog("保存成功");
                }else{
                    NSLog("\(erro!.localizedDescription)");
                }
            }

        }else if(mediaType == 1 && error == nil){
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: photo!)
            } completionHandler: { (success, erro) in
                if(success){
                    NSLog("保存成功");
                }else{
                    NSLog("\(erro!.localizedDescription)");
                }
            }
        }else if(error != nil){
            NSLog("\(error!.localizedDescription)");
        }
    }
    
    
    
    
}

