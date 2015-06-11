//
//  OpticalFlowProcessor.h
//  Pic
//
//  Created by Kashish Hora on 6/10/15.
//  Copyright (c) 2015 Kashish Hora. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <opencv2/opencv.hpp>

using namespace cv;

@protocol OpticalFlowProcessorDelegate

- (void)willTrackMovement;
- (void)tracked:(CGPoint)source to:(CGPoint)destination;

@end


@interface OpticalFlowProcessor : NSObject

- (void)setDelegate:(id <OpticalFlowProcessorDelegate>)delegate_;
- (void)processImage:(CGImageRef)image;

@end
