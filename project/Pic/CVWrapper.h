//
//  CVWrapper.h
//  Pic
//
//  Created by Kashish Hora on 06/11/2015.
//  Copyright (c) 2013 Kashish Hora. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CVWrapper : NSObject

+ (UIImage *)drawContours:(UIImage *)inputImage;
+ (NSArray *)getHistogram:(UIImage *)inputImage;
+ (double)calculateOpticalFlowForPreviousImage:(UIImage *)previousImage andCurrent:(UIImage *)currentImage;
@end
