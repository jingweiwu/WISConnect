//
//  WISDevice.h
//  WisdriIS
//
//  Created by Jingwei Wu on 4/20/16.
//  Copyright © 2016 Wisdri. All rights reserved.
//

#ifndef WISDevice_h
#define WISDevice_h

#import <Foundation/Foundation.h>
#import "WISDeviceType.h"

#endif /* WISDevice_h */


@interface WISDevice : NSObject <NSCopying, NSCoding>

@property (readwrite, strong) NSString *deviceID;
@property (readwrite, strong) NSString *deviceName;
/// 设备编号, 设备位号
@property (readwrite, strong) NSString *deviceCode;
/// 设备类型ID
@property (readwrite, strong) WISDeviceType *deviceType;
@property (readwrite, strong) NSString *company;
@property (readwrite, strong) NSString *processSegment;
@property (readwrite, strong) NSDate *putIntoServiceTime;
/// 设备信息备注
@property (readwrite, strong) NSString *remark;

- (instancetype)init; // __attribute__((unavailable("init method not available")));

- (instancetype)initWithDeviceID:(NSString *)deviceID
                      deviceName:(NSString *)deviceName
                      deviceCode:(NSString *)deviceCode
                      deviceType:(WISDeviceType *)deviceType
                         company:(NSString *)company
                  processSegment:(NSString *)processSegment
              putIntoServiceTime:(NSDate *)putIntoServiceTime
                       andRemark:(NSString *)remark;

@end
