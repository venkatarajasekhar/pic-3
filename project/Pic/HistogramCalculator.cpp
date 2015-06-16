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

vector<float> HistogramCalculator::calculateHistogram(const Mat &inputMatrix)
{
    
    // Split inputFrame into R, G, and B components
    vector<Mat> bgrPlanes;
    split(inputMatrix, bgrPlanes);
    
    // cout << "inputMatrix = " << endl << " " << inputMatrix << endl << endl;
    
    int histSize = 256;
    float range[] = {0, 256};
    const float* histRange = {range};
    bool uniform = true;
    bool accumulate = true;
    
    Mat b_hist, g_hist, r_hist;
    
    calcHist(&bgrPlanes[0], 1, 0, Mat(), b_hist, 1, &histSize, &histRange, uniform, accumulate);
    calcHist(&bgrPlanes[1], 1, 0, Mat(), g_hist, 1, &histSize, &histRange, uniform, accumulate);
    calcHist(&bgrPlanes[2], 1, 0, Mat(), r_hist, 1, &histSize, &histRange, uniform, accumulate);
    
    vector<float> outputVector;

    for(int i = 0; i < histSize; i++ ) {
        outputVector.push_back(b_hist.at<float>(i));
    }
    for( int i = 0; i < histSize; i++ ) {
        outputVector.push_back(g_hist.at<float>(i));
    }
    for( int i = 0; i < histSize; i++ ){
        outputVector.push_back(r_hist.at<float>(i));
    }
    
    return outputVector;

}