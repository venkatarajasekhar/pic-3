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

+ (UIImage *)getHistogram:(UIImage *)inputImage
{
    cv::Mat matImage = [inputImage CVMat];
    
    HistogramCalculator::HistogramCalculator histogramCalculator;
    cv::Mat outputHistogram = histogramCalculator.calculateHistogram(matImage);
    
    
    return [UIImage imageWithCVMat:outputHistogram];
    
//    std::vector<float> outputHistogram = histogramCalculator.calculateHistogram(matImage);
    
//    NSMutableArray *histogramArray = [[NSMutableArray alloc] init];
//    
//    for (std::vector<float>::size_type i = 0; i != outputHistogram.size(); i++) {
//       
//        [histogramArray addObject:[NSNumber numberWithFloat:outputHistogram[i]]];
//    }
//    
//    return histogramArray;
}

+ (double)calculateOpticalFlowForPreviousImage:(UIImage *)previousImage andCurrent:(UIImage *)currentImage
{
    cv::Mat previousMatrix = [previousImage CVMat];
    cv::Mat currentMatrix = [currentImage CVMat];
    
    // FlowCalculator::FlowCalculator flowCalculator;
    UIImage *previousGrayscaleImage = [UIImage imageWithCVMat:getGrayscale(previousMatrix)];
    UIImage *currentGrayscaleImage = [UIImage imageWithCVMat:getGrayscale(currentMatrix)];

    
    // double output = flowCalculator.calculateOpticalFlow(previousMatrix, currentMatrix);
    
    return -1;
}

@end
