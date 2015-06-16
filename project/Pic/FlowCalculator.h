//
//  FlowCalculator.h
//  Pic
//
//  Created by Kashish Hora on 6/15/15.
//  Copyright (c) 2015 Kashish Hora. All rights reserved.
//

#ifndef __Pic__FlowCalculator__
#define __Pic__FlowCalculator__

#include <stdio.h>
#include <opencv2/opencv.hpp>

cv::Mat getGrayscale(const cv::Mat& inputMatrix);

class FlowCalculator
{public:
    double calculateOpticalFlow(const cv::Mat& previousMatrix, const cv::Mat& currentMatrix);
};

#endif /* defined(__Pic__FlowCalculator__) */
