//
//  CVWrapper.m
//  Pic
//
//  Created by Kashish Hora on 06/11/2015.
//  Copyright (c) 2013 Kashish Hora. All rights reserved.
//

#import "CVWrapper.h"
#import "UIImage+OpenCV.h"
#import "ContourDetector.h"
#import "HistogramCalculator.h"

@implementation CVWrapper

+ (UIImage *)drawContours:(UIImage *)inputImage
{
    cv::Mat matImage = [inputImage CVMat3];
    ContourDetector::ContourDetector contourDetector;
    return [UIImage imageWithCVMat:contourDetector.processFrame(matImage)];
}

+ (UIImage *)getHistogram:(UIImage *)inputImage
{
    cv::Mat matImage = [inputImage CVMat3];
    
    HistogramCalculator::HistogramCalculator histogramCalculator;
    cv::Mat outputHistogram = histogramCalculator.calculateHistogram(matImage);
    
    
    return [UIImage imageWithCVMat:outputHistogram];
}


@end
