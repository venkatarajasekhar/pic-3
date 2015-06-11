//
//  ContourDetector.h
//  Pic
//
//  Created by Kashish Hora on 6/11/15.
//  Copyright (c) 2015 Kashish Hora. All rights reserved.
//

#ifndef __Pic__ContourDetector__
#define __Pic__ContourDetector__

#include <stdio.h>
#include <opencv2/opencv.hpp>
#include <iostream>

class ContourDetector
{
    
    // Processes a frame and returns output image
    public:
        cv::Mat processFrame(const cv::Mat& inputFrame);
    
    private:
        cv::Mat gray, edges;
        void getGray(const cv::Mat& input, cv::Mat& gray);
};

#endif /* defined(__Pic__ContourDetector__) */
