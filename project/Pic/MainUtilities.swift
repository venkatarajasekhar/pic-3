//
//  MainUtilities.swift
//  Pic
//
//  Created by Kashish Hora on 6/24/15.
//  Copyright (c) 2015 Kashish Hora. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import ImageIO
import CoreMotion

typealias FaceScore = Double
typealias AccelerationScore = Double
typealias GravityScore = Double
typealias OpticalFlowScore = Double
typealias Timestamp = Double

let kVideoProcessorProcessingQueueName = "VideoProcessingQueue"
let kVideoProcessorSyncingDelay = 10

let kFrameProcessorProcessingQueueName = "FrameProcessingQueue"

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

struct FrameData {
    private var image: UIImage
    var timestamp: Timestamp
    
    init(image: UIImage, timestamp: Timestamp) {
        self.image = image
        self.timestamp = timestamp
    }
    
    func getImage() -> UIImage {
        return self.image
    }
}
