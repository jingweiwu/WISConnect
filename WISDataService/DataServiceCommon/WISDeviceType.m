//
//  WISDeviceType.h
//  WISConnect
//
//  Created by Jingwei Wu on 4/19/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#import "WISDeviceType.h"

///Encoding Keys
NSString *const deviceTypeIDEncodingKey = @"deviceTypeID";
NSString *const deviceTypeNameEncodingKey = @"deviceTypeName";
NSString *const inspectionCycleEncodingKey = @"inspectionCycle";
NSString *const acceptableDelayTimeEncodingKey = @"acceptableDelayTime";
NSString *const inspectionInformationEncodingKey = @"inspectionInformation";

@interface WISDeviceType ()

@end

@implementation WISDeviceType

- (instancetype)init {
    return [self initWithDeviceTypeID:@""
                       deviceTypeName:@""
                      inspectionCycle:0
                  acceptableDelayTime:0
             andinspectionInformation:@""];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _deviceTypeID = (NSString *)[aDecoder decodeObjectForKey:deviceTypeIDEncodingKey];
        _deviceTypeName = (NSString *)[aDecoder decodeObjectForKey:deviceTypeNameEncodingKey];
        _inspectionCycle = (NSInteger)[aDecoder decodeIntegerForKey:inspectionCycleEncodingKey];
        _acceptableDelayTime = (NSInteger)[aDecoder decodeIntegerForKey:acceptableDelayTimeEncodingKey];
        _inspectionInformation = (NSString *)[aDecoder decodeObjectForKey:inspectionInformationEncodingKey];
    }
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.deviceTypeID forKey:deviceTypeIDEncodingKey];
    [aCoder encodeObject:self.deviceTypeName forKey:deviceTypeNameEncodingKey];
    [aCoder encodeInteger:self.inspectionCycle forKey:inspectionCycleEncodingKey];
    [aCoder encodeInteger:self.acceptableDelayTime forKey:acceptableDelayTimeEncodingKey];
    [aCoder encodeObject:self.inspectionInformation forKey:inspectionInformationEncodingKey];
}

- (instancetype)initWithDeviceTypeID:(NSString *)deviceTypeID
                      deviceTypeName:(NSString *)deviceTypeName
                     inspectionCycle:(NSInteger)inspectionCycle
                 acceptableDelayTime:(NSInteger)acceptableDelayTime
            andinspectionInformation:(NSString *)inspectionInformation {
    
    if (self = [super init]) {
        _deviceTypeID = deviceTypeID;
        _deviceTypeName = deviceTypeName;
        _inspectionCycle = inspectionCycle;
        _acceptableDelayTime = acceptableDelayTime;
        _inspectionInformation = inspectionInformation;
    }
    return self;
}


- (id) copyWithZone:(NSZone *)zone {
    WISDeviceType * deviceType = [[[self class] allocWithZone:zone] initWithDeviceTypeID:[self.deviceTypeID copy]
                                                                          deviceTypeName:[self.deviceTypeName copy]
                                                                         inspectionCycle:self.inspectionCycle
                                                                     acceptableDelayTime:self.acceptableDelayTime
                                                                andinspectionInformation:[self.inspectionInformation copy]];
    return deviceType;
}

#pragma mark - computed properties

- (NSString *) inspectionCycleDescription {
    return [WISDeviceType hoursAsReadableString:self.inspectionCycle];
}

- (NSString *) acceptableDelayTimeDescription {
    return [WISDeviceType hoursAsReadableString:self.acceptableDelayTime];
}

+ (NSString *) hoursAsReadableString:(NSInteger)timeInHour {
    NSString *description = @"";
    
    if (timeInHour > 0) {
        NSInteger year = timeInHour / (24*365);
        NSInteger month = (timeInHour % (24*365)) / (24*30);
        NSInteger week = ((timeInHour % (24*365)) % (24*30)) / (24*7);
        NSInteger day = (((timeInHour % (24*365)) % (24*30)) % (24*7)) / 24;
        NSInteger hour = (((timeInHour % (24*365)) % (24*30)) % (24*7)) % 24;
        
        NSString *yearString = year > 0 ? [NSString stringWithFormat:@"%ld年", (long)year] : @"";
        NSString *monthString = month > 0 ? [NSString stringWithFormat:@"%ld月", (long)month] : @"";
        NSString *weekString = week > 0 ? [NSString stringWithFormat:@"%ld周", (long)week] : @"";
        NSString *dayString = day > 0 ? [NSString stringWithFormat:@"%ld天", (long)day] : @"";
        NSString *hourString = hour > 0 ? [NSString stringWithFormat:@"%ld小时", (long)hour] : @"";
        
        description = [NSString stringWithFormat:@"%@%@%@%@%@", yearString, monthString, weekString, dayString, hourString];
    }
    return description;
}



@end
