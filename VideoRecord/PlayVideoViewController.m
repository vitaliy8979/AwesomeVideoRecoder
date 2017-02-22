//
//  PlayVideoViewController.m
//  VideoRecord
//
//  Created by Vitaliy on 15/4/27.
//  Copyright (c) 2015 Vitaliy. All rights reserved.
//

#import "PlayVideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AppDelegate.h"
#import "Defines.h"

@interface PlayVideoViewController ()<UITextFieldDelegate, UIScrollViewDelegate>

@end

@implementation PlayVideoViewController
{

//    AVPlayer *player;
    AVPlayerLayer *playerLayer;
    AVPlayerItem *playerItem;
    
    UIImageView* playImg;
    CGFloat currentLength;
    CGFloat videoLength;
    int currentIndex;
    id playbackObserver;
    BOOL isTapScrolling;
    UIView *selectedView;
    UITextField *actTextField;
    BOOL showedPopup;
    UIActivityIndicatorView *indicator;
}

@synthesize videoURL;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.nameText.delegate = self;
    self.scrollView.delegate = self;
    self.nameText.text = DELEGATE.videoFileName;
    
    [self setVideoPlayer];
    
    UITapGestureRecognizer *singleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(viewSingleTap:)];
    [self.view addGestureRecognizer:singleFingerTap];
    
    /* menu */
    QBPopupMenuItem *backItem = [QBPopupMenuItem itemWithImage:[UIImage imageNamed:@"back"] target:self action:@selector(actionBack)];
    QBPopupMenuItem *forwardItem = [QBPopupMenuItem itemWithImage:[UIImage imageNamed:@"forward"] target:self action:@selector(actionForward)];
    QBPopupMenuItem *trashItem = [QBPopupMenuItem itemWithImage:[UIImage imageNamed:@"trash"] target:self action:@selector(actionTrash)];
    
    NSArray *items = @[trashItem, backItem, forwardItem];
    
    QBPlasticPopupMenu *plasticPopupMenu = [[QBPlasticPopupMenu alloc] initWithItems:items];
    plasticPopupMenu.height = 30;
    self.plasticPopupMenu = plasticPopupMenu;
    
    CGFloat activityHeight = 30;
    CGRect srcRect = [[UIScreen mainScreen] bounds];
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [activityIndicator setTintColor:[UIColor whiteColor]];
    activityIndicator.alpha = 0.0f;
    [activityIndicator setFrame:CGRectMake((srcRect.origin.x-activityHeight)/2, (srcRect.origin.y-activityHeight)/2, activityHeight, activityHeight)];
    [activityIndicator startAnimating];
    [self.videoView.layer addSublayer:activityIndicator.layer];
    indicator = activityIndicator;
}

- (void)setVideoPlayer
{
    AVAsset *movieAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    _isPlaying = NO;
    
    playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
    self.moviePlayer = [AVPlayer playerWithPlayerItem:playerItem];
    CGRect scrRect = [[UIScreen mainScreen] bounds];
    
    playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.moviePlayer];
    playerLayer.frame = CGRectMake(0, 0, scrRect.size.width, scrRect.size.height - 168 - self.videoView.frame.origin.y);
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.videoView.layer addSublayer:playerLayer];
    
    [playerItem seekToTime:kCMTimeZero];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playingEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    CMTime vtime = [asset duration];
    float fsecond = (float)vtime.value/vtime.timescale;
    DELEGATE.timeDuration =fsecond;   
    
    
    CMTime interval = CMTimeMake(33, 1000);
    __weak __typeof(self) weakself = self;
    
    playbackObserver = [self.moviePlayer addPeriodicTimeObserverForInterval:interval
                       queue:dispatch_get_main_queue() usingBlock: ^(CMTime time) {
                           
                        CMTime endTime = CMTimeConvertScale (weakself.moviePlayer.currentItem.asset.duration, weakself.moviePlayer.currentTime.timescale, kCMTimeRoundingMethod_RoundHalfAwayFromZero);
                         if (CMTimeCompare(endTime, kCMTimeZero) != 0) {
                              double normalizedTime = (double) weakself.moviePlayer.currentTime.value / (double) endTime.value;
                              NSLog(@"normalze : %g", normalizedTime);
                              if (weakself.isPlaying) {
                                  NSLog(@"normalze : %f", videoLength*normalizedTime);
                                  [weakself.scrollView setContentOffset:
                                  CGPointMake((CGFloat)videoLength*normalizedTime, 0) animated:NO];
                             } else {                                                                                  NSLog(@"PLAY STOP");
                             }
                        }
       }];
}

- (void)actionBack{
    NSInteger index = selectedView.tag;
    if (index == 0) return;
    
    NSURL *selectURL = [_clipURLS objectAtIndex:index];
    [_clipURLS removeObjectAtIndex:index];
    [_clipURLS insertObject:selectURL atIndex:index-1];
    NSNumber *degree = [_degrees objectAtIndex:index];
    [_degrees removeObjectAtIndex:index];
    [_degrees insertObject:degree atIndex:index-1];
    
    [self refresh];

}

- (void)actionForward{
    NSInteger index = selectedView.tag;
    if (index == _clipURLS.count-1) return;
    
    NSURL *selectURL = [_clipURLS objectAtIndex:index];
    [_clipURLS removeObjectAtIndex:index];
    [_clipURLS insertObject:selectURL atIndex:index+1];
    NSNumber *degree = [_degrees objectAtIndex:index];
    [_degrees removeObjectAtIndex:index];
    [_degrees insertObject:degree atIndex:index+1];
    
    [self refresh];
}

- (void)actionTrash{
    [self showActivityIndicator];
    NSInteger index = selectedView.tag;
    
    NSURL *videoFileURL = [_clipURLS objectAtIndex:index];
    if (videoFileURL == nil) return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *filePath = [[videoFileURL absoluteString] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:filePath]) {
            NSError *error = nil;
            [fileManager removeItemAtPath:filePath error:&error];
            
            if (error) {
                NSLog(@"delete All Video Failed:%@", error);
            } else {
                 [self performSelectorOnMainThread:@selector(refresh) withObject:nil waitUntilDone:YES];
            }
        }
    });
    [_clipURLS removeObjectAtIndex:index];
    [_degrees removeObjectAtIndex:index];
}

- (void)viewSingleTap:(UITapGestureRecognizer *)recognizer {
    if (selectedView != nil) {
        selectedView.layer.borderColor = UIColorFromRGB(0x1660AB).CGColor;
    }
    if (actTextField != nil) {
        [actTextField resignFirstResponder];
        actTextField = nil;
    }
    if (showedPopup) {
        [self.plasticPopupMenu dismissAnimated:YES];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    CGRect scrRect = [[UIScreen mainScreen] bounds];

    currentLength = scrRect.size.width/2;
    currentIndex = 0;
    videoLength = 0;
    [self setframeVideo:currentIndex];
  
}

-(void) refresh {
    for (UIView  *view in _scrollView.subviews) {
        [view removeFromSuperview];
    }
    
    CGRect scrRect = [[UIScreen mainScreen] bounds];
    
    currentLength = scrRect.size.width/2;
    currentIndex = 0;
    videoLength = 0;
    [self setframeVideo:currentIndex];
    [self mergeAndExportVideosAtFileURLs:_clipURLS];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!isTapScrolling) return;
    
    if (_isPlaying) {
        _isPlaying = NO;
        [self.moviePlayer pause];
        [self.playBtn setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];

    }
    CGPoint point = [scrollView contentOffset];
    NSLog(@"dfsdfas x : y %f  %f", point.x, point.y);
    
    CMTime seekTime = CMTimeMakeWithSeconds(point.x / videoLength * (double)self.moviePlayer.currentItem.asset.duration.value/(double)self.moviePlayer.currentItem.asset.duration.timescale, self.moviePlayer.currentTime.timescale);
    
    [self.moviePlayer seekToTime:seekTime];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    isTapScrolling = NO;
    NSLog(@"sdfasfasf");
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    isTapScrolling = YES;
    NSLog(@"235235246437");
}

-(void)setframeVideo:(int)index
{
    if (index == _clipURLS.count) {
        CGRect scrRect = [[UIScreen mainScreen] bounds];
            [self.scrollView setContentSize:CGSizeMake(scrRect.size.width/2+currentLength + 5, _scrollView.frame.size.height)];
//            [self.scrollView setContentOffset:
//             CGPointMake(0, 0) animated:YES];
        videoLength = currentLength - scrRect.size.width/2;
        return;
    }
    
    NSURL *fileURL = [_clipURLS objectAtIndex:index];
    NSInteger videoAngleInDegree =[[_degrees objectAtIndex:index] integerValue];
    
    NSMutableArray *imagesArray = [[NSMutableArray alloc] init];
    NSMutableArray *times = [[NSMutableArray alloc] init];

    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:fileURL options:nil];
    AVAssetImageGenerator *generate = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generate.appliesPreferredTrackTransform = YES;
    
    CMTime vtime = [asset duration];
    CGFloat dur  = 1.0f;
    int seconds = 0;
    float fsecond = (float)vtime.value/vtime.timescale;
    NSLog(@"fsecond %f", fsecond);
    
    if (fsecond < dur) {
        CMTime time = CMTimeMakeWithSeconds(0, 60);
        [times addObject:[NSValue valueWithCMTime:time]];
        seconds = 1;
    } else {
        seconds = ceil(fsecond);
        NSLog(@"vtime   %d", seconds);
        fsecond = 1.0f;
        for (Float64 i = 0; i < seconds; i+=dur) // For 2 fps in 1 sec of Video
        {
            CMTime time = CMTimeMakeWithSeconds(i, 60);
            [times addObject:[NSValue valueWithCMTime:time]];
        }
    }
    
    [generate generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
        int sec = ceil (actualTime.value/actualTime.timescale);
        NSLog(@"fefe   %d", sec);
        
        if (result == AVAssetImageGeneratorSucceeded)
        {
            UIImage *generatedImage =[self imageRotatedByDegrees:[[UIImage alloc] initWithCGImage:image] deg:videoAngleInDegree];
            
            [imagesArray addObject:generatedImage];
            if (seconds == imagesArray.count) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setImageOnCurrentView:imagesArray Scale:fsecond];
                });
//              [self performSelectorOnMainThread:@selector(setImageOnCurrentView:) withObject:imagesArray waitUntilDone:YES];
            }
        }
    }];
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:[recognizer.view superview]];
    if (selectedView != nil) {
        selectedView.layer.borderColor = UIColorFromRGB(0x1660AB).CGColor;
    }
    
    NSLog(@"sdfsdfsdf   %f ---  location   %f", recognizer.view.frame.origin.x, location.x);
    CGRect scrRect = [[UIScreen mainScreen] bounds];

    selectedView = recognizer.view;
    selectedView.layer.borderColor = [UIColor redColor].CGColor;
    showedPopup = YES;
    
    CGPoint point = [self.scrollView contentOffset];

    CGFloat x = selectedView.frame.origin.x - point.x;
    
   [self.plasticPopupMenu showInView:self.view targetRect:CGRectMake(x, scrRect.size.height - 143, selectedView.frame.size.width, selectedView.frame.size.width) animated:YES];
}

-(void)setImageOnCurrentView:(NSMutableArray*)imgs Scale:(CGFloat)scale
{
    NSInteger count = imgs.count;
    
    CGFloat imgwidth = scale * 50.0f;
    CGFloat viewWidth = imgwidth*count;
    CGFloat viewX =currentLength+5;
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(viewX, 0, viewWidth, _scrollView.frame.size.height)];
    view.tag = currentIndex;
    UITapGestureRecognizer *singleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(handleSingleTap:)];
    [view addGestureRecognizer:singleFingerTap];
    
    view.layer.borderColor = UIColorFromRGB(0x1660AB).CGColor;
    view.layer.borderWidth = 1.0f;
    [_scrollView addSubview:view];
    currentLength = viewX + viewWidth;
    NSLog(@"view Width : %f", viewWidth);
    
    for (int i = 0; i<count; i++) {
        UIImage *img = [imgs objectAtIndex:i];
        
        float itemWidth = imgwidth;
        
        if (i == count-1) {
            itemWidth = viewWidth - imgwidth*i;
        }
        
        UIImageView *imgView = [[UIImageView alloc]initWithFrame:CGRectMake(itemWidth*i, 0, itemWidth, _scrollView.frame.size.height)];
        
        imgView.contentMode = UIViewContentModeScaleToFill;
        imgView.image = img;
        [view addSubview:imgView];
        NSLog(@"item width : %f", itemWidth);
    }
    
    [self setframeVideo:++currentIndex];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    DELEGATE.videoFileName = self.nameText.text;
    [textField resignFirstResponder];
    return YES;
}
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    actTextField = textField;
     [textField selectAll:self];
}
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    actTextField = nil;
}

-(void)playOrPause{
    if (_isPlaying) {
        _isPlaying = NO;
        [self.moviePlayer pause];
        [self.playBtn setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    }else{
        _isPlaying = YES;
        [self.moviePlayer play];
        [self.playBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    }
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

#define degreesToRadians(x) (M_PI * x / 180.0)

- (void)mergeAndExportVideosAtFileURLs:(NSMutableArray *)fileURLArray
{
    if (_clipURLS.count <= 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *filePath = [[videoURL absoluteString] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:filePath]) {
                NSError *error = nil;
                [fileManager removeItemAtPath:filePath error:&error];
                
                if (error) {
                    NSLog(@"delete All Video Failed:%@", error);
                } else {
                    videoURL = nil;
                    DELEGATE.timeDuration = 0.0f;
                    [self performSelectorOnMainThread:@selector(backController) withObject:nil waitUntilDone:YES];
                }
            }
        });
        return;
    }
    NSError *error = nil;
    //video size
    CGSize renderSize = CGSizeMake(0, 0);
    float preLayerWidth = SCREEN_WIDTH;
    float preLayerHeight = SCREEN_HEIGHT;
    float preLayerHWRate =preLayerHeight/preLayerWidth;
    
    NSMutableArray *layerInstructionArray = [[NSMutableArray alloc] init];
    
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    CMTime totalDuration = kCMTimeZero;
    
    NSMutableArray *assetTrackArray = [[NSMutableArray alloc] init];
    NSMutableArray *assetArray = [[NSMutableArray alloc] init];
    for (NSURL *fileURL in _clipURLS) {
        
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
        
        NSInteger videoAngleInDegree =[[_degrees objectAtIndex:i] integerValue];
        
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
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideActivityIndicator];

            videoURL = mergeFileURL;
            if (self.videoView.layer.sublayers.count > 0)
                [playerLayer removeFromSuperlayer];
            
            [self setVideoPlayer];

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

- (void) showActivityIndicator
{
    [UIView animateWithDuration:0.3f animations:^{
        indicator.alpha = 1.0f;
        [indicator startAnimating];
    } completion:^(BOOL finished) {
        
    }];
}
- (void)hideActivityIndicator
{
    [UIView animateWithDuration:0.3f animations:^{
        [indicator stopAnimating];
    } completion:^(BOOL finished) {
        
    }];
    
    if (indicator != nil) {
        [indicator removeFromSuperview];
        indicator = nil;
    }
}
- (void)pressPlayButton
{
    [playerItem seekToTime:kCMTimeZero];
    [self.playBtn setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
//    [player play];
}

- (void)playingEnd:(NSNotification *)notification
{
    if (_isPlaying) {
        [self pressPlayButton];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)backController{
    [self dismissViewControllerAnimated:YES completion:nil];

}
- (IBAction)back:(id)sender {
    [self backController];
}

- (IBAction)play:(id)sender {
    [self playOrPause];
}
- (void)dealloc
{
    [self.moviePlayer removeTimeObserver:playbackObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}
@end
