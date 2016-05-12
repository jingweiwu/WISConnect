//
//  WISMaintenanceTaskMarking.h
//  WISConnect
//
//  Created by Jingwei Wu on 3/10/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WISMaintenanceTaskRating : NSObject

@property (readwrite) NSInteger totalScore;
@property (readwrite) NSInteger attitudeScore;
@property (readwrite) NSInteger responseScore;
@property (readwrite) NSInteger qualityScore;
@property (readwrite, strong) NSString *additionalRemark;

- (instancetype)init; // __attribute__((unavailable("init method not available")));

- (instancetype)initWithTotalScore:(NSInteger) totalScore
                     attitudeScore:(NSInteger) attitudeScore
                        responseScore:(NSInteger) responseScore
                         qualityScore:(NSInteger) qualityScore
                  andAdditionalRemark:(NSString *) additionalRemark;

@end
