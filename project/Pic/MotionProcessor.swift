//
//  MotionProcessor.swift
//  Pic
//
//  Created by Kashish Hora on 6/25/15.
//  Copyright (c) 2015 Kashish Hora. All rights reserved.
//

import CoreMotion

let kMotionProcessorSyncingDelay = 10

class MotionProcessor: NSObject {
    var motionDataArray: [CMDeviceMotion]
    var processingQueue: dispatch_queue_t
    private var currentlyProcessing: Bool = false
    
    init(queueName: String) {
        self.processingQueue = dispatch_queue_create(queueName, DISPATCH_QUEUE_SERIAL)
        self.motionDataArray = [CMDeviceMotion]()
    }
    
    func processMotionData(newMotionData: CMDeviceMotion) {
        addMotionDataInSync(newMotionData)
    }
    
    func addMotionDataInSync(newMotionData: CMDeviceMotion) {
        if motionDataArray.count == 0 {
            motionDataArray.append(newMotionData)
        } else {
            var currentIndex = motionDataArray.count - kMotionProcessorSyncingDelay >= 0 ? motionDataArray.count - kMotionProcessorSyncingDelay : 0
            while (motionDataArray[currentIndex].timestamp < newMotionData.timestamp) && (currentIndex < motionDataArray.count - 1) {
                currentIndex++
            }
            if currentIndex == motionDataArray.count {
                NSLog("newMotionData dropped.")
            } else {
                NSLog("motionDataArray[%i] added.", currentIndex)
                motionDataArray.insert(newMotionData, atIndex: currentIndex)
            }
        }
    }
}