//
//  PlayVideoViewController.h
//  VideoRecord
//
//  Created by Vitaliy on 15/4/27.
//  Copyright (c) 2015 Vitaliy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "QBPopupMenu.h"
#import "QBPlasticPopupMenu.h"

@interface PlayVideoViewController : UIViewController
-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
@property (weak, nonatomic) IBOutlet UIView *videoView;
@property (weak, nonatomic) IBOutlet UITextField *nameText;
@property(nonatomic,retain) NSURL * videoURL;
@property(nonatomic,retain) NSMutableArray * clipURLS;
@property(nonatomic,retain) NSMutableArray * degrees;
@property (retain, nonatomic) AVPlayer *moviePlayer;
@property (readwrite, nonatomic) BOOL isPlaying;
@property (nonatomic, strong) QBPopupMenu *popupMenu;
@property (nonatomic, strong) QBPlasticPopupMenu *plasticPopupMenu;

- (IBAction)back:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
- (IBAction)play:(id)sender;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end
