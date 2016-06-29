//
//  WISAttendanceRecord.h
//  WisdriIS
//
//  Created by Jingwei Wu on 6/26/16.
//  Copyright © 2016 Wisdri. All rights reserved.
//

#ifndef WISAttendanceRecord_h
#define WISAttendanceRecord_h

#import <Foundation/Foundation.h>
#import "WISSorter.h"

#endif // WISAttendanceRecord_h

/**
 * @brief 由服务器定义的考勤状态
 */
typedef NS_ENUM(NSInteger, AttendanceStatus) {
    /// 未定义
    UndefinedAttendanceStatus = -2,
    /// 无记录
    NoAttendanceRecord = -1,
    /// 打卡记录正常
    AttendanceNormal = 1,
    /// 打卡记录异常
    AttendanceAbnormal = 2,
    /// 已打卡
    AttendanceClocked = 3,
    /// 未打卡
    AttendanceNotClocked = 4,
};

/**
 * @brief 由服务器定义的排班内容
 */
typedef NS_ENUM(NSInteger, WorkShift) {
    /// 未定义
    UndefinedWorkShift = -1,
    /// 白班
    DayShift = 1,
    /// 夜班
    NightShift = 2,
    /// 休息
    OffDuty = 3,
};

@class WISUser;

@interface WISAttendanceRecord : NSObject <NSCopying, NSSecureCoding>

/// 考勤状态
@property (readwrite) AttendanceStatus attendanceStatus;
/// 排班信息
@property (readwrite) WorkShift shift;
/// 人员信息
@property (readwrite, strong) WISUser *staff;
/// 查询考勤状态的日期
@property (readwrite, strong) NSDate *attendanceRecordDate;


- (instancetype)init;

- (instancetype)initWithAttendanceStatus:(AttendanceStatus) attendanceStatus
                                   shift:(WorkShift) shift
                                   staff:(WISUser *) staff
                    attendanceRecordDate:(NSDate *) recordDate;

+ (arrayForwardSorterWithResult) arrayForwardSorterByStaffFullNameWithResult;
+ (arrayBackwardSorterWithResult) arrayBackwardSorterByStaffFullNameWithResult;
+ (arrayForwardSorterWithBOOL) arrayForwardByStaffFullNameWithBOOL;
+ (arrayBackwardSorterWithBOOL) arrayBackwardByStaffFullNameWithBOOL;

@end


