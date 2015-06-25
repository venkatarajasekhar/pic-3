//
//  FrameProcessor.swift
//  Pic
//
//  Created by Kashish Hora on 6/24/15.
//  Copyright (c) 2015 Kashish Hora. All rights reserved.
//

import AVFoundation

let kFrameProcessorSyncingDelay = 10

class FrameProcessor: NSObject {
    var frameDataArray: [FrameData]
    var processingQueue: dispatch_queue_t
    private var currentlyProcessing: Bool = false
    
    init(queueName: String) {
        self.processingQueue = dispatch_queue_create(queueName, DISPATCH_QUEUE_SERIAL)
        self.frameDataArray = [FrameData]()
    }
    
    func processFrameData(ciImage: CIImage, timestamp: CMTime, imageOptions: Dictionary<NSString, Int>, videoBox: CGRect) {
        if currentlyProcessing {
            let uiImage = UIImage(CIImage: ciImage, scale: 1.0, orientation: .Right)
            let seconds: Timestamp = Double(timestamp.value) / Double(timestamp.timescale)
            if let image = uiImage {
                let newFrameData = FrameData(image: image, timestamp: seconds)
                addFrameDataInSync(newFrameData)
            } else {
                NSLog("Invalid image found.")
            }
        }
    }
    
    func addFrameDataInSync(newFrameData: FrameData) {
        if frameDataArray.count == 0 {
            frameDataArray.append(newFrameData)
        } else {
            var currentIndex = frameDataArray.count - kFrameProcessorSyncingDelay >= 0 ? frameDataArray.count - kVideoProcessorSyncingDelay : 0
            while (frameDataArray[currentIndex].timestamp < newFrameData.timestamp) && (currentIndex < frameDataArray.count - 1) {
                currentIndex++
            }
            if currentIndex == frameDataArray.count {
                NSLog("newFrameData dropped.")
            } else {
                NSLog("frameDataArray[%i] added.", currentIndex)
                frameDataArray.insert(newFrameData, atIndex: currentIndex)
            }
        }
    }
}
