//
//  WISMaintenanceTaskMarking.m
//  WISConnect
//
//  Created by Jingwei Wu on 3/10/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#import "WISMaintenanceTaskRating.h"

NSString *const totalScoreEncodingID = @"totalScore";
NSString *const attitudeScoreEncodingID = @"attitudeScore";
NSString *const responseScoreEncodingID = @"responseScore";
NSString *const qualityScoreEncodingID = @"qualityScore";
NSString *const additionalRemarkEncodingID = @"additionalRemark";

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


- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _totalScore = (NSInteger)[aDecoder decodeIntegerForKey:totalScoreEncodingID];
        _attitudeScore = (NSInteger)[aDecoder decodeIntegerForKey:attitudeScoreEncodingID];
        _responseScore = (NSInteger)[aDecoder decodeIntegerForKey:responseScoreEncodingID];
        _qualityScore = (NSInteger)[aDecoder decodeIntegerForKey:qualityScoreEncodingID];
        _additionalRemark = (NSString *)[aDecoder decodeObjectForKey:additionalRemarkEncodingID];
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:_totalScore forKey:totalScoreEncodingID];
    [aCoder encodeInteger:_attitudeScore forKey:attitudeScoreEncodingID];
    [aCoder encodeInteger:_responseScore forKey:responseScoreEncodingID];
    [aCoder encodeInteger:_qualityScore forKey:qualityScoreEncodingID];
    [aCoder encodeObject:_additionalRemark forKey:additionalRemarkEncodingID];
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
