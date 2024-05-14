//
//  AppInitLog.h
//  App
//
//  Created by jaiprakash bokhare on 07/05/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface NotificationLog : NSObject

@property (nonatomic, readonly) NSNotification *notification;
@property (nonatomic, readonly) NSDate *time;

- (instancetype)initWithNotification:(NSNotification *)notification time:(NSDate *)time;

@end

NS_ASSUME_NONNULL_END
