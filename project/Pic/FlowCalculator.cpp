//
//  FlowCalculator.cpp
//  Pic
//
//  Created by Kashish Hora on 6/15/15.
//  Copyright (c) 2015 Kashish Hora. All rights reserved.
//

#include "FlowCalculator.h"

using namespace cv;
using namespace std;

Mat getGrayscale(const Mat& inputMatrix, int scale) {
    Mat sampleMatrix(inputMatrix.rows / scale, inputMatrix.cols / scale, inputMatrix.type());
    resize(inputMatrix, sampleMatrix, sampleMatrix.size());
    Mat grayscaleResizedMatrix;
    cvtColor(sampleMatrix, grayscaleResizedMatrix, COLOR_BGR2GRAY);
    return grayscaleResizedMatrix;
}

double FlowCalculator::calculateOpticalFlow(const Mat& previousMatrix, const Mat& currentMatrix)
{
    // TODO: Figure out how scale is relevent
    float scale = 30;
    
    // Generate scaled grayscale image from previousMatrix
    Mat previousGrayscale = getGrayscale(previousMatrix, scale);
    
    // Generate scaled grayscale image from currentMatrix
    Mat currentGrayscale = getGrayscale(currentMatrix, scale);
    
    double m = -1;
    
    Mat flowMatrix(currentGrayscale.rows, currentGrayscale.cols, CV_32FC2);
    
//    calcOpticalFlowFarneback(currentGrayscale, currentGrayscale, flowMatrix,
//                             0.5,
//                             3,
//                             15,
//                             3,
//                             5,
//                             1.2,
//                             0);

//    for (int y = 0; y < currentGrayscale.rows; y++) {
//        for (int x = 0; x < currentGrayscale.cols; x++) {
//            double deltaX = flowMatrix.at<Vec2f>(y,x)[0] - x;
//            double deltaY = flowMatrix.at<Vec2f>(y,x)[1] - y;
//            m += abs(deltaX) + abs(deltaY);
//        }
//    }
    
    previousGrayscale.release();
    currentGrayscale.release();
    flowMatrix.release();
    
    return m;
}