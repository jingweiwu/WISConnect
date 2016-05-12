//
//  WISCompany.h
//  WisdriIS
//
//  Created by Jingwei Wu on 5/2/16.
//  Copyright © 2016 Wisdri. All rights reserved.
//

#ifndef WISCompany_h
#define WISCompany_h

#import <Foundation/Foundation.h>

#endif /* WISCompany_h */

@interface WISCompany : NSObject <NSCopying, NSCoding>

@property (readwrite, strong) NSString *companyID;
@property (readwrite, strong) NSString *companyName;

- (instancetype)init; // __attribute__((unavailable("init method not available")));

- (instancetype)initWithCompanyID:(NSString *)companyID
                      companyName:(NSString *)companyName;

@end
