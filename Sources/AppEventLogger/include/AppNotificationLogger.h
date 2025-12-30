//
//  AppInitLog.h
//  App
//
//  Created by jaiprakash bokhare on 07/05/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class NotificationLog;

@interface AppNotificationLogger : NSObject
+ (NSMutableArray<NotificationLog *> *)getNotifications;
+ (void) removeObserver;
+ (void) clearNotifications;

@end

NS_ASSUME_NONNULL_END
