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

Mat getGrayscale(const Mat& inputMatrix) {
    Mat grayscaleMatrix;
    cvtColor(inputMatrix, grayscaleMatrix, COLOR_BGR2GRAY);
    return grayscaleMatrix;
}

double FlowCalculator::calculateOpticalFlow(const Mat& previousMatrix, const Mat& currentMatrix)
{
    // TODO: Figure out how scale is relevent
    float scale = 1;
    
    // Generate scaled grayscale image from previousMatrix
    Mat previousGrayscale = getGrayscale(previousMatrix);
    
    // Generate scaled grayscale image from currentMatrix
    Mat currentGrayscale = getGrayscale(currentMatrix);
    
    double m = -1;
    
    Mat flowMatrix(currentGrayscale.rows, currentGrayscale.cols, CV_32FC2);
    
    calcOpticalFlowFarneback(currentGrayscale, currentGrayscale, flowMatrix,
                             0.5,
                             3,
                             15,
                             3,
                             5,
                             1.2,
                             0);
    // cout << "currentScaledMatrix = " << endl << " " << currentScaledMatrix << endl << endl;

    return m;
}