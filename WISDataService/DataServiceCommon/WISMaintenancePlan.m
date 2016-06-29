//
//  WISMaintenancePlan.m
//  WISConnect
//
//  Created by Jingwei Wu on 2/22/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#import "WISMaintenancePlan.h"
#import "WISFileInfo.h"

NSString *const planDescriptionEncodingKey = @"planDescription";
NSString *const estimateEndingTimeEncodingKey = @"estimateEndingTime";
NSString *const updatedTimeEncodingKey = @"updatedTime";
NSString *const participantsEncodingKey = @"participants";
NSString *const imagesInfoOfMaintenancePlanEncodingKey = @"imagesInfoOfMaintenancePlan";

@interface WISMaintenancePlan ()

@end

@implementation WISMaintenancePlan

- (instancetype)init {
    return [self initWithDescription:@""
                  estimateEndingTime:[NSDate date]
                         updatedTime:[NSDate date]
                        participants:[NSMutableArray array]
                       andImagesInfo:[NSMutableDictionary dictionary]];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _planDescription = (NSString *)[aDecoder decodeObjectForKey:planDescriptionEncodingKey];
        _estimatedEndingTime = (NSDate *)[aDecoder decodeObjectForKey:estimateEndingTimeEncodingKey];
        _updatedTime = (NSDate *)[aDecoder decodeObjectForKey:updatedTimeEncodingKey];
        _participants = (NSMutableArray<WISUser *> *)[aDecoder decodeObjectForKey:participantsEncodingKey];
        _imagesInfo = (NSMutableDictionary<NSString *, WISFileInfo *> *)[aDecoder decodeObjectForKey:imagesInfoOfMaintenancePlanEncodingKey];
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.planDescription forKey:planDescriptionEncodingKey];
    [aCoder encodeObject:self.estimatedEndingTime forKey:estimateEndingTimeEncodingKey];
    [aCoder encodeObject:self.updatedTime forKey:updatedTimeEncodingKey];
    [aCoder encodeObject:self.participants forKey:participantsEncodingKey];
    [aCoder encodeObject:self.imagesInfo forKey:imagesInfoOfMaintenancePlanEncodingKey];
}

- (instancetype)initWithDescription:(NSString *) description
                 estimateEndingTime:(NSDate *) estimatedEndingTime
                        updatedTime:(NSDate *) updatedTime
                       participants:(NSMutableArray<WISUser *> *) participants
                      andImagesInfo:(NSMutableDictionary<NSString *, WISFileInfo *> *)imagesInfo; {
    if(self = [super init]) {
        _planDescription = description;
        _estimatedEndingTime = estimatedEndingTime;
        _updatedTime = updatedTime;
        _participants = participants;
        _imagesInfo = [NSMutableDictionary dictionaryWithDictionary:imagesInfo];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    WISMaintenancePlan *maintenancePlan = [[[self class] allocWithZone:zone] initWithDescription:[self.planDescription copy]
                                                                              estimateEndingTime:[self.estimatedEndingTime copy]
                                                                                     updatedTime:[self.updatedTime copy]
                                                                                    participants:[self.participants mutableCopy]
                                                                                   andImagesInfo:[self.imagesInfo mutableCopy]];
    return maintenancePlan;
}


+ (BOOL) arraySortForwardWithLhs:(WISMaintenancePlan *)lhs rhs: (WISMaintenancePlan *)rhs {
    NSComparisonResult result = [lhs.updatedTime compare:rhs.updatedTime];
    if (result == NSOrderedAscending) {
        return YES;
    } else {
        return NO;
    }
}


+ (BOOL) arraySortBackwardWithLhs:(WISMaintenancePlan *)lhs rhs: (WISMaintenancePlan *)rhs {
    NSComparisonResult result = [lhs.updatedTime compare:rhs.updatedTime];
    if (result == NSOrderedDescending) {
        return YES;
    } else {
        return NO;
    }
}


+ (arrayForwardSorterWithResult) arrayForwardSorterWithResult {
    arrayForwardSorterWithResult sorter = ^(id lhsOriginal, id rhsOriginal) {
        WISMaintenancePlan *lhs = (WISMaintenancePlan *)lhsOriginal;
        WISMaintenancePlan *rhs = (WISMaintenancePlan *)rhsOriginal;
        
        return [lhs.updatedTime compare:rhs.updatedTime];
    };
    return sorter;
}


+ (arrayForwardSorterWithResult) arrayBackwardSorterWithResult {
    arrayForwardSorterWithResult sorter = ^(id lhsOriginal, id rhsOriginal) {
        WISMaintenancePlan *lhs = (WISMaintenancePlan *)lhsOriginal;
        WISMaintenancePlan *rhs = (WISMaintenancePlan *)rhsOriginal;
        
        return [rhs.updatedTime compare:lhs.updatedTime];
    };
    return sorter;
}


@end
