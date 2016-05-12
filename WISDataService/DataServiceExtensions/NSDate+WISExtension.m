//
//  NSDate+WISExtension.m
//  WisdriIS
//
//  Created by Jingwei Wu on 4/20/16.
//  Copyright © 2016 Wisdri. All rights reserved.
//

#import "NSDate+WISExtension.h"

@implementation NSDate (WISExtension)

+ (instancetype) dateFromDateString:(NSString *)dateString {
    NSDate *date = nil;
    if (dateString) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        date = [dateFormatter dateFromString:dateString];
    }
    return date;
}

+ (instancetype) dateFromDateTimeString:(NSString *)dateTimeString {
    NSDate *date = nil;
    if (dateTimeString) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        date = [dateFormatter dateFromString:dateTimeString];
    }
    return date;
}


-(NSString *) toDateTimeString {
    NSString* dateTimeString = @"";
    if (self) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        dateTimeString = [dateFormatter stringFromDate:self];
    }
    return dateTimeString;
}

-(NSString *) toDateStringWithSeparator:(NSString *)separator {
    NSString* dateTimeString = @"";
    if (self) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:[NSString stringWithFormat:@"yyyy%@MM%@dd",separator, separator]];
        dateTimeString = [dateFormatter stringFromDate:self];
    }
    return dateTimeString;
}

@end
