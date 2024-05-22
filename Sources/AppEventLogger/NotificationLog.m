//
//  AppInitLog.m
//  App
//
//  Created by jaiprakash bokhare on 07/05/24.
//

#import "NotificationLog.h"

@implementation NotificationLog

- (instancetype)initWithNotification:(NSNotification *)notification time:(NSDate *)time{
    self = [super init];
    if (self) {
        _notification = notification;
        _time = time;
    }
    return self;
}

@end
