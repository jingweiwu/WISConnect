//
//  WISMaitenanceTaskState.h
//  WisdriIS
//
//  Created by Jingwei Wu on 5/5/16.
//  Copyright © 2016 Wisdri. All rights reserved.
//

#ifndef WISMaintenanceTaskState_h
#define WISMaintenanceTaskState_h

#import <Foundation/Foundation.h>
#import "WISSorter.h"

#endif /* WISMaintenanceTaskState_h */

@class WISUser;
@interface WISMaintenanceTaskState : NSObject <NSCopying, NSCoding>

@property (readwrite, strong) NSString *state;
@property (readwrite, strong) NSDate *startTime;
@property (readwrite, strong) NSDate *endTime;
@property (readwrite, strong) WISUser *personInCharge;

- (instancetype)init; // __attribute__((unavailable("init method not available")));

- (instancetype)initWithState:(NSString *)state
                    startTime:(NSDate *)startTime
                      endTime:(NSDate *)endTime
               personInCharge:(WISUser *)personInCharge;

+ (BOOL) arraySortForwardByEndTimeWithLhs:(WISMaintenanceTaskState *)lhs rhs: (WISMaintenanceTaskState *)rhs;
+ (BOOL) arraySortBackwardByEndTimeWithLhs:(WISMaintenanceTaskState *)lhs rhs: (WISMaintenanceTaskState *)rhs;

+ (arrayForwardSorterWithResult) arrayForwardSorterWithResult;
+ (arrayForwardSorterWithResult) arrayBackwardSorterWithResult;

@end
