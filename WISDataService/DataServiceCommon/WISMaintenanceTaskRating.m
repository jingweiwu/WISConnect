//
//  WISMaintenanceTaskMarking.m
//  WISConnect
//
//  Created by Jingwei Wu on 3/10/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#import "WISMaintenanceTaskRating.h"

@implementation WISMaintenanceTaskRating

- (instancetype)init {
    return [self initWithTotalScore:0 attitudeScore:0 responseScore:0 qualityScore:0 andAdditionalRemark:@""];
}

- (instancetype)initWithTotalScore:(NSInteger)totalScore
                     attitudeScore:(NSInteger)attitudeScore
                     responseScore:(NSInteger)responseScore
                      qualityScore:(NSInteger)qualityScore
               andAdditionalRemark:(NSString *)additionalRemark {
    
    if (self = [super init]) {
        _totalScore = totalScore;
        _attitudeScore = attitudeScore;
        _responseScore = responseScore;
        _qualityScore = qualityScore;
        _additionalRemark = additionalRemark;
    }
    return self;
}

- (id) copyWithZone:(NSZone *)zone {
    WISMaintenanceTaskRating * rating = [[[self class] allocWithZone:zone] initWithTotalScore:self.totalScore
                                                                                attitudeScore:self.attitudeScore
                                                                                responseScore:self.responseScore
                                                                                 qualityScore:self.qualityScore
                                                                          andAdditionalRemark:[self.additionalRemark copy]];
    
    return rating;
}



@end
