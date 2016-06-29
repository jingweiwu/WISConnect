//
//  WISUser.h
//  WISConnect
//
//  Created by Jingwei Wu on 2/21/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, Gender) {
    GenderMale = 1,
    GenderFemale = 2,
};

@class WISCompany, UIImage, WISFileInfo;

@interface WISUser : NSObject <NSCopying, NSCoding>

@property (readwrite, strong) NSString *userName;
@property (readwrite, strong) NSString *fullName;
@property (readwrite, strong) NSString *telephoneNumber;
@property (readwrite, strong) NSString *cellPhoneNumber;
@property (readwrite, strong) NSString *urgentPhoneNumber;
@property (readwrite, strong) NSString *roleCode;
@property (readwrite, strong) NSString *roleName;

@property (readwrite) Gender gender;
@property (readwrite, strong) NSString *title;
@property (readwrite, strong) NSDate *birthday;
@property (readwrite, strong) NSString *eMail;
@property (readwrite, strong) NSString *identityCardNumber;
@property (readwrite, strong) WISCompany *company;
@property (readwrite, strong) NSDate *lastUpatedTime;
@property (readwrite, strong) NSString *remark;

@property (readwrite, strong) UIImage *thumbnailPhoto;
@property (readwrite, strong) NSMutableDictionary<NSString *, WISFileInfo *> *imagesInfo;

- (instancetype)init; // __attribute__((unavailable("init method not available")));

- (instancetype)initWithUserName:(NSString *)userName
                            name:(NSString *)fullName
                 telephoneNumber:(NSString *)telephoneNumber
                 cellPhoneNumber:(NSString *)cellPhoneNumber
               urgentPhoneNumber:(NSString *)urgentPhoneNumber
                        roleCode:(NSString *)roleCode
                        roleName:(NSString *)roleName
                          gender:(Gender)gender
                           title:(NSString *)title
                        birthday:(NSDate *)birthday
                           eMail:(NSString *)eMail
              identityCardNumber:(NSString *)identityCardNumber
                         company:(WISCompany *)company
                 lastUpdatedTime:(NSDate *)lastUpdatedTime
                          remark:(NSString *)remark
                   andImagesInfo:(NSMutableDictionary<NSString *, WISFileInfo *> *)imagesInfo;

@end
