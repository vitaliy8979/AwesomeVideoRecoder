//
//  AppDelegate.h
//  VideoRecord
//
//  Created by Vitaliy on 15/6/2.
//  Copyright (c) 2015 Vitaliy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property(nonatomic, strong) CTCallCenter *callCenter;
@property (nonatomic, retain) NSString *videoFileName;
@property (nonatomic, readwrite) CGFloat timeDuration;
@end

