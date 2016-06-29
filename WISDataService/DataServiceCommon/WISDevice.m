//
//  WISDevice.m
//  WisdriIS
//
//  Created by Jingwei Wu on 4/20/16.
//  Copyright © 2016 Wisdri. All rights reserved.
//

#import "WISDevice.h"

///Encoding Keys
NSString *const deviceIDEncodingKey = @"device";
NSString *const deviceNameEncodingKey = @"deviceName";
NSString *const deviceCodeEncodingKey = @"deviceCode";
NSString *const deviceTypeEncodingKey = @"deviceType";
NSString *const deviceCompanyEncodingKey = @"deviceCompany";
NSString *const processSegmentEncodingKey = @"processSegment";
NSString *const putIntoServiceTimeEncodingKey = @"putIntoServiceTime";
NSString *const remarkEncodingKey = @"remark";

@interface WISDevice ()

@end

@implementation WISDevice

- (instancetype)init {
    return [self initWithDeviceID:@""
                       deviceName:@""
                       deviceCode:@""
                       deviceType:[[WISDeviceType alloc]init]
                          company:@""
                   processSegment:@""
               putIntoServiceTime:[NSDate date]
                        andRemark:@""];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _deviceID = (NSString *)[aDecoder decodeObjectForKey:deviceIDEncodingKey];
        _deviceName = (NSString *)[aDecoder decodeObjectForKey:deviceNameEncodingKey];
        _deviceCode = (NSString *)[aDecoder decodeObjectForKey:deviceCodeEncodingKey];
        _deviceType = (WISDeviceType *)[aDecoder decodeObjectForKey:deviceTypeEncodingKey];
        _company = (NSString *)[aDecoder decodeObjectForKey:deviceCompanyEncodingKey];
        _processSegment = (NSString *)[aDecoder decodeObjectForKey:processSegmentEncodingKey];
        _putIntoServiceTime = (NSDate *)[aDecoder decodeObjectForKey:putIntoServiceTimeEncodingKey];
        _remark = (NSString *)[aDecoder decodeObjectForKey:remarkEncodingKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.deviceID forKey:deviceIDEncodingKey];
    [aCoder encodeObject:self.deviceName forKey:deviceNameEncodingKey];
    [aCoder encodeObject:self.deviceCode forKey:deviceCodeEncodingKey];
    [aCoder encodeObject:self.deviceType forKey:deviceTypeEncodingKey];
    [aCoder encodeObject:self.company forKey:deviceCompanyEncodingKey];
    [aCoder encodeObject:self.processSegment forKey:processSegmentEncodingKey];
    [aCoder encodeObject:self.putIntoServiceTime forKey:putIntoServiceTimeEncodingKey];
    [aCoder encodeObject:self.remark forKey:remarkEncodingKey];
}


- (instancetype)initWithDeviceID:(NSString *)deviceID
                      deviceName:(NSString *)deviceName
                      deviceCode:(NSString *)deviceCode
                      deviceType:(WISDeviceType *)deviceType
                         company:(NSString *)company
                  processSegment:(NSString *)processSegment
              putIntoServiceTime:(NSDate *)putIntoServiceTime
                       andRemark:(NSString *)remark {
    
    if (self = [super init]) {
        _deviceID = deviceID;
        _deviceName = deviceName;
        _deviceCode = deviceCode;
        _deviceType = deviceType;
        _company = company;
        _processSegment = processSegment;
        _putIntoServiceTime = putIntoServiceTime;
        _remark = remark;
    }
    return self;
}



- (id) copyWithZone:(NSZone *)zone {
    WISDevice * device = [[[self class] allocWithZone:zone] initWithDeviceID:[self.deviceID copy]
                                                                  deviceName:[self.deviceName copy]
                                                                  deviceCode:[self.deviceCode copy]
                                                                  deviceType:[self.deviceType copy]
                                                                     company:[self.company copy]
                                                              processSegment:[self.processSegment copy]
                                                          putIntoServiceTime:[self.putIntoServiceTime copy]
                                                                   andRemark:[self.remark copy]];
    return device;
}

@end

