//
//  OpticalFlowProcessor.m
//  Pic
//
//  Created by Kashish Hora on 6/10/15.
//  Copyright (c) 2015 Kashish Hora. All rights reserved.
//

#import "OpticalFlowProcessor.h"

@interface OpticalFlowProcessor() {
    id <OpticalFlowProcessorDelegate> delegate;
    cv::Mat previousMatrix;
    int framesBetweenProcessing;
}

@end

using namespace cv;

@implementation OpticalFlowProcessor

- (Mat)matrixFromImage:(CGImageRef)image {
    
    CGFloat rows = CGImageGetHeight(image);
    CGFloat columns = CGImageGetWidth(image);
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image);
    Mat mat(rows, columns, CV_8UC4);
    
    CGContextRef context = CGBitmapContextCreate((void *)mat.data,
                                                 columns,
                                                 rows,
                                                 8,
                                                 columns * 8,
                                                 colorSpace,
                                                 kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);
    CGContextDrawImage(context, CGRectMake(0, 0, columns, rows), image);
    CGContextRelease(context);
    return mat;
}

- (void)processImage:(CGImageRef)image {
    
    if (framesBetweenProcessing++ > 2) {
        return;
    }
    Mat matrix = [self matrixFromImage: image];
    
    float scale = 6;
    Mat sampleMatrix(matrix.rows / scale,
                     matrix.cols / scale,
                     matrix.type());
    resize(matrix, sampleMatrix, sampleMatrix.size());
    Mat grayMatrix(sampleMatrix.rows, sampleMatrix.cols, CV_8UC1);
    cvtColor(sampleMatrix, grayMatrix, CV_BGR2GRAY);
    
    if (previousMatrix.rows) {
        
        Mat flowMatrix(sampleMatrix.rows, sampleMatrix.cols, CV_32FC2);
        calcOpticalFlowFarneback(previousMatrix,
                                 grayMatrix,
                                 flowMatrix,
                                 0.5,    // pyrScale
                                 3,      // levels
                                 15,     // winsize
                                 3,      // iterations
                                 5,      // polyN
                                 1.2,    // polySigma
                                 0);
        [delegate willTrackMovement];
        
        for (int y = 0; y < sampleMatrix.rows; y++) {
            for (int x = 0; x < sampleMatrix.cols; x++) {
                [delegate tracked:CGPointMake(x * scale, y * scale)
                               to:CGPointMake(flowMatrix.at<Vec2f>(y,x)[0] * scale,
                                              flowMatrix.at<Vec2f>(y,x)[1] * scale)];
            }
        }
    }
    previousMatrix = grayMatrix;
    framesBetweenProcessing = 0;
}

- (void)setDelegate:(id<OpticalFlowProcessorDelegate>)delegate_ {
    self.delegate = delegate_;
}

@end
