//
//  WISClockRecord.h
//  WisdriIS
//
//  Created by Jingwei Wu on 5/3/16.
//  Copyright © 2016 Wisdri. All rights reserved.
//


#ifndef WISClockRecord_h
#define WISClockRecord_h

#import <Foundation/Foundation.h>

#endif /* WISClockRecord_h */

/**
 * @brief 由服务器定义的打卡请求
 */
typedef NS_ENUM(NSInteger, ClockAction) {
    /// 未定义
    ClockUndefined = 0,
    /// 打卡 - 上班
    ClockIn = 1,
    /// 打卡 - 下班
    ClockOff = 2,
};

@interface WISClockRecord : NSObject <NSCopying, NSCoding>

@property (readwrite) ClockAction clockAction;
@property (readwrite, strong) NSDate *clockActionTime;

- (instancetype)init; // __attribute__((unavailable("init method not available")));

- (instancetype)initWithClockAction:(ClockAction)clockAction clockActionTime:(NSDate *)clockActionTime;

@end
