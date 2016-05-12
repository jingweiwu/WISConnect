//
//  WISInspectionTask.m
//  WisdriIS
//
//  Created by Jingwei Wu on 4/20/16.
//  Copyright © 2016 Wisdri. All rights reserved.
//

#import "WISInspectionTask.h"

/// Encoding Keys
NSString *const deviceEncodingKey = @"device";
NSString *const lastInspectionFinishedTimePlusCycleTimeEncodingKey = @"lastInspectionFinishedTimePlusCycleTime";
NSString *const inspectionFinishedTimeEncodingKey = @"inspectionFinishedTime";
NSString *const inspectionResultEncodingKey = @"inspectionResult";
NSString *const imagesInfoOfInspectionTaskEncodingKey = @"imagesInfoOfInspectionTask";
NSString *const inspectionResultDescriptionEncodingKey = @"inspectionResultDescription";

@interface WISInspectionTask ()

@end

@implementation WISInspectionTask

- (instancetype)init {
    return [self initWithDevice:[[WISDevice alloc]init] lastInspectionFinishedTimePlusCycleTime:[NSDate date]
         inspectionFinishedTime:[NSDate date]
               inspectionResult:DeviceNormal
                     imagesInfo:[NSMutableDictionary dictionary]
       andInspectionResultDescription:@""];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _device = (WISDevice *)[aDecoder decodeObjectForKey:deviceEncodingKey];
        _lastInspectionFinishedTimePlusCycleTime = (NSDate *)[aDecoder decodeObjectForKey:lastInspectionFinishedTimePlusCycleTimeEncodingKey];
        _inspectionFinishedTime = (NSDate *)[aDecoder decodeObjectForKey:inspectionFinishedTimeEncodingKey];
        _inspectionResult = (InspectionResult)[aDecoder decodeIntegerForKey:inspectionResultEncodingKey];
        _imagesInfo = [[NSMutableDictionary alloc]initWithDictionary: (NSDictionary *)[aDecoder decodeObjectForKey:imagesInfoOfInspectionTaskEncodingKey]];
        _inspectionResultDescription = [aDecoder decodeObjectForKey:inspectionResultDescriptionEncodingKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.device forKey:deviceEncodingKey];
    [aCoder encodeObject:self.lastInspectionFinishedTimePlusCycleTime forKey:lastInspectionFinishedTimePlusCycleTimeEncodingKey];
    [aCoder encodeObject:self.inspectionFinishedTime forKey:inspectionFinishedTimeEncodingKey];
    [aCoder encodeInteger:(NSInteger)self.inspectionResult forKey:inspectionResultEncodingKey];
    [aCoder encodeObject:self.imagesInfo forKey:imagesInfoOfInspectionTaskEncodingKey];
    [aCoder encodeObject:self.inspectionResultDescription forKey:inspectionResultDescriptionEncodingKey];
}

- (instancetype)initWithDevice:(WISDevice *)device lastInspectionFinishedTimePlusCycleTime:(NSDate *)lastInspectionFinishedTimePlusCycleTime
        inspectionFinishedTime:(NSDate *)inspectionFinishedTime
              inspectionResult:(InspectionResult)inspectionResult
                    imagesInfo:(NSMutableDictionary<NSString *, WISFileInfo *> *)imagesInfo
andInspectionResultDescription:(NSString *)inspectionResultDescription {
    
    if (self = [super init]) {
        _device = device;
        _lastInspectionFinishedTimePlusCycleTime = lastInspectionFinishedTimePlusCycleTime;
        _inspectionFinishedTime = inspectionFinishedTime;
        _inspectionResult = inspectionResult;
        _imagesInfo = imagesInfo;
        _inspectionResultDescription = inspectionResultDescription;
    }
    return self;
}


- (id) copyWithZone:(NSZone *)zone {
    WISInspectionTask * task = [[[self class] allocWithZone:zone] initWithDevice:[self.device copy]
                                         lastInspectionFinishedTimePlusCycleTime:[self.lastInspectionFinishedTimePlusCycleTime copy]
                                                          inspectionFinishedTime:[self.inspectionFinishedTime copy]                                                                inspectionResult:self.inspectionResult
                                                                      imagesInfo:[self.imagesInfo mutableCopy]
                                                  andInspectionResultDescription:[self.inspectionResultDescription copy]];
    return task;
}


#pragma mark - computed properties
- (NSDate *) inspectionDeadLine {
    NSDate *deadLine = nil;
    if (self.lastInspectionFinishedTimePlusCycleTime) {
        NSTimeInterval acceptDelayTimeInSecond = self.device.deviceType.acceptableDelayTime * 3600.0f;
        deadLine = [NSDate dateWithTimeInterval:acceptDelayTimeInSecond sinceDate:self.lastInspectionFinishedTimePlusCycleTime];
    }
    return deadLine;
}

- (NSDate *) lastInspectionFinishedTime {
    NSDate *lastInspectionFinishedT = nil;
    if (self.lastInspectionFinishedTimePlusCycleTime) {
        NSTimeInterval inspectionCyclInSecond = - self.device.deviceType.inspectionCycle * 3600.0f;
        lastInspectionFinishedT = [NSDate dateWithTimeInterval:inspectionCyclInSecond sinceDate:self.lastInspectionFinishedTimePlusCycleTime];
    }
    return lastInspectionFinishedT;
}

- (void) appendImagsInfoWithFileName:(NSString *)name andImageInfo:(WISFileInfo *)info {
    NSString *fileName = [[NSString alloc]initWithFormat:@"%@", name];
    [self.imagesInfo setValue:info forKey:fileName];
    self.imagesInfo = self.imagesInfo;
}

- (void) appendImagesInfo:(id)imagesInformation {
    NSArray *infos = [[NSArray alloc] initWithArray:(NSArray *)imagesInformation];
    
    if (infos.count > 0) {
        for (WISFileInfo *info in infos) {
            [self.imagesInfo setObject:info forKey:info.fileName];
        }
    }
    self.imagesInfo = self.imagesInfo;
}



@end
