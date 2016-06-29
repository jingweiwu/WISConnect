//
//  NSDate+WISExtension.h
//  WisdriIS
//
//  Created by Jingwei Wu on 4/20/16.
//  Copyright © 2016 Wisdri. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (WISExtension)

+ (instancetype) dateFromDateString:(NSString *)dateString;

+ (instancetype) dateFromDateTimeString:(NSString *)dateTimeString;

- (NSString *) toDateTimeString;

- (NSString *) toDateStringWithSeparator:(NSString *)separator;

@end