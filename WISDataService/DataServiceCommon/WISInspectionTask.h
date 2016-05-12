//
//  WISInspectionTask.h
//  WisdriIS
//
//  Created by Jingwei Wu on 4/20/16.
//  Copyright © 2016 Wisdri. All rights reserved.
//

#ifndef WISInspectionTask_h
#define WISInspectionTask_h

#import <Foundation/Foundation.h>
#import "WISDevice.h"
#import "WISDeviceType.h"
#import "WISFileInfo.h"

#endif /* WISInspectionTask_h */

typedef NS_ENUM(NSInteger, InspectionResult) {
    /// not selected
    NotSelected = 0,
    /// 设备正常
    DeviceNormal = 1,
    /// 设备故障待处理
    DeviceFaultForHandle = 2,
};

@interface WISInspectionTask : NSObject <NSCopying, NSCoding>

@property (readwrite, strong) WISDevice *device;
/// 最近一次点检的时间＋该类型设备的点检周期
@property (readwrite, strong) NSDate *lastInspectionFinishedTimePlusCycleTime;
/// 点检任务完成时间 - 由APP端生成
@property (readwrite, strong) NSDate *inspectionFinishedTime;
/// 点检结果
@property (readwrite) InspectionResult inspectionResult;
@property (readwrite, strong) NSMutableDictionary<NSString *, WISFileInfo *> *imagesInfo;
@property (readwrite, strong) NSString *inspectionResultDescription;


- (instancetype)init; // __attribute__((unavailable("init method not available")));

- (instancetype)initWithDevice:(WISDevice *)device lastInspectionFinishedTimePlusCycleTime:(NSDate *)lastInspectionFinishedTimePlusCycleTime
        inspectionFinishedTime:(NSDate *)inspectionFinishedTime
              inspectionResult:(InspectionResult)inspectionResult
                    imagesInfo:(NSMutableDictionary<NSString *, WISFileInfo *> *)imagesInfo
      andInspectionResultDescription:(NSString *)inspectionResultDescription;


#pragma mark - computed properties

- (NSDate *) inspectionDeadLine;

- (NSDate *) lastInspectionFinishedTime;

- (void) appendImagsInfoWithFileName:(NSString *)name andImageInfo:(WISFileInfo *)info;

- (void) appendImagesInfo:(id)imagesInfo;

@end

