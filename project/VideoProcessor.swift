//
//  VideoProcessor.swift
//  Pic
//
//  Created by Kashish Hora on 12/27/14.
//  Copyright (c) 2014 Kashish Hora. All rights reserved.
//

import UIKit
import AVFoundation
import ImageIO
import CoreMotion

typealias FaceScore = Double
typealias AccelerationScore = Double
typealias GravityScore = Double
typealias Timestamp = Double

let kProcessingQueueName = "ProcessingQueue"

struct Frame {
    var frameTimestamp: Timestamp?
    var frameBuffer: CVImageBuffer?
    var frameImage: UIImage?
    var faceScore: FaceScore?
    var motionData: CMDeviceMotion?
    var accelerationScore: AccelerationScore?
    var gravityScore: GravityScore?
    var histogram: NSArray?
    
    func getImage() -> UIImage? {
        return frameImage
    }
    
    func getImageDeprec() -> UIImage? {
        
        CVPixelBufferLockBaseAddress(frameBuffer, 0)
        
        var baseAddress = CVPixelBufferGetBaseAddress(frameBuffer)
        
        let bytesPerRow: size_t = CVPixelBufferGetBytesPerRow(frameBuffer);
        // Get the pixel buffer width and height
        let width: size_t = CVPixelBufferGetWidth(frameBuffer);
        let height: size_t = CVPixelBufferGetHeight(frameBuffer);
        
        let colorSpace: CGColorSpaceRef = CGColorSpaceCreateDeviceRGB()
        
        let bitmapInfo = CGBitmapInfo(CGImageAlphaInfo.PremultipliedFirst.rawValue) | CGBitmapInfo.ByteOrder32Little
        let context: CGContextRef = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, bitmapInfo)
        
        let cgImage = CGBitmapContextCreateImage(context)
        
        CVPixelBufferUnlockBaseAddress(frameBuffer,0)
        
        return UIImage(CGImage: cgImage, scale: 1, orientation: UIImageOrientation.Right)
    }
}

class VideoProcessor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var faceDetector: CIDetector!
    var frameData: [Frame]!
    var processingQueue: dispatch_queue_t!
    var motionDataArray: [CMDeviceMotion]!
    

    init(faceDetector: CIDetector) {
        self.faceDetector = faceDetector
        self.frameData = Array<Frame>()
        self.processingQueue = dispatch_queue_create(kProcessingQueueName, DISPATCH_QUEUE_SERIAL)
        self.motionDataArray = Array<CMDeviceMotion>()
    }
    
    func processFrames(sampleBuffer: CMSampleBuffer!, timestamp: CMTime, imageOptions:Dictionary<NSString, Int>, videoBox: CGRect) {
        let pixelBuffer: CVPixelBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)
    
        let ciImage = CIImage(CVPixelBuffer: pixelBuffer)
        let uiImage = UIImage(CIImage: ciImage, scale: 1.0, orientation: .Right)
        
        var features = [CIFaceFeature]()
            
        if faceDetector != nil {
            features = faceDetector.featuresInImage(ciImage, options: imageOptions) as! [CIFaceFeature]
        }
        var seconds: Timestamp = Double(timestamp.value) / Double(timestamp.timescale)
        
        var newFrame = Frame(frameTimestamp: seconds, frameBuffer: nil, frameImage: uiImage, faceScore: self.faceScore(features), motionData: nil, accelerationScore: nil, gravityScore: nil, histogram: CVWrapper.getHistogram(uiImage))
        
        dispatch_sync(processingQueue, { () -> Void in
            self.addFrameInSync(newFrame)
        })
    }

    func processMotion(newMotionData: CMDeviceMotion) {
        dispatch_async(processingQueue, { () -> Void in
            self.addMotionInSync(newMotionData)
        })
    }
    
    func addMotionInSync(newMotionData: CMDeviceMotion) {
        if motionDataArray.count == 0 {
            motionDataArray.append(newMotionData)
        } else {
            var currentIndex = 0
            while (motionDataArray[currentIndex].timestamp < newMotionData.timestamp) && (currentIndex < motionDataArray.count - 1) {
                currentIndex++
            }
            motionDataArray.insert(newMotionData, atIndex: currentIndex)
        }
    }
    
    func reset(){
        self.frameData = Array<Frame>()
        self.motionDataArray = Array<CMDeviceMotion>()
    }
    
    func getBestFrame() -> Frame? {
        var output = Array<Frame>()
        var maxFrame = Frame(frameTimestamp: nil, frameBuffer: nil, frameImage: nil, faceScore: nil, motionData: nil, accelerationScore: 0, gravityScore: 0, histogram: nil)
        let frameSet = self.frameData
        for (index, frame: Frame) in enumerate(frameData) {
            if frame.faceScore >= maxFrame.faceScore {
                if let accelerationScore = frame.accelerationScore {
                    if let gravityScore = frame.gravityScore {
                        if accelerationScore + gravityScore > maxFrame.accelerationScore! + maxFrame.gravityScore! {
                            //println("frame[\(index)]: \(frame.frameTimestamp)")
                            maxFrame = frame
                        }
                    }
                }
            }
        }
        return maxFrame
    }
    
    func syncMotion() {
        var frameIndex = 0
        var motionIndex = 0
        if motionDataArray.count == 0 {
            fatalError("There isn't any MotionData.")
        }
        // Start at first frame that also has corresponding motion
        while frameData[frameIndex].frameTimestamp < motionDataArray[motionIndex].timestamp {
            frameData.removeAtIndex(frameIndex)
        }
        
        while frameIndex < frameData.count {
            // If we've run out of Motion Data elements, trigger fatal error
            if motionIndex >= motionDataArray.count {
                fatalError("Error: not enough motion data - motionIndex: \(motionIndex) > motionDataArray.count: \(motionDataArray.count).")
            }
            
            var minDifference = DBL_MAX
            
            // Keep checking next MotionData element while the timestamp difference is decreasing
            while fabs(frameData[frameIndex].frameTimestamp! - motionDataArray[motionIndex].timestamp) < minDifference {
                minDifference = fabs(frameData[frameIndex].frameTimestamp! - motionDataArray[motionIndex].timestamp)
                motionIndex++
            }
            frameData[frameIndex].motionData = motionDataArray[motionIndex - 1]
            frameIndex++
        }
    }
    
    func generateAccelerationScores() {
        var currentIndex = 1
        var maxGravity = 0.0
        var maxAcceleration = 0.0
        
        // Set first frame score to 0
        frameData[0].accelerationScore = 0.0
        frameData[0].gravityScore = 0.0
        
        while currentIndex < frameData.count {
            frameData[currentIndex].gravityScore = accelerationDifferenceMagnitude(frameData[currentIndex - 1].motionData?.gravity, second: frameData[currentIndex].motionData?.gravity)
            frameData[currentIndex].accelerationScore = accelerationDifferenceMagnitude(frameData[currentIndex - 1].motionData?.userAcceleration, second: frameData[currentIndex].motionData?.userAcceleration)
            
            if let value = frameData[currentIndex].gravityScore {
                if value > maxGravity {
                    maxGravity = value
                }
            }
            if let value = frameData[currentIndex].accelerationScore {
                if value > maxAcceleration {
                    maxAcceleration = value
                }
            }
            currentIndex++
        }
        
        currentIndex = 1
        // Scale scores to make more positive = better
        while currentIndex < frameData.count {
            if let unscaledGravityScore = frameData[currentIndex].gravityScore {
                frameData[currentIndex].gravityScore = maxGravity - unscaledGravityScore
            }
            if let unscaledAccelerationScore = frameData[currentIndex].accelerationScore {
                frameData[currentIndex].accelerationScore = maxAcceleration - unscaledAccelerationScore
            }
            currentIndex++
        }
    }
    
    func printScores() {
        for frame: Frame in frameData {
            if let score = frame.accelerationScore {
                println("\(score)")
            }
        }
    }
    
    func printFrameTimestampsInorder() {
        for frame: Frame in frameData {
            println("\(frame.frameTimestamp), \(frame.motionData?.timestamp)")
        }
    }
    
    func printMotionDataTimestampsInorder() {
        for motionData: CMDeviceMotion in motionDataArray {
            println("\(motionData.timestamp)")
        }
    }
    
    private func addFrameInSync(newFrame: Frame) {
        if frameData.count == 0 {
            frameData.append(newFrame)
        } else {
            var currentIndex = 0
            while (frameData[currentIndex].frameTimestamp < newFrame.frameTimestamp) && (currentIndex < frameData.count - 1) {
                currentIndex++
            }
            NSLog("frame[%i].faceScore", currentIndex)
            
            frameData.insert(newFrame, atIndex: currentIndex)
        }
    }
    
    private func faceScore(features: [CIFaceFeature]) -> FaceScore {
        var score = 0.0
        
        for face: CIFaceFeature in features {
            //score += 1.0
            if face.hasLeftEyePosition && !face.leftEyeClosed {
                score += 1.0
            }
            if face.hasRightEyePosition && !face.rightEyeClosed {
                score += 1.0
            }
            if face.hasSmile {
                score += 1.0
            }
        }
        return score
    }
    
    private func accelerationDifferenceMagnitude(first: CMAcceleration?, second: CMAcceleration?) -> Double? {
        var output: Double?
        if let first = first {
            if let second = second {
                var x = second.x - first.x
                var y = second.y - second.y
                var z = second.z - second.z
                output = sqrt(x*x + y*y + z*z)
            }
        }
        return output
    }
}