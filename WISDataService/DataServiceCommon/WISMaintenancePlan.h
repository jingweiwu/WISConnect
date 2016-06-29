//
//  WISMaintenancePlan.h
//  WISConnect
//
//  Created by Jingwei Wu on 2/22/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WISSorter.h"

@class WISFileInfo, WISUser;

@interface WISMaintenancePlan : NSObject <NSCopying, NSCoding>

@property (readwrite, strong) NSString *planDescription;
@property (readwrite, strong) NSDate *estimatedEndingTime;
@property (readwrite, strong) NSDate *updatedTime;
@property (readwrite, strong) NSMutableArray<WISUser *> *participants;
@property (readwrite, strong) NSMutableDictionary<NSString *, WISFileInfo *> *imagesInfo;

- (instancetype)init; // __attribute__((unavailable("init method not available")));

- (instancetype)initWithDescription:(NSString *) description
                 estimateEndingTime:(NSDate *) estimatedEndingTime
                        updatedTime:(NSDate *) updatedTime
                       participants:(NSMutableArray<WISUser *> *) participants
                      andImagesInfo:(NSMutableDictionary<NSString *, WISFileInfo *> *)imagesInfo;

+ (BOOL) arraySortForwardWithLhs:(WISMaintenancePlan *)lhs rhs: (WISMaintenancePlan *)rhs;
+ (BOOL) arraySortBackwardWithLhs:(WISMaintenancePlan *)lhs rhs: (WISMaintenancePlan *)rhs;

+ (arrayForwardSorterWithResult) arrayForwardSorterWithResult;
+ (arrayForwardSorterWithResult) arrayBackwardSorterWithResult;

@end
