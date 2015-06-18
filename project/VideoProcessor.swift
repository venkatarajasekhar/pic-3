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
typealias OpticalFlowScore = Double
typealias Timestamp = Double

let kProcessingQueueName = "ProcessingQueue"
let kSyncingDelay = 10

struct Frame {
    var frameTimestamp: Timestamp? = nil
    var frameImage: UIImage? = nil
    var faceScore: FaceScore = 0.0
    var motionData: CMDeviceMotion? = nil
    var accelerationScore: AccelerationScore = 0.0
    var gravityScore: GravityScore = 0.0
    
    func getImage() -> UIImage? {
        return frameImage
    }
}

class VideoProcessor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var faceDetector: CIDetector!
    var frameData: [Frame]!
    var processingQueue: dispatch_queue_t!
    var flowProcessingQueue: dispatch_queue_t!
    var motionDataArray: [CMDeviceMotion]!
    var currentlyProcessing: Bool
    
    init(faceDetector: CIDetector) {
        self.faceDetector = faceDetector
        self.frameData = [Frame]()
        self.processingQueue = dispatch_queue_create(kProcessingQueueName, DISPATCH_QUEUE_SERIAL)
        self.motionDataArray = [CMDeviceMotion]()
        self.currentlyProcessing = true
    }
    
    func processFrames(ciImage: CIImage, timestamp: CMTime, imageOptions:Dictionary<NSString, Int>, videoBox: CGRect) {
        if currentlyProcessing {
            let uiImage = UIImage(CIImage: ciImage, scale: 1.0, orientation: .Right)
            var features = [CIFaceFeature]()
            
            if faceDetector != nil {
                features = faceDetector.featuresInImage(ciImage, options: imageOptions) as! [CIFaceFeature]
            }
            var seconds: Timestamp = Double(timestamp.value) / Double(timestamp.timescale)
            var newFrame = Frame(frameTimestamp: seconds, frameImage: uiImage, faceScore: self.faceScore(features), motionData: nil, accelerationScore: 0, gravityScore: 0)

            dispatch_sync(processingQueue, { () -> Void in
                self.addFrameInSync(newFrame)
            })
        }
    }
    
    private func addFrameInSync(newFrame: Frame) {
        if frameData.count == 0 {
            frameData.append(newFrame)
        } else {
            var currentIndex = frameData.count - kSyncingDelay >= 0 ? frameData.count - kSyncingDelay : 0
            while (frameData[currentIndex].frameTimestamp < newFrame.frameTimestamp) && (currentIndex < frameData.count - 1) {
                currentIndex++
            }
            if currentIndex == frameData.count {
                NSLog("Frame dropped.")
            }
            else {
                NSLog("frameData[%i] added.", currentIndex)
                frameData.insert(newFrame, atIndex: currentIndex)
            }
        }
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
    
    func getBestFrame() -> Frame? {
        var output = Array<Frame>()
        var maxFrame = Frame()
        let frameSet = self.frameData
        for (index, frame: Frame) in enumerate(frameData) {
            if frame.faceScore >= maxFrame.faceScore {
                if frame.accelerationScore + frame.gravityScore > maxFrame.accelerationScore + maxFrame.gravityScore {
                    //println("frame[\(index)]: \(frame.frameTimestamp)")
                    maxFrame = frame
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
            
            maxGravity = frameData[currentIndex].gravityScore > maxGravity ? frameData[currentIndex].gravityScore : maxGravity
            maxAcceleration = frameData[currentIndex].accelerationScore > maxGravity ? frameData[currentIndex].accelerationScore : maxGravity

            currentIndex++
        }
        
        currentIndex = 1
        // Scale scores to make more positive = better
        while currentIndex < frameData.count {
            frameData[currentIndex].gravityScore = maxGravity - frameData[currentIndex].gravityScore
            frameData[currentIndex].accelerationScore = maxAcceleration - frameData[currentIndex].accelerationScore
            currentIndex++
        }
    }
    
    func printScores() {
        for frame: Frame in frameData {
            println("\(frame.accelerationScore)")
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
    
    func reset(){
        self.frameData = [Frame]()
        self.motionDataArray = [CMDeviceMotion]()
    }
    
    func stopProcessing() {
        self.currentlyProcessing = false
    }
    
    func startProcessing() {
        self.currentlyProcessing = true
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
    
    private func accelerationDifferenceMagnitude(first: CMAcceleration?, second: CMAcceleration?) -> Double {
        var output = 0.0
        if let first = first, second = second {
            var x = second.x - first.x
            var y = second.y - second.y
            var z = second.z - second.z
            output = sqrt(x*x + y*y + z*z)
        }
        return output
    }
}