//
//  AppDelegate.m
//  VideoRecord
//
//  Created by Vitaliy on 15/6/2.
//  Copyright (c) 2015 Vitaliy. All rights reserved.
//

#import "AppDelegate.h"
#import "ShootVideoViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    ShootVideoViewController* shootVC = [[ShootVideoViewController alloc] init];
//    UINavigationController* nav = [[UINavigationController alloc]initWithRootViewController:shootVC];
    
    self.window.rootViewController = shootVC;
    [self.window makeKeyAndVisible];
#if 0
    _callCenter = [[CTCallCenter alloc] init];
    
    [_callCenter setCallEventHandler:^(CTCall *call)
     {
         if ([call.callState isEqualToString: CTCallStateConnected])
         {
             NSLog(@"Connected");
         }
         else if ([call.callState isEqualToString: CTCallStateDialing])
         {
             NSLog(@"Dialing");
         }
         else if ([call.callState isEqualToString: CTCallStateDisconnected])
         {
             NSLog(@"Disconnected");
//             [shootVC performSelectorOnMainThread:@selector(resumeRecordVideo) withObject:nil waitUntilDone:YES];
             
         } else if ([call.callState isEqualToString: CTCallStateIncoming])
         {
             NSLog(@"Incoming");
//             [shootVC performSelectorOnMainThread:@selector(stopRecordVideo) withObject:nil waitUntilDone:YES];
         }
     }];
#endif
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
