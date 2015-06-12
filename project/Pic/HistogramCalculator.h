//
//  HistogramCalculator.h
//  Pic
//
//  Created by Kashish Hora on 6/11/15.
//  Copyright (c) 2015 Kashish Hora. All rights reserved.
//

#ifndef __Pic__HistogramCalculator__
#define __Pic__HistogramCalculator__

#include <stdio.h>
#include <opencv2/opencv.hpp>
#include <iostream>

class HistogramCalculator
{
    // Calculates histogram and writes it tou outputHistogram
public:
    std::vector<cv::Mat> calculateHistogram(const cv::Mat& inputFrame);
};


#endif /* defined(__Pic__HistogramCalculator__) */
