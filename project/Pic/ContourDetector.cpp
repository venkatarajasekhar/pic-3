//
//  ContourDetector.cpp
//  Pic
//
//  Created by Kashish Hora on 6/11/15.
//  Copyright (c) 2015 Kashish Hora. All rights reserved.
//

#include "ContourDetector.h"

using namespace cv;
using namespace std;


bool ContourDetector::processFrame(const cv::Mat &inputFrame, cv::Mat &outputFrame)
{
    cvtColor(inputFrame, gray, cv::COLOR_BGR2GRAY);
    
    Mat edges;
    Canny(gray, edges, 50, 150);
    vector<vector<Point>> c;
    findContours(edges, c, RETR_LIST, CHAIN_APPROX_NONE);
    
    inputFrame.copyTo(outputFrame);
    drawContours(outputFrame, c, -1, Scalar(0,200,0));
    
    return true;
}