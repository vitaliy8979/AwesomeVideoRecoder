//
//  Defines.h
//  VideoRecord
//
//  Created by Vitaliy on 14-1-25.
//  Copyright (c) 2014 Vitaliy. All rights reserved.
//

#ifndef SCCaptureCameraDemo_SCDefines_h
#define SCCaptureCameraDemo_SCDefines_h

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define VIDEO_FOLDER @"videoFolder"
#define VIDEO_SESSION_SIZE AVCaptureSessionPreset352x288

#define DELEGATE ((AppDelegate*) [[UIApplication sharedApplication] delegate])
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#endif
