//
//  NSError+WISExtension.h
//  WISConnect
//
//  Created by Jingwei Wu on 3/10/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * const ErrorTaskIDKey;
FOUNDATION_EXPORT NSString * const ErrorOperationTypeKey;

@interface NSError (WISExtension)

- (NSString *) taskIDOfOperation;
- (NSInteger) operationType;

@end
