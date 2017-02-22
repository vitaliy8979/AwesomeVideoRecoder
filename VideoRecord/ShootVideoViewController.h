//
//  ShootVideoViewController.h
//  VideoRecord
//
//  Created by Vitaliy on 13/5/2016.
//  Copyright (c) 2016 Vitaliy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "UIView+Tools.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define SHOOTVIEW_HEIGHT 90
#define MAX_VIDEO_TIME 3600 //second

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface ShootVideoViewController : UIViewController

@property float totalTime;
-(NSMutableArray*)getClipURLS;

@end
