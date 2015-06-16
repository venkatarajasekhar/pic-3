//
//  UIImage+Convert.h
//  Pic
//
//  Created by Kashish Hora on 6/16/15.
//  Copyright (c) 2015 Kashish Hora. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>

@interface UIImage (Convert)

+ (UIImage *)imageWithBuffer:(CMSampleBufferRef)sampleBuffer;

@end
