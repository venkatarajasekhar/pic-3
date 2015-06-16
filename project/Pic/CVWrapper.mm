//
//  CVWrapper.m
//  Pic
//
//  Created by Kashish Hora on 06/11/2015.
//  Copyright (c) 2013 Kashish Hora. All rights reserved.
//

#import "CVWrapper.h"
#import "HistogramCalculator.h"
#import "FlowCalculator.h"
#import "ContourDetector.h"
#import "UIImage+OpenCV.h"


@implementation CVWrapper

+ (UIImage *)drawContours:(UIImage *)inputImage
{
    cv::Mat matImage = [inputImage CVMat3];
    ContourDetector::ContourDetector contourDetector;
    return [UIImage imageWithCVMat:contourDetector.processFrame(matImage)];
}

+ (NSArray *)getHistogram:(UIImage *)inputImage
{
    cv::Mat matImage = [inputImage CVMat];
    
    HistogramCalculator::HistogramCalculator histogramCalculator;
    std::vector<float> outputHistogram = histogramCalculator.calculateHistogram(matImage);
    
    NSMutableArray *histogramArray = [[NSMutableArray alloc] init];
    
    for (std::vector<float>::size_type i = 0; i != outputHistogram.size(); i++) {
       
        [histogramArray addObject:[NSNumber numberWithFloat:outputHistogram[i]]];
    }
    
    return histogramArray;
}

+ (double)calculateOpticalFlowForPreviousImage:(UIImage *)previousImage andCurrent:(UIImage *)currentImage
{
    cv::Mat previousMatrix = [previousImage CVMat];
    cv::Mat currentMatrix = [currentImage CVMat];
    
    FlowCalculator::FlowCalculator flowCalculator;
    int scale = 20;
    UIImage *previousGrayscaleScaledImage = [UIImage imageWithCVMat:getGrayscale(previousMatrix, scale)];
    UIImage *currentGrayscaleScaledImage = [UIImage imageWithCVMat:getGrayscale(currentMatrix, scale)];

    CGImageRef previousImageRef = previousGrayscaleScaledImage.CGImage;
    CGImageRef currentImageRef = currentGrayscaleScaledImage.CGImage;
    CGImageRelease(previousImageRef);
    CGImageRelease(currentImageRef);
    
    // double output = flowCalculator.calculateOpticalFlow(previousMatrix, currentMatrix);
    
    return -1;
}

@end
