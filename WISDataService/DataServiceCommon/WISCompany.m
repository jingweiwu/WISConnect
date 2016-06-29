//
//  WISCompany.m
//  WisdriIS
//
//  Created by Jingwei Wu on 5/2/16.
//  Copyright © 2016 Wisdri. All rights reserved.
//

#import "WISCompany.h"

NSString *const companyIDEncodingKey = @"companyID";
NSString *const companyNameEncodingKey = @"companyName";

@interface WISCompany()

@end


@implementation WISCompany


- (instancetype)init {
    return [self initWithCompanyID:@"" companyName:@""];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _companyID = (NSString *)[aDecoder decodeObjectForKey:companyIDEncodingKey];
        _companyName = (NSString *)[aDecoder decodeObjectForKey:companyNameEncodingKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.companyID forKey:companyIDEncodingKey];
    [aCoder encodeObject:self.companyName forKey:companyNameEncodingKey];
}


- (instancetype)initWithCompanyID:(NSString *)companyID
                      companyName:(NSString *)companyName {
    
    if (self = [super init]) {
        _companyID = companyID;
        _companyName = companyName;
    }
    return self;
}

- (id) copyWithZone:(NSZone *)zone {
    WISCompany * company = [[[self class] allocWithZone:zone] initWithCompanyID:[self.companyID copy] companyName:[self.companyName copy]];
    return company;
}


@end
