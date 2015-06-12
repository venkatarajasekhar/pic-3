//
//  HistogramCalculator.cpp
//  Pic
//
//  Created by Kashish Hora on 6/11/15.
//  Copyright (c) 2015 Kashish Hora. All rights reserved.
//

#include "HistogramCalculator.h"

using namespace cv;
using namespace std;

std::vector<cv::Mat> HistogramCalculator::calculateHistogram(const cv::Mat &inputFrame)
{
    
    // Split inputFrame into R, G, and B components
    vector<Mat> rgbPlanes;
    split(inputFrame, rgbPlanes);
    
    int histogramSize = 256;
    float range[] = {0, 256};
    const float* histogramRange = {range};
    bool uniform = true;
    bool accumulate = true;
    
    calcHist(&rgbPlanes[0], 1, 0, Mat(), rgbPlanes[0], 1, &histogramSize, &histogramRange, uniform, accumulate);
    calcHist(&rgbPlanes[1], 1, 0, Mat(), rgbPlanes[1], 1, &histogramSize, &histogramRange, uniform, accumulate);
    calcHist(&rgbPlanes[2], 1, 0, Mat(), rgbPlanes[2], 1, &histogramSize, &histogramRange, uniform, accumulate);
    
    return rgbPlanes;
}