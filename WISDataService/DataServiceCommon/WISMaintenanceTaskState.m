//
//  WISMaitenanceTaskState.m
//  WisdriIS
//
//  Created by Jingwei Wu on 5/5/16.
//  Copyright © 2016 Wisdri. All rights reserved.
//

#import "WISUser.h"
#import "WISMaintenanceTaskState.h"

NSString *const stateEncodingKey = @"state";
NSString *const stateStartTimeEncodingKey = @"stateStartTime";
NSString *const stateEndTimeEncodingKey = @"stateEndTime";
NSString *const statePersonInChargeEncodingKey = @"statePersonInCharge";

@implementation WISMaintenanceTaskState

- (instancetype)init {
    return [self initWithState:@""
                     startTime:[NSDate date]
                       endTime:[NSDate date]
                personInCharge:[[WISUser alloc]init]];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _state = (NSString *)[aDecoder decodeObjectForKey:stateEncodingKey];
        _startTime = (NSDate *)[aDecoder decodeObjectForKey:stateStartTimeEncodingKey];
        _endTime = (NSDate *)[aDecoder decodeObjectForKey:stateEndTimeEncodingKey];
        _personInCharge = (WISUser *)[aDecoder decodeObjectForKey:statePersonInChargeEncodingKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.state forKey:stateEncodingKey];
    [aCoder encodeObject:self.startTime forKey:stateStartTimeEncodingKey];
    [aCoder encodeObject:self.endTime forKey:stateEndTimeEncodingKey];
    [aCoder encodeObject:self.personInCharge forKey:statePersonInChargeEncodingKey];
}

- (instancetype)initWithState:(NSString *)state
                    startTime:(NSDate *)startTime
                      endTime:(NSDate *)endTime
               personInCharge:(WISUser *)personInCharge {
    
    if (self = [super init]) {
        _state = state;
        _startTime = startTime;
        _endTime = endTime;
        _personInCharge = personInCharge;
    }
    return self;
}

- (id) copyWithZone:(NSZone *)zone {
    WISMaintenanceTaskState * taskState = [[[self class] allocWithZone:zone] initWithState:[self.state copy]
                                                                                startTime:[self.startTime copy]
                                                                                  endTime:[self.endTime copy]
                                                                           personInCharge:[self.personInCharge copy]];
    return taskState;
}


+ (BOOL) arraySortForwardByEndTimeWithLhs:(WISMaintenanceTaskState *)lhs rhs: (WISMaintenanceTaskState *)rhs {
    NSComparisonResult result = [lhs.endTime compare:rhs.endTime];
    if (result == NSOrderedAscending) {
        return YES;
    } else {
        return NO;
    }
}


+ (BOOL) arraySortBackwardByEndTimeWithLhs:(WISMaintenanceTaskState *)lhs rhs: (WISMaintenanceTaskState *)rhs {
    NSComparisonResult result = [lhs.endTime compare:rhs.endTime];
    if (result == NSOrderedDescending) {
        return YES;
    } else {
        return NO;
    }
}

@end
