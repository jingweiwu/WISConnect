//
//  NSError+WISExtension.m
//  WISConnect
//
//  Created by Jingwei Wu on 3/10/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#import "NSError+WISExtension.h"

NSString * const ErrorTaskIDKey = @"ErrorTaskIDKey";
NSString * const ErrorOperationTypeKey = @"ErrorOperationTypeKey";

@implementation NSError (WISExtension)

- (NSString *) taskIDOfOperation {
    NSString *taskID = [self.userInfo valueForKey:ErrorTaskIDKey];
    
    if (taskID) {
        return taskID;
    } else {
        return @"";
    }
}

- (NSInteger) operationType {
    NSNumber *operationTypeNumber = [self.userInfo valueForKey:ErrorOperationTypeKey];
    
    if (operationTypeNumber) {
        return [operationTypeNumber integerValue];
    } else {
        return 0;
    }
}

@end
