//
//  CameraEngine.swift
//  naruhodo
//
//  Created by FUJIKI TAKESHI on 2014/11/10.
//  Copyright (c) 2014年 Takeshi Fujiki. All rights reserved.
//

import Foundation
import AVFoundation
import AssetsLibrary

class CameraEngine : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate{

    let captureSession = AVCaptureSession()
    let videoDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    let audioDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
    var videoWriter : VideoWriter?

    var height:Int?
    var width:Int?
    
    var isCapturing = false
    var isPaused = false
    var isDiscontinue = false
    var fileIndex = 0
    
    var timeOffset = CMTimeMake(0, 0)
    var lastAudioPts: CMTime?

    let lockQueue = dispatch_queue_create("com.takecian.LockQueue", nil)
    let recordingQueue = dispatch_queue_create("com.takecian.RecordingQueue", DISPATCH_QUEUE_SERIAL)

    func startup(){
        // video input
        videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, 30)
        
        do
        {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice) as AVCaptureDeviceInput
            captureSession.addInput(videoInput)
        }
        catch let error as NSError {
            Logger.log(error.localizedDescription)
        }

        do
        {
            let audioInput = try AVCaptureDeviceInput(device: audioDevice) as AVCaptureDeviceInput
            captureSession.addInput(audioInput)
        }
        catch let error as NSError {
            Logger.log(error.localizedDescription)
        }
        
        // video output
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.setSampleBufferDelegate(self, queue: recordingQueue)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey : Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
        ]
        captureSession.addOutput(videoDataOutput)
        
        height = videoDataOutput.videoSettings["Height"] as! Int!
        width = videoDataOutput.videoSettings["Width"] as! Int!
        
        // audio output
        let audioDataOutput = AVCaptureAudioDataOutput()
        audioDataOutput.setSampleBufferDelegate(self, queue: recordingQueue)
        captureSession.addOutput(audioDataOutput)
        
        captureSession.startRunning()
    }
    
    func shutdown(){
        captureSession.stopRunning()
    }

    func start(){
        dispatch_sync(lockQueue) {
            if !self.isCapturing{
                Logger.log("in")
                self.isPaused = false
                self.isDiscontinue = false
                self.isCapturing = true
                self.timeOffset = CMTimeMake(0, 0)
            }
        }
    }
    
    func stop(){
        dispatch_sync(self.lockQueue) {
            if self.isCapturing{
                self.isCapturing = false
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    Logger.log("in")
                    self.videoWriter!.finish { () -> Void in
                        Logger.log("Recording finished.")
                        self.videoWriter = nil
                        let assetsLib = ALAssetsLibrary()
                        assetsLib.writeVideoAtPathToSavedPhotosAlbum(self.filePathUrl(), completionBlock: {
                            (nsurl, error) -> Void in
                            Logger.log("Transfer video to library finished.")
                            self.fileIndex += 1
                        })
                    }
                })
            }
        }
    }
    
    func pause(){
        dispatch_sync(self.lockQueue) {
            if self.isCapturing{
                Logger.log("in")
                self.isPaused = true
                self.isDiscontinue = true
            }
        }
    }
    
    func resume(){
        dispatch_sync(self.lockQueue) {
            if self.isCapturing{
                Logger.log("in")
                self.isPaused = false
            }
        }
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!){
        dispatch_sync(self.lockQueue) {
            if !self.isCapturing || self.isPaused {
                return
            }
            
            let isVideo = captureOutput is AVCaptureVideoDataOutput
            
            if self.videoWriter == nil && !isVideo {
                let fileManager = NSFileManager()
                if fileManager.fileExistsAtPath(self.filePath()) {
                    do {
                        try fileManager.removeItemAtPath(self.filePath())
                    } catch _ {
                    }
                }
                
                let fmt = CMSampleBufferGetFormatDescription(sampleBuffer)
                let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmt!)
                
                Logger.log("setup video writer")
                self.videoWriter = VideoWriter(
                    fileUrl: self.filePathUrl(),
                    height: self.height!, width: self.width!,
                    channels: Int(asbd.memory.mChannelsPerFrame),
                    samples: asbd.memory.mSampleRate
                )
            }
            
            if self.isDiscontinue {
                if isVideo {
                    return
                }

                var pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

                let isAudioPtsValid = self.lastAudioPts!.flags.intersect(CMTimeFlags.Valid)
                if isAudioPtsValid.rawValue != 0 {
                    Logger.log("isAudioPtsValid is valid")
                    let isTimeOffsetPtsValid = self.timeOffset.flags.intersect(CMTimeFlags.Valid)
                    if isTimeOffsetPtsValid.rawValue != 0 {
                        Logger.log("isTimeOffsetPtsValid is valid")
                        pts = CMTimeSubtract(pts, self.timeOffset);
                    }
                    let offset = CMTimeSubtract(pts, self.lastAudioPts!);

                    if (self.timeOffset.value == 0)
                    {
                        Logger.log("timeOffset is \(self.timeOffset.value)")
                        self.timeOffset = offset;
                    }
                    else
                    {
                        Logger.log("timeOffset is \(self.timeOffset.value)")
                        self.timeOffset = CMTimeAdd(self.timeOffset, offset);
                    }
                }
                self.lastAudioPts!.flags = CMTimeFlags()
                self.isDiscontinue = false
            }
            
            var buffer = sampleBuffer
            if self.timeOffset.value > 0 {
                buffer = self.ajustTimeStamp(sampleBuffer, offset: self.timeOffset)
            }

            if !isVideo {
                var pts = CMSampleBufferGetPresentationTimeStamp(buffer)
                let dur = CMSampleBufferGetDuration(buffer)
                if (dur.value > 0)
                {
                    pts = CMTimeAdd(pts, dur)
                }
                self.lastAudioPts = pts
            }
            
            self.videoWriter?.write(buffer, isVideo: isVideo)
        }
    }
    
    func filePath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0] as String
        let filePath : String = "\(documentsDirectory)/video\(self.fileIndex).mp4"
        return filePath
    }
    
    func filePathUrl() -> NSURL! {
        return NSURL(fileURLWithPath: self.filePath())
    }
    
    func ajustTimeStamp(sample: CMSampleBufferRef, offset: CMTime) -> CMSampleBufferRef {
        var count: CMItemCount = 0
        CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
        var info = [CMSampleTimingInfo](count: count, repeatedValue: CMSampleTimingInfo(duration: CMTimeMake(0, 0), presentationTimeStamp: CMTimeMake(0, 0), decodeTimeStamp: CMTimeMake(0, 0)))
        CMSampleBufferGetSampleTimingInfoArray(sample, count, &info, &count);

        for i in 0..<count {
            info[i].decodeTimeStamp = CMTimeSubtract(info[i].decodeTimeStamp, offset);
            info[i].presentationTimeStamp = CMTimeSubtract(info[i].presentationTimeStamp, offset);
        }

        var out: CMSampleBuffer?
        CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, &info, &out);
        return out!
    }
}
