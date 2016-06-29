//
//  WISDeviceType.h
//  WISConnect
//
//  Created by Jingwei Wu on 4/19/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#ifndef WISDeviceType_h
#define WISDeviceType_h

#import <Foundation/Foundation.h>

#endif /* WISDeviceType_h */

@interface WISDeviceType : NSObject <NSCopying, NSCoding>

@property (readwrite, strong) NSString *deviceTypeID;
@property (readwrite, strong) NSString *deviceTypeName;
/// 点检周期, 单位: 小时
@property (readwrite) NSInteger inspectionCycle;
/// 可接受的延迟时间, 单位: 小时
@property (readwrite) NSInteger acceptableDelayTime;
/// 点检提示信息
@property (readwrite, strong) NSString *inspectionInformation;

- (instancetype)init; // __attribute__((unavailable("init method not available")));

- (instancetype)initWithDeviceTypeID:(NSString *)deviceTypeID
                      deviceTypeName:(NSString *)deviceTypeName
                     inspectionCycle:(NSInteger)inspectionCycle
                 acceptableDelayTime:(NSInteger)acceptableDelayTime
            andinspectionInformation:(NSString *)inspectionInformation;

#pragma mark - computed properties

- (NSString *) inspectionCycleDescription;
- (NSString *) acceptableDelayTimeDescription;

+ (NSString *) hoursAsReadableString:(NSInteger)timeInHour;

@end
