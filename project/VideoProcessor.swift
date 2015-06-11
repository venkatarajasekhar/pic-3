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
    var frameImage: UIImage?
    var faceScore: FaceScore?
    var motionData: CMDeviceMotion?
    var accelerationScore: AccelerationScore?
    var gravityScore: GravityScore?
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
        
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        CVPixelBufferLockBaseAddress(imageBuffer, 0)
        
        var baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
        
        let bytesPerRow: size_t = CVPixelBufferGetBytesPerRow(imageBuffer);
        // Get the pixel buffer width and height
        let width: size_t = CVPixelBufferGetWidth(imageBuffer);
        let height: size_t = CVPixelBufferGetHeight(imageBuffer);
        
        let colorSpace: CGColorSpaceRef = CGColorSpaceCreateDeviceRGB()
        
        let bitmapInfo = CGBitmapInfo(CGImageAlphaInfo.PremultipliedFirst.rawValue) | CGBitmapInfo.ByteOrder32Little
        let context: CGContextRef = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, bitmapInfo)
        
        let cgImage = CGBitmapContextCreateImage(context)
        
        CVPixelBufferUnlockBaseAddress(imageBuffer,0)
        
        let image = UIImage(CGImage: cgImage, scale: 1, orientation: UIImageOrientation.Right)
        
        var features = [CIFaceFeature]()
            
        if faceDetector != nil {
            features = faceDetector.featuresInImage(CIImage(CGImage: image?.CGImage), options: imageOptions) as! [CIFaceFeature]
        }
        
        var seconds: Timestamp = Double(timestamp.value) / Double(timestamp.timescale)
        var newFrame = Frame(frameTimestamp: seconds, frameImage: image, faceScore: self.faceScore(features), motionData: nil, accelerationScore: nil, gravityScore: nil)
        
        dispatch_sync(processingQueue, { () -> Void in
            self.addFrameInSync(newFrame)
        })
    }
    
    func renderFrame(frame: Frame) -> UIImage {
        return UIImage()
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
        var maxFrame = Frame(frameTimestamp: nil, frameImage: nil, faceScore: 0, motionData: nil, accelerationScore: 0, gravityScore: 0)
        let frameSet = self.frameData
        println()
        for (index, frame: Frame) in enumerate(frameData) {
            if frame.faceScore >= maxFrame.faceScore {
                if let accelerationScore = frame.accelerationScore {
                    if let gravityScore = frame.gravityScore {
                        if accelerationScore + gravityScore > maxFrame.accelerationScore! + maxFrame.gravityScore! {
                            println("frame[\(index)]: \(frame)")
                            maxFrame = frame
                        }
                    }
                }
            }
        }
        let allFrameData = frameData
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
            println("frame[\(currentIndex)].faceScore = \(newFrame.faceScore)")
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