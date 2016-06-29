//
//  WISAttendanceRecord.m
//  WisdriIS
//
//  Created by Jingwei Wu on 6/26/16.
//  Copyright © 2016 Wisdri. All rights reserved.
//

#import "WISAttendanceRecord.h"
#import "WISUser.h"

NSString *const attendanceStatusEncodingKey = @"attendanceStatus";
NSString *const shiftOfAttendanceRecordEncodingKey = @"shiftOfAttendanceRecord";
NSString *const staffOfAttendanceRecordEncodingKey = @"staffOfAttendanceRecord";
NSString *const attendanceRecordDateEncodingKey = @"attendanceRecordDate";

@interface WISAttendanceRecord()

@end

@implementation WISAttendanceRecord

- (instancetype)init {
    return [self initWithAttendanceStatus:UndefinedAttendanceStatus
                                    shift:UndefinedWorkShift
                                    staff:[[WISUser alloc] init]
                     attendanceRecordDate:[NSDate date]];
}

- (instancetype)initWithAttendanceStatus:(AttendanceStatus) attendanceStatus
                                   shift:(WorkShift) shift
                                   staff:(WISUser *) staff
                    attendanceRecordDate:(NSDate *) recordDate {
    if (self = [super init]) {
        _attendanceStatus = attendanceStatus;
        _shift = shift;
        _staff = staff;
        _attendanceRecordDate = recordDate;
    }
    return self;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _attendanceStatus = (AttendanceStatus)[aDecoder decodeIntegerForKey:attendanceStatusEncodingKey];
        _shift = (WorkShift)[aDecoder decodeIntegerForKey:shiftOfAttendanceRecordEncodingKey];
        _staff = (WISUser *)[aDecoder decodeObjectOfClass:[WISUser class] forKey:staffOfAttendanceRecordEncodingKey];
        _attendanceRecordDate = (NSDate *)[aDecoder decodeObjectOfClass:[NSDate class] forKey:attendanceRecordDateEncodingKey];
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:(NSInteger)_attendanceStatus forKey:attendanceStatusEncodingKey];
    [aCoder encodeInteger:(NSInteger)_shift  forKey:shiftOfAttendanceRecordEncodingKey];
    [aCoder encodeObject:_staff forKey:staffOfAttendanceRecordEncodingKey];
    [aCoder encodeObject:_attendanceRecordDate forKey:attendanceRecordDateEncodingKey];
}

+ (BOOL) supportsSecureCoding {
    return YES;
}

- (id) copyWithZone:(NSZone *)zone {
    WISAttendanceRecord * record = [[[self class] allocWithZone:zone] initWithAttendanceStatus:self.attendanceStatus
                                                                                         shift:self.shift
                                                                                         staff:[self.staff copy]
                                                                          attendanceRecordDate:[self.attendanceRecordDate copy]];
    return record;
}


+ (arrayForwardSorterWithResult) arrayForwardSorterByStaffFullNameWithResult {
    arrayForwardSorterWithResult sorter = ^(id lhsOriginal, id rhsOriginal) {
        WISAttendanceRecord *lhs = (WISAttendanceRecord *)lhsOriginal;
        WISAttendanceRecord *rhs = (WISAttendanceRecord *)rhsOriginal;
        
        return [lhs.staff.fullName compare:rhs.staff.fullName];
    };
    return sorter;
}

+ (arrayBackwardSorterWithResult) arrayBackwardSorterByStaffFullNameWithResult {
    arrayForwardSorterWithResult sorter = ^(id lhsOriginal, id rhsOriginal) {
        WISAttendanceRecord *lhs = (WISAttendanceRecord *)lhsOriginal;
        WISAttendanceRecord *rhs = (WISAttendanceRecord *)rhsOriginal;
        
        return [rhs.staff.fullName compare:lhs.staff.fullName];
    };
    return sorter;
}

+ (arrayForwardSorterWithBOOL) arrayForwardByStaffFullNameWithBOOL {
    arrayForwardSorterWithBOOL sorter = ^(id lhsOriginal, id rhsOriginal) {
        WISAttendanceRecord *lhs = (WISAttendanceRecord *)lhsOriginal;
        WISAttendanceRecord *rhs = (WISAttendanceRecord *)rhsOriginal;
        
        NSComparisonResult result = [lhs.staff.fullName compare:rhs.staff.fullName];
        if (result == NSOrderedAscending || result == NSOrderedSame) {
            return YES;
        } else {
            return NO;
        }
    };
    
    return sorter;
}

+ (arrayBackwardSorterWithBOOL) arrayBackwardByStaffFullNameWithBOOL {
    arrayBackwardSorterWithBOOL sorter = ^(id lhsOriginal, id rhsOriginal) {
        WISAttendanceRecord *lhs = (WISAttendanceRecord *)lhsOriginal;
        WISAttendanceRecord *rhs = (WISAttendanceRecord *)rhsOriginal;
        
        NSComparisonResult result = [lhs.staff.fullName compare:rhs.staff.fullName];
        if (result == NSOrderedDescending || result == NSOrderedSame) {
            return YES;
        } else {
            return NO;
        }
    };
    
    return sorter;
}


@end
