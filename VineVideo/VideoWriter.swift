//
//  VideoWriter.swift
//  naruhodo
//
//  Created by FUJIKI TAKESHI on 2014/11/11.
//  Copyright (c) 2014年 Takeshi Fujiki. All rights reserved.
//

import Foundation
import AVFoundation
import AssetsLibrary

class VideoWriter : NSObject{
    var fileWriter: AVAssetWriter!
    var videoInput: AVAssetWriterInput!
    var audioInput: AVAssetWriterInput!
    
    init(fileUrl:NSURL!, height:Int, width:Int, channels:Int, samples:Float64){
        fileWriter = try? AVAssetWriter(URL: fileUrl, fileType: AVFileTypeQuickTimeMovie)
        
        let videoOutputSettings: Dictionary<String, AnyObject> = [
            AVVideoCodecKey : AVVideoCodecH264,
            AVVideoWidthKey : width,
            AVVideoHeightKey : height
        ];
        videoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoOutputSettings)
        videoInput.expectsMediaDataInRealTime = true
        fileWriter.addInput(videoInput)
        
        let audioOutputSettings: Dictionary<String, AnyObject> = [
            AVFormatIDKey : Int(kAudioFormatMPEG4AAC),
            AVNumberOfChannelsKey : channels,
            AVSampleRateKey : samples,
            AVEncoderBitRateKey : 128000
        ]
        audioInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: audioOutputSettings)
        audioInput.expectsMediaDataInRealTime = true
        fileWriter.addInput(audioInput)
    }
    
    func write(sample: CMSampleBufferRef, isVideo: Bool){
        if CMSampleBufferDataIsReady(sample) {
            if fileWriter.status == AVAssetWriterStatus.Unknown {
                Logger.log("Start writing, isVideo = \(isVideo), status = \(fileWriter.status.rawValue)")
                let startTime = CMSampleBufferGetPresentationTimeStamp(sample)
                fileWriter.startWriting()
                fileWriter.startSessionAtSourceTime(startTime)
            }
            if fileWriter.status == AVAssetWriterStatus.Failed {
                Logger.log("Error occured, isVideo = \(isVideo), status = \(fileWriter.status.rawValue), \(fileWriter.error!.localizedDescription)")
                return
            }
            if isVideo {
                if videoInput.readyForMoreMediaData {
                    videoInput.appendSampleBuffer(sample)
                }
            }else{
                if audioInput.readyForMoreMediaData {
                    audioInput.appendSampleBuffer(sample)
                }
            }
        }
    }
    
    func finish(callback: Void -> Void){
        fileWriter.finishWritingWithCompletionHandler(callback)
    }
}