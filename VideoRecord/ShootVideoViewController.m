//
//  ShootVideoViewController.m
//  VideoRecord
//
//  Created by Vitaliy on 13/5/2016.
//  Copyright (c) 2016 Vitaliy. All rights reserved.
//

#import "ShootVideoViewController.h"
#import "PlayVideoViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "AppDelegate.h"
#import "Defines.h"

#define TIMER_INTERVAL 0.05
#define VIDEO_FOLDER @"videoFolder"

typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

@interface ShootVideoViewController ()<AVCaptureFileOutputRecordingDelegate>

@property (strong,nonatomic) AVCaptureSession *captureSession;
@property (strong,nonatomic) AVCaptureDeviceInput *captureDeviceInput;
@property (strong,nonatomic) AVCaptureMovieFileOutput *captureMovieFileOutput;
@property (strong,nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;

@property (strong,nonatomic)  UIView *viewContainer;
@property (strong,nonatomic)  UIImageView *focusCursor;

@end

@implementation ShootVideoViewController{
    
    NSMutableArray* urlArray;
    NSMutableArray* degreeArray;
    float currentTime;
    
    NSTimer *countTimer;
    UIView* progressPreView;
    float progressStep;
    
    float preLayerWidth;
    float preLayerHeight;
    float preLayerHWRate;
    
    UILabel* recordTimeLb;
    UIButton* editBt;
    UIButton* shootBt;
    UIButton* finishBt;
    UIButton* flashBt;
    UIButton* cameraBt;
    UIImageView *thumView;
    BOOL isfront;
    BOOL isRecordingStop;
    NSURL *outputURL;
}

@synthesize totalTime;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColorFromRGB(0x1d1e20);
    
    if (totalTime==0) {
        totalTime =MAX_VIDEO_TIME;
    }

    urlArray = [[NSMutableArray alloc]init];
    degreeArray = [[NSMutableArray alloc]init];
    
    preLayerWidth = SCREEN_WIDTH;
    preLayerHeight = SCREEN_HEIGHT;
    preLayerHWRate =preLayerHeight/preLayerWidth;
    
    progressStep = SCREEN_WIDTH*TIMER_INTERVAL/totalTime;
    
    [self createVideoFolderIfNotExist];
    [self initCapture];
    isfront = NO;
    isRecordingStop = NO;
    DELEGATE.videoFileName = @"Untitled";
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)initCapture{
    self.viewContainer = [[UIView alloc]initWithFrame:CGRectMake(0, 0, preLayerWidth, preLayerHeight)];
    [self.view addSubview:self.viewContainer];
   
    
    self.focusCursor = [[UIImageView alloc]initWithFrame:CGRectMake(100, 100, 40, 40)];
    [self.focusCursor setImage:[UIImage imageNamed:@"focusImg"]];
    self.focusCursor.alpha = 0;
    [self.viewContainer addSubview:self.focusCursor];
    
    
    _captureSession=[[AVCaptureSession alloc]init];

    if ([_captureSession canSetSessionPreset:VIDEO_SESSION_SIZE]) {
        _captureSession.sessionPreset=VIDEO_SESSION_SIZE;
    }
    
    AVCaptureDevice *captureDevice=[self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];
    AVCaptureDevice *audioCaptureDevice=[[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    
    NSError *error=nil;
    _captureDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:captureDevice error:&error];

    AVCaptureDeviceInput *audioCaptureDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:audioCaptureDevice error:&error];

    _captureMovieFileOutput=[[AVCaptureMovieFileOutput alloc]init];
    
    if ([_captureSession canAddInput:_captureDeviceInput]) {
        [_captureSession addInput:_captureDeviceInput];
        [_captureSession addInput:audioCaptureDeviceInput];
        AVCaptureConnection *captureConnection=[_captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([captureConnection isVideoStabilizationSupported ]) {
            captureConnection.preferredVideoStabilizationMode=AVCaptureVideoStabilizationModeAuto;
        }
    }
    
    if ([_captureSession canAddOutput:_captureMovieFileOutput]) {
        [_captureSession addOutput:_captureMovieFileOutput];
    }
    
    _captureVideoPreviewLayer=[[AVCaptureVideoPreviewLayer alloc]initWithSession:self.captureSession];
    
    CALayer *layer= self.viewContainer.layer;
    layer.masksToBounds=YES;
    
    _captureVideoPreviewLayer.frame=  CGRectMake(0, 0, preLayerWidth, preLayerHeight);
    _captureVideoPreviewLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;
    [layer insertSublayer:_captureVideoPreviewLayer below:self.focusCursor.layer];

    [self addGenstureRecognizer];

    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, preLayerWidth, 45)];
    topView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
    [self.viewContainer addSubview:topView];
    
    recordTimeLb = [[UILabel alloc]initWithFrame:CGRectMake((SCREEN_WIDTH - 100)/2, 5, 100, 35)];
    recordTimeLb.text = @"00:00";
    recordTimeLb.textColor = [UIColor whiteColor];
    recordTimeLb.textAlignment = NSTextAlignmentCenter;
    [topView addSubview:recordTimeLb];
    
    editBt = [[UIButton alloc]initWithFrame:CGRectMake(20, 5, 34, 34)];
    [editBt addTarget:self action:@selector(editBtTap:) forControlEvents:UIControlEventTouchUpInside];
    [editBt setTitle:@"Edit" forState:UIControlStateNormal];
    [topView addSubview:editBt];
    
    flashBt = [[UIButton alloc]initWithFrame:CGRectMake(SCREEN_WIDTH-90, 5, 34, 34)];
    [flashBt setBackgroundImage:[UIImage imageNamed:@"flashOn"] forState:UIControlStateNormal];
    [flashBt makeCornerRadius:17 borderColor:nil borderWidth:0];
    [flashBt addTarget:self action:@selector(flashBtTap:) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:flashBt];
    
    flashBt = [[UIButton alloc]initWithFrame:CGRectMake(SCREEN_WIDTH-90, 5, 34, 34)];
    [flashBt setBackgroundImage:[UIImage imageNamed:@"flashOn"] forState:UIControlStateNormal];
    [flashBt makeCornerRadius:17 borderColor:nil borderWidth:0];
    [flashBt addTarget:self action:@selector(flashBtTap:) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:flashBt];
    
    cameraBt = [[UIButton alloc]initWithFrame:CGRectMake(SCREEN_WIDTH-40, 5, 34, 34)];
    [cameraBt setBackgroundImage:[UIImage imageNamed:@"changeCamer"] forState:UIControlStateNormal];
    [cameraBt makeCornerRadius:17 borderColor:nil borderWidth:0];
    [cameraBt addTarget:self action:@selector(changeCamera:) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:cameraBt];
    
    UIView *botView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT-SHOOTVIEW_HEIGHT, SCREEN_WIDTH, SHOOTVIEW_HEIGHT)];
    botView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
    [self.viewContainer addSubview:botView];
    
    shootBt = [[UIButton alloc]initWithFrame:CGRectMake((SCREEN_WIDTH - 80)/2, (SHOOTVIEW_HEIGHT-80)/2, 80, 80)];
    [shootBt setImage:[UIImage imageNamed:@"record_start"] forState:UIControlStateNormal];
    [shootBt addTarget:self action:@selector(shootButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [botView addSubview:shootBt];

    finishBt = [[UIButton alloc]initWithFrame:CGRectMake(45, 15, 60, 60)];
    finishBt.adjustsImageWhenHighlighted = NO;
    [finishBt setTitle:@"Done" forState:UIControlStateNormal];
    [finishBt addTarget:self action:@selector(finishBtTap) forControlEvents:UIControlEventTouchUpInside];
    [botView addSubview:finishBt];

    thumView = [[UIImageView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - 80, 10, 70, 70)];
    thumView.contentMode = UIViewContentModeScaleToFill;
    thumView.layer.cornerRadius = 5;
    [botView addSubview:thumView];
}

-(void)flashBtTap:(UIButton*)bt{
    if (bt.selected == YES) {
        bt.selected = NO;
        [flashBt setBackgroundImage:[UIImage imageNamed:@"flashOn"] forState:UIControlStateNormal];
        [self setTorchMode:AVCaptureTorchModeOff];
    }else{
        bt.selected = YES;
        [flashBt setBackgroundImage:[UIImage imageNamed:@"flashOff"] forState:UIControlStateNormal];
        [self setTorchMode:AVCaptureTorchModeOn];
    }
}

-(void)startTimer{
    countTimer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    [countTimer fire];
}

-(void)stopTimer{
    [countTimer invalidate];
    countTimer = nil;
}
- (void)onTimer:(NSTimer *)timer
{
    if ([self.captureMovieFileOutput isRecording]) {
        CGFloat cTime = CMTimeGetSeconds(self.captureMovieFileOutput.recordedDuration);
    
        if (currentTime > 0)
            cTime += currentTime;
    
        recordTimeLb.text = [NSString stringWithFormat:@"%02d:%02d", (int)cTime/60, (int)cTime % 60];
    }
    
    if (currentTime>=totalTime) {
        [countTimer invalidate];
        countTimer = nil;
        [_captureMovieFileOutput stopRecording];
    }
}

-(void)finishBtTap{
    if (outputURL) {
        [self saveToCameraRoll:outputURL];

        NSLog(@"clicked finish button");
        [self.captureSession stopRunning];
        
        [self deleteAllVideos];
        currentTime = 0;
        [shootBt setImage:[UIImage imageNamed:@"record_start"] forState:UIControlStateNormal];
        
    //    [self mergeAndExportVideosAtFileURLs:urlArray];
    }
//    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void) saveToCameraRoll:(NSURL *)srcURL
{
    NSLog(@"srcURL: %@", srcURL);

    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    ALAssetsLibraryWriteVideoCompletionBlock videoWriteCompletionBlock =
    ^(NSURL *newURL, NSError *error) {
        if (error) {
            NSLog( @"Error writing image with metadata to Photo Library: %@", error );
        } else {
            NSLog( @"Wrote image with metadata to Photo Library %@", newURL.absoluteString);
        }
    };
    
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:srcURL])
    {
        [library writeVideoAtPathToSavedPhotosAlbum:srcURL
                                    completionBlock:videoWriteCompletionBlock];
    }
}
-(void)editBtTap:(UIButton*)bt{
    if (urlArray.count == 0)
        return;
    
    if (_captureMovieFileOutput.isRecording) {
        [_captureMovieFileOutput stopRecording];
    }else{
        [self mergeAndExportVideosAtFileURLs:urlArray];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];

    currentTime =DELEGATE.timeDuration;
    recordTimeLb.text = [NSString stringWithFormat:@"%02d:%02d", (int) currentTime /60, (int)currentTime % 60];
    
    [self.captureSession startRunning];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    [self.captureSession stopRunning];

    [shootBt setImage:[UIImage imageNamed:@"record_start"] forState:UIControlStateNormal];
}

#pragma mark capture video
- (void)shootButtonClick{
    AVCaptureConnection *captureConnection=[self.captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    
    if (![self.captureMovieFileOutput isRecording]) {
        [self getVideoOrientation];
        captureConnection.videoOrientation=[self.captureVideoPreviewLayer connection].videoOrientation;
        [self.captureMovieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:[self getVideoSaveFilePathString]] recordingDelegate:self];
    }
    else{
        [self stopTimer];
        [self.captureMovieFileOutput stopRecording];
        
    }
}
-(void)showImageOnThumView:(NSURL*)fileURL
{
    NSInteger videoAngleInDegree =[[degreeArray lastObject] integerValue];
    
    NSMutableArray *times = [[NSMutableArray alloc] init];
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:fileURL options:nil];
    AVAssetImageGenerator *generate = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generate.appliesPreferredTrackTransform = YES;

    CMTime time = CMTimeMakeWithSeconds(0, 60);
    [times addObject:[NSValue valueWithCMTime:time]];
    
    [generate generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
        
        if (result == AVAssetImageGeneratorSucceeded)
        {
            UIImage *generatedImage =[self imageRotatedByDegrees:[[UIImage alloc] initWithCGImage:image] deg:videoAngleInDegree];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                thumView.image = generatedImage;
            });
        }
    }];
}

- (void)getVideoOrientation
{
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    NSInteger degree = 0;

    if (orientation == UIDeviceOrientationPortrait) {
        degree = 0;
    }
    else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
        degree = 180;// M_PI;
    } else if (orientation == UIDeviceOrientationLandscapeLeft) {
        degree = isfront? 90 : -90;// -M_PI_2;
    } else if (orientation == UIDeviceOrientationLandscapeRight) {
        degree = isfront? -90 : 90;// M_PI_2;
    }
    [degreeArray addObject:[NSNumber numberWithInteger:degree]];
}

- (UIImage *)imageRotatedByDegrees:(UIImage*)oldImage deg:(CGFloat)degrees
{
    //Calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,oldImage.size.width, oldImage.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(degrees * M_PI / 180);
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    
    //Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    //Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    
    //Rotate the image context
    CGContextRotateCTM(bitmap, (degrees * M_PI / 180));
    
    //Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-oldImage.size.width / 2, -oldImage.size.height / 2, oldImage.size.width, oldImage.size.height), [oldImage CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (void)changeCamera:(UIButton*)bt {
    AVCaptureDevice *currentDevice=[self.captureDeviceInput device];
    AVCaptureDevicePosition currentPosition=[currentDevice position];
    AVCaptureDevice *toChangeDevice;
    AVCaptureDevicePosition toChangePosition=AVCaptureDevicePositionFront;
    if (currentPosition==AVCaptureDevicePositionUnspecified||currentPosition==AVCaptureDevicePositionFront) {
        toChangePosition=AVCaptureDevicePositionBack;
        flashBt.hidden = NO;
        isfront = NO;
    }else{
        flashBt.hidden = YES;
        isfront = YES;
    }
    toChangeDevice=[self getCameraDeviceWithPosition:toChangePosition];
    AVCaptureDeviceInput *toChangeDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:toChangeDevice error:nil];
    
    [self.captureSession beginConfiguration];
    [self.captureSession removeInput:self.captureDeviceInput];
    if ([self.captureSession canAddInput:toChangeDeviceInput]) {
        [self.captureSession addInput:toChangeDeviceInput];
        self.captureDeviceInput=toChangeDeviceInput;
    }
    [self.captureSession commitConfiguration];
    
    flashBt.selected = NO;
    [flashBt setBackgroundImage:[UIImage imageNamed:@"flashOn"] forState:UIControlStateNormal];
    [self setTorchMode:AVCaptureTorchModeOff];
    
}

#pragma mark - capture video deletage
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    [shootBt setImage:[UIImage imageNamed:@"record_stop"] forState:UIControlStateNormal];

    [self startTimer];
}
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    [shootBt setImage:[UIImage imageNamed:@"record_start"] forState:UIControlStateNormal];
    
    CGFloat cTime = CMTimeGetSeconds(self.captureMovieFileOutput.recordedDuration);
    currentTime+=cTime;

    [urlArray addObject:outputFileURL];
    [self showImageOnThumView:outputFileURL];
    if (currentTime>=totalTime) {
        [self mergeAndExportVideosAtFileURLs:urlArray];
    }
}

#define degreesToRadians(x) (M_PI * x / 180.0)

- (void)mergeAndExportVideosAtFileURLs:(NSMutableArray *)fileURLArray
{
    NSError *error = nil;
 //video size
    CGSize renderSize = CGSizeMake(0, 0);
    
    NSMutableArray *layerInstructionArray = [[NSMutableArray alloc] init];
    
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    CMTime totalDuration = kCMTimeZero;
    
    NSMutableArray *assetTrackArray = [[NSMutableArray alloc] init];
    NSMutableArray *assetArray = [[NSMutableArray alloc] init];
    for (NSURL *fileURL in fileURLArray) {
        
        AVAsset *asset = [AVAsset assetWithURL:fileURL];
        [assetArray addObject:asset];
        
        NSArray* tmpAry =[asset tracksWithMediaType:AVMediaTypeVideo];
        if (tmpAry.count>0) {
            AVAssetTrack *assetTrack = [tmpAry objectAtIndex:0];
            
            [assetTrackArray addObject:assetTrack];
            renderSize.width = MAX(renderSize.width, assetTrack.naturalSize.width);
            renderSize.height = MAX(renderSize.height, assetTrack.naturalSize.height);
        }
    }
    
    CGFloat renderW = MAX(renderSize.width, renderSize.height);
    
    for (int i = 0; i < [assetArray count] && i < [assetTrackArray count]; i++) {
        
        AVAsset *asset = [assetArray objectAtIndex:i];
        AVAssetTrack *assetTrack = [assetTrackArray objectAtIndex:i];
        
        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        NSArray*dataSourceArray= [asset tracksWithMediaType:AVMediaTypeAudio];
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                            ofTrack:([dataSourceArray count]>0)?[dataSourceArray objectAtIndex:0]:nil
                             atTime:totalDuration
                              error:nil];
        
        AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                            ofTrack:assetTrack
                             atTime:totalDuration
                              error:&error];
        
        AVMutableVideoCompositionLayerInstruction *layerInstruciton = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];

        totalDuration = CMTimeAdd(totalDuration, asset.duration);
        
        CGFloat rate;
        rate = renderW / MAX(assetTrack.naturalSize.width, assetTrack.naturalSize.height);
        
        CGAffineTransform layerTransform;
        
        NSInteger videoAngleInDegree =[[degreeArray objectAtIndex:i] integerValue];

        switch ((int)videoAngleInDegree) {
            case 0:
                layerTransform = CGAffineTransformMake(assetTrack.preferredTransform.a, assetTrack.preferredTransform.b, assetTrack.preferredTransform.c, assetTrack.preferredTransform.d, assetTrack.preferredTransform.tx * rate, assetTrack.preferredTransform.ty * rate);
                 layerTransform = CGAffineTransformConcat(layerTransform, CGAffineTransformMake(1, 0, 0, 1, -(assetTrack.naturalSize.width - assetTrack.naturalSize.height) / 2+preLayerHWRate*(preLayerHeight-preLayerWidth)/8, 0));
                break;
            case 90:
                layerTransform = CGAffineTransformMake(assetTrack.preferredTransform.a, assetTrack.preferredTransform.b, assetTrack.preferredTransform.c, assetTrack.preferredTransform.d, assetTrack.preferredTransform.tx * rate, assetTrack.preferredTransform.ty * rate);

                layerTransform = CGAffineTransformConcat(layerTransform, CGAffineTransformMakeRotation(degreesToRadians(90.0)));
                layerTransform = CGAffineTransformTranslate(layerTransform, -assetTrack.naturalSize.width, 0);
                layerTransform = CGAffineTransformConcat(layerTransform, CGAffineTransformMake(1, 0, 0, 1, 0, -(assetTrack.naturalSize.width - assetTrack.naturalSize.height)/2 + preLayerHWRate*(preLayerHeight-preLayerWidth)/8));
                break;
            case 180:
                layerTransform = CGAffineTransformMake(assetTrack.preferredTransform.a, assetTrack.preferredTransform.b, assetTrack.preferredTransform.c, assetTrack.preferredTransform.d, assetTrack.preferredTransform.tx * rate, assetTrack.preferredTransform.ty * rate);
                
                layerTransform = CGAffineTransformConcat(layerTransform, CGAffineTransformMakeRotation(degreesToRadians(180.0)));
                layerTransform = CGAffineTransformTranslate(layerTransform, -assetTrack.naturalSize.width, assetTrack.naturalSize.height);
                layerTransform = CGAffineTransformConcat(layerTransform, CGAffineTransformMake(1, 0, 0, 1, -(assetTrack.naturalSize.width - assetTrack.naturalSize.height) / 2+preLayerHWRate*(preLayerHeight-preLayerWidth)/8, 0));
                break;
            case -90:
                layerTransform = CGAffineTransformMake(assetTrack.preferredTransform.a, assetTrack.preferredTransform.b, assetTrack.preferredTransform.c, assetTrack.preferredTransform.d, assetTrack.preferredTransform.tx * rate, assetTrack.preferredTransform.ty * rate);
                
                layerTransform = CGAffineTransformConcat(layerTransform, CGAffineTransformMakeRotation(degreesToRadians(-90.0)));
                layerTransform = CGAffineTransformTranslate(layerTransform, 0, assetTrack.naturalSize.height);
                layerTransform = CGAffineTransformConcat(layerTransform, CGAffineTransformMake(1, 0, 0, 1, 0, -(assetTrack.naturalSize.width - assetTrack.naturalSize.height) / 2.0+preLayerHWRate*(preLayerHeight-preLayerWidth)/8));
                break;
            default:
                layerTransform = CGAffineTransformMake(assetTrack.preferredTransform.a, assetTrack.preferredTransform.b, assetTrack.preferredTransform.c, assetTrack.preferredTransform.d, assetTrack.preferredTransform.tx * rate, assetTrack.preferredTransform.ty * rate);
                break;
        }
        
        layerTransform = CGAffineTransformScale(layerTransform, rate, rate);
        
        [layerInstruciton setTransform:layerTransform atTime:kCMTimeZero];
        [layerInstruciton setOpacity:0.0 atTime:totalDuration];

        [layerInstructionArray addObject:layerInstruciton];
    }
    
    NSString *path = [self getVideoMergeFilePathString];
    NSURL *mergeFileURL = [NSURL fileURLWithPath:path];
    
    AVMutableVideoCompositionInstruction *mainInstruciton = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruciton.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
    mainInstruciton.layerInstructions = layerInstructionArray;
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    mainCompositionInst.instructions = @[mainInstruciton];
    mainCompositionInst.frameDuration = CMTimeMake(1, 100);
    mainCompositionInst.renderSize = CGSizeMake(renderW, renderW);
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetLowQuality];
    exporter.videoComposition = mainCompositionInst;
    exporter.outputURL = mergeFileURL;
    outputURL = mergeFileURL;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            PlayVideoViewController* view = [[PlayVideoViewController alloc]initWithNibName:@"PlayVideoViewController" bundle:nil];
            view.videoURL =mergeFileURL;
            view.clipURLS = urlArray;
            view.degrees = degreeArray;
            [self presentViewController:view animated:YES completion:nil];
            
        });
    }];
    
    
}

//Finally, save as mp4
- (NSString *)getVideoMergeFilePathString
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    
    path = [path stringByAppendingPathComponent:VIDEO_FOLDER];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    
    NSString *name = [NSString stringWithFormat:@"%@.mp4", DELEGATE.videoFileName == nil ? @"Untitled" : DELEGATE.videoFileName];
    NSString *fileName = [[path stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:name];
    
    return fileName;
}

//Record the time saved to be saved as mov
- (NSString *)getVideoSaveFilePathString
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    
    path = [path stringByAppendingPathComponent:VIDEO_FOLDER];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    
    NSString *fileName = [[path stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:@".mov"];
    
    return fileName;
}

- (void)createVideoFolderIfNotExist
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    
    NSString *folderPath = [path stringByAppendingPathComponent:VIDEO_FOLDER];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isDirExist = [fileManager fileExistsAtPath:folderPath isDirectory:&isDir];
    
    if(!(isDirExist && isDir))
    {
        BOOL bCreateDir = [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
        if(!bCreateDir){
            NSLog(@"Failed to create video folder.");
        }
    }
}

- (void)deleteAllVideos
{
    for (NSURL *videoFileURL in urlArray) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *filePath = [[videoFileURL absoluteString] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:filePath]) {
                NSError *error = nil;
                [fileManager removeItemAtPath:filePath error:&error];
                
                if (error) {
                    NSLog(@"delete All Video Failed:%@", error);
                }
            }
        });
    }
    [urlArray removeAllObjects];
    [degreeArray removeAllObjects];
}

#pragma mark - Private method
-(AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position]==position) {
            return camera;
        }
    }
    return nil;
}

-(void)changeDeviceProperty:(PropertyChangeBlock)propertyChange{
    AVCaptureDevice *captureDevice= [self.captureDeviceInput device];
    NSError *error;

    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else{
        NSLog(@"Error, error information setting device properties takes place：%@",error.localizedDescription);
    }
}

-(void)setTorchMode:(AVCaptureTorchMode )torchMode{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isTorchModeSupported:torchMode]) {
            [captureDevice setTorchMode:torchMode];
        }
    }];
}

-(void)setFocusMode:(AVCaptureFocusMode )focusMode{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:focusMode];
        }
    }];
}

-(void)setExposureMode:(AVCaptureExposureMode)exposureMode{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:exposureMode];
        }
    }];
}

-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];
        }
    }];
}

-(void)addGenstureRecognizer{
    UITapGestureRecognizer *tapGesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapScreen:)];
    [self.viewContainer addGestureRecognizer:tapGesture];
}
-(void)tapScreen:(UITapGestureRecognizer *)tapGesture{
    CGPoint point= [tapGesture locationInView:self.viewContainer];

    CGPoint cameraPoint= [self.captureVideoPreviewLayer captureDevicePointOfInterestForPoint:point];
    [self setFocusCursorWithPoint:point];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
}

-(void)setFocusCursorWithPoint:(CGPoint)point{
    self.focusCursor.center=point;
    self.focusCursor.transform=CGAffineTransformMakeScale(1.5, 1.5);
    self.focusCursor.alpha=1.0;
    [UIView animateWithDuration:1.0 animations:^{
        self.focusCursor.transform=CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.focusCursor.alpha=0;
        
    }];
}
-(NSMutableArray*)getClipURLS
{
    return urlArray;
}
@end
