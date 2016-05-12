//
//  WISUser.m
//  WISConnect
//
//  Created by Jingwei Wu on 2/21/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WISUser.h"
#import "WISCompany.h"
#import "WISFileInfo.h"

NSString *const userNameEncodingKey = @"userName";
NSString *const fullNameEncodingKey = @"fullName";
NSString *const telephoneNumberEncodingKey = @"telephone";
NSString *const cellPhoneNumberEncodingKey = @"cellPhone";
NSString *const urgentPhoneNumberencodingKey = @"urgentPhone";
NSString *const roleCodeEncodingKey = @"roleCode";
NSString *const roleNameEncodingKey = @"roleName";

NSString *const genderEncodingKey = @"gender";
NSString *const titleEncodingKey = @"title";
NSString *const birthdayEncodingKey = @"birthday";
NSString *const eMailEncodingKey = @"eMail";
NSString *const identityCardNumberEncodingKey = @"identityCardNumber";
NSString *const userCompanyEncodingKey = @"userCompany";
NSString *const userInfoLastUpdatedTimeEncodingKey = @"userInfoLastUpdatedTime";
NSString *const userRemarkEncodingKey = @"userRemark";

NSString *const userthumbnailPhotoEncodingKey = @"userthumbnailPhoto";
NSString *const userImagesInfoEncodingKey = @"userImagesInfo";

@interface WISUser ()

@end

@implementation WISUser

- (instancetype)init {
    return [self initWithUserName:@""
                             name:@""
                  telephoneNumber:@""
                  cellPhoneNumber:@""
                urgentPhoneNumber:@""
                         roleCode:@""
                         roleName:@""
                           gender:GenderMale
                            title:@""
                         birthday:[NSDate date]
                            eMail:@""
               identityCardNumber:@""
                          company:[[WISCompany alloc]init]
                  lastUpdatedTime:[NSDate date]
                           remark:@""
                    andImagesInfo:[NSMutableDictionary dictionary]];
}

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
                   andImagesInfo:(NSMutableDictionary<NSString *, WISFileInfo *> *)imagesInfo {
    
    if (self = [super init]) {
        _userName = userName;
        _fullName = fullName;
        _telephoneNumber = telephoneNumber;
        _cellPhoneNumber = cellPhoneNumber;
        _urgentPhoneNumber = urgentPhoneNumber;
        _roleCode = roleCode;
        _roleName = roleName;
        
        _gender = gender;
        _title = title;
        _birthday = birthday;
        _eMail = eMail;
        _identityCardNumber = identityCardNumber;
        _company = company;
        _lastUpatedTime = lastUpdatedTime;
        _remark = remark;
        
        _thumbnailPhoto = [[UIImage alloc] init];
        _imagesInfo = imagesInfo;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _userName = (NSString *)[aDecoder decodeObjectForKey:userNameEncodingKey];
        _fullName = (NSString *)[aDecoder decodeObjectForKey:fullNameEncodingKey];
        _telephoneNumber = (NSString *)[aDecoder decodeObjectForKey:telephoneNumberEncodingKey];
        _cellPhoneNumber = (NSString *)[aDecoder decodeObjectForKey:cellPhoneNumberEncodingKey];
        _urgentPhoneNumber = (NSString *)[aDecoder decodeObjectForKey:urgentPhoneNumberencodingKey];
        _roleCode = (NSString *)[aDecoder decodeObjectForKey:roleCodeEncodingKey];
        _roleName = (NSString *)[aDecoder decodeObjectForKey:roleNameEncodingKey];
        
        _gender = (Gender)[aDecoder decodeIntegerForKey:genderEncodingKey];
        _title = (NSString *)[aDecoder decodeObjectForKey:titleEncodingKey];
        _birthday = (NSDate *)[aDecoder decodeObjectForKey:birthdayEncodingKey];
        _eMail = (NSString *)[aDecoder decodeObjectForKey:eMailEncodingKey];
        _identityCardNumber = (NSString *)[aDecoder decodeObjectForKey:identityCardNumberEncodingKey];
        _company = (WISCompany *)[aDecoder decodeObjectForKey:userCompanyEncodingKey];
        _lastUpatedTime = (NSDate *)[aDecoder decodeObjectForKey:userInfoLastUpdatedTimeEncodingKey];
        _remark = (NSString *)[aDecoder decodeObjectForKey:userRemarkEncodingKey];
        
        _thumbnailPhoto = (UIImage *)[aDecoder decodeObjectForKey:userthumbnailPhotoEncodingKey];
        _imagesInfo = [[NSMutableDictionary alloc]initWithDictionary:(NSDictionary *)[aDecoder decodeObjectForKey:userImagesInfoEncodingKey]];
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.userName forKey:userNameEncodingKey];
    [aCoder encodeObject:self.fullName forKey:fullNameEncodingKey];
    [aCoder encodeObject:self.telephoneNumber forKey:telephoneNumberEncodingKey];
    [aCoder encodeObject:self.cellPhoneNumber forKey:cellPhoneNumberEncodingKey];
    [aCoder encodeObject:self.urgentPhoneNumber forKey:urgentPhoneNumberencodingKey];
    [aCoder encodeObject:self.roleCode forKey:roleCodeEncodingKey];
    [aCoder encodeObject:self.roleName forKey:roleNameEncodingKey];
    
    [aCoder encodeInteger:(NSInteger)self.gender forKey:genderEncodingKey];
    [aCoder encodeObject:self.title forKey:titleEncodingKey];
    [aCoder encodeObject:self.birthday forKey:birthdayEncodingKey];
    [aCoder encodeObject:self.eMail forKey:eMailEncodingKey];
    [aCoder encodeObject:self.identityCardNumber forKey:identityCardNumberEncodingKey];
    [aCoder encodeObject:self.company forKey:userCompanyEncodingKey];
    [aCoder encodeObject:self.lastUpatedTime forKey:userInfoLastUpdatedTimeEncodingKey];
    [aCoder encodeObject:self.remark forKey:userRemarkEncodingKey];
    
    [aCoder encodeObject:self.thumbnailPhoto forKey:userthumbnailPhotoEncodingKey];
    [aCoder encodeObject:self.imagesInfo forKey:userImagesInfoEncodingKey];
}

- (id) copyWithZone:(NSZone *)zone {
    WISUser * user = [[[self class] allocWithZone:zone] initWithUserName:[self.userName copy]
                                                                    name:[self.fullName copy]
                                                         telephoneNumber:[self.telephoneNumber copy]
                                                         cellPhoneNumber:[self.cellPhoneNumber copy]
                                                       urgentPhoneNumber:[self.urgentPhoneNumber copy]
                                                                roleCode:[self.roleCode copy]
                                                                roleName:[self.roleName copy]
                                                                  gender:self.gender
                                                                   title:[self.title copy]
                                                                birthday:[self.birthday copy]
                                                                   eMail:[self.eMail copy]
                                                      identityCardNumber:[self.identityCardNumber copy]
                                                                 company:[self.company copy]
                                                         lastUpdatedTime:[self.lastUpatedTime copy]
                                                                  remark:[self.remark copy]
                                                           andImagesInfo:[self.imagesInfo mutableCopy]];
    
    user.thumbnailPhoto = [self.thumbnailPhoto copy];
    return user;
}


@end
