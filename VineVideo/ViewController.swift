//
//  ViewController.swift
//  VineVideo
//
//  Created by FUJIKI TAKESHI on 2014/11/13.
//  Copyright (c) 2014年 Takeshi Fujiki. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    var startButton, stopButton, pauseResumeButton : UIButton!
    var isRecording = false
    let cameraEngine = CameraEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.cameraEngine.startup()
        
        let videoLayer = AVCaptureVideoPreviewLayer(session: self.cameraEngine.captureSession)
        videoLayer.frame = self.view.bounds
        videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.view.layer.addSublayer(videoLayer)
        
        self.setupButton()
    }
    
    func setupButton(){
        self.startButton = UIButton(frame: CGRectMake(0,0,60,50))
        self.startButton.backgroundColor = UIColor.redColor()
        self.startButton.layer.masksToBounds = true
        self.startButton.setTitle("start", forState: .Normal)
        self.startButton.layer.cornerRadius = 20.0
        self.startButton.layer.position = CGPoint(x: self.view.bounds.width/5, y:self.view.bounds.height-50)
        self.startButton.addTarget(self, action: #selector(ViewController.onClickStartButton(_:)), forControlEvents: .TouchUpInside)
        
        self.stopButton = UIButton(frame: CGRectMake(0,0,60,50))
        self.stopButton.backgroundColor = UIColor.grayColor()
        self.stopButton.layer.masksToBounds = true
        self.stopButton.setTitle("stop", forState: .Normal)
        self.stopButton.layer.cornerRadius = 20.0
        self.stopButton.layer.position = CGPoint(x: self.view.bounds.width/5 * 2, y:self.view.bounds.height-50)
        self.stopButton.addTarget(self, action: #selector(ViewController.onClickStopButton(_:)), forControlEvents: .TouchUpInside)
        
        self.pauseResumeButton = UIButton(frame: CGRectMake(0,0,60,50))
        self.pauseResumeButton.backgroundColor = UIColor.grayColor()
        self.pauseResumeButton.layer.masksToBounds = true
        self.pauseResumeButton.setTitle("pause", forState: .Normal)
        self.pauseResumeButton.layer.cornerRadius = 20.0
        self.pauseResumeButton.layer.position = CGPoint(x: self.view.bounds.width/5 * 3, y:self.view.bounds.height-50)
        self.pauseResumeButton.addTarget(self, action: #selector(ViewController.onClickPauseButton(_:)), forControlEvents: .TouchUpInside)
        
        self.view.addSubview(self.startButton)
        self.view.addSubview(self.stopButton);
        self.view.addSubview(self.pauseResumeButton);
    }
    
    func onClickStartButton(sender: UIButton){
        if !self.cameraEngine.isCapturing {
            self.cameraEngine.start()
            self.changeButtonColor(self.startButton, color: UIColor.grayColor())
            self.changeButtonColor(self.stopButton, color: UIColor.redColor())
        }
    }
    
    func onClickPauseButton(sender: UIButton){
        if self.cameraEngine.isCapturing {
            if self.cameraEngine.isPaused {
                self.cameraEngine.resume()
                self.pauseResumeButton.setTitle("pause", forState: .Normal)
                self.pauseResumeButton.backgroundColor = UIColor.grayColor()
            }else{
                self.cameraEngine.pause()
                self.pauseResumeButton.setTitle("resume", forState: .Normal)
                self.pauseResumeButton.backgroundColor = UIColor.blueColor()
            }
        }
    }
    
    func onClickStopButton(sender: UIButton){
        if self.cameraEngine.isCapturing {
            self.cameraEngine.stop()
            self.changeButtonColor(self.startButton, color: UIColor.redColor())
            self.changeButtonColor(self.stopButton, color: UIColor.grayColor())
        }
    }
    
    func changeButtonColor(target: UIButton, color: UIColor){
        target.backgroundColor = color
    }}

