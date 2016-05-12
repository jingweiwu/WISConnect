//
//  WISClockRecord.m
//  WisdriIS
//
//  Created by Jingwei Wu on 5/3/16.
//  Copyright © 2016 Wisdri. All rights reserved.
//

#import "WISClockRecord.h"

NSString *const clockActionEncodingKey = @"clockAction";
NSString *const clockActionTimeEncodingKey = @"clockActionTime";

@interface WISClockRecord()

@end

@implementation WISClockRecord

- (instancetype)init {
    return [self initWithClockAction:ClockUndefined clockActionTime:[NSDate date]];
}

- (instancetype)initWithClockAction:(ClockAction)clockAction clockActionTime:(NSDate *)clockActionTime {
    if (self = [super init]) {
        _clockAction = clockAction;
        _clockActionTime = clockActionTime;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _clockAction = (ClockAction)[aDecoder decodeIntegerForKey:clockActionEncodingKey];
        _clockActionTime = (NSDate *)[aDecoder decodeObjectForKey:clockActionTimeEncodingKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:(NSInteger)self.clockAction forKey:clockActionEncodingKey ];
    [aCoder encodeObject:self.clockActionTime forKey:clockActionTimeEncodingKey];
}

- (id) copyWithZone:(NSZone *)zone {
    WISClockRecord * record = [[[self class] allocWithZone:zone] initWithClockAction:self.clockAction
                                                                     clockActionTime:[self.clockActionTime copy]];
    return record;
}

@end
