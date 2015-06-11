//
//  MainViewController.swift
//  Pic
//
//  Created by Kashish Hora on 12/23/14.
//  Copyright (c) 2014 Kashish Hora. All rights reserved.
//

import UIKit
import AVFoundation
import ImageIO
import CoreMotion

let kOutputDataQueueName = "VideoDataOutputQueue"
let kVideoProcessorQueueName = "videoProcessorQueue"
let kMotionQueueName = "motionQueue"
let kFaceLayerName = "FaceLayer"

class MainViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, RecordButtonDelegate {
    
    var videoSession: AVCaptureSession! = AVCaptureSession()
    var cameraDevice: AVCaptureDevice!
    
    var videoDataOutput = AVCaptureVideoDataOutput()
    var videoDataOutputQueue: dispatch_queue_t!
    
    var previewLayer: AVCaptureVideoPreviewLayer!
    var customPreviewLayer: CALayer!
    var avConnection: AVCaptureConnection!
    
    var faceDetector: CIDetector!
    
    var isUsingFrontFacingCamera = false
    var currentlyRecording = false

    var videoProcessorQueue: dispatch_queue_t!
    var videoProcessor: VideoProcessor!

    var motionManager = CMMotionManager()
    var motionQueue: NSOperationQueue!
    
    var bestImageButton: UIButton?
    
    @IBOutlet weak var recordButton: RecordButton!
    @IBOutlet weak var previewView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        recordButton.delegate = self
        
        self.setupAVSession()
        self.setupMotion()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.view.layoutIfNeeded()
        let rootLayer = previewView.layer
        rootLayer.masksToBounds = true
        
        previewLayer.frame = rootLayer.bounds
        rootLayer.addSublayer(previewLayer)
        
        customPreviewLayer.setAffineTransform(CGAffineTransformMakeRotation(CGFloat(M_PI) / 2))
        customPreviewLayer.frame = rootLayer.bounds

        rootLayer.addSublayer(customPreviewLayer)
    }
    
    func setupMotion() {
        if motionManager.deviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 120.0
        }
        motionQueue = NSOperationQueue()
        motionQueue.name = kMotionQueueName
        motionQueue.underlyingQueue = dispatch_queue_create(kMotionQueueName, DISPATCH_QUEUE_SERIAL)
    }
    
    func setupAVSession() {
        
        videoSession.sessionPreset = AVCaptureSessionPreset1280x720
        
        cameraDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        if cameraDevice == nil {
            fatalError("Error: Failed to obtain interface to camera.")
        }
        var error: NSError?
        if cameraDevice.lockForConfiguration(&error) {
            if cameraDevice.lowLightBoostSupported {
                cameraDevice.automaticallyEnablesLowLightBoostWhenAvailable = true
            }
            cameraDevice.focusMode = .ContinuousAutoFocus
        } else {
            println("Could not lock camera for configuration.")
        }
        error = nil
        var deviceInput: AVCaptureDeviceInput = AVCaptureDeviceInput.deviceInputWithDevice(cameraDevice, error: &error) as! AVCaptureDeviceInput
        assert (error == nil)
        
        if videoSession.canAddInput(deviceInput) {
            videoSession.addInput(deviceInput)
        } else {
            fatalError("Video session can't add image output.")
        }
        
        var rgbOutputSettings: [NSObject : AnyObject] = [kCVPixelBufferPixelFormatTypeKey : kCMPixelFormat_32BGRA]
        videoDataOutput.videoSettings = rgbOutputSettings
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        
        videoDataOutputQueue = dispatch_queue_create(kOutputDataQueueName, DISPATCH_QUEUE_SERIAL)
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        
        videoProcessorQueue = dispatch_queue_create(kVideoProcessorQueueName, DISPATCH_QUEUE_CONCURRENT)
        
        if videoSession.canAddOutput(videoDataOutput) {
            videoSession.addOutput(videoDataOutput)
        }
        
        // TODO: determine if it's necessary to have 240 FPS
        // configureCameraForHighestFramerate()
        
        
        
        let detectorOptions = [CIDetectorAccuracy:CIDetectorAccuracyLow, CIDetectorEyeBlink : 1, CIDetectorSmile : 1]
        faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: detectorOptions as [NSObject : AnyObject])
        
        videoProcessor = VideoProcessor(faceDetector: faceDetector)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: videoSession)
        //previewLayer.backgroundColor = UIColor.blackColor().CGColor
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        customPreviewLayer = CALayer()
        
        avConnection = previewLayer.connection
        avConnection.preferredVideoStabilizationMode = .Cinematic
        
        videoSession.startRunning()
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        
        let attachmentsUnmanaged = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate))
        
        if let attachments: CFDictionary = attachmentsUnmanaged?.takeRetainedValue() {
            
            let ciImage = CIImage(CVPixelBuffer: pixelBuffer, options: attachments as [NSObject : AnyObject])
            
            let temporaryContext: CIContext = CIContext(options: nil)
            let videoImage: CGImageRef = temporaryContext.createCGImage(ciImage, fromRect: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetWidth(pixelBuffer)))
            let originalImage = UIImage(CGImage: videoImage)
            var processedImage = CVWrapper.drawContours(originalImage)
            
            let currentDeviceOrientation = UIDevice.currentDevice().orientation
            
            var exifOrientation: PhotosExif0Row! = kDeviceOrientationToExifOrientation[isUsingFrontFacingCamera]?[currentDeviceOrientation]
            if exifOrientation == nil {
                exifOrientation = kDeviceOrientationToExifOrientation[isUsingFrontFacingCamera]?[.Portrait]
            }
            
            let imageOptions = [CIDetectorImageOrientation: exifOrientation.rawValue]
            
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
            if formatDescription == nil {
                println("Could not obtain format description from sample")
                return
            }
            
            let cleanAperature: CGRect = CMVideoFormatDescriptionGetCleanAperture(formatDescription, 0)
            
            if !currentlyRecording {
                
                let features = faceDetector != nil ? faceDetector.featuresInImage(ciImage, options: imageOptions) : []

                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    // self.drawFaceBoxesForFeatures(features, clap: cleanAperature, orientation: currentDeviceOrientation)
                    self.customPreviewLayer.contents = processedImage?.CGImage
                })
            } else {
                dispatch_async(videoProcessorQueue, { () -> Void in
                    let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                    self.videoProcessor.processFrames(sampleBuffer, timestamp: timestamp, imageOptions: imageOptions, videoBox: cleanAperature)
                })
            }
        }
    }
    
    func drawFaceBoxesForFeatures(features: [AnyObject], clap: CGRect, orientation: UIDeviceOrientation) -> Void {
        let sublayers = previewLayer.sublayers as! [CALayer]
        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        // hide all the face layers
        for layer in sublayers {
            if layer.name != nil {
                if layer.name == kFaceLayerName {
                    layer.hidden = true
                }
            }
            
        }
        
        if features.count == 0 || clap == CGRect.zeroRect { // bail early
            CATransaction.commit()
            return
        }
        
        if currentlyRecording {
            CATransaction.commit()
            return
        }
        
        let parentFrameSize: CGSize = previewView.frame.size
        let gravity: String = previewLayer.videoGravity
        let isMirrored = previewLayer.connection.videoMirrored
        let previewBox: CGRect = previewLayer.frame
        
        for item in features {
            if let ff = item as? CIFaceFeature {
                
                var faceRect: CGRect = ff.bounds
                                
                let widthScaleBy: CGFloat = previewBox.size.width / clap.size.height
                let heightScaleBy: CGFloat = previewBox.size.height / clap.size.width
                var transform = isMirrored ? CGAffineTransformMake(0, heightScaleBy, -widthScaleBy, 0, previewBox.size.width, 0) :
                    CGAffineTransformMake(0, heightScaleBy, widthScaleBy, 0, 0, 0)
                
                faceRect = CGRectApplyAffineTransform(faceRect, transform)
                
                //  Apply the preview origin offset, if any.
                faceRect = CGRectOffset(faceRect, previewBox.origin.x, previewBox.origin.y)
                
                var featureLayer: CALayer!
                
                // Reuse an existing hidden layer if possible
                for layer in sublayers {
                    if layer.name != nil {
                        if layer.name == kFaceLayerName && layer.hidden {
                            featureLayer = layer
                            layer.hidden = false
                        }
                    }
                    
                    if featureLayer != nil { break }
                }
                
                // create a new layer if necessary
                if (featureLayer == nil) {
                    featureLayer = CALayer()
                    featureLayer.borderColor = UIColor.redColor().CGColor
                    featureLayer.borderWidth = 1
                    featureLayer.name = kFaceLayerName
                    previewLayer.addSublayer(featureLayer)
                }
                
                featureLayer.frame = faceRect
                //println("Set face rect to \(faceRect)")
                
                //  Transform for the orientation of the device.
                switch orientation {
                case .Portrait:
                    featureLayer.setAffineTransform(RotationTransform(0.0))
                case .PortraitUpsideDown:
                    featureLayer.setAffineTransform(RotationTransform(180.0))
                case .LandscapeLeft:
                    featureLayer.setAffineTransform(RotationTransform(90.0))
                case .LandscapeRight:
                    featureLayer.setAffineTransform(RotationTransform(-90.0))
                case .FaceUp:
                    break
                case .FaceDown:
                    break
                default:
                    break
                    
                }
                
            } // END for each face feature
            
        } // END for each item
        CATransaction.commit()
    }

    func hideAllFaces() {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        let sublayers = previewLayer.sublayers as! [CALayer]
        for layer in sublayers {
            if layer.name != nil {
                if layer.name == kFaceLayerName {
                    layer.hidden = true
                }
            }
            
        }
        CATransaction.commit()

    }

    @IBAction func switchCameras(sender: AnyObject) {
        var desiredPosition: AVCaptureDevicePosition = isUsingFrontFacingCamera ? AVCaptureDevicePosition.Back : AVCaptureDevicePosition.Front
        
        for device in AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) {
            if (device.position == desiredPosition) {
                previewLayer.session.beginConfiguration()
                let input: AVCaptureInput! = AVCaptureDeviceInput.deviceInputWithDevice(device as! AVCaptureDevice, error: nil) as! AVCaptureInput
                for oldInput in previewLayer.session.inputs {
                    previewLayer.session.removeInput(oldInput as! AVCaptureInput)
                }
                previewLayer.session.addInput(input)
                previewLayer.session.commitConfiguration()
                break
            }
        }
        isUsingFrontFacingCamera = !isUsingFrontFacingCamera
    }
    
    func configureCameraForHighestFramerate() {
        var bestFormat: AVCaptureDeviceFormat?
        var bestFrameRateRange: AVFrameRateRange?
        
        let formatList = cameraDevice.formats as! [AVCaptureDeviceFormat]
        
        for format: AVCaptureDeviceFormat in formatList {
            let rangeList = format.videoSupportedFrameRateRanges as! [AVFrameRateRange]
            for range: AVFrameRateRange in rangeList {
                if range.maxFrameRate > bestFrameRateRange?.maxFrameRate {
                    bestFormat = format
                    bestFrameRateRange = range
                }
            }
        }
        
        if let bestFormat = bestFormat{
            if cameraDevice.lockForConfiguration(nil) == true {
                cameraDevice.activeFormat = bestFormat
                cameraDevice.activeVideoMaxFrameDuration = bestFrameRateRange!.minFrameDuration
                cameraDevice.activeVideoMinFrameDuration = bestFrameRateRange!.minFrameDuration
                cameraDevice.unlockForConfiguration()
            }
        }
    }

    func toggleRecording() {
        currentlyRecording = !self.currentlyRecording
        hideAllFaces()

        // Make sure we don't skip frames if we're recording
        videoDataOutput.alwaysDiscardsLateVideoFrames = !currentlyRecording
        
        // Toggle motion tracking
        if currentlyRecording {
            videoProcessor.reset()
            var error: NSError?
            motionManager.startDeviceMotionUpdatesToQueue(motionQueue, withHandler: { (motionData: CMDeviceMotion!, error) -> Void in
                //println("\(motionData.timestamp), \(motionData.gravity.x), \(motionData.gravity.y), \(motionData.gravity.z)")
                self.videoProcessor.processMotion(motionData)
            })
        } else {
            motionManager.stopDeviceMotionUpdates()
            videoProcessor.syncMotion()
            videoProcessor.generateAccelerationScores()
            
            //videoProcessor.printScores()
            //videoProcessor.printMotionDataTimestampsInorder()
            //videoProcessor.printFrameTimestampsInorder()
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let frame = self.videoProcessor.getBestFrame()
                println("frame: \(frame!.frameTimestamp), \(frame!.faceScore), \(frame!.gravityScore), \(frame!.accelerationScore)")
                self.bestImageButton = UIButton(frame: self.view.bounds)
                self.view.addSubview(self.bestImageButton!)
                self.bestImageButton?.setImage(frame?.frameImage, forState: .Normal)
                self.bestImageButton?.hidden = false
                self.bestImageButton?.addTarget(self, action: Selector("hideBestImageButton"), forControlEvents: .TouchUpInside)
            })
        }
    }
    
    func hideBestImageButton() {
        self.bestImageButton?.removeFromSuperview()
        self.bestImageButton = nil
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animateAlongsideTransitionInView(self.view, animation: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            
            self.view.transform = CGAffineTransformConcat(self.view.transform, CGAffineTransformInvert(coordinator.targetTransform()))
            self.view.frame = CGRect(origin: CGPointZero, size: size)
            }, completion: nil)
    }
    
}