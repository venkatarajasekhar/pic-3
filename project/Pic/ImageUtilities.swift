//
//  ImageUtilities.swift
//  Pic
//
//  Created by Kashish Hora on 12/27/14.
//  Copyright (c) 2014 Kashish Hora. All rights reserved.
//

import Foundation
import UIKit
import CoreImage
import ImageIO
import AssetsLibrary
import AVFoundation

let kOrientationToDegreesFront: [UIDeviceOrientation: CGFloat] = [
    .Portrait: -90,
    .PortraitUpsideDown: 90,
    .LandscapeLeft: 180,
    .LandscapeRight: 0,
    .FaceUp: 0,
    .FaceDown: 0
]

let kOrientationToDegreesBack: [UIDeviceOrientation: CGFloat] = [
    .Portrait: -90,
    .PortraitUpsideDown: 90,
    .LandscapeLeft: 0,
    .LandscapeRight: 180,
    .FaceUp: 0,
    .FaceDown: 0
]

/* kCGImagePropertyOrientation values
The intended display orientation of the image. If present, this key is a CFNumber value with the same value as defined
by the TIFF and EXIF specifications -- see enumeration of integer constants.
The value specified where the origin (0,0) of the image is located. If not present, a value of 1 is assumed.

used when calling featuresInImage: options: The value for this key is an integer NSNumber from 1..8 as found in kCGImagePropertyOrientation.
If present, the detection will be done based on that orientation but the coordinates in the returned features will still be based on those of the image. */

enum PhotosExif0Row: Int {
    case TOP_0COL_LEFT			= 1 //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
    case TOP_0COL_RIGHT			= 2 //   2  =  0th row is at the top, and 0th column is on the right.
    case BOTTOM_0COL_RIGHT      = 3 //   3  =  0th row is at the bottom, and 0th column is on the right.
    case BOTTOM_0COL_LEFT       = 4 //   4  =  0th row is at the bottom, and 0th column is on the left.
    case LEFT_0COL_TOP          = 5 //   5  =  0th row is on the left, and 0th column is the top.
    case RIGHT_0COL_TOP         = 6 //   6  =  0th row is on the right, and 0th column is the top.
    case RIGHT_0COL_BOTTOM      = 7 //   7  =  0th row is on the right, and 0th column is the bottom.
    case LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.
}

let kDeviceOrientationToExifOrientationFront: [UIDeviceOrientation: PhotosExif0Row] = [
    .Portrait: .RIGHT_0COL_TOP,
    .PortraitUpsideDown: .LEFT_0COL_BOTTOM,
    .LandscapeLeft: .BOTTOM_0COL_RIGHT,
    .LandscapeRight: .TOP_0COL_LEFT,
    .FaceUp: .RIGHT_0COL_TOP,
    .FaceDown: .RIGHT_0COL_TOP
]

let kDeviceOrientationToExifOrientationBack: [UIDeviceOrientation: PhotosExif0Row] = [
    .Portrait: .RIGHT_0COL_TOP,
    .PortraitUpsideDown: .LEFT_0COL_BOTTOM,
    .LandscapeLeft: .TOP_0COL_LEFT,
    .LandscapeRight: .BOTTOM_0COL_RIGHT,
    .FaceUp: .RIGHT_0COL_TOP,
    .FaceDown: .RIGHT_0COL_TOP
]

//  Maps a Bool, representing whether the front facing camera is being used, to the correct
//  dictionary that itself maps the device orientation to the correcnt EXIF orientation.
let kDeviceOrientationToExifOrientation: [Bool: [UIDeviceOrientation: PhotosExif0Row]] = [
    true: kDeviceOrientationToExifOrientationFront,
    false: kDeviceOrientationToExifOrientationBack
]

func DegreesToRadians(degrees:CGFloat) -> CGFloat {
    return degrees * CGFloat(M_PI) / CGFloat(180.0)
}

func RotationTransform(degrees:Float) -> CGAffineTransform
{
    return CGAffineTransformMakeRotation(DegreesToRadians(CGFloat(degrees)))
}


// create a CGImage with provided pixel buffer, pixel buffer must be uncompressed kCVPixelFormatType_32ARGB or kCVPixelFormatType_32BGRA
func CreateCGImageFromCVPixelBuffer(pixelBuffer:CVPixelBufferRef) -> CGImage!
{
    var err: OSStatus = noErr
    var bitmapInfo: CGBitmapInfo
    var image: CGImage!
    
    CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
    var sourcePixelFormat: OSType = CVPixelBufferGetPixelFormatType( pixelBuffer )
    if ( kCVPixelFormatType_32ARGB == Int(sourcePixelFormat) ) {
        bitmapInfo = CGBitmapInfo(CGBitmapInfo.ByteOrder32Big.rawValue | CGImageAlphaInfo.NoneSkipFirst.rawValue)
    } else if ( kCVPixelFormatType_32BGRA == Int(sourcePixelFormat) ) {
        bitmapInfo = CGBitmapInfo(CGBitmapInfo.ByteOrder32Little.rawValue | CGImageAlphaInfo.NoneSkipFirst.rawValue)
    } else {
        return nil // -95014; // only uncompressed pixel formats
    }
    
    let width: Int = CVPixelBufferGetWidth( pixelBuffer )
    let height: Int = CVPixelBufferGetHeight( pixelBuffer )
    let sourceRowBytes: Int = CVPixelBufferGetBytesPerRow( pixelBuffer );
    let sourceBaseAddr: UnsafeMutablePointer<Void>  = CVPixelBufferGetBaseAddress( pixelBuffer );
    //println("Pixel buffer info - w:\(width) h:\(height) BytesPerRow:\(sourceRowBytes) BaseAddr:\(sourceBaseAddr)")
    
    let colorspace = CGColorSpaceCreateDeviceRGB();
    let context = CGBitmapContextCreate(sourceBaseAddr, width, height, 8, sourceRowBytes, colorspace, bitmapInfo)
    if (context != nil) {
        image = CGBitmapContextCreateImage(context)
    } else {
        println("CreateCGImageFromCVPixelBuffer():  Failed to create bitmap context")
    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0)
    
    return image;
}

func CreateCGBitmapContextForSize(size: CGSize) -> CGContextRef
{
    let colorSpace:CGColorSpace! = CGColorSpaceCreateDeviceRGB();
    let bytesPerRow = Int(size.width) * 4
    let bitsPerComponent = 8
    
    let bitmapInfo = CGBitmapInfo(CGImageAlphaInfo.PremultipliedLast.rawValue)
    let context = CGBitmapContextCreate(nil, Int(size.width), Int(size.height), bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo)
    
    CGContextSetAllowsAntialiasing(context, false);
    return context;
}