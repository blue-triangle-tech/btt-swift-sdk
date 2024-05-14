//
//  AppInitLog.m
//  App
//
//  Created by jaiprakash bokhare on 07/05/24.
//

#import "AppNotificationLogger.h"
#import <UIKit/UIKit.h>
#import "NotificationLog.h"

NSMutableArray<NotificationLog *> *appNotifications;

@interface AppNotificationLogger()

@end

@implementation AppNotificationLogger

+ (void)load {
    
    NSLog(@"AppInitLog::initialize...");
    
    appNotifications = [[NSMutableArray<NotificationLog *> alloc] init];
    
    __block __weak id finishObserver = [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        NotificationLog * notificationLog = [[NotificationLog alloc] initWithNotification:notification time:[NSDate date]];
        [appNotifications addObject:notificationLog];
        NSLog(@"AppInitLog::UIApplicationDidFinishLaunchingNotification...");
    }];
     
    __block __weak id backgroundObserver = [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        [appNotifications removeAllObjects];
        NSLog(@"AppInitLog::UIApplicationDidEnterBackgroundNotification...");
    }];
      
    __block __weak id forgroundObserver = [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        NotificationLog * notificationLog = [[NotificationLog alloc] initWithNotification:notification time:[NSDate date]];
        [appNotifications addObject:notificationLog];
        NSLog(@"AppInitLog::UIApplicationWillEnterForegroundNotification...");
    }];
    
    __block __weak id activeObserver = [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        NotificationLog * notificationLog = [[NotificationLog alloc] initWithNotification:notification time:[NSDate date]];
        [appNotifications addObject:notificationLog];
        NSLog(@"AppInitLog::UIApplicationDidBecomeActiveNotification...");
    }];
    
}

+(NSMutableArray<NotificationLog *> *)getNotifications{
    return appNotifications;
}

+(void) removeObserver{
    @try{
        
        [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationDidFinishLaunchingNotification object:nil];
        [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
        [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
        [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    @catch(id exception) {
        NSLog(@"AppInitLog::NSNotificationCenter...%@", exception);
    }
}

    
@end

