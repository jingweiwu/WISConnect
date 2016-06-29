//
//  WISDataManager.m
//  WISConnect
//
//  Created by Jingwei Wu on 2/25/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#import "WISDataManager.h"



NSString *const WISErrorDomain = @"WISErrorDomain";
//NSDictionary *const WISRoleCodeDictionary = @{@"CTO":@"技术主管",
//                                                     @"FactoryManager":@"厂级负责人",
//                                                     @"FactoryMinister":@"前方部长",
//                                                     @"DutyManager":@"值班经理",
//                                                     @"Engineer":@"工程师",
//                                                     @"Operator":@"生产人员",
//                                                     @"Electrician":@"电工",};


NSString *const defaultUserInfoArchivingStorageDirectoryKey = @"defaultUserInfoArchivingStorageDirectory";
NSString *const preDefinedUserInfoArchivingFolderName = @"UserInfoArchivingCache";

NSString *const currentUserFileName = @"SignedInUserInfo.userInfoArchive";
NSString *const networkRequestTokenFileName = @"networkRequestToken.userInfoArchive";

@interface WISDataManager ()

@property (weak) WISNetworkService *networkService;

@property (readwrite, strong) WISUser *currentUser;
@property (readwrite, strong) NSString *networkRequestToken;

/// 角色对照表
@property (readwrite,strong) NSArray<NSString *> const *roleCodes;
@property (readwrite,strong) NSDictionary<NSString *, NSString *> const *roleNameDictionary;

/// 登录时用
@property (readwrite, strong) NSString *temporaryUserName;
@property (readwrite, strong) NSString *temporaryRequestToken;

@property (readwrite, strong) NSMutableDictionary <NSString*, WISUser*> *users;
/// @brief key是WISMainenanceTask类中的TaskID属性
@property (readwrite, strong) NSMutableDictionary <NSString*, WISMaintenanceTask*> *maintenanceTasks;

 @property (readwrite, strong, atomic) NSMutableDictionary <NSString *, WISInspectionTask *> *inspectionTasks;
 @property (readwrite, strong) NSMutableDictionary <NSString *, WISInspectionTask *> *overDueInspectionTasks;

 @property (readwrite, strong) NSMutableDictionary <NSString *, WISDeviceType *> *deviceTypes;

@property (readwrite, strong) NSMutableDictionary <NSString *, NSString *> *processSegments;


/// 以下method暂不开放给使用者
///
// 保存图片 (本地／服务器)
- (NSURLSessionUploadTask *) storeImageWithImages:(NSDictionary<NSString *, UIImage *> *)images
      uploadProgressIndicator:(WISSystemDataTransmissionProgressIndicator)progress
            completionHandler:(WISSystemOperationHandler)handler;



// 获取图片(本地／服务器)
- (NSURLSessionDownloadTask *) obtainImageWithImagesInfo:(NSDictionary<NSString *, WISFileInfo *> *)imagesInfo
         downloadProgressIndicator:(WISSystemDataTransmissionProgressIndicator)progress
                 completionHandler:(WISSystemOperationHandler)handler;


// 上传图片 (至服务器)
//- (NSURLSessionUploadTask *) uploadImageWithImages:(NSDictionary<NSString *, UIImage *> *)images
//             progressIndicator:(WISSystemDataTransmissionProgressIndicator)progress
//             completionHandler:(WISSystemDataTransmissionHandler)handler;


// 下载图片 (自服务器)
- (NSURLSessionDownloadTask *) downloadImageWithImageLocations:(NSArray<NSString *> *)imagesRemoteLocation
                                             progressIndicator:(WISSystemDataTransmissionProgressIndicator)progress
                                             completionHandler:(WISSystemDataTransmissionHandler)handler;


@end


@implementation WISDataManager

#pragma mark - Initializer
+ (instancetype) sharedInstance {
    static WISDataManager *sharedDataManagerInstance;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken,^(void) {
        sharedDataManagerInstance = [[self alloc] init];
    });
    
    return sharedDataManagerInstance;
}


- (instancetype) init {
    if (self = [super init]) {
        _networkService = [WISNetworkService sharedInstance];
        
        _currentUser = [[WISUser alloc] init];
        
        _networkRequestToken = nil;
        
        _roleCodes = @[@"CTO", @"FactoryManager", @"FactoryMinister", @"DutyManager", @"Engineer", @"Operator", @"Electrician",];
        _roleNameDictionary =  @{_roleCodes[TechManager]:@"技术主管",
                                 _roleCodes[FactoryManager]:@"厂级负责人",
                                 _roleCodes[FieldManager]:@"前方部长",
                                 _roleCodes[DutyManager]:@"值班经理",
                                 _roleCodes[Engineer]:@"工程师",
                                 _roleCodes[Operator]:@"生产人员",
                                 _roleCodes[Technician]:@"电工",};
        
        _temporaryUserName = nil;
        _temporaryRequestToken = nil;

        _users = [NSMutableDictionary<NSString*, WISUser*> dictionary];
        _maintenanceTasks = [NSMutableDictionary<NSString*, WISMaintenanceTask*> dictionary];
        _processSegments = [NSMutableDictionary<NSString*, NSString*> dictionary];
        
        _inspectionTasks = [NSMutableDictionary<NSString *, WISInspectionTask *> dictionary];
        _overDueInspectionTasks = [NSMutableDictionary<NSString *, WISInspectionTask *> dictionary];
        _deviceTypes = [NSMutableDictionary<NSString *, WISDeviceType *> dictionary];
        
        // _imageStore = [WISLocalDocumentImageStore sharedInstance];
        
        [self.networkService setNetworkReachabilityStatusChangeHandler:^(NSInteger statusAsInteger) {
            NSNumber *statusNumber = [NSNumber numberWithInteger:statusAsInteger];
            [[NSNotificationCenter defaultCenter] postNotificationName:WISNetworkStatusChangedNotification object:statusNumber];
            if ([self.networkingDelegate respondsToSelector:@selector(networkStatusChangedTo:)]) {
                [self.networkingDelegate networkStatusChangedTo:statusAsInteger];
            }
        }];

        [self.networkService startNetworkingReachabilityStatusMonitoring];
    }
    return self;
}

- (WISNetworkReachabilityStatus)networkReachabilityStatus {
    return (WISNetworkReachabilityStatus)[self.networkService networkReachabilityStatusAsInteger];
}


#pragma mark - SignIn Operation

- (NSURLSessionDataTask *) signInWithUserName:(NSString *)userName
                                  andPassword:(NSString *)password
                            completionHandler:(WISSystemSignInHandler)handler {
    
    NSDictionary * signInParams = nil;
    NSURLSessionDataTask *dataTask = nil;
    
    if ([userName isEqual: @""] || userName == nil || [password isEqual: @""] || password == nil) {
        NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeWrongFuncParameters andCallbackError:nil];
        
        handler(FALSE, err);
        
        [[NSNotificationCenter defaultCenter]
         postNotificationName:WISSystemSignInFailedNotification
         object:(NSError *)err];
        
        if ([self.systemDataDelegate respondsToSelector:@selector(signInFailedWithError:)]) {
            [self.systemDataDelegate signInFailedWithError:err];
        }
        
    } else {
        
        self.temporaryUserName = userName;
        self.temporaryRequestToken = password;
        
        signInParams = [NSDictionary
         dictionaryWithObjectsAndKeys:userName, @"UserName", password, @"PassWord", nil];
        
        dataTask = [self.networkService dataRequestWithRequestType:SignIn
                                                            params:signInParams
                                                     andUriSetting:nil
         completionHandler:^(RequestType requestType, NSData *responsedData, NSError *error) {
             if (!responsedData) {
                 NSLog(@"SignIn 请求异常，原因: %@", @"返回的数据为空");
                 
                 NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeResponsedNULLData andCallbackError:error];
                 
                 handler(FALSE, err);
                 
                 [[NSNotificationCenter defaultCenter]
                  postNotificationName:WISSystemSignInFailedNotification
                  object:(NSError *)err];
                 
                 if ([self.systemDataDelegate respondsToSelector:@selector(signInFailedWithError:)]) {
                     [self.systemDataDelegate signInFailedWithError:err];
                 }
                 
             } else {
             
                 NSError *parseError;
                 NSDictionary *parsedData = nil;
                 
                 parsedData = [NSJSONSerialization JSONObjectWithData:responsedData
                                                              options:NSJSONReadingMutableContainers
                                                                error:&parseError];
                 
                 if (!parsedData || parseError) {
                     NSLog(@"SignIn 操作解析内容失败，原因: %@", parseError);
                     
                     NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeIncorrectResponsedDataFormat andCallbackError:parseError];
                     
                     handler(FALSE, err);
                     
                     [[NSNotificationCenter defaultCenter]
                      postNotificationName:WISSystemSignInFailedNotification
                      object:(NSError *)err];
                     
                     if ([self.systemDataDelegate respondsToSelector:@selector(signInFailedWithError:)]) {
                         [self.systemDataDelegate signInFailedWithError:err];
                     }
                     
                 } else {
                     
                     SignInResult result = (SignInResult)[parsedData[@"Result"] integerValue];
                     id parsedImageURL = nil;
                     NSError *err;
                     
                     switch (result) {
                         case SignInSuccessful:
                             _currentUser.userName = self.temporaryUserName;
                             _currentUser.fullName = (parsedData[@"UserInfo"])[@"Name"];
                             _currentUser.roleCode = (parsedData[@"UserInfo"])[@"RoleCode"];
                             _currentUser.roleName = (parsedData[@"UserInfo"])[@"RoleName"];
                             
                             parsedImageURL = (parsedData[@"UserInfo"])[@"ImageURL"];
                             _currentUser.imagesInfo = [NSMutableDictionary dictionary];
                             
                             if(parsedImageURL || ((NSNull *)parsedImageURL == [NSNull null])) {
                                 // do nothing
                             } else {
                                 /// 根据接口的不同构建不同的PHOTO LIST. 现在的接口是仅返回一个String
                                 NSString *imageURL = (NSString *)parsedImageURL;
                                 WISFileInfo *imageInfo = [WISDataManager produceFileInfoWithFileRemoteURL:imageURL];
                                 [_currentUser.imagesInfo addEntriesFromDictionary:[NSDictionary dictionaryWithObject:imageInfo forKey:imageInfo.fileName]];
                             }
                             
                             _networkRequestToken = self.temporaryRequestToken;
                             
                             //清空DataManager中的相关项
                             [_users removeAllObjects];
                             [_maintenanceTasks removeAllObjects];
                             [_processSegments removeAllObjects];
                             
                             // roleCodeDictionary is changed to immutable variable 2016.03.08
//                             if ([self.roleCodeDictionary valueForKey:_currentUser.roleCode]) {
//                                 self.roleCodeDictionary[_currentUser.roleCode] = (parsedData[@"UserInfo"])[@"RoleName"];
//                             } else {
//                                 [self.roleCodeDictionary setValue:(parsedData[@"UserInfo"])[@"RoleName"]
//                                                            forKey:_currentUser.roleCode];
//                             }
                             
                             [[NSNotificationCenter defaultCenter]
                              postNotificationName:WISSystemSignInSucceededNotification
                              object:self];
                             
                             if ([self.systemDataDelegate respondsToSelector:@selector(signInSucceeded)]) {
                                 [self.systemDataDelegate signInSucceeded];
                             }
                             handler(YES, nil);
                             break;
                             
                         case UserNotExist:
                             err = [self produceErrorObjectWithWISErrorCode:ErrorCodeSignInUserNotExist andCallbackError:nil];
                             
                             handler(FALSE, err);
                             
                             [[NSNotificationCenter defaultCenter]
                              postNotificationName:WISSystemSignInFailedNotification
                              object:(NSError *)err];
                             
                             if ([self.systemDataDelegate respondsToSelector:@selector(signInFailedWithError:)]) {
                                 [self.systemDataDelegate signInFailedWithError:err];
                             }
                             break;
                             
                         case WrongPassword:
                             err = [self produceErrorObjectWithWISErrorCode:ErrorCodeSignInWrongPassword andCallbackError:nil];
                             
                             handler(FALSE, err);
                             
                             [[NSNotificationCenter defaultCenter]
                              postNotificationName:WISSystemSignInFailedNotification
                              object:(NSData *)responsedData];
                             
                             if ([self.systemDataDelegate respondsToSelector:@selector(signInFailedWithError:)]) {
                                 [self.systemDataDelegate signInFailedWithError:err];
                             }
                             break;
                             
                         default:
                             break;
                     }
                 }
             }
         }];
    }
    
    return dataTask;
}

- (NSURLSessionDataTask *) changePasswordWithCurrentPassword:(NSString *)currentPassword
                                                 newPassword:(NSString *)newPassword
                                          compeletionHandler:(WISSystemOperationHandler)handler {
    
    NSURLSessionDataTask * dataTask = nil;
    NSDictionary *operationParams = nil;
    
    if ([self.currentUser.userName isEqual: @""] || self.currentUser.userName == nil
        || [self.networkRequestToken isEqual: @""] || self.networkRequestToken == nil) {
        
        NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeNoCurrentUserInfo andCallbackError:nil];
        handler(FALSE, err, @"", nil);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WISSystemchangingPasswordFailedNotification
                                                            object:(NSError *)err];
        if ([self.systemDataDelegate respondsToSelector:@selector(changePasswordFailedWithError:)]) {
            [self.systemDataDelegate changePasswordFailedWithError:err];
        }
        
    } else if(![self.networkRequestToken isEqual: currentPassword]) {
        
        NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeSignInWrongPassword andCallbackError:nil];
        handler(FALSE, err, @"", nil);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WISSystemchangingPasswordFailedNotification
                                                            object:(NSError *)err];
        if ([self.systemDataDelegate respondsToSelector:@selector(changePasswordFailedWithError:)]) {
            [self.systemDataDelegate changePasswordFailedWithError:err];
        }
    
    } else {
        
        NSDictionary *userParam = [NSDictionary dictionaryWithObjectsAndKeys:self.currentUser.userName, @"UserName",
                                 self.networkRequestToken, @"PassWord", nil];
        NSDictionary *passwordParam = [NSDictionary dictionaryWithObjectsAndKeys:currentPassword, @"OldPassword", newPassword, @"NewPassword", nil];
        
        operationParams = [NSDictionary dictionaryWithObjectsAndKeys:userParam, @"User", passwordParam, @"Password", nil];
        
        __block NSString *newNetworkRequestToken = newPassword;
        
        dataTask = [self.networkService dataRequestWithRequestType:ChangingPassword
                                                            params:operationParams
                                                     andUriSetting:nil
        completionHandler:^(RequestType requestType, NSData *responsedData, NSError *error) {
            if (!responsedData) {
                NSLog(@"Changing Password 请求异常，原因: %@", @"返回的数据为空");
                
                NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeResponsedNULLData andCallbackError:error];
                handler(FALSE, err, @"", nil);
                
                [[NSNotificationCenter defaultCenter] postNotificationName:WISSystemchangingPasswordFailedNotification
                                                                    object:(NSError *)err];
                if ([self.systemDataDelegate respondsToSelector:@selector(changePasswordFailedWithError:)]) {
                    [self.systemDataDelegate changePasswordFailedWithError:err];
                }
                
            } else {
                
                NSError *parseError;
                NSDictionary *parsedData = nil;
                
                parsedData = [NSJSONSerialization JSONObjectWithData:responsedData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&parseError];
                
                if (!parsedData || parseError) {
                    NSLog(@"Changing Password 操作解析内容失败，原因: %@", parseError);
                    
                    NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeIncorrectResponsedDataFormat andCallbackError:parseError];
                    handler(FALSE, err, @"", nil);
                    
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:WISSystemchangingPasswordFailedNotification
                     object:(NSError *)err];
                    
                    if ([self.systemDataDelegate respondsToSelector:@selector(changePasswordFailedWithError:)]) {
                        [self.systemDataDelegate changePasswordFailedWithError:err];
                    }
                    
                } else {
                    
                    RequestResult result = (RequestResult)[parsedData[@"Result"] integerValue];
                    NSError *err;
                    
                    NSMutableDictionary *updatedData = [NSMutableDictionary dictionary];
                    
                    switch (result) {
                        case RequestSuccessful:
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:WISSystemChangingPasswordSucceededNotification
                             object:updatedData];
                            
                            if ([self.systemDataDelegate respondsToSelector:@selector(changePasswordSucceeded)]) {
                                [self.systemDataDelegate changePasswordSucceeded];
                            }
                            handler(YES, nil, NSStringFromClass([updatedData class]), updatedData);
                            
                            self.networkRequestToken = newNetworkRequestToken;
                            
                            break;
                            
                        case RequestFailed:
                            err = [self produceErrorObjectWithWISErrorCode:ErrorCodeInvalidOperation andCallbackError:nil];
                            handler(FALSE, err, @"", nil);
                            
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:WISSystemchangingPasswordFailedNotification
                             object:(NSError *)err];
                            
                            if ([self.systemDataDelegate respondsToSelector:@selector(changePasswordFailedWithError:)]) {
                                [self.systemDataDelegate changePasswordFailedWithError:err];
                            }
                            break;
                            
                        default:
                            break;
                    }
                }
            }
        }];
    }
    
    return dataTask;
}

- (NSURLSessionDataTask *) updateProcessSegmentWithCompletionHandler:(WISMaintenanceTaskUpdateInfoHandler)handler {
    
    NSDictionary * updateParams = nil;
    NSURLSessionDataTask * dataTask = nil;
    
    if ([self.currentUser.userName isEqual: @""] || self.currentUser.userName == nil
            || [self.networkRequestToken isEqual: @""] || self.networkRequestToken == nil) {
        
        NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeNoCurrentUserInfo andCallbackError:nil];
        handler(FALSE, err, @"", nil);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateProcessSegmentSFailedNotification
                                                            object:(NSError *)err];
        if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateProcessSegmentFailedWithError:)]) {
            [self.maintenanceTaskOpDelegate updateProcessSegmentFailedWithError:err];
        }
        
    } else {
        
        updateParams = [NSDictionary dictionaryWithObjectsAndKeys:self.currentUser.userName, @"UserName",
                        self.networkRequestToken, @"PassWord", nil];
        
        dataTask = [self.networkService dataRequestWithRequestType:UpdateMaintenanceAreas
                                                            params:updateParams
                                                     andUriSetting:nil
        completionHandler:^(RequestType requestType, NSData *responsedData, NSError *error) {
            if (!responsedData) {
                NSLog(@"Update Process Segment 请求异常，原因: %@", @"返回的数据为空");
                
                NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeResponsedNULLData andCallbackError:error];
                handler(FALSE, err, @"", nil);
              
                [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateProcessSegmentSFailedNotification
                                                                    object:(NSError *)err];
                if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateProcessSegmentFailedWithError:)]) {
                    [self.maintenanceTaskOpDelegate updateProcessSegmentFailedWithError:err];
                }
              
            } else {
                
                NSError *parseError;
                NSDictionary *parsedData = nil;
                
                parsedData = [NSJSONSerialization JSONObjectWithData:responsedData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&parseError];
                
                if (!parsedData || parseError) {
                    NSLog(@"Update Process Segment 操作解析内容失败，原因: %@", parseError);
                    
                    NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeIncorrectResponsedDataFormat andCallbackError:parseError];
                    handler(FALSE, err, @"", nil);
                    
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:WISUpdateProcessSegmentSFailedNotification
                     object:(NSError *)err];
                    
                    if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateProcessSegmentFailedWithError:)]) {
                        [self.maintenanceTaskOpDelegate updateProcessSegmentFailedWithError:err];
                    }
                    
                } else {
                    
                    RequestResult result = (RequestResult)[parsedData[@"Result"] integerValue];
                    NSArray *segments = nil;
                    NSError *err;
                    
                    NSMutableDictionary *updatedData = [NSMutableDictionary dictionary];
                    
                    switch (result) {
                        case RequestSuccessful:
                            segments = parsedData[@"Areas"];
                            
                            if(segments.count > 0) {
                                for(NSDictionary *segment in segments) {
                                    if(![self.processSegments valueForKey:[NSString stringWithFormat:@"%@", segment[@"AreaID"]]]) {
                                        [self.processSegments setValue:segment[@"AreaName"]
                                                                forKey:[NSString stringWithFormat:@"%@", segment[@"AreaID"]]];
                                    }
                                    [updatedData setValue:segment[@"AreaName"] forKey:[NSString stringWithFormat:@"%@", segment[@"AreaID"]]];
                                }
                            }
                            
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:WISUpdateProcessSegmentSucceededNotification
                             object:updatedData];
                            
                            if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateProcessSegmentSucceeded)]) {
                                [self.maintenanceTaskOpDelegate updateProcessSegmentSucceeded];
                            }
                            handler(YES, nil, NSStringFromClass([updatedData class]), updatedData);
                            break;
                            
                        case RequestFailed:
                            err = [self produceErrorObjectWithWISErrorCode:ErrorCodeInvalidOperation andCallbackError:nil];
                            handler(FALSE, err, @"", nil);
                            
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:WISUpdateProcessSegmentSFailedNotification
                             object:(NSError *)err];
                            
                            if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateProcessSegmentFailedWithError:)]) {
                                [self.maintenanceTaskOpDelegate updateProcessSegmentFailedWithError:err];
                            }
                            break;
                            
                        default:
                            break;
                    }
                }
            }
        }];
    }
    
    return dataTask;
}


#pragma mark - Current User Detail Information

- (NSURLSessionDataTask *) submitUserDetailInfoWithNewInfo:(WISUser *)newUserInfo
                                         completionHandler:(WISSystemOperationHandler)handler {
    
    NSDictionary * operationParams = nil;
    NSURLSessionDataTask * dataTask = nil;
    
    if ([self.currentUser.userName isEqual: @""] || self.currentUser.userName == nil
        || [self.networkRequestToken isEqual: @""] || self.networkRequestToken == nil) {
        
        NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeNoCurrentUserInfo andCallbackError:nil];
        handler(FALSE, err, @"", nil);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WISSystemSubmitCurrentUserDetailInfoFailedNotification
                                                            object:(NSError *)err];
        if ([self.systemDataDelegate respondsToSelector:@selector(submitCurrentUserDetailInfoFailedWithError:)]) {
            [self.systemDataDelegate submitCurrentUserDetailInfoFailedWithError:err];
        }
        
    } else {
        
        operationParams = [self produceSubmitUserInformationParameterWithUserName:self.currentUser.userName
                                                              networkRequestToken:self.networkRequestToken
                                                                         userInfo:newUserInfo];
        
        dataTask = [self.networkService dataRequestWithRequestType:SubmitCurrentUserDetailInfo
                                                            params:operationParams
                                                     andUriSetting:nil
        completionHandler:^(RequestType requestType, NSData *responsedData, NSError *error) {
            if (!responsedData) {
                NSLog(@"Submit Current User Detail Info 请求异常，原因: %@", @"返回的数据为空");
                
                NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeResponsedNULLData andCallbackError:error];
                handler(FALSE, err, @"", nil);
                
                [[NSNotificationCenter defaultCenter] postNotificationName:WISSystemSubmitCurrentUserDetailInfoFailedNotification
                                                                    object:(NSError *)err];
                if ([self.systemDataDelegate respondsToSelector:@selector(submitCurrentUserDetailInfoFailedWithError:)]) {
                    [self.systemDataDelegate submitCurrentUserDetailInfoFailedWithError:err];
                }
                
            } else {
                
                NSError *parseError;
                NSDictionary *parsedData = nil;
                
                parsedData = [NSJSONSerialization JSONObjectWithData:responsedData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&parseError];
                
                if (!parsedData || parseError) {
                    NSLog(@"Submit Current User Detail Info 操作解析内容失败，原因: %@", parseError);
                    
                    NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeIncorrectResponsedDataFormat andCallbackError:parseError];
                    handler(FALSE, err, @"", nil);
                    
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:WISSystemSubmitCurrentUserDetailInfoFailedNotification
                     object:(NSError *)err];
                    
                    if ([self.systemDataDelegate respondsToSelector:@selector(submitCurrentUserDetailInfoFailedWithError:)]) {
                        [self.systemDataDelegate submitCurrentUserDetailInfoFailedWithError:err];
                    }
                    
                } else {
                    
                    RequestResult result = (RequestResult)[parsedData[@"Result"] integerValue];
                    NSError *err;
                    switch (result) {
                        case RequestSuccessful:
                            self.currentUser = [newUserInfo copy];
                            
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:WISSystemSubmitCurrentUserDetailInfoSucceededNotification
                             object:newUserInfo];
                            
                            if ([self.systemDataDelegate respondsToSelector:@selector(submitCurrentUserDetailInfoSucceeded)]) {
                                [self.systemDataDelegate submitCurrentUserDetailInfoSucceeded];
                            }
                            handler(YES, nil, NSStringFromClass([newUserInfo class]), newUserInfo);
                            break;
                            
                        case RequestFailed:
                            err = [self produceErrorObjectWithWISErrorCode:ErrorCodeInvalidOperation andCallbackError:nil];
                            handler(FALSE, err, @"", nil);
                            
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:WISSystemSubmitCurrentUserDetailInfoFailedNotification
                             object:(NSError *)err];
                            
                            if ([self.systemDataDelegate respondsToSelector:@selector(submitCurrentUserDetailInfoFailedWithError:)]) {
                                [self.systemDataDelegate submitCurrentUserDetailInfoFailedWithError:err];
                            }
                            break;
                            
                        default:
                            break;
                    }
                }
            }
        }];
    }
    return dataTask;
}

- (NSURLSessionDataTask *) updateCurrentUserDetailInformationWithCompletionHandler:(WISSystemOperationHandler)handler {
    NSDictionary * updateParams = nil;
    NSURLSessionDataTask * dataTask = nil;
    
    if ([self.currentUser.userName isEqual: @""] || self.currentUser.userName == nil
        || [self.networkRequestToken isEqual: @""] || self.networkRequestToken == nil) {
        
        NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeNoCurrentUserInfo andCallbackError:nil];
        handler(FALSE, err, @"", nil);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WISSystemUpdateCurrentUserDetailInfoFailedNotification
                                                            object:(NSError *)err];
        if ([self.systemDataDelegate respondsToSelector:@selector(updateCurrentUserDetailInfoFailedWithError:)]) {
            [self.systemDataDelegate updateCurrentUserDetailInfoFailedWithError:err];
        }
        
    } else {
        
        updateParams = [NSDictionary dictionaryWithObjectsAndKeys:self.currentUser.userName, @"UserName",
                        self.networkRequestToken, @"PassWord", nil];
        
        dataTask = [self.networkService dataRequestWithRequestType:UpdateCurrentUserDetailInfo
                                                            params:updateParams
                                                     andUriSetting:nil
        completionHandler:^(RequestType requestType, NSData *responsedData, NSError *error) {
            if (!responsedData) {
                NSLog(@"Update Current User Detail Info 请求异常，原因: %@", @"返回的数据为空");
                
                NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeResponsedNULLData andCallbackError:error];
                handler(FALSE, err, @"", nil);
                
                [[NSNotificationCenter defaultCenter] postNotificationName:WISSystemUpdateCurrentUserDetailInfoFailedNotification
                                                                    object:(NSError *)err];
                if ([self.systemDataDelegate respondsToSelector:@selector(updateCurrentUserDetailInfoFailedWithError:)]) {
                    [self.systemDataDelegate updateCurrentUserDetailInfoFailedWithError:err];
                }
                
            } else {
                
                NSError *parseError;
                NSDictionary *parsedData = nil;
                
                parsedData = [NSJSONSerialization JSONObjectWithData:responsedData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&parseError];
                
                if (!parsedData || parseError) {
                    NSLog(@"Update Current User Detail Info 操作解析内容失败，原因: %@", parseError);
                    
                    NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeIncorrectResponsedDataFormat andCallbackError:parseError];
                    handler(FALSE, err, @"", nil);
                    
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:WISSystemUpdateCurrentUserDetailInfoFailedNotification
                     object:(NSError *)err];
                    
                    if ([self.systemDataDelegate respondsToSelector:@selector(updateCurrentUserDetailInfoFailedWithError:)]) {
                        [self.systemDataDelegate updateCurrentUserDetailInfoFailedWithError:err];
                    }
                    
                } else {
                    
                    RequestResult result = (RequestResult)[parsedData[@"Result"] integerValue];
                    NSError *err;
                    
                    NSDictionary *userData = nil;
                    WISUser *userDetailInfo = [[WISUser alloc] init];
                    
                    switch (result) {
                        case RequestSuccessful:
                            userData = parsedData[@"Users"];
                            
                            if (userData && ((NSNull *)userData != [NSNull null])) {
                                
                                userDetailInfo.userName = ((NSNull*)userData[@"UserName"] == [NSNull null]) ? @"" : (NSString *)userData[@"UserName"];
                                userDetailInfo.fullName = ((NSNull*)userData[@"Name"] == [NSNull null]) ? @"" : (NSString *)userData[@"Name"];
                                userDetailInfo.telephoneNumber = ((NSNull*)userData[@"Telephone"] == [NSNull null]) ? @"" : (NSString *)userData[@"Telephone"];
                                userDetailInfo.cellPhoneNumber = ((NSNull*)userData[@"Mobilephone"] == [NSNull null]) ? @"" : (NSString *)userData[@"Mobilephone"];
                                userDetailInfo.urgentPhoneNumber = ((NSNull*)userData[@"UrgentPhone"] == [NSNull null]) ? @"" : (NSString *)userData[@"UrgentPhone"];
                                
                                userDetailInfo.birthday = ((NSNull*)userData[@"Birthday"] == [NSNull null]) ? [NSDate date] : [NSDate dateFromDateString:(NSString *)userData[@"Birthday"]];
                                userDetailInfo.eMail = ((NSNull*)userData[@"Email"] == [NSNull null]) ? @"" : (NSString *)userData[@"Email"];
                                userDetailInfo.identityCardNumber = ((NSNull*)userData[@"IDcard"] == [NSNull null]) ? @"" : (NSString *)userData[@"IDcard"];
                                userDetailInfo.lastUpatedTime = ((NSNull*)userData[@"LastUpdateTime"] == [NSNull null]) ? [NSDate date] : [NSDate dateFromDateTimeString:(NSString *)userData[@"LastUpdateTime"]];
                                userDetailInfo.title = ((NSNull*)userData[@"Title"] == [NSNull null]) ? @"" : (NSString *)userData[@"Title"];
                                userDetailInfo.remark = ((NSNull*)userData[@"Remark"] == [NSNull null]) ? @"" : (NSString *)userData[@"Remark"];
                                
                                /// GENDER
                                NSString *genderString = (NSString *)userData[@"Gender"];
                                if ([genderString integerValue] == 0) {
                                    userDetailInfo.gender = GenderFemale;
                                } else {
                                    userDetailInfo.gender = GenderMale;
                                }
                                
                                /// COMPANY
                                NSDictionary *companyDic = userData[@"Company"];
                                if (companyDic && ((NSNull *)companyDic != [NSNull null])) {
                                    userDetailInfo.company.companyID = ((NSNull*)companyDic[@"CompanyID"] == [NSNull null]) ? @"" : (NSString *)companyDic[@"CompanyID"];
                                    userDetailInfo.company.companyName = ((NSNull*)companyDic[@"CompanyName"] == [NSNull null]) ? @"" : (NSString *)companyDic[@"CompanyName"];
                                }
                                
                                /// ROLE
                                NSDictionary *roleDic = userData[@"Role"];
                                if (roleDic && ((NSNull *)roleDic != [NSNull null])) {
                                    userDetailInfo.roleName = ((NSNull*)roleDic[@"RoleName"] == [NSNull null]) ? @"" : (NSString *)roleDic[@"RoleName"];
                                }
                                
                                /// IMAGES INFO
                                NSArray *imagesURL = (NSArray *)userData[@"ImageURL"];
                                if (imagesURL && !((NSNull *)imagesURL == [NSNull null])) {
                                    for (NSString *url in imagesURL) {
                                        WISFileInfo *imageInfo = [WISDataManager produceFileInfoWithFileRemoteURL:url];
                                        
                                        if (![userDetailInfo.imagesInfo valueForKey:imageInfo.fileName]) {
                                            [userDetailInfo.imagesInfo setValue:imageInfo forKey:imageInfo.fileName];
                                        }
                                    }
                                    
                                } else {
                                    // do nothing, because WISMaintenanceTask initializer has done the initializing job.
                                }
                            }
                            
                            // self.currentUser = [userDetailInfo copy];
                            
                            self.currentUser.userName = userDetailInfo.userName;
                            self.currentUser.fullName = userDetailInfo.fullName;
                            self.currentUser.cellPhoneNumber = userDetailInfo.cellPhoneNumber;
                            self.currentUser.telephoneNumber = userDetailInfo.telephoneNumber;
                            self.currentUser.urgentPhoneNumber = userDetailInfo.urgentPhoneNumber;
                            
                            self.currentUser.birthday = userDetailInfo.birthday;
                            self.currentUser.eMail = userDetailInfo.eMail;
                            self.currentUser.identityCardNumber = userDetailInfo.identityCardNumber;
                            self.currentUser.lastUpatedTime = userDetailInfo.lastUpatedTime;
                            self.currentUser.title = userDetailInfo.title;
                            self.currentUser.remark = userDetailInfo.remark;
                            
                            self.currentUser.gender = userDetailInfo.gender;
                            self.currentUser.company = userDetailInfo.company;
                            
                            self.currentUser.imagesInfo = userDetailInfo.imagesInfo;
                            
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:WISSystemUpdateCurrentUserDetailInfoSucceededNotification
                             object:userDetailInfo];
                            
                            if ([self.systemDataDelegate respondsToSelector:@selector(updateCurrentUserDetailInfoSucceeded)]) {
                                [self.systemDataDelegate updateCurrentUserDetailInfoSucceeded];
                            }
                            handler(YES, nil, NSStringFromClass([userDetailInfo class]), userDetailInfo);
                            break;
                            
                        case RequestFailed:
                            err = [self produceErrorObjectWithWISErrorCode:ErrorCodeInvalidOperation andCallbackError:nil];
                            handler(FALSE, err, @"", nil);
                            
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:WISSystemUpdateCurrentUserDetailInfoFailedNotification
                             object:(NSError *)err];
                            
                            if ([self.systemDataDelegate respondsToSelector:@selector(updateCurrentUserDetailInfoFailedWithError:)]) {
                                [self.systemDataDelegate updateCurrentUserDetailInfoFailedWithError:err];
                            }
                            break;
                            
                        default:
                            break;
                    }
                }
            }
        }];
    }
    return dataTask;
}


#pragma mark - Clock Operations

- (NSURLSessionDataTask *) submitClockActionWithCompletionHandler:(WISSystemOperationHandler)handler {
    
    NSDictionary * updateParams = nil;
    NSURLSessionDataTask * dataTask = nil;
    
    if ([self.currentUser.userName isEqual: @""] || self.currentUser.userName == nil
        || [self.networkRequestToken isEqual: @""] || self.networkRequestToken == nil) {
        
        NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeNoCurrentUserInfo andCallbackError:nil];
        handler(FALSE, err, @"", nil);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WISSystemSubmitClockActionFailedNotification
                                                            object:(NSError *)err];
        if ([self.systemDataDelegate respondsToSelector:@selector(submitClockActionFailedWithError:)]) {
            [self.systemDataDelegate submitClockActionFailedWithError:err];
        }
        
    } else {
        
        updateParams = [NSDictionary dictionaryWithObjectsAndKeys:self.currentUser.userName, @"UserName",
                        self.networkRequestToken, @"PassWord", nil];
        
        dataTask = [self.networkService dataRequestWithRequestType:SubmitClockAction
                                                            params:updateParams
                                                     andUriSetting:nil
        completionHandler:^(RequestType requestType, NSData *responsedData, NSError *error) {
            if (!responsedData) {
                NSLog(@"Submit Clock Action 请求异常，原因: %@", @"返回的数据为空");
                
                NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeResponsedNULLData andCallbackError:error];
                handler(FALSE, err, @"", nil);
                
                [[NSNotificationCenter defaultCenter] postNotificationName:WISSystemSubmitClockActionFailedNotification
                                                                    object:(NSError *)err];
                if ([self.systemDataDelegate respondsToSelector:@selector(submitClockActionFailedWithError:)]) {
                    [self.systemDataDelegate submitClockActionFailedWithError:err];
                }
                
            } else {
                
                NSError *parseError;
                NSDictionary *parsedData = nil;
                
                parsedData = [NSJSONSerialization JSONObjectWithData:responsedData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&parseError];
                
                if (!parsedData || parseError) {
                    NSLog(@"Submit Clock Action 操作解析内容失败，原因: %@", parseError);
                    
                    NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeIncorrectResponsedDataFormat andCallbackError:parseError];
                    handler(FALSE, err, @"", nil);
                    
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:WISSystemSubmitClockActionFailedNotification
                     object:(NSError *)err];
                    
                    if ([self.systemDataDelegate respondsToSelector:@selector(submitClockActionFailedWithError:)]) {
                        [self.systemDataDelegate submitClockActionFailedWithError:err];
                    }
                    
                } else {
                    
                    RequestResult result = (RequestResult)[parsedData[@"Result"] integerValue];
                    ClockStatus status;
                    NSError *err;
                    
                    NSString *updatedData = [NSString stringWithFormat:@"%ld", (NSInteger)UndefinedClockStatus];
                    
                    switch (result) {
                        case RequestSuccessful:
                            if(parsedData[@"Status"] && !((NSNull *)parsedData[@"Status"] == [NSNull null])) {
                                NSString *statusAsString = (NSString *)parsedData[@"Status"];
                                status = (ClockStatus)[statusAsString integerValue];
                                updatedData = statusAsString;
                            }
                            
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:WISSystemSubmitClockActionSucceededNotification
                             object:updatedData];
                            
                            if ([self.systemDataDelegate respondsToSelector:@selector(submitClockActionSucceeded)]) {
                                [self.systemDataDelegate submitClockActionSucceeded];
                            }
                            handler(YES, nil, NSStringFromClass([NSString class]), updatedData);
                            break;
                            
                        case RequestFailed:
                            err = [self produceErrorObjectWithWISErrorCode:ErrorCodeInvalidOperation andCallbackError:nil];
                            handler(FALSE, err, @"", nil);
                            
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:WISSystemSubmitClockActionFailedNotification
                             object:(NSError *)err];
                            
                            if ([self.systemDataDelegate respondsToSelector:@selector(submitClockActionFailedWithError:)]) {
                                [self.systemDataDelegate submitClockActionFailedWithError:err];
                            }
                            break;
                            
                        default:
                            break;
                    }
                }
            }
        }];
    }
    
    return dataTask;
}

- (NSURLSessionDataTask *) updateCurrentClockStatusWithCompletionHandler:(WISSystemOperationHandler)handler {
    
    NSDictionary * updateParams = nil;
    NSURLSessionDataTask * dataTask = nil;
    
    if ([self.currentUser.userName isEqual: @""] || self.currentUser.userName == nil
        || [self.networkRequestToken isEqual: @""] || self.networkRequestToken == nil) {
        
        NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeNoCurrentUserInfo andCallbackError:nil];
        handler(FALSE, err, @"", nil);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WISSystemUpdateCurrentClockStatusFailedNotification
                                                            object:(NSError *)err];
        if ([self.systemDataDelegate respondsToSelector:@selector(updateCurrentClockStatusFailedWithError:)]) {
            [self.systemDataDelegate updateCurrentClockStatusFailedWithError:err];
        }
        
    } else {
        
        updateParams = [NSDictionary dictionaryWithObjectsAndKeys:self.currentUser.userName, @"UserName",
                        self.networkRequestToken, @"PassWord", nil];
        
        dataTask = [self.networkService dataRequestWithRequestType:UpdateCurrentClockStatus
                                                            params:updateParams
                                                     andUriSetting:nil
        completionHandler:^(RequestType requestType, NSData *responsedData, NSError *error) {
            if (!responsedData) {
                NSLog(@"Update Current Clock Status 请求异常，原因: %@", @"返回的数据为空");
                
                NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeResponsedNULLData andCallbackError:error];
                handler(FALSE, err, @"", nil);
                
                [[NSNotificationCenter defaultCenter] postNotificationName:WISSystemUpdateCurrentClockStatusFailedNotification
                                                                    object:(NSError *)err];
                if ([self.systemDataDelegate respondsToSelector:@selector(updateCurrentClockStatusFailedWithError:)]) {
                    [self.systemDataDelegate updateCurrentClockStatusFailedWithError:err];
                }
                
            } else {
                
                NSError *parseError;
                NSDictionary *parsedData = nil;
                
                parsedData = [NSJSONSerialization JSONObjectWithData:responsedData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&parseError];
                
                if (!parsedData || parseError) {
                    NSLog(@"Update Current Clock Status 操作解析内容失败，原因: %@", parseError);
                    
                    NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeIncorrectResponsedDataFormat andCallbackError:parseError];
                    handler(FALSE, err, @"", nil);
                    
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:WISSystemUpdateCurrentClockStatusFailedNotification
                     object:(NSError *)err];
                    
                    if ([self.systemDataDelegate respondsToSelector:@selector(updateCurrentClockStatusFailedWithError:)]) {
                        [self.systemDataDelegate updateCurrentClockStatusFailedWithError:err];
                    }
                    
                } else {
                    
                    RequestResult result = (RequestResult)[parsedData[@"Result"] integerValue];
                    ClockStatus status;
                    NSError *err;
                    
                    NSString *updatedData = [NSString stringWithFormat:@"%ld", (long)UndefinedClockStatus];
                    
                    switch (result) {
                        case RequestSuccessful:
                            if(parsedData[@"Status"] && !((NSNull *)parsedData[@"Status"] == [NSNull null])) {
                                NSString *statusAsString = (NSString *)parsedData[@"Status"];
                                status = (ClockStatus)[(NSString *)parsedData[@"Status"] integerValue];
                                updatedData = statusAsString;
                            }
                            
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:WISSystemUpdateCurrentClockStatusSucceededNotification
                             object:updatedData];
                            
                            if ([self.systemDataDelegate respondsToSelector:@selector(updateCurrentClockStatusSucceeded)]) {
                                [self.systemDataDelegate updateCurrentClockStatusSucceeded];
                            }
                            handler(YES, nil, NSStringFromClass([NSString class]), updatedData);
                            break;
                            
                        case RequestFailed:
                            err = [self produceErrorObjectWithWISErrorCode:ErrorCodeInvalidOperation andCallbackError:nil];
                            handler(FALSE, err, @"", nil);
                            
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:WISSystemUpdateCurrentClockStatusFailedNotification
                             object:(NSError *)err];
                            
                            if ([self.systemDataDelegate respondsToSelector:@selector(updateCurrentClockStatusFailedWithError:)]) {
                                [self.systemDataDelegate updateCurrentClockStatusFailedWithError:err];
                            }
                            break;
                            
                        default:
                            break;
                    }
                }
            }
        }];
    }
    
    return dataTask;
}

- (NSURLSessionDataTask *) updateClockRecordsWithStartDate:(NSDate *)startDate
                                                   endDate:(NSDate *)endDate
                                         completionHandler:(WISSystemOperationHandler)handler {
    NSDictionary * updateParams = nil;
    NSURLSessionDataTask * dataTask = nil;
    
    if ([self.currentUser.userName isEqual: @""] || self.currentUser.userName == nil
        || [self.networkRequestToken isEqual: @""] || self.networkRequestToken == nil) {
        
        NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeNoCurrentUserInfo andCallbackError:nil];
        handler(FALSE, err, @"", nil);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WISSystemUpdateClockRecordsFailedNotification
                                                            object:(NSError *)err];
        if ([self.systemDataDelegate respondsToSelector:@selector(updateClockRecordsFailedWithError:)]) {
            [self.systemDataDelegate updateClockRecordsFailedWithError:err];
        }
        
    } else {
        
        updateParams = [NSDictionary dictionaryWithObjectsAndKeys:self.currentUser.userName, @"UserName",
                        self.networkRequestToken, @"PassWord", nil];
        
        NSMutableArray<NSString *> *setting = [NSMutableArray array];
        [setting addObject:[startDate toDateStringWithSeparator:@"/"]];
        [setting addObject:[endDate toDateStringWithSeparator:@"/"]];
        
        dataTask = [self.networkService dataRequestWithRequestType:UpdateClockRecords
                                                            params:updateParams
                                                     andUriSetting:setting
        completionHandler:^(RequestType requestType, NSData *responsedData, NSError *error) {
            if (!responsedData) {
                NSLog(@"Update Clock Records 请求异常，原因: %@", @"返回的数据为空");
                
                NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeResponsedNULLData andCallbackError:error];
                handler(FALSE, err, @"", nil);
                
                [[NSNotificationCenter defaultCenter] postNotificationName:WISSystemUpdateClockRecordsFailedNotification
                                                                    object:(NSError *)err];
                if ([self.systemDataDelegate respondsToSelector:@selector(updateClockRecordsFailedWithError:)]) {
                    [self.systemDataDelegate updateClockRecordsFailedWithError:err];
                }
                
            } else {
                
                NSError *parseError;
                NSDictionary *parsedData = nil;
                
                parsedData = [NSJSONSerialization JSONObjectWithData:responsedData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&parseError];
                
                if (!parsedData || parseError) {
                    NSLog(@"Update Clock Records 操作解析内容失败，原因: %@", parseError);
                    
                    NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeIncorrectResponsedDataFormat andCallbackError:parseError];
                    handler(FALSE, err, @"", nil);
                    
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:WISSystemUpdateClockRecordsFailedNotification
                     object:(NSError *)err];
                    
                    if ([self.systemDataDelegate respondsToSelector:@selector(updateClockRecordsFailedWithError:)]) {
                        [self.systemDataDelegate updateClockRecordsFailedWithError:err];
                    }
                    
                } else {
                    
                    RequestResult result = (RequestResult)[parsedData[@"Result"] integerValue];
                    NSError *err;
                    
                    NSMutableArray<WISClockRecord *> *updatedData = [NSMutableArray array];
                    
                    switch (result) {
                        case RequestSuccessful:
                            if(parsedData[@"ClockRecords"] && !((NSNull *)parsedData[@"ClockRecords"] == [NSNull null])) {
                                NSArray *arr = parsedData[@"ClockRecords"];
                                
                                if (arr.count > 0) {
                                    for (NSDictionary *shift in arr) {
                                        WISClockRecord *record  = [[WISClockRecord alloc]init];
                                        record.clockAction = (ClockAction)[(NSString *)shift[@"Action"] integerValue];
                                        record.clockActionTime = [NSDate dateFromDateTimeString:(NSString *)shift[@"ClockTime"]];
                                        
                                        [updatedData addObject:record];
                                    }
                                }
                            }
                            
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:WISSystemUpdateClockRecordsSucceededNotification
                             object:updatedData];
                            
                            if ([self.systemDataDelegate respondsToSelector:@selector(updateClockRecordsSucceeded)]) {
                                [self.systemDataDelegate updateClockRecordsSucceeded];
                            }
                            handler(YES, nil, NSStringFromClass([updatedData class]), updatedData);
                            break;
                            
                        case RequestFailed:
                            err = [self produceErrorObjectWithWISErrorCode:ErrorCodeInvalidOperation andCallbackError:nil];
                            handler(FALSE, err, @"", nil);
                            
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:WISSystemUpdateClockRecordsFailedNotification
                             object:(NSError *)err];
                            
                            if ([self.systemDataDelegate respondsToSelector:@selector(updateClockRecordsFailedWithError:)]) {
                                [self.systemDataDelegate updateClockRecordsFailedWithError:err];
                            }
                            break;
                            
                        default:
                            break;
                    }
                }
            }
        }];
    }
    
    return dataTask;
}

- (NSURLSessionDataTask *) updateWorkShiftsWithStartDate:(NSDate *)startDate
                                            recordNumber:(NSInteger)number
                                       completionHandler:(WISSystemOperationHandler)handler {
    
    NSDictionary * updateParams = nil;
    NSURLSessionDataTask * dataTask = nil;
    
    if ([self.currentUser.userName isEqual: @""] || self.currentUser.userName == nil
        || [self.networkRequestToken isEqual: @""] || self.networkRequestToken == nil) {
        
        NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeNoCurrentUserInfo andCallbackError:nil];
        handler(FALSE, err, @"", nil);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WISSystemUpdateWorkShiftsFailedNotification
                                                            object:(NSError *)err];
        if ([self.systemDataDelegate respondsToSelector:@selector(updateWorkShiftsFailedWithError:)]) {
            [self.systemDataDelegate updateWorkShiftsFailedWithError:err];
        }
        
    } else {
        
        updateParams = [NSDictionary dictionaryWithObjectsAndKeys:self.currentUser.userName, @"UserName",
                        self.networkRequestToken, @"PassWord", nil];
        
        NSMutableArray<NSString *> *setting = [NSMutableArray array];
        [setting addObject:[startDate toDateStringWithSeparator:@"/"]];
        [setting addObject:[NSString stringWithFormat:@"%ld", (long)number]];
        
        dataTask = [self.networkService dataRequestWithRequestType:UpdateWorkShifts
                                                            params:updateParams
                                                     andUriSetting:setting
        completionHandler:^(RequestType requestType, NSData *responsedData, NSError *error) {
            if (!responsedData) {
                NSLog(@"Update Work Shifts 请求异常，原因: %@", @"返回的数据为空");
                
                NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeResponsedNULLData andCallbackError:error];
                handler(FALSE, err, @"", nil);
                
                [[NSNotificationCenter defaultCenter] postNotificationName:WISSystemUpdateWorkShiftsFailedNotification
                                                                    object:(NSError *)err];
                if ([self.systemDataDelegate respondsToSelector:@selector(updateWorkShiftsFailedWithError:)]) {
                    [self.systemDataDelegate updateWorkShiftsFailedWithError:err];
                }
                
            } else {
                
                NSError *parseError;
                NSDictionary *parsedData = nil;
                
                parsedData = [NSJSONSerialization JSONObjectWithData:responsedData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&parseError];
                
                if (!parsedData || parseError) {
                    NSLog(@"Update Work Shifts 操作解析内容失败，原因: %@", parseError);
                    
                    NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeIncorrectResponsedDataFormat andCallbackError:parseError];
                    handler(FALSE, err, @"", nil);
                    
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:WISSystemUpdateWorkShiftsFailedNotification
                     object:(NSError *)err];
                    
                    if ([self.systemDataDelegate respondsToSelector:@selector(updateWorkShiftsFailedWithError:)]) {
                        [self.systemDataDelegate updateWorkShiftsFailedWithError:err];
                    }
                    
                } else {
                    
                    RequestResult result = (RequestResult)[parsedData[@"Result"] integerValue];
                    NSError *err;
                    
                    NSMutableArray<NSString *> *updatedData = [NSMutableArray array];
                    
                    switch (result) {
                        case RequestSuccessful:
                            if(parsedData[@"Shifts"] && !((NSNull *)parsedData[@"Shifts"] == [NSNull null])) {
                                NSArray *arr = parsedData[@"Shifts"];
                                
                                if (arr.count > 0) {
                                    for (NSString *shift in arr) {
                                        [updatedData addObject:shift];
                                    }
                                }
                            }
                            
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:WISSystemUpdateWorkShiftsSucceededNotification
                             object:updatedData];
                            
                            if ([self.systemDataDelegate respondsToSelector:@selector(updateWorkShiftsSucceeded)]) {
                                [self.systemDataDelegate updateWorkShiftsSucceeded];
                            }
                            handler(YES, nil, NSStringFromClass([updatedData class]), updatedData);
                            break;
                            
                        case RequestFailed:
                            err = [self produceErrorObjectWithWISErrorCode:ErrorCodeInvalidOperation andCallbackError:nil];
                            handler(FALSE, err, @"", nil);
                            
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:WISSystemUpdateWorkShiftsFailedNotification
                             object:(NSError *)err];
                            
                            if ([self.systemDataDelegate respondsToSelector:@selector(updateWorkShiftsFailedWithError:)]) {
                                [self.systemDataDelegate updateWorkShiftsFailedWithError:err];
                            }
                            break;
                            
                        default:
                            break;
                    }
                }
            }
        }];
    }
    
    return dataTask;
}

- (NSURLSessionDataTask *) updateAttendanceRecordsWithDate:(NSDate *)date
                                         completionHandler:(WISSystemOperationHandler)handler {
    NSDictionary * updateParams = nil;
    NSURLSessionDataTask * dataTask = nil;
    
    if ([self.currentUser.userName isEqual: @""] || self.currentUser.userName == nil
        || [self.networkRequestToken isEqual: @""] || self.networkRequestToken == nil) {
        
        NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeNoCurrentUserInfo andCallbackError:nil];
        handler(FALSE, err, @"", nil);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WISSystemUpdateAttendanceRecordsFailedNotification
                                                            object:(NSError *)err];
        if ([self.systemDataDelegate respondsToSelector:@selector(updateAttendanceRecordsFailedWithError:)]) {
            [self.systemDataDelegate updateAttendanceRecordsFailedWithError:err];
        }
        
    } else {
        updateParams = [NSDictionary dictionaryWithObjectsAndKeys:self.currentUser.userName, @"UserName",
                        self.networkRequestToken, @"PassWord", nil];
        
        NSMutableArray<NSString *> *setting = [NSMutableArray array];
        [setting addObject:[date toDateStringWithSeparator:@"/"]];
        
        dataTask = [self.networkService dataRequestWithRequestType:UpdateAttendanceRecords
                                                            params:updateParams
                                                     andUriSetting:setting
        completionHandler:^(RequestType requestType, NSData *responsedData, NSError *error) {
            if (!responsedData) {
                NSLog(@"Update Attendance Records 请求异常，原因: %@", @"返回的数据为空");
                
                NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeResponsedNULLData andCallbackError:error];
                handler(FALSE, err, @"", nil);
                
                [[NSNotificationCenter defaultCenter] postNotificationName:WISSystemUpdateAttendanceRecordsFailedNotification
                                                                    object:(NSError *)err];
                if ([self.systemDataDelegate respondsToSelector:@selector(updateAttendanceRecordsFailedWithError:)]) {
                    [self.systemDataDelegate updateAttendanceRecordsFailedWithError:err];
                }
                
            } else {
                
                NSError *parseError;
                NSDictionary *parsedData = nil;
                
                parsedData = [NSJSONSerialization JSONObjectWithData:responsedData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&parseError];
                
                if (!parsedData || parseError) {
                    NSLog(@"Update Attendance Records 操作解析内容失败，原因: %@", parseError);
                    
                    NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeIncorrectResponsedDataFormat andCallbackError:parseError];
                    handler(FALSE, err, @"", nil);
                    
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:WISSystemUpdateAttendanceRecordsFailedNotification
                     object:(NSError *)err];
                    
                    if ([self.systemDataDelegate respondsToSelector:@selector(updateAttendanceRecordsFailedWithError:)]) {
                        [self.systemDataDelegate updateAttendanceRecordsFailedWithError:err];
                    }
                    
                } else {
                    
                    RequestResult result = (RequestResult)[parsedData[@"Result"] integerValue];
                    NSError *err;
                    
                    NSMutableArray<WISAttendanceRecord *> *updatedData = [NSMutableArray array];
                    
                    switch (result) {
                        case RequestSuccessful:
                            if(parsedData[@"StaffStatusList"] && !((NSNull *)parsedData[@"StaffStatusList"] == [NSNull null])) {
                                NSArray *arr = parsedData[@"StaffStatusList"];
                                
                                if (arr.count > 0) {
                                    for (NSDictionary *attendanceRecord in arr) {
                                        WISAttendanceRecord *record  = [[WISAttendanceRecord alloc] init];
                                        record.attendanceStatus = (AttendanceStatus)[(NSString *)attendanceRecord[@"ClockState"] integerValue];
                                        record.shift = (WorkShift)[(NSString *)attendanceRecord[@"Shift"] integerValue];
                                        record.attendanceRecordDate = [date copy];
                                        
                                        WISUser *staff = [[WISUser alloc] init];
                                        NSDictionary *user = (NSDictionary *)attendanceRecord[@"Staff"];
                                        
                                        if (user && !((NSNull *)user == [NSNull null])) {
                                            staff.userName = ((NSNull*)user[@"UserName"] == [NSNull null]) ? @"" : (NSString *)user[@"UserName"];
                                            staff.fullName = ((NSNull*)user[@"Name"] == [NSNull null]) ? @"" : (NSString *)user[@"Name"];
                                            staff.roleCode = ((NSNull*)user[@"RoleCode"] == [NSNull null]) ? @"" : (NSString *)user[@"RoleCode"];
                                            staff.roleName = ((NSNull*)user[@"RoleName"] == [NSNull null]) ? @"" : (NSString *)user[@"RoleName"];
                                            staff.cellPhoneNumber = ((NSNull*)user[@"MobilePhone"] == [NSNull null]) ? @"" : (NSString *)user[@"MobilePhone"];
                                            staff.telephoneNumber = ((NSNull*)user[@"Telephone"] == [NSNull null]) ? @"" : (NSString *)user[@"Telephone"];
                                            
                                            /// IMAGES INFO
                                            NSArray *imagesURL = (NSArray *)user[@"ImageURL"];
                                            if (imagesURL && !((NSNull *)imagesURL == [NSNull null])) {
                                                for (NSString *url in imagesURL) {
                                                    WISFileInfo *imageInfo = [WISDataManager produceFileInfoWithFileRemoteURL:url];
                                                    
                                                    if (![staff.imagesInfo valueForKey:imageInfo.fileName]) {
                                                        [staff.imagesInfo setValue:imageInfo forKey:imageInfo.fileName];
                                                    }
                                                }
                                                
                                            } else {
                                                // do nothing, because WISUser initializer has done the initializing job.
                                            }
                                            
                                            record.staff = staff;
                                            
                                            if (![self.users valueForKey:staff.userName])
                                                [self.users setValue:staff forKey:staff.userName];
                                        } else {
                                            // do nothing, because WISAttendanceRecords initializer has done the initial job.
                                        }
                                        
                                        [updatedData addObject:record];
                                    }
                                }
                            }
                            
                            [updatedData sortWithOptions:NSSortConcurrent usingComparator:WISAttendanceRecord.arrayForwardSorterByStaffFullNameWithResult];
                            
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:WISSystemUpdateAttendanceRecordsSucceededNotification
                             object:updatedData];
                            
                            if ([self.systemDataDelegate respondsToSelector:@selector(updateAttendanceRecordsSucceeded)]) {
                                [self.systemDataDelegate updateAttendanceRecordsSucceeded];
                            }
                            handler(YES, nil, NSStringFromClass([updatedData class]), updatedData);
                            break;
                            
                        case RequestFailed:
                            err = [self produceErrorObjectWithWISErrorCode:ErrorCodeInvalidOperation andCallbackError:nil];
                            handler(FALSE, err, @"", nil);
                            
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:WISSystemUpdateAttendanceRecordsFailedNotification
                             object:(NSError *)err];
                            
                            if ([self.systemDataDelegate respondsToSelector:@selector(updateAttendanceRecordsFailedWithError:)]) {
                                [self.systemDataDelegate updateAttendanceRecordsFailedWithError:err];
                            }
                            break;
                            
                        default:
                            break;
                    }
                }
            }
        }];
    }
    
    return dataTask;
}


#pragma mark - Update Users Information

- (NSURLSessionDataTask *) updateContactUserInfoWithCompletionHandler:(WISMaintenanceTaskUpdateInfoHandler)handler {
    return [self updateUserInfoWithRequsetType:UpdateContactUserInfo completionHandler:handler];
}


- (NSURLSessionDataTask *) updateRelavantUserInfoWithCompletionHandler:(WISMaintenanceTaskUpdateInfoHandler)handler {
    return [self updateUserInfoWithRequsetType:UpdateRelavantUserInfo completionHandler:handler];
}


- (NSURLSessionDataTask *) updateUserInfoWithRequsetType:(RequestType)requestType completionHandler:(WISMaintenanceTaskUpdateInfoHandler)handler {
    
    NSDictionary * updateParams = nil;
    NSURLSessionDataTask * dataTask = nil;
    
    if ([self.currentUser.userName isEqual: @""] || self.currentUser.userName == nil
        || [self.networkRequestToken isEqual: @""] || self.networkRequestToken == nil) {
        
        NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeNoCurrentUserInfo andCallbackError:nil];
        handler(FALSE, err, @"", nil);
        
        if (requestType == UpdateContactUserInfo) {
            [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateContactUserInfoFailedNotification object:(NSError *)err];
            if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateContactUserInfoFailedWithError:)]) {
                [self.maintenanceTaskOpDelegate updateContactUserInfoFailedWithError:err];
            }
            
        } else if(requestType == UpdateRelavantUserInfo) {
            [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateRelavantUserInfoFailedNotification object:(NSError *)err];
            if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateContactUserInfoFailedWithError:)]) {
                [self.maintenanceTaskOpDelegate updateContactUserInfoFailedWithError:err];
            }
        }
        
    } else {
        
        updateParams = [NSDictionary dictionaryWithObjectsAndKeys:self.currentUser.userName, @"UserName",
                        self.networkRequestToken, @"PassWord", nil];
        
        dataTask = [self.networkService dataRequestWithRequestType:requestType
                                                 params:updateParams
                                          andUriSetting:nil
        completionHandler:^(RequestType requestType, NSData *responsedData, NSError *error) {
            if (!responsedData) {
                NSLog(@"Update User Info 请求异常，原因: %@", @"返回的数据为空");
                
                NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeResponsedNULLData andCallbackError:error];
                handler(FALSE, err, @"", nil);
                
                if (requestType == UpdateContactUserInfo) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateContactUserInfoFailedNotification object:(NSError *)err];
                    if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateContactUserInfoFailedWithError:)]) {
                        [self.maintenanceTaskOpDelegate updateContactUserInfoFailedWithError:err];
                    }
                    
                } else if(requestType == UpdateRelavantUserInfo) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateRelavantUserInfoFailedNotification object:(NSError *)err];
                    if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateContactUserInfoFailedWithError:)]) {
                        [self.maintenanceTaskOpDelegate updateContactUserInfoFailedWithError:err];
                    }
                }
                
            } else {
                NSError *parseError;
                NSDictionary *parsedData = nil;
                
                parsedData = [NSJSONSerialization JSONObjectWithData:responsedData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&parseError];
                
                if (!parsedData || parseError) {
                    NSLog(@"Update User Info 操作解析内容失败，原因: %@", parseError);
                    
                    NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeIncorrectResponsedDataFormat andCallbackError:parseError];
                    handler(FALSE, err, @"", nil);
                    
                    if (requestType == UpdateContactUserInfo) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateContactUserInfoFailedNotification
                                                                            object:(NSError *)err];
                        if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateContactUserInfoFailedWithError:)]) {
                            [self.maintenanceTaskOpDelegate updateContactUserInfoFailedWithError:err];
                        }
                        
                    } else if(requestType == UpdateRelavantUserInfo) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateRelavantUserInfoFailedNotification
                                                                            object:(NSError *)err];
                        if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateContactUserInfoFailedWithError:)]) {
                            [self.maintenanceTaskOpDelegate updateContactUserInfoFailedWithError:err];
                        }
                    }
                    
                } else {
                    
                    RequestResult result = (RequestResult)[parsedData[@"Result"] integerValue];
                    NSArray *usersData = nil;
                    NSError *err;
                    
                    NSMutableArray *updatedData = [NSMutableArray array];
                    
                    switch (result) {
                        case RequestSuccessful:
                            usersData = parsedData[@"Users"];
                            
                            if (usersData && ((NSNull *)usersData != [NSNull null])) {
                                if(usersData.count > 0) {
                                    for(NSDictionary *user in usersData) {
                                        WISUser *newUserInfo = [[WISUser alloc] init];
                                        
                                        newUserInfo.userName = ((NSNull*)user[@"UserName"] == [NSNull null]) ? @"" : (NSString *)user[@"UserName"];
                                        newUserInfo.fullName = ((NSNull*)user[@"Name"] == [NSNull null]) ? @"" : (NSString *)user[@"Name"];
                                        newUserInfo.telephoneNumber = ((NSNull*)user[@"Telephone"] == [NSNull null]) ? @"" : (NSString *)user[@"Telephone"];
                                        newUserInfo.cellPhoneNumber = ((NSNull*)user[@"MobilePhone"] == [NSNull null]) ? @"" : (NSString *)user[@"MobilePhone"];
                                        newUserInfo.roleCode = ((NSNull*)user[@"RoleCode"] == [NSNull null]) ? @"" : (NSString *)user[@"RoleCode"];
                                        newUserInfo.roleName = ((NSNull*)user[@"RoleName"] == [NSNull null]) ? @"" : (NSString *)user[@"RoleName"];
                                        
                                        /// IMAGES INFO
                                        NSArray *imagesURL = (NSArray *)user[@"ImageURL"];
                                        if (imagesURL && !((NSNull *)imagesURL == [NSNull null])) {
                                            for (NSString *url in imagesURL) {
                                                WISFileInfo *imageInfo = [WISDataManager produceFileInfoWithFileRemoteURL:url];
                                                
                                                if (![newUserInfo.imagesInfo valueForKey:imageInfo.fileName]) {
                                                    [newUserInfo.imagesInfo setValue:imageInfo forKey:imageInfo.fileName];
                                                }
                                            }
                                            
                                        } else {
                                            // do nothing, because WISMaintenanceTask initializer has done the initializing job.
                                        }
                                        
                                        if(![self.users valueForKey:newUserInfo.userName]) {
                                            [self.users setValue:newUserInfo forKey:newUserInfo.userName];
                                        }
                                        
                                        [updatedData addObject:newUserInfo];
                                    }
                                }
                            }
                            
                            if (requestType == UpdateContactUserInfo) {
                                [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateContactUserInfoSucceededNotification
                                                                                    object:updatedData];
                                if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateContactUserInfoSucceeded)]) {
                                    [self.maintenanceTaskOpDelegate updateContactUserInfoSucceeded];
                                }
                                
                            } else if(requestType == UpdateRelavantUserInfo) {
                                [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateContactUserInfoSucceededNotification
                                                                                    object:updatedData];
                                if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateContactUserInfoSucceeded)]) {
                                    [self.maintenanceTaskOpDelegate updateContactUserInfoSucceeded];
                                }
                            }
                            
                            handler(YES, nil, NSStringFromClass([updatedData class]), updatedData);
                            break;
                            
                        case RequestFailed:
                            err = [self produceErrorObjectWithWISErrorCode:ErrorCodeInvalidOperation andCallbackError:nil];
                            handler(FALSE, err, @"", nil);
                            
                            if (requestType == UpdateContactUserInfo) {
                                [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateContactUserInfoFailedNotification object:(NSError *)err];
                                if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateContactUserInfoFailedWithError:)]) {
                                    [self.maintenanceTaskOpDelegate updateContactUserInfoFailedWithError:err];
                                }
                                
                            } else if(requestType == UpdateRelavantUserInfo) {
                                [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateRelavantUserInfoFailedNotification object:(NSError *)err];
                                if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateContactUserInfoFailedWithError:)]) {
                                    [self.maintenanceTaskOpDelegate updateContactUserInfoFailedWithError:err];
                                }
                            }
                            break;
                            
                        default:
                            break;
                    }
                }
            }
        }];
    }
    return dataTask;
}


#pragma mark - Submit User Client ID

/// Submit User Client ID Operation And Response Method
- (NSURLSessionDataTask *) submitUserClientID:(NSString *)clientID completionHandler:(WISMaintenanceTaskOperationHandler)handler {
    
    NSDictionary * updateParams = nil;
    NSURLSessionDataTask *dataTask = nil;
    
    if ([self.currentUser.userName isEqual: @""] || self.currentUser.userName == nil
        || [self.networkRequestToken isEqual: @""] || self.networkRequestToken == nil) {
        
        NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeNoCurrentUserInfo andCallbackError:nil];
        handler(FALSE, err);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WISSubmitUserClientIDFailedNotification
                                                            object:(NSError *)err];
        
        if([self.systemDataDelegate respondsToSelector:@selector(SubmiteUserClientIDFailedWithError:)]) {
            [self.systemDataDelegate SubmiteUserClientIDFailedWithError:err];
        }
        
    } else {
        
        updateParams = [NSDictionary dictionaryWithObjectsAndKeys:self.currentUser.userName, @"UserName",
                        self.networkRequestToken, @"PassWord", nil];
        NSMutableArray<NSString *> *uriSetting = [NSMutableArray array];
        
        [uriSetting addObject:[NSString stringWithFormat:@"%ld", (NSUInteger)OSType_iOS]];
        [uriSetting addObject:clientID];
        
        dataTask = [self.networkService dataRequestWithRequestType:SubmitUserClientID
                                                            params:updateParams
                                                     andUriSetting:uriSetting
         completionHandler:^(RequestType requestType, NSData *responsedData, NSError *error) {
              if (!responsedData) {
                  NSLog(@"Submit Client ID 请求异常，原因: %@", @"返回的数据为空");
                  
                  NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeResponsedNULLData andCallbackError:error];
                  handler(FALSE, err);
                  
                  [[NSNotificationCenter defaultCenter] postNotificationName:WISSubmitUserClientIDFailedNotification object:(NSError *)err];
                  
                  if([self.systemDataDelegate respondsToSelector:@selector(SubmiteUserClientIDFailedWithError:)]) {
                      [self.systemDataDelegate SubmiteUserClientIDFailedWithError:err];
                  }
             
              } else {
                  
                  NSError *parseError;
                  NSDictionary *parsedData = nil;
                  
                  parsedData = [NSJSONSerialization JSONObjectWithData:responsedData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&parseError];
                  
                  if (!parsedData || parseError) {
                      NSLog(@"Submit Client ID 操作解析内容失败，原因: %@", parseError);
                      
                      NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeIncorrectResponsedDataFormat andCallbackError:parseError];
                      handler(FALSE, err);
                      
                      [[NSNotificationCenter defaultCenter]
                       postNotificationName:WISSubmitUserClientIDFailedNotification
                       object:(NSError *)err];
                      
                      if([self.systemDataDelegate respondsToSelector:@selector(SubmiteUserClientIDFailedWithError:)]) {
                          [self.systemDataDelegate SubmiteUserClientIDFailedWithError:err];
                      }
                      
                  } else {
                      
                      RequestResult result = (RequestResult)[parsedData[@"Result"] integerValue];
                      NSError *err;
                      
                      NSMutableDictionary *updatedData = [NSMutableDictionary dictionary];
                      
                      switch (result) {
                          case RequestSuccessful:
                              [[NSNotificationCenter defaultCenter]
                               postNotificationName:WISSubmitUserClientIDSucceededNotification
                               object:updatedData];
                              
                              if([self.systemDataDelegate respondsToSelector:@selector(SubmiteUserClientIDSucceeded)]) {
                                  [self.systemDataDelegate SubmiteUserClientIDSucceeded];
                              }
                              
                              handler(YES, nil);
                              break;
                              
                          case RequestFailed:
                              err = [self produceErrorObjectWithWISErrorCode:ErrorCodeInvalidOperation andCallbackError:nil];
                              
                              [[NSNotificationCenter defaultCenter]
                               postNotificationName:WISSubmitUserClientIDFailedNotification
                               object:(NSError *)err];
                              
                              if([self.systemDataDelegate respondsToSelector:@selector(SubmiteUserClientIDFailedWithError:)]) {
                                  [self.systemDataDelegate SubmiteUserClientIDFailedWithError:err];
                              }
                              
                              handler(FALSE, err);
                              break;
                              
                          default:
                              break;
                      }
                  }
              }
         }];
    }
    
    return dataTask;
}


#pragma mark - Update Maintenance Task Information

/// Update Maintenance Task Brief Information Operation And Response Method
- (NSURLSessionDataTask *) updateMaintenanceTaskBriefInfoWithTaskTypeID:(MaintenanceTaskType)taskTypeID
                                                      completionHandler:(WISMaintenanceTaskUpdateInfoHandler)handler {

    NSDictionary * updateParams = nil;
    NSURLSessionDataTask *dataTask = nil;
    
    if ([self.currentUser.userName isEqual: @""] || self.currentUser.userName == nil
        || [self.networkRequestToken isEqual: @""] || self.networkRequestToken == nil) {
        
        NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeNoCurrentUserInfo andCallbackError:nil];
        handler(FALSE, err, @"", nil);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateMaintenanceTaskBriefInfoFailedNotification object:(NSError *)err];
        if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateMaintenanceTasksBriefInfoFailedWithError:)]) {
            [self.maintenanceTaskOpDelegate updateMaintenanceTasksBriefInfoFailedWithError:err];
        }
        
    } else {
        
        updateParams = [NSDictionary dictionaryWithObjectsAndKeys:self.currentUser.userName, @"UserName",
                        self.networkRequestToken, @"PassWord", nil];
        
        dataTask = [self.networkService dataRequestWithRequestType:UpdateMaintenanceTaskBriefInfo
                                                            params:updateParams
                                          andUriSetting:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%ld", (long)taskTypeID], nil]
         completionHandler:^(RequestType requestType, NSData *responsedData, NSError *error) {
              if (!responsedData) {
                  NSLog(@"Update MaintenanceTask Brief Info 请求异常，原因: %@", @"返回的数据为空");
                  
                  NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeResponsedNULLData andCallbackError:error];
                  handler(FALSE, err, @"", nil);
                  
                  [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateMaintenanceTaskBriefInfoFailedNotification object:(NSError *)err];
                  if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateMaintenanceTasksBriefInfoFailedWithError:)]) {
                      [self.maintenanceTaskOpDelegate updateMaintenanceTasksBriefInfoFailedWithError:err];
                  }
                  
              } else {
                  
                  NSError *parseError;
                  NSDictionary *parsedData = nil;
                  
                  parsedData = [NSJSONSerialization JSONObjectWithData:responsedData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&parseError];
                  
                  if (!parsedData || parseError) {
                      NSLog(@"Update MaintenanceTask Brief Info 操作解析内容失败，原因: %@", parseError);
                      
                      NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeIncorrectResponsedDataFormat andCallbackError:parseError];
                      handler(FALSE, err, @"", nil);
                      
                      [[NSNotificationCenter defaultCenter]
                       postNotificationName:WISUpdateMaintenanceTaskBriefInfoFailedNotification
                       object:(NSError *)err];
                      
                      if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateMaintenanceTasksBriefInfoFailedWithError:)]) {
                          [self.maintenanceTaskOpDelegate updateMaintenanceTasksBriefInfoFailedWithError:err];
                      }
                      
                  } else {
                      
                      RequestResult result = (RequestResult)[parsedData[@"Result"] integerValue];
                      NSArray *tasks = nil;
                      NSString *taskID = nil;
                      NSInteger taskCount = 0;
                      
                      NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                      [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                      
                      NSError *err;
                      
                      NSMutableArray *updatedData = [NSMutableArray array];
                      
                      switch (result) {
                          case RequestSuccessful:
                              taskCount = [parsedData[@"Count"] integerValue];
                              
                              if(taskCount <= 0) {
                                  // do nothing
                              } else {
                                  
                                  //
                                  [self.maintenanceTasks removeAllObjects];
                                  
                                  tasks = parsedData[@"Tasks"];
                                  for(NSDictionary *task in tasks) {
                                      
                                      taskID = [NSString stringWithFormat:@"%@", task[@"TaskId"]];
                                      
                                      WISMaintenanceTask *maintenanceTask = [[WISMaintenanceTask alloc] init];
                                      
                                      maintenanceTask.taskID = taskID;
                                      maintenanceTask.taskName = ((NSNull*)task[@"TaskName"] == [NSNull null]) ? @"" : (NSString *)task[@"TaskName"];
                                      maintenanceTask.taskApplicationContent = ((NSNull*)task[@"Description"] == [NSNull null]) ? @"" : (NSString *)task[@"Description"];
                                      if (task[@"CreateTime"] && !((NSNull*)task[@"CreateTime"] == [NSNull null])) {
                                          // maintenanceTask.createdDateTime = [dateFormatter dateFromString:task[@"CreateTime"]];
                                          maintenanceTask.createdDateTime = [NSDate dateFromDateTimeString:task[@"CreateTime"]];
                                      }
                                      maintenanceTask.state = ((NSNull*)task[@"Status"] == [NSNull null]) ? @"" : (NSString *)task[@"Status"];
                                      maintenanceTask.taskType = taskTypeID;
                                      maintenanceTask.processSegmentName = ((NSNull*)task[@"FaultArea"] == [NSNull null]) ? @"" : (NSString *)task[@"FaultArea"];
                                      
                                      WISUser *taskPersonInCharge = [[WISUser alloc] init];
                                      NSDictionary *personInCharge = (NSDictionary *)task[@"Manager"];
                                      
                                      if (personInCharge && !((NSNull *)personInCharge == [NSNull null])) {
                                          taskPersonInCharge.userName = ((NSNull*)personInCharge[@"UserName"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"UserName"];
                                          taskPersonInCharge.fullName = ((NSNull*)personInCharge[@"Name"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"Name"];
                                          taskPersonInCharge.roleCode = ((NSNull*)personInCharge[@"RoleCode"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"RoleCode"];
                                          taskPersonInCharge.roleName = ((NSNull*)personInCharge[@"RoleName"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"RoleName"];
                                          taskPersonInCharge.cellPhoneNumber = ((NSNull*)personInCharge[@"MobilePhone"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"MobilePhone"];
                                          taskPersonInCharge.telephoneNumber = ((NSNull*)personInCharge[@"Telephone"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"Telephone"];
                                          
                                          /// IMAGES INFO
                                          NSArray *imagesURL = (NSArray *)personInCharge[@"ImageURL"];
                                          if (imagesURL && !((NSNull *)imagesURL == [NSNull null])) {
                                              for (NSString *url in imagesURL) {
                                                  WISFileInfo *imageInfo = [WISDataManager produceFileInfoWithFileRemoteURL:url];
                                                  
                                                  if (![taskPersonInCharge.imagesInfo valueForKey:imageInfo.fileName]) {
                                                      [taskPersonInCharge.imagesInfo setValue:imageInfo forKey:imageInfo.fileName];
                                                  }
                                              }
                                              
                                          } else {
                                              // do nothing, because WISMaintenanceTask initializer has done the initializing job.
                                          }
                                          
                                          maintenanceTask.personInCharge = taskPersonInCharge;
                                          
                                          if (![self.users valueForKey:taskPersonInCharge.userName])
                                              [self.users setValue:taskPersonInCharge forKey:taskPersonInCharge.userName];
                                      } else {
                                          // do nothing, because WISMaintenanceTask initializer has done the initial job.
                                          // _maintenanceTasks[taskID].personInCharge = nil;
                                      }

                                      if (![self.maintenanceTasks valueForKey:taskID]) {
                                          [self.maintenanceTasks setValue:maintenanceTask forKey:taskID];
                                      }
                                      
                                      [updatedData addObject:maintenanceTask];
                                  }
                                  [updatedData sortWithOptions:NSSortConcurrent usingComparator:[WISMaintenanceTask arrayBackwardSorterWithResult]];
                              }
                              
                              
                              [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateMaintenanceTaskBriefInfoSucceededNotification
                                                                                  object:updatedData];
                              
                              if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateMaintenanceTasksBriefInfoSucceeded)]) {
                                  [self.maintenanceTaskOpDelegate updateMaintenanceTasksBriefInfoSucceeded];
                              }
                              handler(YES, nil, NSStringFromClass([updatedData class]), updatedData);
                              break;
                              
                          case RequestFailed:
                              err = [self produceErrorObjectWithWISErrorCode:ErrorCodeInvalidOperation andCallbackError:nil];
                              handler(FALSE, err, @"", nil);
                              
                              [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateMaintenanceTaskBriefInfoFailedNotification
                                                                                  object:(NSError *)err];
                              
                              if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateMaintenanceTasksBriefInfoFailedWithError:)]) {
                                  [self.maintenanceTaskOpDelegate updateMaintenanceTasksBriefInfoFailedWithError:err];
                              }
                              break;
                              
                          default:
                              break;
                      }
                  }
              }
         }];
    }
    
    return dataTask;
}

/// Update Finished Maintenance Task Brief Information Operation And Response Method
- (NSURLSessionDataTask *) updateFinishedMaintenanceTaskBriefInfoWithTaskTypeID:(MaintenanceTaskType)taskTypeID
                                            recordNumberInPage:(NSInteger)numberInPage
                                                     pageIndex:(NSInteger)index
                                             completionHandler:(WISMaintenanceTaskUpdateInfoHandler)handler {
    NSDictionary * updateParams = nil;
    NSURLSessionDataTask *dataTask = nil;
    
    if ([self.currentUser.userName isEqual: @""] || self.currentUser.userName == nil
        || [self.networkRequestToken isEqual: @""] || self.networkRequestToken == nil) {
        
        NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeNoCurrentUserInfo andCallbackError:nil];
        handler(FALSE, err, @"", nil);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateFinishedMaintenanceTaskBriefInfoFailedNotification object:(NSError *)err];
        if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateFinishedMaintenanceTasksBriefInfoFailedWithError:)]) {
            [self.maintenanceTaskOpDelegate updateFinishedMaintenanceTasksBriefInfoFailedWithError:err];
        }
        
    } else {
        
        updateParams = [NSDictionary dictionaryWithObjectsAndKeys:self.currentUser.userName, @"UserName",
                        self.networkRequestToken, @"PassWord", nil];
        
        NSArray *uriSetting = [NSArray arrayWithObjects:
                               [NSString stringWithFormat:@"%ld", (long)taskTypeID],
                               [NSString stringWithFormat:@"%ld", numberInPage],
                               [NSString stringWithFormat:@"%ld", index],
                               nil];
        
        dataTask = [self.networkService dataRequestWithRequestType:UpdateHistoryMaintenanceTasksInfoInPages
                                                            params:updateParams
                                                     andUriSetting:uriSetting
         completionHandler:^(RequestType requestType, NSData *responsedData, NSError *error) {
              if (!responsedData) {
                  NSLog(@"Update Finished MaintenanceTask Brief Info 请求异常，原因: %@", @"返回的数据为空");
                  
                  NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeResponsedNULLData andCallbackError:error];
                  handler(FALSE, err, @"", nil);
                  
                  [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateFinishedMaintenanceTaskBriefInfoFailedNotification object:(NSError *)err];
                  if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateFinishedMaintenanceTasksBriefInfoFailedWithError:)]) {
                      [self.maintenanceTaskOpDelegate updateFinishedMaintenanceTasksBriefInfoFailedWithError:err];
                  }
                  
              } else {
                  
                  NSError *parseError;
                  NSDictionary *parsedData = nil;
                  
                  parsedData = [NSJSONSerialization JSONObjectWithData:responsedData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&parseError];
                  
                  if (!parsedData || parseError) {
                      NSLog(@"Update Finished MaintenanceTask Brief Info 操作解析内容失败，原因: %@", parseError);
                      
                      NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeIncorrectResponsedDataFormat andCallbackError:parseError];
                      handler(FALSE, err, @"", nil);
                      
                      [[NSNotificationCenter defaultCenter]
                       postNotificationName:WISUpdateFinishedMaintenanceTaskBriefInfoFailedNotification
                       object:(NSError *)err];
                      
                      if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateFinishedMaintenanceTasksBriefInfoFailedWithError:)]) {
                          [self.maintenanceTaskOpDelegate updateFinishedMaintenanceTasksBriefInfoFailedWithError:err];
                      }
                      
                  } else {
                      
                      RequestResult result = (RequestResult)[parsedData[@"Result"] integerValue];
                      NSArray *tasks = nil;
                      NSString *taskID = nil;
                      NSInteger taskCount = 0;
                      
                      NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                      [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                      
                      NSError *err;
                      
                      NSMutableArray<WISMaintenanceTask *> *updatedData = [NSMutableArray array];
                      
                      switch (result) {
                          case RequestSuccessful:
                              taskCount = [parsedData[@"Count"] integerValue];
                              
                              if(taskCount <= 0) {
                                  // do nothing
                              } else {
                                  
                                  //
                                  // [self.maintenanceTasks removeAllObjects];
                                  
                                  tasks = parsedData[@"Tasks"];
                                  for(NSDictionary *task in tasks) {
                                      
                                      taskID = [NSString stringWithFormat:@"%@", task[@"TaskId"]];
                                      
                                      WISMaintenanceTask *maintenanceTask = [[WISMaintenanceTask alloc] init];
                                      
                                      maintenanceTask.taskID = taskID;
                                      maintenanceTask.taskName = ((NSNull*)task[@"TaskName"] == [NSNull null]) ? @"" : (NSString *)task[@"TaskName"];
                                      maintenanceTask.taskApplicationContent = ((NSNull*)task[@"Description"] == [NSNull null]) ? @"" : (NSString *)task[@"Description"];
                                      if (task[@"CreateTime"] && !((NSNull*)task[@"CreateTime"] == [NSNull null])) {
                                          // maintenanceTask.createdDateTime = [dateFormatter dateFromString:task[@"CreateTime"]];
                                          maintenanceTask.createdDateTime = [NSDate dateFromDateTimeString:task[@"CreateTime"]];
                                      }
                                      maintenanceTask.state = ((NSNull*)task[@"Status"] == [NSNull null]) ? @"" : (NSString *)task[@"Status"];
                                      maintenanceTask.taskType = taskTypeID;
                                      maintenanceTask.processSegmentName = ((NSNull*)task[@"FaultArea"] == [NSNull null]) ? @"" : (NSString *)task[@"FaultArea"];
                                      
                                      WISUser *taskPersonInCharge = [[WISUser alloc] init];
                                      NSDictionary *personInCharge = (NSDictionary *)task[@"Manager"];
                                      
                                      if (personInCharge && !((NSNull *)personInCharge == [NSNull null])) {
                                          taskPersonInCharge.userName = ((NSNull*)personInCharge[@"UserName"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"UserName"];
                                          taskPersonInCharge.fullName = ((NSNull*)personInCharge[@"Name"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"Name"];
                                          taskPersonInCharge.roleCode = ((NSNull*)personInCharge[@"RoleCode"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"RoleCode"];
                                          taskPersonInCharge.roleName = ((NSNull*)personInCharge[@"RoleName"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"RoleName"];
                                          taskPersonInCharge.cellPhoneNumber = ((NSNull*)personInCharge[@"MobilePhone"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"MobilePhone"];
                                          taskPersonInCharge.telephoneNumber = ((NSNull*)personInCharge[@"Telephone"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"Telephone"];
                                          
                                          maintenanceTask.personInCharge = taskPersonInCharge;
                                          
                                          if (![self.users valueForKey:taskPersonInCharge.userName])
                                              [self.users setValue:taskPersonInCharge forKey:taskPersonInCharge.userName];
                                      } else {
                                          // do nothing, because WISMaintenanceTask initializer has done the initial job.
                                          // _maintenanceTasks[taskID].personInCharge = nil;
                                      }
                                      
                                      if (![self.maintenanceTasks valueForKey:taskID]) {
                                          [self.maintenanceTasks setValue:maintenanceTask forKey:taskID];
                                      }
                                      
                                      [updatedData addObject:maintenanceTask];
                                  }
                                  [updatedData sortWithOptions:NSSortConcurrent usingComparator:[WISMaintenanceTask arrayBackwardSorterWithResult]];
                              }
                              
                              [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateFinishedMaintenanceTaskBriefInfoSucceededNotification
                                                                                  object:updatedData];
                              
                              if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateFinishedMaintenanceTasksBriefInfoSucceeded)]) {
                                  [self.maintenanceTaskOpDelegate updateFinishedMaintenanceTasksBriefInfoSucceeded];
                              }
                              
                              handler(YES, nil, NSStringFromClass([updatedData class]), updatedData);
                              break;
                              
                          case RequestFailed:
                              err = [self produceErrorObjectWithWISErrorCode:ErrorCodeInvalidOperation andCallbackError:nil];
                              handler(FALSE, err, @"", nil);
                              
                              [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateFinishedMaintenanceTaskBriefInfoFailedNotification
                                                                                  object:(NSError *)err];
                              
                              if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateFinishedMaintenanceTasksBriefInfoFailedWithError:)]) {
                                  [self.maintenanceTaskOpDelegate updateFinishedMaintenanceTasksBriefInfoFailedWithError:err];
                              }
                              break;
                              
                          default:
                              break;
                      }
                  }
              }
         }];
    }
    
    return dataTask;
}


/// Update Maintenance Task detail Information Operation And Response Method
- (NSURLSessionDataTask *) updateMaintenanceTaskLessDetailInfoWithTaskID:(NSString *)taskID
                                                   completionHandler:(WISMaintenanceTaskUpdateInfoHandler)handler {
    
    NSDictionary * updateParams = nil;
    NSURLSessionDataTask *dataTask = nil;
    
    if ([self.currentUser.userName isEqual: @""] || self.currentUser.userName == nil
        || [self.networkRequestToken isEqual: @""] || self.networkRequestToken == nil) {
        
        NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeNoCurrentUserInfo andCallbackError:nil];
        handler(FALSE, err, @"", nil);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateMaintenanceTaskLessDetailInfoFailedNotification object:(NSError *)err];
        if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateMaintenanceTaskLessDetailInfoFailedWithError:)]) {
            [self.maintenanceTaskOpDelegate updateMaintenanceTaskLessDetailInfoFailedWithError:err];
        }

    } else {
        
        updateParams = [NSDictionary dictionaryWithObjectsAndKeys:self.currentUser.userName, @"UserName",
                        self.networkRequestToken, @"PassWord", nil];
        
        dataTask = [self.networkService dataRequestWithRequestType:UpdateMaintenanceTaskLessDetailInfo
                                                            params:updateParams
                                                     andUriSetting:[NSArray arrayWithObjects:taskID, nil]
         completionHandler:^(RequestType requestType, NSData *responsedData, NSError *networkError) {
              
              if (!responsedData) {
                  NSLog(@"Update maintenance task less detail info 请求异常，原因: %@", @"返回的数据为空");
                  
                  NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeResponsedNULLData andCallbackError:networkError];
                  handler(FALSE, err, @"", nil);
                  
                  [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateMaintenanceTaskLessDetailInfoFailedNotification
                                                                      object:(NSError *)err];
                  if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateMaintenanceTaskLessDetailInfoFailedWithError:)]) {
                      [self.maintenanceTaskOpDelegate updateMaintenanceTaskLessDetailInfoFailedWithError:err];
                  }

                  
              } else {
                  
                  NSError *parseError;
                  NSDictionary *parsedData = nil;
                  
                  parsedData = [NSJSONSerialization JSONObjectWithData:responsedData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&parseError];
                  
                  if (!parsedData || parseError) {
                      NSLog(@"Update maintenance task less detail info 操作解析内容失败，原因: %@", parseError);
                      
                      NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeIncorrectResponsedDataFormat andCallbackError:parseError];
                      handler(FALSE, err, @"", nil);
                      
                      [[NSNotificationCenter defaultCenter]
                       postNotificationName:WISUpdateMaintenanceTaskLessDetailInfoFailedNotification
                       object:(NSError *)err];
                      
                      if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateMaintenanceTaskLessDetailInfoFailedWithError:)]) {
                          [self.maintenanceTaskOpDelegate updateMaintenanceTaskLessDetailInfoFailedWithError:err];
                      }
                      
                  } else {
                      
                      RequestResult result = (RequestResult)[parsedData[@"Result"] integerValue];
                      NSDictionary *taskDetail = nil;
                      NSMutableArray *operations = nil;
                      
                      WISMaintenanceTask *newMaintenanceTask = nil;
                      
                      WISUser *taskCreator = [[WISUser alloc] init];
                      WISUser *taskPersonInCharge = [[WISUser alloc] init];
                      WISMaintenanceTaskRating *taskRating = [[WISMaintenanceTaskRating alloc] init];
                      
                      NSMutableDictionary *validOperations = [NSMutableDictionary dictionary];
                      NSError *err;
                      
                      switch (result) {
                          /// 请求成功
                          case RequestSuccessful:
                              newMaintenanceTask = [[WISMaintenanceTask alloc] init];
                              newMaintenanceTask.taskID = taskID;
                              
                              // ***********
                              // update valid operations
                              operations = parsedData[@"Privileges"];
                              
                              if(!operations || ((NSNull *)operations == [NSNull null])) {
                                  newMaintenanceTask.validOperations =
                                  [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"NULL Operation",@""), [NSString stringWithFormat:@"%ld", (long)NULLOperation], nil];
                                  
                              } else {
                                  for (NSDictionary *operation in operations) {
                                      [validOperations addEntriesFromDictionary:[NSDictionary
                                                                                 dictionaryWithObject:(NSString *)operation[@"PrivilegeName"]
                                                                                 forKey:[NSString stringWithFormat:@"%@", operation[@"PrivilegeID"]]]];
                                  }
                                  newMaintenanceTask.validOperations = [NSDictionary dictionaryWithDictionary:validOperations];
                              }
                              
                              taskDetail = parsedData[@"Detail"];
                              if(!((NSNull *)taskDetail == [NSNull null])) {
                                  
                                  // ***********
                                  // update creator and person-in-charge
                                  NSDictionary *creator = (NSDictionary *)taskDetail[@"Creator"];
                                  if (creator && !((NSNull *)creator == [NSNull null])) {
                                      taskCreator.userName = ((NSNull*)creator[@"UserName"] == [NSNull null]) ? @"" : (NSString *)creator[@"UserName"];
                                      taskCreator.fullName = ((NSNull*)creator[@"Name"] == [NSNull null]) ? @"" : (NSString *)creator[@"Name"];
                                      taskCreator.roleCode = ((NSNull*)creator[@"RoleCode"] == [NSNull null]) ? @"" : (NSString *)creator[@"RoleCode"];
                                      taskCreator.roleName = ((NSNull*)creator[@"RoleName"] == [NSNull null]) ? @"" : (NSString *)creator[@"RoleName"];
                                      taskCreator.cellPhoneNumber = ((NSNull*)creator[@"MobilePhone"] == [NSNull null]) ? @"" : (NSString *)creator[@"MobilePhone"];
                                      taskCreator.telephoneNumber = ((NSNull*)creator[@"Telephone"] == [NSNull null]) ? @"" : (NSString *)creator[@"Telephone"];
                                      
                                      newMaintenanceTask.creator = taskCreator;
                                      
                                      if (![self.users valueForKey:taskCreator.userName])
                                          [self.users setValue:taskCreator forKey:taskCreator.userName];
                                  } else {
                                      // do nothing, because WISMaintenanceTask initializer has done the initial job.
                                      // _maintenanceTasks[taskID].creator = nil;
                                  }
                                  
                                  NSDictionary *personInCharge = (NSDictionary *)taskDetail[@"Manager"];
                                  
                                  if (personInCharge && !((NSNull *)personInCharge == [NSNull null])) {
                                      taskPersonInCharge.userName = ((NSNull*)personInCharge[@"UserName"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"UserName"];
                                      taskPersonInCharge.fullName = ((NSNull*)personInCharge[@"Name"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"Name"];
                                      taskPersonInCharge.roleCode = ((NSNull*)personInCharge[@"RoleCode"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"RoleCode"];
                                      taskPersonInCharge.roleName = ((NSNull*)personInCharge[@"RoleName"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"RoleName"];
                                      taskPersonInCharge.cellPhoneNumber = ((NSNull*)personInCharge[@"MobilePhone"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"MobilePhone"];
                                      taskPersonInCharge.telephoneNumber = ((NSNull*)personInCharge[@"Telephone"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"Telephone"];
                                      
                                      newMaintenanceTask.personInCharge = taskPersonInCharge;
                                  
                                      if (![self.users valueForKey:taskPersonInCharge.userName])
                                          [self.users setValue:taskPersonInCharge forKey:taskPersonInCharge.userName];
                                  } else {
                                      // do nothing, because WISMaintenanceTask initializer has done the initial job.
                                      // _maintenanceTasks[taskID].personInCharge = nil;
                                  }
                                  
                                  // ***********
                                  // application content
                                  newMaintenanceTask.taskApplicationContent = ((NSNull*)taskDetail[@"Description"] == [NSNull null]) ? @"" : (NSString *)taskDetail[@"Description"];
                                  
                                  // ***********
                                  // archiving remark
                                  newMaintenanceTask.archivingRemark = ((NSNull*)taskDetail[@"ArchivedDescription"] == [NSNull null]) ? @"" : (NSString *)taskDetail[@"ArchivedDescription"];
                                  
                                  // ***********
                                  // task comment
                                  newMaintenanceTask.taskComment = ((NSNull*)taskDetail[@"Comment"] == [NSNull null]) ? @"" : (NSString *)taskDetail[@"Comment"];
                                  
                                  // ***********
                                  // task finished remark
                                  // for the interface in the future
                                  
                                  // ***********
                                  // task dispute procedure remark
                                  // for the interface in the future
                                  
                                  // ***********
                                  // process segment
                                  newMaintenanceTask.processSegmentName = ((NSNull*)taskDetail[@"FaultArea"] == [NSNull null]) ? @"" : (NSString *)taskDetail[@"FaultArea"];
                                  
                                  // ***********
                                  // task name
                                  newMaintenanceTask.taskName = ((NSNull*)taskDetail[@"TaskName"] == [NSNull null]) ? @"" : (NSString *)taskDetail[@"TaskName"];
                                  
                                  // ***********
                                  // task created time
                                  if (taskDetail[@"CreateTime"] && !((NSNull *)taskDetail[@"CreateTime"] == [NSNull null])) {
                                      newMaintenanceTask.createdDateTime = [NSDate dateFromDateTimeString:(NSString *)taskDetail[@"CreateTime"]];
                                  } else {
                                      // do nothing, because WISMaintenanceTask initializer has done the initial job.
                                      // plan.estimatedEndingTime = nil;
                                  }
                                  
                                  // ***********
                                  // task status
                                  newMaintenanceTask.state = ((NSNull*)taskDetail[@"TaskStatus"] == [NSNull null]) ? @"" : (NSString *)taskDetail[@"TaskStatus"];
                                  
                                  // ***********
                                  // task archived state
                                  NSString *isArchivedString = (NSString *)taskDetail[@"Archived"];
                                  newMaintenanceTask.archived = ([isArchivedString integerValue] == 0) ? false : true;
                                  
                                  // ***********
                                  // task rating
                                  NSDictionary *rating = (NSDictionary *)taskDetail[@"Remark"];
                                  
                                  if (rating && !((NSNull *)rating == [NSNull null])) {
                                      taskRating.additionalRemark = ((NSNull*)rating[@"Description"] == [NSNull null]) ? @"" : (NSString *)rating[@"Description"];
                                      taskRating.totalScore = ((NSNull*)rating[@"Score"] == [NSNull null]) ? 0 : [(NSString *)rating[@"Score"] integerValue];
                                      taskRating.attitudeScore = ((NSNull*)rating[@"AttitudeScore"] == [NSNull null]) ? 0 : [(NSString *)rating[@"AttitudeScore"] integerValue];
                                      taskRating.qualityScore = ((NSNull*)rating[@"QualityScore"] == [NSNull null]) ? 0 : [(NSString *)rating[@"QualityScore"] integerValue];
                                      taskRating.responseScore = ((NSNull*)rating[@"ResponseScore"] == [NSNull null]) ? 0 : [(NSString *)rating[@"ResponseScore"] integerValue];
                                      
                                      newMaintenanceTask.taskRating = taskRating;
                                  } else {
                                      // do nothing, because WISMaintenanceTask initializer has done the initial job.
                                      // _maintenanceTasks[taskID].personInCharge = nil;
                                  }
                                  
                                  // ***********
                                  //images info - MaintenanceTask
                                  NSArray *imagesURL = (NSArray *)taskDetail[@"FileURL"];
                                  if (imagesURL && !((NSNull *)imagesURL == [NSNull null])) {
                                      for (NSString *url in imagesURL) {
                                          WISFileInfo *imageInfo = [WISDataManager produceFileInfoWithFileRemoteURL:url];
                                          
                                          if (![newMaintenanceTask.imagesInfo valueForKey:imageInfo.fileName]) {
                                              [newMaintenanceTask.imagesInfo setValue:imageInfo forKey:imageInfo.fileName];
                                          }
                                      }
                                      
                                  } else {
                                      // ** test **
                                      NSString *fileFullName = @"E:\\FTP\\MM\\taskID-213-iOS-E5EF893D-CB29-434A-AAC6-70E882F999CC.20160321160616.png";
                                      NSArray *fileFullNameComponent = [fileFullName componentsSeparatedByString:@"\\"];
                                                                        
                                      NSString *fileNameTest = [fileFullNameComponent objectAtIndex:(fileFullNameComponent.count - 1)];
                                      // NSString *ex = [fileNameTest pathExtension];
                                      NSString *fileNamePure = [[fileNameTest componentsSeparatedByString:@"."] objectAtIndex:0];
                                      
                                      fileNamePure = fileNamePure;
                                      
                                      // do nothing, because WISMaintenanceTask initializer has done the initializing job.
                                  }
                                  
                                  // ***********
                                  // maintenance plan
                                  NSDictionary *planDic = (NSDictionary *)taskDetail[@"PlanInformation"];
                                  if (planDic && !((NSNull *)planDic == [NSNull null])) {
                                      WISMaintenancePlan *plan = [[WISMaintenancePlan alloc] init];
                                      
                                      plan.planDescription = ((NSNull*)planDic[@"Description"] == [NSNull null]) ? @"" : (NSString *)planDic[@"Description"];
                                      
                                      if (planDic[@"EstimatedTime"] && !((NSNull *)planDic[@"EstimatedTime"] == [NSNull null])) {
                                          // plan.estimatedEndingTime = [dateFormatter dateFromString:(NSString *)planDic[@"EstimatedTime"]];
                                          plan.estimatedEndingTime = [NSDate dateFromDateTimeString:(NSString *)planDic[@"EstimatedTime"]];
                                      } else {
                                          // do nothing, because WISMaintenanceTask initializer has done the initial job.
                                          // plan.estimatedEndingTime = nil;
                                      }
                                      
                                      if (planDic[@"UpdateTime"] && !((NSNull *)planDic[@"UpdateTime"] == [NSNull null])) {
                                          plan.updatedTime = [NSDate dateFromDateTimeString:(NSString *)planDic[@"UpdateTime"]];
                                      } else {
                                          // do nothing
                                      }
                                      
                                      NSMutableArray<NSDictionary *> *participants = planDic[@"Participants"];
                                      if (participants && !((NSNull *)participants == [NSNull null])) {
                                          if (participants.count > 0)
                                              for (NSDictionary *participant in participants) {
                                                  WISUser *planParticipant = [[WISUser alloc] init];
                                                  planParticipant.userName = ((NSNull*)participant[@"UserName"] == [NSNull null]) ? @"" : (NSString *)participant[@"UserName"];
                                                  planParticipant.fullName = ((NSNull*)participant[@"Name"] == [NSNull null]) ? @"" : (NSString *)participant[@"Name"];
                                                  planParticipant.roleCode = ((NSNull*)participant[@"RoleCode"] == [NSNull null]) ? @"" : (NSString *)participant[@"RoleCode"];
                                                  planParticipant.roleName = ((NSNull*)participant[@"RoleName"] == [NSNull null]) ? @"" : (NSString *)participant[@"RoleName"];
                                                  planParticipant.cellPhoneNumber = ((NSNull*)participant[@"MobilePhone"] == [NSNull null]) ? @"" : (NSString *)participant[@"MobilePhone"];
                                                  planParticipant.telephoneNumber = ((NSNull*)participant[@"TelePhone"] == [NSNull null]) ? @"" : (NSString *)participant[@"TelePhone"];
                                                  
                                                  [plan.participants addObject:planParticipant];
                                                  
                                                  if (![self.users valueForKey:planParticipant.userName])
                                                      [self.users setValue:planParticipant forKey:planParticipant.userName];
                                              }
                                      } else {
                                          // do nothing
                                      }
                                      
                                      //images info - MaintenanceTask plan
                                      NSArray *imagesURL = (NSArray *)planDic[@"FileURL"];
                                      if (imagesURL && !((NSNull *)imagesURL == [NSNull null])) {
                                          for (NSString *url in imagesURL) {
                                              WISFileInfo *imageInfo = [WISDataManager produceFileInfoWithFileRemoteURL:url];
                                              
                                              if (![plan.imagesInfo valueForKey:imageInfo.fileName]) {
                                                  [plan.imagesInfo setValue:imageInfo forKey:imageInfo.fileName];
                                              }
                                          }
                                          
                                      } else {
                                          // do nothing, because WISMaintenanceTask initializer has done the initializing job.
                                      }
                                      
                                      [newMaintenanceTask.maintenancePlans addObject:plan];
                                      
                                  } else {
                                      // do nothing, because WISMaintenanceTask initializer has done the initializing job.
                                  }
                              }
                              
                              if (![_maintenanceTasks valueForKey:taskID]) {
                                  [_maintenanceTasks addEntriesFromDictionary:[NSDictionary dictionaryWithObject:newMaintenanceTask forKey:taskID]];
                              }
                              
                              [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateMaintenanceTaskLessDetailInfoSucceededNotification
                                                                                  object:[_maintenanceTasks[taskID] copy]];
                              
                              if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateMaintenanceTaskLessDetailInfoSucceeded)]) {
                                  [self.maintenanceTaskOpDelegate updateMaintenanceTaskLessDetailInfoSucceeded];
                              }

                              handler(YES, nil, NSStringFromClass([newMaintenanceTask class]), newMaintenanceTask);
                              break;
                              
                          /// 请求失败
                          case RequestFailed:
                              err = [self produceErrorObjectWithWISErrorCode:ErrorCodeInvalidOperation andCallbackError:nil];
                              handler(FALSE, err, @"", nil);
                              
                              [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateMaintenanceTaskLessDetailInfoFailedNotification
                                                                                  object:(NSError *)err];
                              
                              if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateMaintenanceTaskLessDetailInfoFailedWithError:)]) {
                                  [self.maintenanceTaskOpDelegate updateMaintenanceTaskLessDetailInfoFailedWithError:err];
                              }

                              break;
                              
                          default:
                              break;
                      }
                  }
              }
         }];
    }
    return dataTask;
}


- (NSURLSessionDataTask *) updateMaintenanceTaskDetailInfoWithTaskID:(NSString *)taskID
                                                       completionHandler:(WISMaintenanceTaskUpdateInfoHandler)handler {
    
    NSDictionary * updateParams = nil;
    NSURLSessionDataTask *dataTask = nil;
    
    if ([self.currentUser.userName isEqual: @""] || self.currentUser.userName == nil
        || [self.networkRequestToken isEqual: @""] || self.networkRequestToken == nil) {
        
        NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeNoCurrentUserInfo andCallbackError:nil];
        handler(FALSE, err, @"", nil);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateMaintenanceTaskDetailInfoFailedNotification object:(NSError *)err];
        if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateMaintenanceTaskDetailInfoFailedWithError:)]) {
            [self.maintenanceTaskOpDelegate updateMaintenanceTaskDetailInfoFailedWithError:err];
        }
        
    } else {
        
        updateParams = [NSDictionary dictionaryWithObjectsAndKeys:self.currentUser.userName, @"UserName",
                        self.networkRequestToken, @"PassWord", nil];
        
        dataTask = [self.networkService dataRequestWithRequestType:UpdateMaintenanceTaskDetailInfo
                                                            params:updateParams
                                                     andUriSetting:[NSArray arrayWithObjects:taskID, nil]
        completionHandler:^(RequestType requestType, NSData *responsedData, NSError *networkError) {
                                                     
            if (!responsedData) {
                NSLog(@"Update maintenance task detail info 请求异常，原因: %@", @"返回的数据为空");
                
                NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeResponsedNULLData andCallbackError:networkError];
                handler(FALSE, err, @"", nil);
                
                [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateMaintenanceTaskDetailInfoFailedNotification
                                                                    object:(NSError *)err];
                if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateMaintenanceTaskDetailInfoFailedWithError:)]) {
                    [self.maintenanceTaskOpDelegate updateMaintenanceTaskDetailInfoFailedWithError:err];
                }
                
            } else {
                
                NSError *parseError;
                NSDictionary *parsedData = nil;
                
                parsedData = [NSJSONSerialization JSONObjectWithData:responsedData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&parseError];
                
                if (!parsedData || parseError) {
                    NSLog(@"Update maintenance task detail info 操作解析内容失败，原因: %@", parseError);
                    
                    NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeIncorrectResponsedDataFormat andCallbackError:parseError];
                    handler(FALSE, err, @"", nil);
                    
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:WISUpdateMaintenanceTaskDetailInfoFailedNotification
                     object:(NSError *)err];
                    
                    if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateMaintenanceTaskDetailInfoFailedWithError:)]) {
                        [self.maintenanceTaskOpDelegate updateMaintenanceTaskDetailInfoFailedWithError:err];
                    }
                    
                } else {
                    
                    RequestResult result = (RequestResult)[parsedData[@"Result"] integerValue];
                    NSDictionary *taskDetail = nil;
                    NSMutableArray *operations = nil;
                    
                    WISMaintenanceTask *newMaintenanceTask = nil;
                    
                    WISUser *taskCreator = [[WISUser alloc] init];
                    WISUser *taskPersonInCharge = [[WISUser alloc] init];
                    WISMaintenanceTaskRating *taskRating = [[WISMaintenanceTaskRating alloc] init];
                    
                    NSMutableDictionary *validOperations = [NSMutableDictionary dictionary];
                    NSError *err;
                    
                    switch (result) {
                            /// 请求成功
                        case RequestSuccessful:
                            newMaintenanceTask = [[WISMaintenanceTask alloc] init];
                            newMaintenanceTask.taskID = taskID;
                            
                            // ***********
                            // update valid operations
                            operations = parsedData[@"Privileges"];
                            
                            if(!operations || ((NSNull *)operations == [NSNull null])) {
                                newMaintenanceTask.validOperations =
                                [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"NULL Operation",@""), [NSString stringWithFormat:@"%ld", (long)NULLOperation], nil];
                                
                            } else {
                                for (NSDictionary *operation in operations) {
                                    [validOperations addEntriesFromDictionary:[NSDictionary
                                                                               dictionaryWithObject:(NSString *)operation[@"PrivilegeName"]
                                                                               forKey:[NSString stringWithFormat:@"%@", operation[@"PrivilegeID"]]]];
                                }
                                newMaintenanceTask.validOperations = [NSDictionary dictionaryWithDictionary:validOperations];
                            }
                            
                            taskDetail = parsedData[@"Detail"];
                            if(!((NSNull *)taskDetail == [NSNull null])) {
                                
                                // ***********
                                // update creator and person-in-charge
                                NSDictionary *creator = (NSDictionary *)taskDetail[@"Creator"];
                                if (creator && !((NSNull *)creator == [NSNull null])) {
                                    taskCreator.userName = ((NSNull*)creator[@"UserName"] == [NSNull null]) ? @"" : (NSString *)creator[@"UserName"];
                                    taskCreator.fullName = ((NSNull*)creator[@"Name"] == [NSNull null]) ? @"" : (NSString *)creator[@"Name"];
                                    taskCreator.roleCode = ((NSNull*)creator[@"RoleCode"] == [NSNull null]) ? @"" : (NSString *)creator[@"RoleCode"];
                                    taskCreator.roleName = ((NSNull*)creator[@"RoleName"] == [NSNull null]) ? @"" : (NSString *)creator[@"RoleName"];
                                    taskCreator.cellPhoneNumber = ((NSNull*)creator[@"MobilePhone"] == [NSNull null]) ? @"" : (NSString *)creator[@"MobilePhone"];
                                    taskCreator.telephoneNumber = ((NSNull*)creator[@"Telephone"] == [NSNull null]) ? @"" : (NSString *)creator[@"Telephone"];
                                    
                                    newMaintenanceTask.creator = taskCreator;
                                    
                                    if (![self.users valueForKey:taskCreator.userName])
                                        [self.users setValue:taskCreator forKey:taskCreator.userName];
                                } else {
                                    // do nothing, because WISMaintenanceTask initializer has done the initial job.
                                    // _maintenanceTasks[taskID].creator = nil;
                                }
                                
                                NSDictionary *personInCharge = (NSDictionary *)taskDetail[@"Manager"];
                                
                                if (personInCharge && !((NSNull *)personInCharge == [NSNull null])) {
                                    taskPersonInCharge.userName = ((NSNull*)personInCharge[@"UserName"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"UserName"];
                                    taskPersonInCharge.fullName = ((NSNull*)personInCharge[@"Name"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"Name"];
                                    taskPersonInCharge.roleCode = ((NSNull*)personInCharge[@"RoleCode"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"RoleCode"];
                                    taskPersonInCharge.roleName = ((NSNull*)personInCharge[@"RoleName"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"RoleName"];
                                    taskPersonInCharge.cellPhoneNumber = ((NSNull*)personInCharge[@"MobilePhone"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"MobilePhone"];
                                    taskPersonInCharge.telephoneNumber = ((NSNull*)personInCharge[@"Telephone"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"Telephone"];
                                    
                                    newMaintenanceTask.personInCharge = taskPersonInCharge;
                                    
                                    if (![self.users valueForKey:taskPersonInCharge.userName])
                                        [self.users setValue:taskPersonInCharge forKey:taskPersonInCharge.userName];
                                } else {
                                    // do nothing, because WISMaintenanceTask initializer has done the initial job.
                                    // _maintenanceTasks[taskID].personInCharge = nil;
                                }
                                
                                // ***********
                                // application content
                                newMaintenanceTask.taskApplicationContent = ((NSNull*)taskDetail[@"Description"] == [NSNull null]) ? @"" : (NSString *)taskDetail[@"Description"];
                                
                                // ***********
                                // archiving remark
                                newMaintenanceTask.archivingRemark = ((NSNull*)taskDetail[@"ArchivedDescription"] == [NSNull null]) ? @"" : (NSString *)taskDetail[@"ArchivedDescription"];
                                
                                // ***********
                                // task comment
                                newMaintenanceTask.taskComment = ((NSNull*)taskDetail[@"Comment"] == [NSNull null]) ? @"" : (NSString *)taskDetail[@"Comment"];
                                
                                // ***********
                                // task finished remark
                                // for the interface in the future
                                
                                // ***********
                                // task dispute procedure remark
                                // for the interface in the future
                                
                                // ***********
                                // process segment
                                newMaintenanceTask.processSegmentName = ((NSNull*)taskDetail[@"FaultArea"] == [NSNull null]) ? @"" : (NSString *)taskDetail[@"FaultArea"];
                                
                                // ***********
                                // task name
                                newMaintenanceTask.taskName = ((NSNull*)taskDetail[@"TaskName"] == [NSNull null]) ? @"" : (NSString *)taskDetail[@"TaskName"];
                                
                                // ***********
                                // task created time
                                if (taskDetail[@"CreateTime"] && !((NSNull *)taskDetail[@"CreateTime"] == [NSNull null])) {
                                    newMaintenanceTask.createdDateTime = [NSDate dateFromDateTimeString:(NSString *)taskDetail[@"CreateTime"]];
                                } else {
                                    // do nothing, because WISMaintenanceTask initializer has done the initial job.
                                    // plan.estimatedEndingTime = nil;
                                }
                                
                                // ***********
                                // task state
                                newMaintenanceTask.state = ((NSNull*)taskDetail[@"TaskStatus"] == [NSNull null]) ? @"" : (NSString *)taskDetail[@"TaskStatus"];
                                
                                // ***********
                                // task archived state
                                NSString *isArchivedString = (NSString *)taskDetail[@"Archived"];
                                newMaintenanceTask.archived = ([isArchivedString integerValue] == 0) ? false : true;
                                
                                // ***********
                                // task rating
                                NSDictionary *rating = (NSDictionary *)taskDetail[@"Remark"];
                                
                                if (rating && !((NSNull *)rating == [NSNull null])) {
                                    taskRating.additionalRemark = ((NSNull*)rating[@"Description"] == [NSNull null]) ? @"" : (NSString *)rating[@"Description"];
                                    taskRating.totalScore = ((NSNull*)rating[@"Score"] == [NSNull null]) ? 0 : [(NSString *)rating[@"Score"] integerValue];
                                    taskRating.attitudeScore = ((NSNull*)rating[@"AttitudeScore"] == [NSNull null]) ? 0 : [(NSString *)rating[@"AttitudeScore"] integerValue];
                                    taskRating.qualityScore = ((NSNull*)rating[@"QualityScore"] == [NSNull null]) ? 0 : [(NSString *)rating[@"QualityScore"] integerValue];
                                    taskRating.responseScore = ((NSNull*)rating[@"ResponseScore"] == [NSNull null]) ? 0 : [(NSString *)rating[@"ResponseScore"] integerValue];
                                    
                                    newMaintenanceTask.taskRating = taskRating;
                                } else {
                                    // do nothing, because WISMaintenanceTask initializer has done the initial job.
                                    // _maintenanceTasks[taskID].personInCharge = nil;
                                }
                                
                                // ***********
                                // task passed states
                                NSArray *states = taskDetail[@"TaskProcessInformation"];
                                
                                if (states && !((NSNull *)states == [NSNull null])) {
                                    if (states.count > 0) {
                                        for (NSDictionary *stateDic in states) {
                                            WISMaintenanceTaskState *taskState = [[WISMaintenanceTaskState alloc]init];
                                            taskState.state = ((NSNull*)stateDic[@"StatusName"] == [NSNull null]) ? @"" : (NSString *)stateDic[@"StatusName"];
                                            if (stateDic[@"StartTime"] && !((NSNull *)stateDic[@"EndTime"] == [NSNull null])) {
                                                taskState.startTime = [NSDate dateFromDateTimeString:(NSString *)stateDic[@"StartTime"]];
                                            }
                                            if (stateDic[@"EndTime"] && !((NSNull *)stateDic[@"EndTime"] == [NSNull null])) {
                                                taskState.endTime = [NSDate dateFromDateTimeString:(NSString *)stateDic[@"EndTime"]];
                                            }
                                            NSDictionary *userState = stateDic[@"User"];
                                            if(userState && !((NSNull *)userState == [NSNull null])) {
                                                taskState.personInCharge.userName = ((NSNull*)userState[@"UserName"] == [NSNull null]) ? @"" : (NSString *)userState[@"UserName"];
                                                taskState.personInCharge.fullName = ((NSNull*)userState[@"Name"] == [NSNull null]) ? @"" : (NSString *)userState[@"Name"];
                                                taskState.personInCharge.roleCode = ((NSNull*)userState[@"RoleCode"] == [NSNull null]) ? @"" : (NSString *)userState[@"RoleCode"];
                                                taskState.personInCharge.roleName = ((NSNull*)userState[@"RoleName"] == [NSNull null]) ? @"" : (NSString *)userState[@"RoleName"];
                                                taskState.personInCharge.telephoneNumber = ((NSNull*)userState[@"Telephone"] == [NSNull null]) ? @"" : (NSString *)userState[@"Telephone"];
                                                taskState.personInCharge.cellPhoneNumber = ((NSNull*)userState[@"MobilePhone"] == [NSNull null]) ? @"" : (NSString *)userState[@"MobilePhone"];
                                            }
                                            [newMaintenanceTask.passedStates addObject:taskState];
                                        }
                                    }
                                }
                                [newMaintenanceTask.passedStates sortWithOptions:NSSortConcurrent usingComparator:WISMaintenanceTaskState.arrayForwardSorterWithResult];
                                
                                // ***********
                                //images info - MaintenanceTask
                                NSArray *imagesURL = (NSArray *)taskDetail[@"FileURL"];
                                if (imagesURL && !((NSNull *)imagesURL == [NSNull null])) {
                                    for (NSString *url in imagesURL) {
                                        WISFileInfo *imageInfo = [WISDataManager produceFileInfoWithFileRemoteURL:url];
                                        
                                        if (![newMaintenanceTask.imagesInfo valueForKey:imageInfo.fileName]) {
                                            [newMaintenanceTask.imagesInfo setValue:imageInfo forKey:imageInfo.fileName];
                                        }
                                    }
                                    
                                } else {
                                    // ** test **
                                    NSString *fileFullName = @"E:\\FTP\\MM\\taskID-213-iOS-E5EF893D-CB29-434A-AAC6-70E882F999CC.20160321160616.png";
                                    NSArray *fileFullNameComponent = [fileFullName componentsSeparatedByString:@"\\"];
                                    
                                    NSString *fileNameTest = [fileFullNameComponent objectAtIndex:(fileFullNameComponent.count - 1)];
                                    // NSString *ex = [fileNameTest pathExtension];
                                    NSString *fileNamePure = [[fileNameTest componentsSeparatedByString:@"."] objectAtIndex:0];
                                    
                                    fileNamePure = fileNamePure;
                                    
                                    // do nothing, because WISMaintenanceTask initializer has done the initializing job.
                                }
                                
                                // ***********
                                // maintenance plans
                                NSArray *plans = (NSArray *)taskDetail[@"PlanInformations"];
                                if (plans && !((NSNull *)plans == [NSNull null])) {
                                    if (plans.count > 0) {
                                        for (NSDictionary *planDic in plans) {
                                            WISMaintenancePlan *plan = [[WISMaintenancePlan alloc] init];
                                            
                                            plan.planDescription = ((NSNull*)planDic[@"Description"] == [NSNull null]) ? @"" : (NSString *)planDic[@"Description"];
                                            
                                            if (planDic[@"EstimatedTime"] && !((NSNull *)planDic[@"EstimatedTime"] == [NSNull null])) {
                                                // plan.estimatedEndingTime = [dateFormatter dateFromString:(NSString *)planDic[@"EstimatedTime"]];
                                                plan.estimatedEndingTime = [NSDate dateFromDateTimeString:(NSString *)planDic[@"EstimatedTime"]];
                                            } else {
                                                // do nothing, because WISMaintenanceTask initializer has done the initial job.
                                                // plan.estimatedEndingTime = nil;
                                            }
                                            
                                            if (planDic[@"UpdateTime"] && !((NSNull *)planDic[@"UpdateTime"] == [NSNull null])) {
                                                plan.updatedTime = [NSDate dateFromDateTimeString:(NSString *)planDic[@"UpdateTime"]];
                                            } else {
                                                // do nothing
                                            }
                                            
                                            NSMutableArray<NSDictionary *> *participants = planDic[@"Participants"];
                                            if (participants && !((NSNull *)participants == [NSNull null])) {
                                                if (participants.count > 0) {
                                                    for (NSDictionary *participant in participants) {
                                                        WISUser *planParticipant = [[WISUser alloc] init];
                                                        planParticipant.userName = ((NSNull*)participant[@"UserName"] == [NSNull null]) ? @"" : (NSString *)participant[@"UserName"];
                                                        planParticipant.fullName = ((NSNull*)participant[@"Name"] == [NSNull null]) ? @"" : (NSString *)participant[@"Name"];
                                                        planParticipant.roleCode = ((NSNull*)participant[@"RoleCode"] == [NSNull null]) ? @"" : (NSString *)participant[@"RoleCode"];
                                                        planParticipant.roleName = ((NSNull*)participant[@"RoleName"] == [NSNull null]) ? @"" : (NSString *)participant[@"RoleName"];
                                                        planParticipant.cellPhoneNumber = ((NSNull*)participant[@"MobilePhone"] == [NSNull null]) ? @"" : (NSString *)participant[@"MobilePhone"];
                                                        planParticipant.telephoneNumber = ((NSNull*)participant[@"TelePhone"] == [NSNull null]) ? @"" : (NSString *)participant[@"TelePhone"];
                                                        
                                                        [plan.participants addObject:planParticipant];
                                                        
                                                        if (![self.users valueForKey:planParticipant.userName]) {
                                                            [self.users setValue:planParticipant forKey:planParticipant.userName];
                                                        }
                                                    }
                                                }
                                                
                                            } else {
                                                // do nothing
                                            }
                                            
                                            //images info - MaintenanceTask plan
                                            NSArray *imagesURL = (NSArray *)planDic[@"FileURL"];
                                            if (imagesURL && !((NSNull *)imagesURL == [NSNull null])) {
                                                for (NSString *url in imagesURL) {
                                                    WISFileInfo *imageInfo = [WISDataManager produceFileInfoWithFileRemoteURL:url];
                                                    
                                                    if (![plan.imagesInfo valueForKey:imageInfo.fileName]) {
                                                        [plan.imagesInfo setValue:imageInfo forKey:imageInfo.fileName];
                                                    }
                                                }
                                                
                                            } else {
                                                // do nothing, because WISMaintenanceTask initializer has done the initializing job.
                                            }
                                            
                                            [newMaintenanceTask.maintenancePlans addObject:plan];
                                        }
                                    }
                                    
                                } else {
                                    // do nothing, because WISMaintenanceTask initializer has done the initializing job.
                                }
                                [newMaintenanceTask.maintenancePlans sortWithOptions:NSSortConcurrent usingComparator:WISMaintenancePlan.arrayForwardSorterWithResult];
                            }
                            
                            if (![_maintenanceTasks valueForKey:taskID]) {
                                [_maintenanceTasks addEntriesFromDictionary:[NSDictionary dictionaryWithObject:newMaintenanceTask forKey:taskID]];
                            }
                            
                            [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateMaintenanceTaskDetailInfoSucceededNotification
                                                                                object:newMaintenanceTask];
                            
                            if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateMaintenanceTaskDetailInfoSucceeded)]) {
                                [self.maintenanceTaskOpDelegate updateMaintenanceTaskDetailInfoSucceeded];
                            }
                            
                            handler(YES, nil, NSStringFromClass([newMaintenanceTask class]), newMaintenanceTask);
                            break;
                            
                            /// 请求失败
                        case RequestFailed:
                            err = [self produceErrorObjectWithWISErrorCode:ErrorCodeInvalidOperation andCallbackError:nil];
                            handler(FALSE, err, @"", nil);
                            
                            [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateMaintenanceTaskDetailInfoFailedNotification
                                                                                object:(NSError *)err];
                            
                            if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(updateMaintenanceTaskDetailInfoFailedWithError:)]) {
                                [self.maintenanceTaskOpDelegate updateMaintenanceTaskDetailInfoFailedWithError:err];
                            }
                            
                            break;
                            
                        default:
                            break;
                    }
                }
            }
        }];
    }
    return dataTask;
}


- (NSURLSessionDataTask *) applyNewMaintenanceTaskWithApplicationContent:(NSString *)applicationContent
                                                        processSegmentID:(NSString *)processSegmentID
                                                    applicationImageInfo:(NSDictionary<NSString *, WISFileInfo *> *)applicationImagesInfo
                                                       completionHandler:(WISMaintenanceTaskOperationHandler)handler {
    return [self maintenanceTaskOperationWithTaskID:@""
                                             remark:@""
                                      operationType:SubmitApply
                                   taskReceiverName:@""
                                 applicationContent:applicationContent
                                   processSegmentID:[processSegmentID integerValue]
                               applicationImageInfo:applicationImagesInfo
                 maintenancePlanEstimatedEndingTime:nil
                         maintenancePlanDescription:@""
                        maintenancePlanParticipants:nil
                                      taskImageInfo:nil
                                         taskRating:nil
                               andCompletionHandler:handler];
}


- (NSURLSessionDataTask *) maintenanceTaskOperationWithTaskID:(NSString *) taskID
                                                       remark:(NSString *) remark
                                                operationType:(MaintenanceTaskOperationType) operationType
                                             taskReceiverName:(NSString *) taskReceiverName /*转单时用. 非转单时填@""*/
                           maintenancePlanEstimatedEndingTime:(NSDate *) maintenancePlanEstimatedEndingTime
                                   maintenancePlanDescription:(NSString *) maintenancePlanDescription
                                  maintenancePlanParticipants:(NSArray <WISUser *> *) maintenancePlanParticipants
                                                taskImageInfo:(NSDictionary<NSString *, WISFileInfo *> *)taskImagesInfo
                                                   taskRating:(WISMaintenanceTaskRating *) taskRating
                                         andCompletionHandler:(WISMaintenanceTaskOperationHandler) handler {
    
    return [self maintenanceTaskOperationWithTaskID:taskID
                                             remark:remark
                                      operationType:operationType
                                   taskReceiverName:taskReceiverName
                                 applicationContent:@""
                                   processSegmentID:0
                               applicationImageInfo:nil
                 maintenancePlanEstimatedEndingTime:maintenancePlanEstimatedEndingTime
                         maintenancePlanDescription:maintenancePlanDescription
                        maintenancePlanParticipants:maintenancePlanParticipants
                                      taskImageInfo:taskImagesInfo
                                         taskRating:taskRating
                               andCompletionHandler:handler];
}


#pragma mark - Update Inspection Information
- (NSURLSessionDataTask *) updateInspectionInfoWithDeviceID:(NSString *) deviceID completionHandler:(WISInspectionTaskUpdateInfoHandler) handler {
    NSDictionary * updateParams = nil;
    NSURLSessionDataTask *dataTask = nil;
    
    if ([self.currentUser.userName isEqual: @""] || self.currentUser.userName == nil
        || [self.networkRequestToken isEqual: @""] || self.networkRequestToken == nil) {
        
        NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeNoCurrentUserInfo andCallbackError:nil];
        handler(FALSE, err, @"", nil);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateInspectionInfoFailedNotification object:(NSError *)err];
        if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(updateInspectionInfoFailedWithError:)]) {
            [self.inspectionTaskOpDelegate updateInspectionInfoFailedWithError:err];
        }
        
    } else {
        
        updateParams = [NSDictionary dictionaryWithObjectsAndKeys:self.currentUser.userName, @"UserName",
                        self.networkRequestToken, @"PassWord", nil];
        
        dataTask = [self.networkService dataRequestWithRequestType:UpdateInspectionInfo
                                                            params:updateParams
                                                     andUriSetting:[NSArray arrayWithObjects:deviceID, nil]
        completionHandler:^(RequestType requestType, NSData *responsedData, NSError *error) {
            if (!responsedData) {
                NSLog(@"Update Inspection Info 请求异常，原因: %@", @"返回的数据为空");
                
                NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeResponsedNULLData andCallbackError:error];
                handler(FALSE, err, @"", nil);
                
                [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateInspectionInfoFailedNotification object:(NSError *)err];
                if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(updateInspectionInfoFailedWithError:)]) {
                    [self.inspectionTaskOpDelegate updateInspectionInfoFailedWithError:err];
                }
                
            } else {
                
                NSError *parseError;
                NSDictionary *parsedData = nil;
                
                parsedData = [NSJSONSerialization JSONObjectWithData:responsedData
                                                              options:NSJSONReadingMutableContainers
                                                                error:&parseError];
                
                if (!parsedData || parseError) {
                    NSLog(@"Update Inspection Info 操作解析内容失败，原因: %@", parseError);
                    
                    NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeIncorrectResponsedDataFormat andCallbackError:parseError];
                    handler(FALSE, err, @"", nil);
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateInspectionInfoFailedNotification object:(NSError *)err];
                    if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(updateInspectionInfoFailedWithError:)]) {
                        [self.inspectionTaskOpDelegate updateInspectionInfoFailedWithError:err];
                    }
                    
                 } else {
                     
                     RequestResult result = (RequestResult)[parsedData[@"Result"] integerValue];
                     NSDictionary *inspection = nil;
                     NSError *err;
                     WISInspectionTask *updatedData = nil;
                     
                     switch (result) {
                         case RequestSuccessful:
                             inspection = parsedData[@"Inspection"];
                             
                             if (inspection && !((NSNull *)inspection == [NSNull null])) {
                                 WISInspectionTask *inspectionTask = [[WISInspectionTask alloc]init];
                                 
                                 // DEVICE INFORMATION
                                 inspectionTask.device.deviceID = [NSString stringWithFormat:@"%@", inspection[@"DeviceId"]];
                                 inspectionTask.device.deviceName = ((NSNull*)inspection[@"DeviceName"] == [NSNull null]) ? @"" : (NSString *)inspection[@"DeviceName"];
                                 inspectionTask.device.deviceCode = ((NSNull*)inspection[@"DeviceCode"] == [NSNull null]) ? @"" : (NSString *)inspection[@"DeviceCode"];
                                 inspectionTask.device.putIntoServiceTime = ((NSNull*)inspection[@"DeviceServiceTime"] == [NSNull null]) ? [NSDate date] : [NSDate dateFromDateTimeString:(NSString *)inspection[@"DeviceServiceTime"]];
                                 inspectionTask.device.company = ((NSNull*)inspection[@"CompanyName"] == [NSNull null]) ? @"" : (NSString *)inspection[@"CompanyName"];
                                 inspectionTask.device.processSegment = ((NSNull*)inspection[@"AreaName"] == [NSNull null]) ? @"" : (NSString *)inspection[@"AreaName"];
                                 inspectionTask.device.remark = ((NSNull*)inspection[@"DeviceRemark"] == [NSNull null]) ? @"" : (NSString *)inspection[@"DeviceRemark"];
                                 
                                 // DEVICE TYPE INFORMATION
                                 inspectionTask.device.deviceType.deviceTypeID = [NSString stringWithFormat:@"%@", inspection[@"DeviceTypeId"]];
                                 inspectionTask.device.deviceType.deviceTypeName = ((NSNull*)inspection[@"DeviceTypeName"] == [NSNull null]) ? @"" : (NSString *)inspection[@"DeviceTypeName"];
                                 inspectionTask.device.deviceType.inspectionCycle = ((NSNull*)inspection[@"CycleTime"] == [NSNull null]) ? 0 : (NSInteger)inspection[@"CycleTime"];
                                 inspectionTask.device.deviceType.inspectionInformation = ((NSNull*)inspection[@"InspectionHint"] == [NSNull null]) ? @"" : (NSString *)inspection[@"InspectionHint"];
                                 
                                 // **
                                 // Let the caller of this method manages device type list
                                 // **
//                                 if (self.deviceTypes != nil) {
//                                     if ([self.deviceTypes valueForKey:inspectionTask.device.deviceType.deviceTypeID]) {
//                                         NSString *deviceTypeID = inspectionTask.device.deviceType.deviceTypeID;
//                                         inspectionTask.device.deviceType = [self.deviceTypes[deviceTypeID] copy];
//                                     }
//                                 }
                                 
                                 // INSPECTION INFORMATION
                                 inspectionTask.lastInspectionFinishedTimePlusCycleTime = ((NSNull*)inspection[@"DeadLine"] == [NSNull null]) ? [NSDate date] : [NSDate dateFromDateTimeString:(NSString *)inspection[@"DeadLine"]];
                                 inspectionTask.inspectionFinishedTime = ((NSNull*)inspection[@"InspectionTime"] == [NSNull null]) ? [NSDate date] : [NSDate dateFromDateTimeString:(NSString *)inspection[@"InspectionTime"]];
                                 inspectionTask.inspectionResult = DeviceNormal;
                                 inspectionTask.inspectionResultDescription = ((NSNull*)inspection[@"Comment"] == [NSNull null]) ? @"" : (NSString *)inspection[@"Comment"];
                                 
                                 NSMutableDictionary <NSString *, WISFileInfo *> *imagesInfo = [NSMutableDictionary dictionary];
                                 NSArray *photoUrls = inspection[@"PhotoUrls"];
                                 if (photoUrls && !((NSNull *)photoUrls == [NSNull null])) {
                                     if (photoUrls.count > 0) {
                                         for (NSString *url in photoUrls) {
                                             WISFileInfo *imageInfo = [WISDataManager produceFileInfoWithFileRemoteURL:url];
                                             
                                             if (![imagesInfo valueForKey:imageInfo.fileName]) {
                                                 [imagesInfo setValue:imageInfo forKey:imageInfo.fileName];
                                             }
                                         }
                                     }
                                 }
                                 inspectionTask.imagesInfo = imagesInfo;
                                 
                                 // **
                                 // Let the caller of this method manages device type list
                                 // **
                                 // [self.inspectionTasks setValue:[inspectionTask copy] forKey:inspectionTask.device.deviceID];
                                 
                                 updatedData = inspectionTask;
                             }
                             
                             [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateInspectionInfoSucceededNotification
                                                                                 object:updatedData];
                             
                             if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(updateInspectionInfoSucceeded)]) {
                                 [self.inspectionTaskOpDelegate updateInspectionInfoSucceeded];
                             }
                             handler(YES, nil, NSStringFromClass([updatedData class]), updatedData);
                             break;
                             
                         case RequestFailed:
                             err = [self produceErrorObjectWithWISErrorCode:ErrorCodeInvalidOperation andCallbackError:nil];
                             handler(FALSE, err, @"", nil);
                             
                             [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateInspectionInfoFailedNotification object:(NSError *)err];
                             
                             if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(updateInspectionInfoFailedWithError:)]) {
                                 [self.inspectionTaskOpDelegate updateInspectionInfoFailedWithError:err];
                             }
                             break;
                             
                         default:
                             break;
                     }
                 }
             }
         }];
    }
    return dataTask;
}


- (NSURLSessionDataTask *) updateInspectionsInfoWithCompletionHandler:(WISInspectionTaskUpdateInfoHandler) handler {
    NSDictionary * updateParams = nil;
    NSURLSessionDataTask *dataTask = nil;
    
    if ([self.currentUser.userName isEqual: @""] || self.currentUser.userName == nil
        || [self.networkRequestToken isEqual: @""] || self.networkRequestToken == nil) {
        
        NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeNoCurrentUserInfo andCallbackError:nil];
        handler(FALSE, err, @"", nil);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateInspectionsInfoFailedNotification object:(NSError *)err];
        if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(updateInspectionsInfoFailedWithError:)]) {
            [self.inspectionTaskOpDelegate updateInspectionsInfoFailedWithError:err];
        }
        
    } else {
        
        updateParams = [NSDictionary dictionaryWithObjectsAndKeys:self.currentUser.userName, @"UserName",
                        self.networkRequestToken, @"PassWord", nil];
        
        dataTask = [self.networkService dataRequestWithRequestType:UpdateInspectionsInfo
                                                            params:updateParams
                                                     andUriSetting:nil
         completionHandler:^(RequestType requestType, NSData *responsedData, NSError *error) {
             if (!responsedData) {
                 NSLog(@"Update Inspections Info 请求异常，原因: %@", @"返回的数据为空");
                 
                 NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeResponsedNULLData andCallbackError:error];
                 handler(FALSE, err, @"", nil);
                 
                 [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateInspectionsInfoFailedNotification object:(NSError *)err];
                 if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(updateInspectionsInfoFailedWithError:)]) {
                     [self.inspectionTaskOpDelegate updateInspectionsInfoFailedWithError:err];
                 }
                 
             } else {
                 
                 NSError *parseError;
                 NSDictionary *parsedData = nil;
                 
                 parsedData = [NSJSONSerialization JSONObjectWithData:responsedData
                                                              options:NSJSONReadingMutableContainers
                                                                error:&parseError];
                 
                 if (!parsedData || parseError) {
                     NSLog(@"Update Inspections Info 操作解析内容失败，原因: %@", parseError);
                     
                     NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeIncorrectResponsedDataFormat andCallbackError:parseError];
                     handler(FALSE, err, @"", nil);
                     
                     [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateInspectionsInfoFailedNotification object:(NSError *)err];
                     if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(updateInspectionsInfoFailedWithError:)]) {
                         [self.inspectionTaskOpDelegate updateInspectionsInfoFailedWithError:err];
                     }
                     
                 } else {
                     
                     RequestResult result = (RequestResult)[parsedData[@"Result"] integerValue];
                     
                     // **
                     // Let the caller of this method manages device type list
                     // **
                     // [self.inspectionTasks removeAllObjects];
                     
                     NSArray *inspections = nil;
                     NSError *err;
                     NSMutableArray *updatedData = [NSMutableArray array];
                     
                     switch (result) {
                         case RequestSuccessful:
                             inspections = parsedData[@"Inspections"];
                             
                             if (inspections && !((NSNull *)inspections == [NSNull null])) {
                                 if (inspections.count > 0) {
                                     for(NSDictionary *inspection in inspections) {
                                         WISInspectionTask *inspectionTask = [[WISInspectionTask alloc]init];
                                         
                                         // DEVICE INFORMATION
                                         inspectionTask.device.deviceID = [NSString stringWithFormat:@"%@", inspection[@"DeviceId"]];
                                         inspectionTask.device.deviceName = ((NSNull*)inspection[@"DeviceName"] == [NSNull null]) ? @"" : (NSString *)inspection[@"DeviceName"];
                                         inspectionTask.device.deviceCode = ((NSNull*)inspection[@"DeviceCode"] == [NSNull null]) ? @"" : (NSString *)inspection[@"DeviceCode"];
                                         inspectionTask.device.putIntoServiceTime = ((NSNull*)inspection[@"DeviceServiceTime"] == [NSNull null]) ? [NSDate date] : [NSDate dateFromDateTimeString:(NSString *)inspection[@"DeviceServiceTime"]];
                                         inspectionTask.device.company = ((NSNull*)inspection[@"CompanyName"] == [NSNull null]) ? @"" : (NSString *)inspection[@"CompanyName"];
                                         inspectionTask.device.processSegment = ((NSNull*)inspection[@"AreaName"] == [NSNull null]) ? @"" : (NSString *)inspection[@"AreaName"];
                                         inspectionTask.device.remark = ((NSNull*)inspection[@"DeviceRemark"] == [NSNull null]) ? @"" : (NSString *)inspection[@"DeviceRemark"];
                                         
                                         // DEVICE TYPE INFORMATION
                                         inspectionTask.device.deviceType.deviceTypeID = [NSString stringWithFormat:@"%@", inspection[@"DeviceTypeId"]];
                                         inspectionTask.device.deviceType.deviceTypeName = ((NSNull*)inspection[@"DeviceTypeName"] == [NSNull null]) ? @"" : (NSString *)inspection[@"DeviceTypeName"];
                                         inspectionTask.device.deviceType.inspectionCycle = ((NSNull*)inspection[@"CycleTime"] == [NSNull null]) ? 0 : [(NSString *)inspection[@"CycleTime"] integerValue];
                                         inspectionTask.device.deviceType.inspectionInformation = ((NSNull*)inspection[@"InspectionHint"] == [NSNull null]) ? @"" : (NSString *)inspection[@"InspectionHint"];
                                         
                                         // **
                                         // Let the caller of this method manages device type list
                                         // **
//                                         if (self.deviceTypes != nil) {
//                                             if ([self.deviceTypes valueForKey:inspectionTask.device.deviceType.deviceTypeID]) {
//                                                 NSString *deviceTypeID = inspectionTask.device.deviceType.deviceTypeID;
//                                                 inspectionTask.device.deviceType = [self.deviceTypes[deviceTypeID] copy];
//                                             }
//                                         }
                                         
                                         // INSPECTION INFORMATION
                                         inspectionTask.lastInspectionFinishedTimePlusCycleTime = ((NSNull*)inspection[@"DeadLine"] == [NSNull null]) ? [NSDate date] : [NSDate dateFromDateTimeString:(NSString *)inspection[@"DeadLine"]];
                                         inspectionTask.inspectionFinishedTime = ((NSNull*)inspection[@"InspectionTime"] == [NSNull null]) ? [NSDate date] : [NSDate dateFromDateTimeString:(NSString *)inspection[@"InspectionTime"]];
                                         /// let the initializer decide initiative inspection result
                                         // inspectionTask.inspectionResult = DeviceNormal;
                                         inspectionTask.inspectionResultDescription = ((NSNull*)inspection[@"Comment"] == [NSNull null]) ? @"" : (NSString *)inspection[@"Comment"];
                                         
                                         NSMutableDictionary <NSString *, WISFileInfo *> *imagesInfo = [NSMutableDictionary dictionary];
                                         NSArray *photoUrls = inspection[@"PhotoUrls"];
                                         if (photoUrls && !((NSNull *)photoUrls == [NSNull null])) {
                                             if (photoUrls.count > 0) {
                                                 for (NSString *url in photoUrls) {
                                                     WISFileInfo *imageInfo = [WISDataManager produceFileInfoWithFileRemoteURL:url];
                                                     
                                                     if (![imagesInfo valueForKey:imageInfo.fileName]) {
                                                         [imagesInfo setValue:imageInfo forKey:imageInfo.fileName];
                                                     }
                                                 }
                                             }
                                         }
                                         inspectionTask.imagesInfo = imagesInfo;
                                         
                                         // **
                                         // Let the caller of this method manages device type list
                                         // **
//                                         if (![self.inspectionTasks valueForKey:inspectionTask.device.deviceID]) {
//                                             [self.inspectionTasks setValue:inspectionTask forKey:inspectionTask.device.deviceID];
//                                         }
                                         [updatedData addObject:inspectionTask];
                                     }
                                     [updatedData sortWithOptions:NSSortConcurrent usingComparator:[WISInspectionTask arrayForwardSorterByExpirationTimeWithResult]];
                                 }
                             }
                             
                             [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateInspectionsInfoSucceededNotification
                                                                                 object:updatedData];
                             
                             if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(updateInspectionsInfoSucceeded)]) {
                                 [self.inspectionTaskOpDelegate updateInspectionsInfoSucceeded];
                             }
                             handler(YES, nil, NSStringFromClass([updatedData class]), updatedData);
                             break;
                             
                         case RequestFailed:
                             err = [self produceErrorObjectWithWISErrorCode:ErrorCodeInvalidOperation andCallbackError:nil];
                             handler(FALSE, err, @"", nil);
                             
                             [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateInspectionsInfoFailedNotification object:(NSError *)err];
                             
                             if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(updateInspectionsInfoFailedWithError:)]) {
                                 [self.inspectionTaskOpDelegate updateInspectionsInfoFailedWithError:err];
                             }
                             break;
                             
                         default:
                             break;
                     }
                 }
             }
         }];
    }
    return dataTask;
}


- (NSURLSessionDataTask *) updateDeviceTypesInfoWithCompletionHandler:(WISInspectionTaskUpdateInfoHandler) handler {
    NSDictionary * updateParams = nil;
    NSURLSessionDataTask *dataTask = nil;
    
    if ([self.currentUser.userName isEqual: @""] || self.currentUser.userName == nil
        || [self.networkRequestToken isEqual: @""] || self.networkRequestToken == nil) {
        
        NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeNoCurrentUserInfo andCallbackError:nil];
        handler(FALSE, err, @"", nil);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateDeviceTypesInfoFailedNotification object:(NSError *)err];
        if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(updateDeviceTypesInfoFailedWithError:)]) {
            [self.inspectionTaskOpDelegate updateDeviceTypesInfoFailedWithError:err];
        }
        
    } else {
        
        updateParams = [NSDictionary dictionaryWithObjectsAndKeys:self.currentUser.userName, @"UserName",
                        self.networkRequestToken, @"PassWord", nil];
        
        dataTask = [self.networkService dataRequestWithRequestType:UpdateDeviceTypesInfo
                                                            params:updateParams
                                                     andUriSetting:nil
         completionHandler:^(RequestType requestType, NSData *responsedData, NSError *error) {
             if (!responsedData) {
                 NSLog(@"Update Inspections Info 请求异常，原因: %@", @"返回的数据为空");
                 
                 NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeResponsedNULLData andCallbackError:error];
                 handler(FALSE, err, @"", nil);
                 
                 [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateInspectionsInfoFailedNotification object:(NSError *)err];
                 if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(updateInspectionsInfoFailedWithError:)]) {
                     [self.inspectionTaskOpDelegate updateInspectionsInfoFailedWithError:err];
                 }
                 
             } else {
                 
                 NSError *parseError;
                 NSDictionary *parsedData = nil;
                 
                 parsedData = [NSJSONSerialization JSONObjectWithData:responsedData
                                                              options:NSJSONReadingMutableContainers
                                                                error:&parseError];
                 
                 if (!parsedData || parseError) {
                     NSLog(@"Update Device Types Info 操作解析内容失败，原因: %@", parseError);
                     
                     NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeIncorrectResponsedDataFormat andCallbackError:parseError];
                     handler(FALSE, err, @"", nil);
                     
                     [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateDeviceTypesInfoFailedNotification object:(NSError *)err];
                     if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(updateDeviceTypesInfoFailedWithError:)]) {
                         [self.inspectionTaskOpDelegate updateDeviceTypesInfoFailedWithError:err];
                     }
                     
                 } else {
                     
                     RequestResult result = (RequestResult)[parsedData[@"Result"] integerValue];
                     
                     // **
                     // Let the caller of this method manages device type list
                     // **
                     // [self.deviceTypes removeAllObjects];
                     
                     NSArray *deviceTypes = nil;
                     NSError *err;
                     NSMutableArray *updatedData = [NSMutableArray array];
                     
                     switch (result) {
                         case RequestSuccessful:
                             deviceTypes = parsedData[@"DeviceTypes"];
                             
                             if (deviceTypes && !((NSNull *)deviceTypes == [NSNull null])) {
                                 if (deviceTypes.count > 0) {
                                     for(NSDictionary *type in deviceTypes) {
                                         WISDeviceType *deviceType = [[WISDeviceType alloc]init];
                                         
                                         // DEVICE TYPE INFORMATION
                                         deviceType.deviceTypeID = [NSString stringWithFormat:@"%@", type[@"Id"]];
                                         deviceType.deviceTypeName = ((NSNull*)type[@"Name"] == [NSNull null]) ? @"" : (NSString *)type[@"Name"];
                                         deviceType.inspectionCycle = ((NSNull*)type[@"CycleTime"] == [NSNull null]) ? 0 : [(NSString *)type[@"CycleTime"] integerValue];
                                         deviceType.acceptableDelayTime = ((NSNull*)type[@"AcceptableDelayTime"] == [NSNull null]) ? 0 : (NSInteger)type[@"AcceptableDelayTime"];
                                         deviceType.inspectionInformation = ((NSNull*)type[@"InspectionHint"] == [NSNull null]) ? @"" : (NSString *)type[@"InspectionHint"];
                                         
                                         // **
                                         // Let the caller of this method manages device type list
                                         // **
//                                         if (![self.deviceTypes valueForKey:deviceType.deviceTypeID]) {
//                                             [self.deviceTypes setValue:deviceType forKey:deviceType.deviceTypeID];
//                                         }
                                         [updatedData addObject:deviceType];
                                     }
                                 }
                             }
                             
                             [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateDeviceTypesInfoSucceededNotification
                                                                                 object:updatedData];
                             
                             if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(updateDeviceTypesInfoSucceeded)]) {
                                 [self.inspectionTaskOpDelegate updateDeviceTypesInfoSucceeded];
                             }
                             handler(YES, nil, NSStringFromClass([updatedData class]), updatedData);
                             break;
                             
                         case RequestFailed:
                             err = [self produceErrorObjectWithWISErrorCode:ErrorCodeInvalidOperation andCallbackError:nil];
                             handler(FALSE, err, @"", nil);
                             
                             [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateDeviceTypesInfoFailedNotification object:(NSError *)err];
                             
                             if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(updateDeviceTypesInfoFailedWithError:)]) {
                                 [self.inspectionTaskOpDelegate updateDeviceTypesInfoFailedWithError:err];
                             }
                             break;
                             
                         default:
                             break;
                     }
                 }
             }
         }];
    }
    return dataTask;
}


- (NSURLSessionDataTask *) updateOverDueInspectionsInfoWithCompletionHandler:(WISInspectionTaskUpdateInfoHandler) handler {
    NSDictionary * updateParams = nil;
    NSURLSessionDataTask *dataTask = nil;
    
    if ([self.currentUser.userName isEqual: @""] || self.currentUser.userName == nil
        || [self.networkRequestToken isEqual: @""] || self.networkRequestToken == nil) {
        
        NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeNoCurrentUserInfo andCallbackError:nil];
        handler(FALSE, err, @"", nil);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateOverDueInspectionsInfoFailedNotification object:(NSError *)err];
        if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(updateOverDueInspectionsInfoFailedWithError:)]) {
            [self.inspectionTaskOpDelegate updateOverDueInspectionsInfoFailedWithError:err];
        }
        
    } else {
        
        updateParams = [NSDictionary dictionaryWithObjectsAndKeys:self.currentUser.userName, @"UserName",
                        self.networkRequestToken, @"PassWord", nil];
        
        dataTask = [self.networkService dataRequestWithRequestType:UpdateOverDueInspectionsInfo
                                                            params:updateParams
                                                     andUriSetting:nil
        completionHandler:^(RequestType requestType, NSData *responsedData, NSError *error) {
            if (!responsedData) {
                NSLog(@"Update Over Due Inspections Info 请求异常，原因: %@", @"返回的数据为空");
                
                NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeResponsedNULLData andCallbackError:error];
                handler(FALSE, err, @"", nil);
                
                [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateOverDueInspectionsInfoFailedNotification object:(NSError *)err];
                if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(updateOverDueInspectionsInfoFailedWithError:)]) {
                    [self.inspectionTaskOpDelegate updateOverDueInspectionsInfoFailedWithError:err];
                }
                
            } else {
                
                NSError *parseError;
                NSDictionary *parsedData = nil;
                
                parsedData = [NSJSONSerialization JSONObjectWithData:responsedData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&parseError];
                
                if (!parsedData || parseError) {
                    NSLog(@"Update Over Due Inspections Info 操作解析内容失败，原因: %@", parseError);
                    
                    NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeIncorrectResponsedDataFormat andCallbackError:parseError];
                    handler(FALSE, err, @"", nil);
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateOverDueInspectionsInfoFailedNotification object:(NSError *)err];
                    if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(updateOverDueInspectionsInfoFailedWithError:)]) {
                        [self.inspectionTaskOpDelegate updateOverDueInspectionsInfoFailedWithError:err];
                    }
                    
                } else {
                    
                    RequestResult result = (RequestResult)[parsedData[@"Result"] integerValue];
                    
                    // **
                    // Let the caller of this method manages device type list
                    // **
                    // [self.inspectionTasks removeAllObjects];
                    
                    NSArray *inspections = nil;
                    NSError *err;
                    NSMutableArray *updatedData = [NSMutableArray array];
                    
                    switch (result) {
                        case RequestSuccessful:
                            inspections = parsedData[@"Inspections"];
                            
                            if (inspections && !((NSNull *)inspections == [NSNull null])) {
                                if (inspections.count > 0) {
                                    for(NSDictionary *inspection in inspections) {
                                        WISInspectionTask *inspectionTask = [[WISInspectionTask alloc]init];
                                        
                                        // DEVICE INFORMATION
                                        inspectionTask.device.deviceID = [NSString stringWithFormat:@"%@", inspection[@"DeviceId"]];
                                        inspectionTask.device.deviceName = ((NSNull*)inspection[@"DeviceName"] == [NSNull null]) ? @"" : (NSString *)inspection[@"DeviceName"];
                                        inspectionTask.device.deviceCode = ((NSNull*)inspection[@"DeviceCode"] == [NSNull null]) ? @"" : (NSString *)inspection[@"DeviceCode"];
                                        inspectionTask.device.putIntoServiceTime = ((NSNull*)inspection[@"DeviceServiceTime"] == [NSNull null]) ? [NSDate date] : [NSDate dateFromDateTimeString:(NSString *)inspection[@"DeviceServiceTime"]];
                                        inspectionTask.device.company = ((NSNull*)inspection[@"CompanyName"] == [NSNull null]) ? @"" : (NSString *)inspection[@"CompanyName"];
                                        inspectionTask.device.processSegment = ((NSNull*)inspection[@"AreaName"] == [NSNull null]) ? @"" : (NSString *)inspection[@"AreaName"];
                                        inspectionTask.device.remark = ((NSNull*)inspection[@"DeviceRemark"] == [NSNull null]) ? @"" : (NSString *)inspection[@"DeviceRemark"];
                                        
                                        // DEVICE TYPE INFORMATION
                                        inspectionTask.device.deviceType.deviceTypeID = [NSString stringWithFormat:@"%@", inspection[@"DeviceTypeId"]];
                                        inspectionTask.device.deviceType.deviceTypeName = ((NSNull*)inspection[@"DeviceTypeName"] == [NSNull null]) ? @"" : (NSString *)inspection[@"DeviceTypeName"];
                                        inspectionTask.device.deviceType.inspectionCycle = ((NSNull*)inspection[@"CycleTime"] == [NSNull null]) ? 0 : [(NSString *)inspection[@"CycleTime"] integerValue];
                                        inspectionTask.device.deviceType.inspectionInformation = ((NSNull*)inspection[@"InspectionHint"] == [NSNull null]) ? @"" : (NSString *)inspection[@"InspectionHint"];
                                        
                                        // **
                                        // Let the caller of this method manages device type list
                                        // **
                                        //                                         if (self.deviceTypes != nil) {
                                        //                                             if ([self.deviceTypes valueForKey:inspectionTask.device.deviceType.deviceTypeID]) {
                                        //                                                 NSString *deviceTypeID = inspectionTask.device.deviceType.deviceTypeID;
                                        //                                                 inspectionTask.device.deviceType = [self.deviceTypes[deviceTypeID] copy];
                                        //                                             }
                                        //                                         }
                                        
                                        // INSPECTION INFORMATION
                                        inspectionTask.lastInspectionFinishedTimePlusCycleTime = ((NSNull*)inspection[@"DeadLine"] == [NSNull null]) ? [NSDate date] : [NSDate dateFromDateTimeString:(NSString *)inspection[@"DeadLine"]];
                                        inspectionTask.inspectionFinishedTime = ((NSNull*)inspection[@"InspectionTime"] == [NSNull null]) ? [NSDate date] : [NSDate dateFromDateTimeString:(NSString *)inspection[@"InspectionTime"]];
                                        inspectionTask.inspectionResult = DeviceNormal;
                                        inspectionTask.inspectionResultDescription = ((NSNull*)inspection[@"Comment"] == [NSNull null]) ? @"" : (NSString *)inspection[@"Comment"];
                                        
                                        NSMutableDictionary <NSString *, WISFileInfo *> *imagesInfo = [NSMutableDictionary dictionary];
                                        NSArray *photoUrls = inspection[@"PhotoUrls"];
                                        if (photoUrls && !((NSNull *)photoUrls == [NSNull null])) {
                                            if (photoUrls.count > 0) {
                                                for (NSString *url in photoUrls) {
                                                    WISFileInfo *imageInfo = [WISDataManager produceFileInfoWithFileRemoteURL:url];
                                                    
                                                    if (![imagesInfo valueForKey:imageInfo.fileName]) {
                                                        [imagesInfo setValue:imageInfo forKey:imageInfo.fileName];
                                                    }
                                                }
                                            }
                                        }
                                        inspectionTask.imagesInfo = imagesInfo;
                                        
                                        // **
                                        // Let the caller of this method manages device type list
                                        // **
                                        //                                         if (![self.inspectionTasks valueForKey:inspectionTask.device.deviceID]) {
                                        //                                             [self.inspectionTasks setValue:inspectionTask forKey:inspectionTask.device.deviceID];
                                        //                                         }
                                        [updatedData addObject:inspectionTask];
                                    }
                                    [updatedData sortWithOptions:NSSortConcurrent usingComparator:[WISInspectionTask arrayForwardSorterByExpirationTimeWithResult]];
                                }
                            }
                            
                            [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateOverDueInspectionsInfoSucceededNotification
                                                                                object:updatedData];
                            
                            if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(updateOverDueInspectionsInfoSucceeded)]) {
                                [self.inspectionTaskOpDelegate updateOverDueInspectionsInfoSucceeded];
                            }
                            handler(YES, nil, NSStringFromClass([updatedData class]), updatedData);
                            break;
                            
                        case RequestFailed:
                            err = [self produceErrorObjectWithWISErrorCode:ErrorCodeInvalidOperation andCallbackError:nil];
                            handler(FALSE, err, @"", nil);
                            
                            [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateOverDueInspectionsInfoFailedNotification object:(NSError *)err];
                            
                            if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(updateOverDueInspectionsInfoFailedWithError:)]) {
                                [self.inspectionTaskOpDelegate updateOverDueInspectionsInfoFailedWithError:err];
                            }
                            break;
                            
                        default:
                            break;
                    }
                }
            }
        }];
    }
    return dataTask;

}


- (NSURLSessionDataTask *) updateHistoricalInspectionsInfoWithStartDate:(NSDate *)startDate
                                                                endDate:(NSDate *)endDate
                                                     recordNumberInPage:(NSInteger)numberInPage
                                                              pageIndex:(NSInteger)index
                                                      completionHandler:(WISInspectionTaskUpdateInfoHandler)handler {
    NSDictionary * updateParams = nil;
    NSURLSessionDataTask *dataTask = nil;
    
    if ([self.currentUser.userName isEqual: @""] || self.currentUser.userName == nil
        || [self.networkRequestToken isEqual: @""] || self.networkRequestToken == nil) {
        
        NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeNoCurrentUserInfo andCallbackError:nil];
        handler(FALSE, err, @"", nil);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateOverDueInspectionsInfoFailedNotification object:(NSError *)err];
        if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(updateHistoricalInspectionsInfoFailedWithError:)]) {
            [self.inspectionTaskOpDelegate updateHistoricalInspectionsInfoFailedWithError:err];
        }
        
    } else {
        
        updateParams = [NSDictionary dictionaryWithObjectsAndKeys:self.currentUser.userName, @"UserName",
                        self.networkRequestToken, @"PassWord", nil];
        NSArray<NSString *> *settings = [NSArray arrayWithObjects:
                                         [startDate toDateStringWithSeparator:@"/"],
                                         [endDate toDateStringWithSeparator:@"/"],
                                         [NSString stringWithFormat:@"%ld", (long)numberInPage],
                                         [NSString stringWithFormat:@"%ld", (long)index],
                                         nil];
        
        dataTask = [self.networkService dataRequestWithRequestType:UpdateHistoricalInspectionsInfo
                                                            params:updateParams
                                                     andUriSetting:settings
        completionHandler:^(RequestType requestType, NSData *responsedData, NSError *error) {
            if (!responsedData) {
                NSLog(@"Update Historical Inspections Info 请求异常，原因: %@", @"返回的数据为空");
                
                NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeResponsedNULLData andCallbackError:error];
                handler(FALSE, err, @"", nil);
                
                [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateHistoricalInspectionsInfoFailedNotification object:(NSError *)err];
                if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(updateHistoricalInspectionsInfoFailedWithError:)]) {
                    [self.inspectionTaskOpDelegate updateHistoricalInspectionsInfoFailedWithError:err];
                }
                
            } else {
                
                NSError *parseError;
                NSDictionary *parsedData = nil;
                
                parsedData = [NSJSONSerialization JSONObjectWithData:responsedData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&parseError];
                
                if (!parsedData || parseError) {
                    NSLog(@"Update Historical Inspections Info 操作解析内容失败，原因: %@", parseError);
                    
                    NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeIncorrectResponsedDataFormat andCallbackError:parseError];
                    handler(FALSE, err, @"", nil);
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateHistoricalInspectionsInfoFailedNotification object:(NSError *)err];
                    if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(updateHistoricalInspectionsInfoFailedWithError:)]) {
                        [self.inspectionTaskOpDelegate updateHistoricalInspectionsInfoFailedWithError:err];
                    }
                    
                } else {
                    
                    RequestResult result = (RequestResult)[parsedData[@"Result"] integerValue];
                    
                    // **
                    // Let the caller of this method manages device type list
                    // **
                    // [self.inspectionTasks removeAllObjects];
                    
                    NSArray *inspections = nil;
                    NSError *err;
                    NSMutableArray *updatedData = [NSMutableArray array];
                    
                    switch (result) {
                        case RequestSuccessful:
                            inspections = parsedData[@"Inspections"];
                            
                            if (inspections && !((NSNull *)inspections == [NSNull null])) {
                                if (inspections.count > 0) {
                                    for(NSDictionary *inspection in inspections) {
                                        WISInspectionTask *inspectionTask = [[WISInspectionTask alloc]init];
                                        
                                        // DEVICE INFORMATION
                                        inspectionTask.device.deviceID = [NSString stringWithFormat:@"%@", inspection[@"DeviceId"]];
                                        inspectionTask.device.deviceName = ((NSNull*)inspection[@"DeviceName"] == [NSNull null]) ? @"" : (NSString *)inspection[@"DeviceName"];
                                        inspectionTask.device.deviceCode = ((NSNull*)inspection[@"DeviceCode"] == [NSNull null]) ? @"" : (NSString *)inspection[@"DeviceCode"];
                                        inspectionTask.device.putIntoServiceTime = ((NSNull*)inspection[@"DeviceServiceTime"] == [NSNull null]) ? [NSDate date] : [NSDate dateFromDateTimeString:(NSString *)inspection[@"DeviceServiceTime"]];
                                        inspectionTask.device.company = ((NSNull*)inspection[@"CompanyName"] == [NSNull null]) ? @"" : (NSString *)inspection[@"CompanyName"];
                                        inspectionTask.device.processSegment = ((NSNull*)inspection[@"AreaName"] == [NSNull null]) ? @"" : (NSString *)inspection[@"AreaName"];
                                        inspectionTask.device.remark = ((NSNull*)inspection[@"DeviceRemark"] == [NSNull null]) ? @"" : (NSString *)inspection[@"DeviceRemark"];
                                        
                                        // DEVICE TYPE INFORMATION
                                        inspectionTask.device.deviceType.deviceTypeID = [NSString stringWithFormat:@"%@", inspection[@"DeviceTypeId"]];
                                        inspectionTask.device.deviceType.deviceTypeName = ((NSNull*)inspection[@"DeviceTypeName"] == [NSNull null]) ? @"" : (NSString *)inspection[@"DeviceTypeName"];
                                        inspectionTask.device.deviceType.inspectionCycle = ((NSNull*)inspection[@"CycleTime"] == [NSNull null]) ? 0 : [(NSString *)inspection[@"CycleTime"] integerValue];
                                        inspectionTask.device.deviceType.inspectionInformation = ((NSNull*)inspection[@"InspectionHint"] == [NSNull null]) ? @"" : (NSString *)inspection[@"InspectionHint"];
                                        
                                        // **
                                        // Let the caller of this method manages device type list
                                        // **
                                        //                                         if (self.deviceTypes != nil) {
                                        //                                             if ([self.deviceTypes valueForKey:inspectionTask.device.deviceType.deviceTypeID]) {
                                        //                                                 NSString *deviceTypeID = inspectionTask.device.deviceType.deviceTypeID;
                                        //                                                 inspectionTask.device.deviceType = [self.deviceTypes[deviceTypeID] copy];
                                        //                                             }
                                        //                                         }
                                        
                                        
                                        // INSPECTION INFORMATION
                                        inspectionTask.lastInspectionFinishedTimePlusCycleTime = ((NSNull*)inspection[@"DeadLine"] == [NSNull null]) ? [NSDate date] : [NSDate dateFromDateTimeString:(NSString *)inspection[@"DeadLine"]];
                                        inspectionTask.inspectionFinishedTime = ((NSNull*)inspection[@"InspectionTime"] == [NSNull null]) ? [NSDate date] : [NSDate dateFromDateTimeString:(NSString *)inspection[@"InspectionTime"]];
                                        inspectionTask.inspectionResult = ((NSNull*)inspection[@"Result"] == [NSNull null]) ? NotSelected : (InspectionResult)[(NSString *)inspection[@"Result"] integerValue];
                                        inspectionTask.inspectionResultDescription = ((NSNull*)inspection[@"Comment"] == [NSNull null]) ? @"" : (NSString *)inspection[@"Comment"];
                                        
                                        WISUser *taskPersonInCharge = [[WISUser alloc] init];
                                        NSDictionary *personInCharge = (NSDictionary *)inspection[@"PersonInCharge"];
                                        
                                        if (personInCharge && !((NSNull *)personInCharge == [NSNull null])) {
                                            taskPersonInCharge.userName = ((NSNull*)personInCharge[@"UserName"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"UserName"];
                                            taskPersonInCharge.fullName = ((NSNull*)personInCharge[@"Name"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"Name"];
                                            taskPersonInCharge.roleCode = ((NSNull*)personInCharge[@"RoleCode"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"RoleCode"];
                                            taskPersonInCharge.roleName = ((NSNull*)personInCharge[@"RoleName"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"RoleName"];
                                            taskPersonInCharge.cellPhoneNumber = ((NSNull*)personInCharge[@"MobilePhone"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"MobilePhone"];
                                            taskPersonInCharge.telephoneNumber = ((NSNull*)personInCharge[@"Telephone"] == [NSNull null]) ? @"" : (NSString *)personInCharge[@"Telephone"];
                                            
                                            /// IMAGES INFO
                                            NSArray *imagesURL = (NSArray *)personInCharge[@"ImageURL"];
                                            if (imagesURL && !((NSNull *)imagesURL == [NSNull null])) {
                                                for (NSString *url in imagesURL) {
                                                    WISFileInfo *imageInfo = [WISDataManager produceFileInfoWithFileRemoteURL:url];
                                                    
                                                    if (![taskPersonInCharge.imagesInfo valueForKey:imageInfo.fileName]) {
                                                        [taskPersonInCharge.imagesInfo setValue:imageInfo forKey:imageInfo.fileName];
                                                    }
                                                }
                                                
                                            } else {
                                                // do nothing, because WISMaintenanceTask initializer has done the initializing job.
                                            }
                                            
                                            inspectionTask.personInCharge = taskPersonInCharge;
                                            
                                        } else {
                                            // do nothing, because WISMaintenanceTask initializer has done the initial job.
                                            // _maintenanceTasks[taskID].personInCharge = nil;
                                        }
                                        
                                        NSMutableDictionary <NSString *, WISFileInfo *> *imagesInfo = [NSMutableDictionary dictionary];
                                        NSArray *photoUrls = inspection[@"PhotoUrls"];
                                        if (photoUrls && !((NSNull *)photoUrls == [NSNull null])) {
                                            if (photoUrls.count > 0) {
                                                for (NSString *url in photoUrls) {
                                                    WISFileInfo *imageInfo = [WISDataManager produceFileInfoWithFileRemoteURL:url];
                                                    
                                                    if (![imagesInfo valueForKey:imageInfo.fileName]) {
                                                        [imagesInfo setValue:imageInfo forKey:imageInfo.fileName];
                                                    }
                                                }
                                            }
                                        }
                                        inspectionTask.imagesInfo = imagesInfo;
                                        
                                        // **
                                        // Let the caller of this method manages device type list
                                        // **
                                        //                                         if (![self.inspectionTasks valueForKey:inspectionTask.device.deviceID]) {
                                        //                                             [self.inspectionTasks setValue:inspectionTask forKey:inspectionTask.device.deviceID];
                                        //                                         }
                                        [updatedData addObject:inspectionTask];
                                    }
                                    [updatedData sortWithOptions:NSSortConcurrent usingComparator:[WISInspectionTask arrayBackwardSorterByFinishedTimeWithResult]];
                                }
                            }
                            
                            [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateHistoricalInspectionsInfoSucceededNotification
                                                                                object:updatedData];
                            
                            if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(updateHistoricalInspectionsInfoSucceeded)]) {
                                [self.inspectionTaskOpDelegate updateHistoricalInspectionsInfoSucceeded];
                            }
                            handler(YES, nil, NSStringFromClass([updatedData class]), updatedData);
                            break;
                            
                        case RequestFailed:
                            err = [self produceErrorObjectWithWISErrorCode:ErrorCodeInvalidOperation andCallbackError:nil];
                            handler(FALSE, err, @"", nil);
                            
                            [[NSNotificationCenter defaultCenter] postNotificationName:WISUpdateHistoricalInspectionsInfoFailedNotification object:(NSError *)err];
                            
                            if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(updateHistoricalInspectionsInfoFailedWithError:)]) {
                                [self.inspectionTaskOpDelegate updateHistoricalInspectionsInfoFailedWithError:err];
                            }
                            break;
                            
                        default:
                            break;
                    }
                }
            }
        }];
    }
    return dataTask;
    
}


- (NSURLSessionDataTask *) submitInspectionResult:(NSArray<WISInspectionTask *> *)inspectionTasks completionHandler:(WISInspectionTaskOperationHandler) handler {
    
    NSDictionary * operationParams = nil;
    NSURLSessionDataTask *dataTask = nil;
    
    if ([self.currentUser.userName isEqual: @""] || self.currentUser.userName == nil
        || [self.networkRequestToken isEqual: @""] || self.networkRequestToken == nil) {
        
        NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeNoCurrentUserInfo andCallbackError:nil];
        handler(FALSE, err);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WISSubmitInspectionsResultFailedNotification object:(NSError *)err];
        if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(submitInspectionsResultFailedWithError:)]) {
            [self.inspectionTaskOpDelegate submitInspectionsResultFailedWithError:err];
        }
        
    } else {
        
        operationParams = [self produceInspectionTasksOperationParameterWithUserName:self.currentUser.userName
                                                                 networkRequestToken:self.networkRequestToken
                                                                     inspectionTasks:inspectionTasks];
        
        dataTask = [self.networkService dataRequestWithRequestType:SubmitInspectionResult
                                                            params:operationParams
                                                     andUriSetting:nil
         completionHandler:^(RequestType requestType, NSData *responsedData, NSError *networkError) {
             if (!responsedData) {
                 NSLog(@"Submit Inspections Result 请求异常，原因: %@", @"返回的数据为空");
                 
                 NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeResponsedNULLData andCallbackError:networkError];
                 handler(FALSE, err);
                 
                 [[NSNotificationCenter defaultCenter] postNotificationName:WISSubmitInspectionsResultFailedNotification object:(NSError *)err];
                 if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(submitInspectionsResultFailedWithError:)]) {
                     [self.inspectionTaskOpDelegate submitInspectionsResultFailedWithError:err];
                 }
                 
             } else {
                 
                 NSError *parseError;
                 NSDictionary *parsedData = nil;
                 
                 parsedData = [NSJSONSerialization JSONObjectWithData:responsedData
                                                              options:NSJSONReadingMutableContainers
                                                                error:&parseError];
                 
                 if (!parsedData || parseError) {
                     NSLog(@"Submit Inspection Result 解析返回内容失败，原因: %@", parseError);
                     
                     NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeIncorrectResponsedDataFormat andCallbackError:parseError];
                     handler(FALSE, err);
                     
                     [[NSNotificationCenter defaultCenter] postNotificationName:WISSubmitInspectionsResultFailedNotification object:(NSError *)err];
                     if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(submitInspectionsResultFailedWithError:)]) {
                         [self.inspectionTaskOpDelegate submitInspectionsResultFailedWithError:err];
                     }
                     
                 } else {
                     
                     RequestResult result = (RequestResult)[parsedData[@"Result"] integerValue];
                     NSError *err;
                     
                     switch (result) {
                         case RequestSuccessful:
                             [[NSNotificationCenter defaultCenter]
                              postNotificationName:WISSubmitInspectionsResultSucceededNotification object:self];
                             if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(submitInspectionsResultSucceeded)]) {
                                 [self.inspectionTaskOpDelegate submitInspectionsResultSucceeded];
                             }
                             
                             handler(YES, nil);
                             
                             break;
                             
                         case RequestFailed:
                             err = [self produceErrorObjectWithWISErrorCode:ErrorCodeInvalidOperation andCallbackError:nil];
                             
                             [[NSNotificationCenter defaultCenter] postNotificationName:WISSubmitInspectionsResultFailedNotification object:(NSError *)err];
                             if ([self.inspectionTaskOpDelegate respondsToSelector:@selector(submitInspectionsResultFailedWithError:)]) {
                                 [self.inspectionTaskOpDelegate submitInspectionsResultFailedWithError:err];
                             }
                             handler(FALSE, err);
                             break;
                             
                         default:
                             break;
                     }
                 }
             }
         }];
    }
    return dataTask;
}



#pragma mark - Image Operations for APP interface

- (NSURLSessionUploadTask *) storeImageOfUserWithUserName:(NSString *)userName
                                                   images:(NSDictionary<NSString *,UIImage *> *)images
                                  uploadProgressIndicator:(WISSystemDataTransmissionProgressIndicator)progress
                                        completionHandler:(WISSystemOperationHandler)handler {
    return [self storeImageWithImages:images
     /// PROGRESS
     uploadProgressIndicator:progress
     /// COMPLETION HANDLER
     completionHandler:^(BOOL completedWithNoError, NSError *error, NSString *classNameOfDataAsString, id data) {
         if (completedWithNoError) {
             NSArray<WISFileInfo *> *imagesInfo = (NSArray<WISFileInfo *> *)data;
             
             if (imagesInfo.count > 0) {
                 if (userName == _currentUser.userName) {
                     for (WISFileInfo *info in imagesInfo) {
                         if (![self.currentUser.imagesInfo valueForKey:info.fileName]) {
                             [self.currentUser.imagesInfo setValue:info forKey:info.fileName];
                         }
                     }
                 } else {
                     for (WISFileInfo *info in imagesInfo) {
                         if (![self.users[userName].imagesInfo valueForKey:info.fileName]) {
                             [self.users[userName].imagesInfo setValue:info forKey:info.fileName];
                         }
                     }
                 }
             }
             handler(TRUE, nil, NSStringFromClass([imagesInfo class]), imagesInfo);
             
         } else {
             
             handler(FALSE, error, @"", nil);
         }
     }];
}


- (NSURLSessionDownloadTask *) obtainImageOfUserWithUserName:(NSString *)userName
                            imagesInfo:(NSDictionary<NSString *,WISFileInfo *> *)imagesInfo
             downloadProgressIndicator:(WISSystemDataTransmissionProgressIndicator)progress
                     completionHandler:(WISSystemOperationHandler)handler {
    return [self obtainImageWithImagesInfo:imagesInfo
     /// PROGRESS
          downloadProgressIndicator:progress
     /// COMPLETION HANDLER
                  completionHandler:handler];
}


- (NSURLSessionUploadTask *) storeImageOfMaintenanceTaskWithTaskID:(NSString *)taskID
                                        images:(NSDictionary<NSString *,UIImage *> *)images
                       uploadProgressIndicator:(WISSystemDataTransmissionProgressIndicator)progress
                             completionHandler:(WISSystemOperationHandler)handler {
    
    return [self storeImageWithImages:images
     /// PROGRESS
     uploadProgressIndicator:progress
     /// COMPLETION HANDLER
     completionHandler:^(BOOL completedWithNoError, NSError *error, NSString *classNameOfDataAsString, id data) {
         if (completedWithNoError) {
             NSArray<WISFileInfo *> *imagesInfo = (NSArray<WISFileInfo *> *)data;
             
             if (imagesInfo.count > 0) {
                 for (WISFileInfo *info in imagesInfo) {
                     if (taskID && ![taskID isEqualToString:@""]) {
                         if (![self.maintenanceTasks[taskID].imagesInfo valueForKey:info.fileName]) {
                             [self.maintenanceTasks[taskID].imagesInfo setValue:info forKey:info.fileName];
                         }
                     }                     
                 }
             }
             handler(TRUE, nil, NSStringFromClass([imagesInfo class]), imagesInfo);
             
         } else {
             
             handler(FALSE, error, @"", nil);
         }
     }];
}


- (NSURLSessionDownloadTask *) obtainImageOfMaintenanceTaskWithTaskID:(NSString *)taskID
                                     imagesInfo:(NSDictionary<NSString *,WISFileInfo *> *)imagesInfo
                      downloadProgressIndicator:(WISSystemDataTransmissionProgressIndicator)progress
                              completionHandler:(WISSystemOperationHandler)handler {
    
    return [self obtainImageWithImagesInfo:imagesInfo
     /// PROGRESS
     downloadProgressIndicator:progress
     /// COMPLETION HANDLER
     completionHandler:handler];
}


#pragma mark - File/Data Transmission and Operation

// 保存图片 (本地／远端服务器)
- (NSURLSessionUploadTask *) storeImageWithImages:(NSDictionary<NSString *, UIImage *> *)images
      uploadProgressIndicator:(WISSystemDataTransmissionProgressIndicator)progress
            completionHandler:(WISSystemOperationHandler)handler {
    
    NSURLSessionUploadTask *uploadTask = nil;
    
    if (images) {
        if (images.count <= 0) {
            progress([NSProgress progressWithTotalUnitCount:0]);
            handler(true, nil, NSStringFromClass([NSArray class]), [NSArray array]);
            
        } else {
            [[[WISFileStoreManager defaultManager]downloadImageStore]setImages:images];
            uploadTask = [self uploadImageWithImages:images
             /// PROGRESS
            progressIndicator:^(NSProgress *transmissionProgress) {
                progress(transmissionProgress);
            }
            /// COMPLETION HANDLER
            completionHandler:^(BOOL completedWithNoError, NSError *error, NSString *classNameOfReceivedDataAsString, id receivedData) {
                handler(completedWithNoError, error, classNameOfReceivedDataAsString, receivedData);
            }];
        }
    }

    return uploadTask;
}


// 获取图片 (本地／远端服务器)
- (NSURLSessionDownloadTask *) obtainImageWithImagesInfo:(NSDictionary<NSString *, WISFileInfo *> *)imagesInfo
         downloadProgressIndicator:(WISSystemDataTransmissionProgressIndicator)progress
                 completionHandler:(WISSystemOperationHandler)handler {
    
    NSURLSessionDownloadTask *downloadTask = nil;
    
    NSArray<NSString *> *requiredImagesName = [imagesInfo allKeys];
    NSArray<NSString *> *imagesNameNotContainedInLocalStore =
        [[[WISFileStoreManager defaultManager] downloadImageStore] findImagesNameNotContainedInStoreFrom:requiredImagesName];
    
    if (imagesNameNotContainedInLocalStore.count <= 0) {
        NSDictionary<NSString *, UIImage *> *requiredImages = nil;
        requiredImages = [[[WISFileStoreManager defaultManager]downloadImageStore]imagesForImagesName:requiredImagesName];
        
        progress([NSProgress progressWithTotalUnitCount:0]);
        handler(YES, nil, NSStringFromClass([requiredImages class]), requiredImages);
    
    } else {
        NSMutableArray<NSString *> *requiredImagesRemoteLocation = [NSMutableArray array];
        
        for (NSString *imageName in imagesNameNotContainedInLocalStore) {
            [requiredImagesRemoteLocation addObject:imagesInfo[imageName].fileRemoteLocation];
        }
        
        downloadTask = [self downloadImageWithImageLocations:requiredImagesRemoteLocation
         /// PROGRESS
         //progressIndicator:^(NSProgress *transmissionProgress) {
         progressIndicator:progress
         
         /// COMPLETION HANDLER
         completionHandler:^(BOOL completedWithNoError, NSError *error, NSString *classNameOfReceivedDataAsString, id receivedData) {
             NSDictionary<NSString *, UIImage *> *requiredImages = nil;
             if (receivedData) {
                 [[[WISFileStoreManager defaultManager]downloadImageStore]setImages:(NSDictionary<NSString *, UIImage *> *)receivedData];
             }
             requiredImages = [[[WISFileStoreManager defaultManager]downloadImageStore]imagesForImagesName:requiredImagesName];
             
             handler(completedWithNoError, error, NSStringFromClass([requiredImages class]), requiredImages);
         }];
    }
    return downloadTask;
}


- (void)clearCacheOfImages {
    // [[[WISFileStoreManager defaultManager]downloadImageStore] clearCacheInMemory];
    [[[WISFileStoreManager defaultManager]downloadImageStore] clearCacheOnDeviceStorage];
}

- (float)cacheSizeOnDeviceStorage {
    return [[[WISFileStoreManager defaultManager]downloadImageStore] cacheSizeOnDeviceStorage];
}


/// 上传图片
- (NSURLSessionUploadTask *) uploadImageWithImages:(NSDictionary<NSString *, UIImage *> *)images
             progressIndicator:(WISSystemDataTransmissionProgressIndicator)progress
             completionHandler:(WISSystemDataTransmissionHandler)handler {
    
    NSMutableData *uploadData = [NSMutableData data];
    // data header
    NSData *dataHeader = nil;
    
    NSData *dataSummary = nil;
    NSMutableArray *dataSummaryAsArray = [NSMutableArray array];
    
    NSMutableData *dataBody = [NSMutableData data];
    
    NSURLSessionUploadTask *uploadTask = nil;
    
    if (images.count <=0) {
        NSLog(@"No image submited for uploading! Pls check the code!");
        return nil;
    } else {
        //
        // ** Construct data body
        //
        NSData *imageData = nil;
        NSInteger offset = 0;
        
        NSDictionary *fileDescriptionInDataSummary = nil;
        NSArray *imageNames = [images allKeys];
        
        for (int i = 0; i < imageNames.count; i++) {
            // imageData = UIImageJPEGRepresentation(images[i], 1.0f);
            imageData = UIImagePNGRepresentation(images[imageNames[i]]);
            
            [dataBody appendData:imageData];
            
            fileDescriptionInDataSummary = [NSDictionary dictionaryWithObjectsAndKeys:
                                            @"png", @"FileType",
                                            imageNames[i], @"FileName",
                                            [NSNumber numberWithInteger:offset], @"Offset",
                                            [NSNumber numberWithUnsignedInteger: imageData.length], @"Length", nil];
            
            [dataSummaryAsArray addObject:fileDescriptionInDataSummary];
            
            offset += imageData.length;
        }
        //
        // ** Construct data summary
        //
        NSError *dataSummaryConvertJSONError = nil;
        
        dataSummary = [NSJSONSerialization dataWithJSONObject:dataSummaryAsArray
                                                      options:NSJSONWritingPrettyPrinted
                                                        error:&dataSummaryConvertJSONError];
        
        NSString *dataSummaryAsString = [[NSString alloc] initWithData:dataSummary encoding:NSUTF8StringEncoding];
        
        if (dataSummaryConvertJSONError){
            // do nothing at the moment
        }
        //
        // ** Construct data summary
        //
        int64_t dataHeaderAsInt = (int64_t)dataSummary.length;
        
        dataHeader = [NSData dataWithBytes:&dataHeaderAsInt length:8];
        
        // stick together
        [uploadData appendData:dataHeader];
        [uploadData appendData:dataSummary];
        [uploadData appendData:dataBody];
        
        uploadTask = [self.networkService uploadRequestWithFileContentType:ImageOfMaintenanceTask
                                                                    params:nil
                                                                    uriSetting:nil
                                                                andUploadData:uploadData
         // PROGRESS
         progressIndicator:^(NSProgress * _Nonnull transmissionProgress) {
             progress(transmissionProgress);
         }
         // COMPLETION HANDLER
         completionHandler:^(NSData *responsedData, NSError *networkError) {
             if (networkError) {
                 NSLog(@"Upload image of maintenance task 网络传输异常，原因: %@", networkError);
                 
                 NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeNetworkTransmission andCallbackError:networkError];
                 handler(FALSE, err, @"", nil);
                 
                 [[NSNotificationCenter defaultCenter] postNotificationName:WISUploadImagesFailedNotification object:(NSError *)err];
                 [self.systemDataDelegate uploadImagesFailedWithError:err];
                 
             } else {
                 if (!responsedData) {
                     NSLog(@"Upload image of maintenance task 请求异常，原因: %@", @"返回的数据为空");
                     
                     NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeResponsedNULLData andCallbackError:nil];
                     handler(FALSE, err, @"", nil);
                     
                     [[NSNotificationCenter defaultCenter] postNotificationName:WISUploadImagesFailedNotification object:(NSError *)err];
                     [self.systemDataDelegate uploadImagesFailedWithError:err];
                     
                 } else {
                     
                     NSError *parseError;
                     NSDictionary *parsedData = nil;
                     
                     parsedData = [NSJSONSerialization JSONObjectWithData:responsedData
                                                                  options:NSJSONReadingMutableContainers
                                                                    error:&parseError];
                     
                     if (!parsedData || parseError) {
                         NSLog(@"Upload image of maintenance task 操作解析服务器返回参数失败，原因: %@", parseError);
                         
                         NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeIncorrectResponsedDataFormat andCallbackError:parseError];
                         handler(FALSE, err, @"", nil);
                         
                         [[NSNotificationCenter defaultCenter]
                          postNotificationName:WISUploadImagesFailedNotification object:(NSError *)err];
                         
                         [self.systemDataDelegate uploadImagesFailedWithError:err];
                         
                     } else {
                         
                         RequestResult result = (RequestResult)[parsedData[@"Result"] integerValue];
                         NSArray *fileInfos = nil;
                         NSError *err;
                         
                         // NSMutableDictionary *updatedData = [NSMutableDictionary dictionary];
                         NSMutableArray<WISFileInfo *> *currentImagesInfo = [NSMutableArray array];
                         WISFileInfo *imageInfo = nil;
                         
                         switch (result) {
                             case RequestSuccessful:
                                 fileInfos = parsedData[@"FileInformation"];
                                 
                                 if (!fileInfos || (NSNull *)fileInfos == [NSNull null]) {
                                     
                                 } else {
                                     if(fileInfos.count > 0) {
                                         for(NSDictionary *fileInfo in fileInfos) {
                                             
                                             imageInfo = [[WISFileInfo alloc] init];
                                             imageInfo.fileName = [[[NSString stringWithString:fileInfo[@"FileName"]]componentsSeparatedByString:@"."] objectAtIndex:0];
                                             imageInfo.fileRemoteLocation = fileInfo[@"Url"];
                                             imageInfo.fileType = [imageInfo.fileRemoteLocation pathExtension];
                                             imageInfo.fileOnDeviceLocation = @"";
                                             
                                             [currentImagesInfo addObject:imageInfo];
                                             
                                             /// !!! 这一句要放到维保任务的图片上传程序里！！！
//                                             if (![self.maintenanceTasks[taskID].imagesInfo valueForKey:imageInfo.fileName]) {
//                                                 [self.maintenanceTasks[taskID].imagesInfo setValue:imageInfo forKey:imageInfo.fileName];
//                                             }
                                         }
                                     }
                                 }
                                 
                                 [[NSNotificationCenter defaultCenter]
                                  postNotificationName:WISUploadImagesSucceededNotification object:currentImagesInfo];
                                 
                                 [self.systemDataDelegate uploadImagesSucceeded];
                                 handler(TRUE, nil, NSStringFromClass([currentImagesInfo class]), currentImagesInfo);
                                 break;
                                 
                             case RequestFailed:
                                 err = [self produceErrorObjectWithWISErrorCode:ErrorCodeInvalidOperation andCallbackError:nil];
                                 
                                 [[NSNotificationCenter defaultCenter]
                                  postNotificationName:WISUploadImagesFailedNotification
                                  object:(NSError *)err];
                                 
                                 [self.systemDataDelegate uploadImagesFailedWithError:err];
                                 handler(FALSE, err, @"", nil);
                                 break;
                                 
                             default:
                                 break;
                         }
                     }
                 }
             }
         }];
    }
    return uploadTask;
}


/// 下载图片
- (NSURLSessionDownloadTask *) downloadImageWithImageLocations:(NSArray<NSString *> *)imagesRemoteLocation
                       progressIndicator:(WISSystemDataTransmissionProgressIndicator)progress
                       completionHandler:(WISSystemDataTransmissionHandler)handler {
   
    NSDictionary *downloadParams = [NSDictionary dictionaryWithObjectsAndKeys:imagesRemoteLocation, @"FileURL", nil];
    NSURLSessionDownloadTask *downloadTask = nil;
    downloadTask = [self.networkService downloadRequestWithFileContentType:ImageOfMaintenanceTask
                                                                    params:downloadParams
                                                                uriSetting:nil
     // PROGRESS
     progressIndicator:^(NSProgress *transmissionProgress) {
         progress(transmissionProgress);
         
     // COMPLETION HANDLER
     } completionHandler:^(NSData *responsedData, NSError *networkError) {
         if(networkError) {
             NSLog(@"Download image of maintenance task 网络传输异常，原因: %@", networkError);
             
             NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeNetworkTransmission andCallbackError:networkError];
             handler(FALSE, err, @"", nil);
             
             [[NSNotificationCenter defaultCenter] postNotificationName:WISDownloadImagesFailedNotification object:(NSError *)err];
             [self.systemDataDelegate downloadImagesFailedWithError:err];
             
         } else {
             
             if ((!responsedData)||responsedData.length == 0) {
                 NSLog(@"Download image of maintenance task 请求异常，原因: %@", @"返回的数据为空");
                 
                 NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeResponsedNULLData andCallbackError:nil];
                 handler(FALSE, err, @"", nil);
                 
                 [[NSNotificationCenter defaultCenter] postNotificationName:WISDownloadImagesFailedNotification object:(NSError *)err];
                 [self.systemDataDelegate downloadImagesFailedWithError:err];
                 
             } else {
                 
                 NSData *dataHeader = nil;
                 NSData *dataSummary = nil;

                 //
                 // ** Extract data header
                 //
                 NSRange rangeOfHeader = NSMakeRange(0, 8);
                 dataHeader = [responsedData subdataWithRange:rangeOfHeader];
                 
                 int64_t *headerAddress = (int64_t *)dataHeader.bytes;
                 int64_t lengthOfDataSummary = *headerAddress;
                 //
                 // ** Extract data summary
                 //
                 NSRange rangeOfSummary = NSMakeRange(8, lengthOfDataSummary);
                 dataSummary = [responsedData subdataWithRange:rangeOfSummary];
                 //
                 // ** Parse data summary
                 //
                 NSError *parseError;
                 NSArray *parsedData = nil;
                 
                 parsedData = [NSJSONSerialization JSONObjectWithData:dataSummary
                                                              options:NSJSONReadingMutableContainers
                                                                error:&parseError];
                 
                 if (!parsedData || parseError) {
                     NSLog(@"Download image of maintenance task 操作解析数据包内的文件信息参数失败，原因: %@", parseError);
                     
                     NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeIncorrectResponsedDataFormat andCallbackError:parseError];
                     
                     [[NSNotificationCenter defaultCenter]
                      postNotificationName:WISDownloadImagesFailedNotification
                      object:(NSError *)err];
                     
                     [self.systemDataDelegate downloadImagesFailedWithError:err];
                     
                     handler(FALSE, err, @"", nil);
                     
                 } else {
                     
                     NSInteger fileStartAddress = 8 + lengthOfDataSummary;
                     NSData *imageData = nil;
                     NSMutableDictionary<NSString *, UIImage *> *receivedImages = [NSMutableDictionary dictionary];
                     
                     NSInteger imageDataLength = 0;
                     NSInteger imageDataOffset = 0;
                     
                     if (parsedData.count <= 0) {
                         // do something later
                     } else {
                         
                         for (NSDictionary *fileStorageInfo in parsedData) {
                             imageDataLength = [fileStorageInfo[@"Length"] integerValue];
                             imageDataOffset = [fileStorageInfo[@"Offset"] integerValue];
                             
                             NSRange rangeOfimageData = NSMakeRange(fileStartAddress+imageDataOffset, imageDataLength);
                             imageData = [responsedData subdataWithRange:rangeOfimageData];
                             
                             UIImage *image = [UIImage imageWithData:imageData];
                             NSString *imageNameWithDate = [NSString stringWithFormat:@"%@", fileStorageInfo[@"FileName"]];
                             NSString *imageName = [[imageNameWithDate componentsSeparatedByString:@"."] objectAtIndex:0];
                             
                             if (![receivedImages valueForKey:imageName]) {
                                 [receivedImages setValue:image forKey:imageName];
                             }
                         }
                     }
                     
                     [[NSNotificationCenter defaultCenter] postNotificationName:WISDownloadImagesSucceededNotification object:receivedImages];
                     
                     [self.systemDataDelegate downloadImagesSucceeded];
                     handler(TRUE, nil, NSStringFromClass([receivedImages class]), receivedImages);
                 }
             }
         }
     }];
    return downloadTask;
}


#pragma mark - support method: producers

/// 对象内部使用, 用于进行维保任务各种操作网络请求的通用函数
- (NSURLSessionDataTask *) maintenanceTaskOperationWithTaskID:(NSString *) taskID
                                                       remark:(NSString *) remark
                                                operationType:(MaintenanceTaskOperationType) operationType
                                             taskReceiverName:(NSString *) taskReceiverName /*转单时用. 非转单时填@""*/
                                           applicationContent:(NSString *) applicationContent
                                             processSegmentID:(NSInteger) processSegmentID
                                         applicationImageInfo:(NSDictionary<NSString *, WISFileInfo *> *)applicationImagesInfo
                           maintenancePlanEstimatedEndingTime:(NSDate *) maintenancePlanEstimatedEndingTime
                                maintenancePlanDescription:(NSString *) maintenancePlanDescription
                                  maintenancePlanParticipants:(NSArray <WISUser *> *) maintenancePlanParticipants
                                                taskImageInfo:(NSDictionary<NSString *, WISFileInfo *> *)taskImagesInfo
                                                   taskRating:(WISMaintenanceTaskRating *) taskRating
                                         andCompletionHandler:(WISMaintenanceTaskOperationHandler) handler {
    
    NSDictionary * operationParams = nil;
    NSURLSessionDataTask *dataTask = nil;
    
    if ([self.currentUser.userName isEqual: @""] || self.currentUser.userName == nil
        || [self.networkRequestToken isEqual: @""] || self.networkRequestToken == nil) {
        
        NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeNoCurrentUserInfo callbackError:nil
                                                         taskID:taskID
                                andMaintenanceTaskOperationType:operationType];
        handler(FALSE, err);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WISOperationOnMaintenanceTaskFailedNotification object:(NSError *)err];
        if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(OperationOnMaintenanceTaskFailedWithError:)]) {
            [self.maintenanceTaskOpDelegate OperationOnMaintenanceTaskFailedWithError:err];
        }
        
    } else {
        
        operationParams = [self produceMaintenanceTaskOperationParameterWithUserName:self.currentUser.userName
                                                                 networkRequestToken:self.networkRequestToken
                                                                              taskID:taskID
                                                                              remark:remark
                                                                       operationType:operationType
                                                                    taskReceiverName:taskReceiverName
                                                                  applicationContent:applicationContent
                                                                    processSegmentID:processSegmentID
                                                                applicationImageInfo:applicationImagesInfo
                                                  maintenancePlanEstimatedEndingTime:maintenancePlanEstimatedEndingTime
                                                          maintenancePlanDescription:maintenancePlanDescription
                                                         maintenancePlanParticipants:maintenancePlanParticipants
                                                                       taskImageInfo:taskImagesInfo
                                                                       andTaskRating:taskRating];
        
        dataTask = [self.networkService dataRequestWithRequestType:SubmitCommand
                                                            params:operationParams
                                                     andUriSetting:nil
         completionHandler:^(RequestType requestType, NSData *responsedData, NSError *networkError) {
              if (!responsedData) {
                  NSLog(@"Operation on maintenance task (taskID: %@) 请求异常，原因: %@", taskID, @"返回的数据为空");
                  
                  NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeResponsedNULLData callbackError:networkError
                                                                   taskID:taskID
                                          andMaintenanceTaskOperationType:operationType];
                  handler(FALSE, err);
                  
                  [[NSNotificationCenter defaultCenter] postNotificationName:WISOperationOnMaintenanceTaskFailedNotification object:(NSError *)err];
                  if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(OperationOnMaintenanceTaskFailedWithError:)]) {
                      [self.maintenanceTaskOpDelegate OperationOnMaintenanceTaskFailedWithError:err];
                  }
                  
              } else {
                  
                  NSError *parseError;
                  NSDictionary *parsedData = nil;
                  
                  parsedData = [NSJSONSerialization JSONObjectWithData:responsedData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&parseError];
                  
                  if (!parsedData || parseError) {
                      NSLog(@"Operation on maintenance task (taskID: %@) 解析返回内容失败，原因: %@", taskID, parseError);
                      
                      NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeIncorrectResponsedDataFormat andCallbackError:parseError];
                      handler(FALSE, err);
                      
                      [[NSNotificationCenter defaultCenter]
                       postNotificationName:WISOperationOnMaintenanceTaskFailedNotification
                       object:(NSError *)err];
                      
                      if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(OperationOnMaintenanceTaskFailedWithError:)]) {
                          [self.maintenanceTaskOpDelegate OperationOnMaintenanceTaskFailedWithError:err];
                      }
                      
                  } else {
                      
                      RequestResult result = (RequestResult)[parsedData[@"Result"] integerValue];
                      NSError *err;
                      
                      switch (result) {
                          case RequestSuccessful:
                              [[NSNotificationCenter defaultCenter]
                               postNotificationName:WISOperationOnMaintenanceTaskSucceededNotification object:self];
                              if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(OperationOnMaintenanceTaskSucceeded)]) {
                                  [self.maintenanceTaskOpDelegate OperationOnMaintenanceTaskSucceeded];
                              }
                              
                              handler(YES, nil);
                              
                              break;
                              
                          case RequestFailed:
                              err = [self produceErrorObjectWithWISErrorCode:ErrorCodeInvalidOperation callbackError:nil taskID:taskID andMaintenanceTaskOperationType:operationType];
                              
                              [[NSNotificationCenter defaultCenter] postNotificationName:WISOperationOnMaintenanceTaskFailedNotification object:(NSError *)err];
                            
                              if ([self.maintenanceTaskOpDelegate respondsToSelector:@selector(OperationOnMaintenanceTaskFailedWithError:)]) {
                                  [self.maintenanceTaskOpDelegate OperationOnMaintenanceTaskFailedWithError:err];
                              }
                              handler(FALSE, err);
                              break;
                              
                          default:
                              break;
                      }
                  }
                  
                  
//                  NSString *parsedData;
//                  
//                  parsedData = [[NSString alloc] initWithData:responsedData encoding:NSUTF8StringEncoding];
//                  
//                  BOOL operationSuccessful = [parsedData  isEqual: @"true"];
//                  
//                  if (operationSuccessful) {
//                      handler(YES, nil);
//                      
//                      [[NSNotificationCenter defaultCenter] postNotificationName:WISOperationOnMaintenanceTaskSucceededNotification object:self];
//                      
//                      [self.opDelegate OperationOnMaintenanceTaskSucceeded];
//                      
//                  } else {
//                      
//                      NSError *err = [self produceErrorObjectWithWISErrorCode:ErrorCodeInvalidOperation callbackError:nil
//                                                                       taskID:taskID
//                                              andMaintenanceTaskOperationType:operationType];
//                      handler(FALSE, err);
//                      
//                      [[NSNotificationCenter defaultCenter]
//                       postNotificationName:WISOperationOnMaintenanceTaskFailedNotification
//                       object:(NSError *)err];
//                      
//                      [self.opDelegate OperationOnMaintenanceTaskFailedWithError:err];
//                  }
              }
         }];
    }
    
    return dataTask;
}


/// 程序内部使用的支持性函数，用于维保任务操作请求过程网络参数的生成
- (NSDictionary *) produceMaintenanceTaskOperationParameterWithUserName:(NSString *) userName
                                                    networkRequestToken:(NSString *) requestToken
                                                                 taskID:(NSString *) taskID
                                                                 remark:(NSString *) remark
                                                          operationType:(MaintenanceTaskOperationType) operationType
                                                       taskReceiverName:(NSString *) taskReceiverName /*转单时用*/
                                                     applicationContent:(NSString *) applicationContent
                                                       processSegmentID:(NSInteger) processSegmentID
                                                   applicationImageInfo:(NSDictionary<NSString *, WISFileInfo *> *)applicationImagesInfo
                                     maintenancePlanEstimatedEndingTime:(NSDate *) maintenancePlanEstimatedEndingTime
                                             maintenancePlanDescription:(NSString *) maintenancePlanDescription
                                            maintenancePlanParticipants:(NSArray <WISUser *> *) maintenancePlanParticipants
                                                          taskImageInfo:(NSDictionary<NSString *, WISFileInfo *> *)taskImagesInfo
                                                          andTaskRating:(WISMaintenanceTaskRating *) taskRating {
    
    NSMutableDictionary *operationParam = [NSMutableDictionary dictionary];
    
    // userName and networkRequestToken
    [operationParam setValue:[NSDictionary dictionaryWithObjectsAndKeys:userName, @"UserName", requestToken, @"PassWord", nil]
                      forKey:@"User"];
    
    // taskID
    if (taskID == nil || [taskID isEqualToString:@""])
        [operationParam setValue:[NSNumber numberWithInteger:0] forKey:@"TaskID"];
    else
        [operationParam setValue:taskID forKey:@"TaskID"];

    // remark
    if (remark == nil || [remark isEqualToString:@""])
        [operationParam setValue:@"" forKey:@"Description"];
    else
        [operationParam setValue:remark forKey:@"Description"];
    
    // taskReceiverName
    if (taskReceiverName == nil || [taskReceiverName isEqualToString:@""])
        [operationParam setValue:[NSNull null] forKey:@"NextUserName"];
    else
        [operationParam setValue:taskReceiverName forKey:@"NextUserName"];
    
    // operationType
    [operationParam setValue:[NSNumber numberWithInteger:operationType] forKey:@"OperationID"];
    
    // ***** submit new maintenanceTask information *****
    if ((taskID == nil || [taskID isEqualToString:@""]) && operationType == SubmitApply) {
        NSString *tpAppContent = nil;
        NSInteger tpProcessSegmentID;
        NSMutableArray<NSString *> *tpApplicationImageLocations = [NSMutableArray array];
        
        if (applicationContent ==nil || [applicationContent isEqualToString:@""])
            tpAppContent = @"";
        else
            tpAppContent = applicationContent;
        
        if (processSegmentID == NSIntegerMin)
            tpProcessSegmentID = NSIntegerMin;
        else
            tpProcessSegmentID = processSegmentID;

        if (applicationImagesInfo && !((NSNull *)applicationImagesInfo == [NSNull null])) {
            if(applicationImagesInfo.count > 0) {
                for(WISFileInfo *imageInfo in applicationImagesInfo.allValues) {
                    [tpApplicationImageLocations addObject:imageInfo.fileRemoteLocation];
                }
            }
        }
        
        [operationParam setValue:[NSDictionary dictionaryWithObjectsAndKeys:tpAppContent, @"ApplyContent", [NSNumber numberWithInteger:tpProcessSegmentID], @"FaultAreaID", tpApplicationImageLocations, @"FileURL", nil]
                          forKey:@"Order"];
    } else {
        [operationParam setValue:[NSNull null] forKey:@"Order"];
    }
    
    
    // ***** maintenance plan information *****
    if (operationType != SubmitMaintenancePlan && operationType != ApplyForRecheck && operationType != StartFastProcedure && operationType != Approve && operationType != Continue && operationType != Modify) {
        [operationParam setValue:[NSNull null] forKey:@"Plan"];
        
    } else {
    
        NSString *tpMaintenancePlanDescription = nil;
        NSDate *tpMaintenancePlanEstimatedEndingTime = nil;
        NSMutableArray<NSString *> *tpTaskImageLocations = [NSMutableArray array];
        NSMutableArray <NSDictionary *> *tpMaintenancePlanParticipants = [NSMutableArray array];
        
        // description
        if (maintenancePlanDescription == nil || [maintenancePlanDescription isEqualToString:@""])
            tpMaintenancePlanDescription = @"";
        else
            tpMaintenancePlanDescription = maintenancePlanDescription;
        // estimated ending time
        if (maintenancePlanEstimatedEndingTime == nil) {
            tpMaintenancePlanEstimatedEndingTime = [NSDate date];
            NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
            NSInteger interval = [timeZone secondsFromGMTForDate: tpMaintenancePlanEstimatedEndingTime];
            tpMaintenancePlanEstimatedEndingTime = [tpMaintenancePlanEstimatedEndingTime dateByAddingTimeInterval:interval];
        } else
            tpMaintenancePlanEstimatedEndingTime = maintenancePlanEstimatedEndingTime;
        
        // imageLocations
        if (taskImagesInfo && !((NSNull *)taskImagesInfo == [NSNull null])) {
            if(taskImagesInfo.count > 0) {
                for(WISFileInfo *imageInfo in taskImagesInfo.allValues) {
                    if (imageInfo.fileRemoteLocation) {
                        [tpTaskImageLocations addObject:imageInfo.fileRemoteLocation];
                    } else {
                        [tpTaskImageLocations addObject:@""];
                    }
                }
            }
        }
        
        // maintenancePlanParticipants
        if (maintenancePlanParticipants == nil) {
            // do nothing
        } else {
            if (maintenancePlanParticipants.count > 0) {
                for (WISUser *participant in maintenancePlanParticipants) {
                    [tpMaintenancePlanParticipants addObject:[NSDictionary dictionaryWithObjectsAndKeys:participant.userName, @"UserName", participant.fullName, @"Name", participant.roleCode, @"RoleCode", participant.roleName, @"RoleName", participant.cellPhoneNumber, @"MobilePhone", participant.telephoneNumber, @"Telephone", nil]];
                }
            }
        }
        
        // convert tpMaintenancePlanEstimatedEndingTime into NSString format
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *maintenancePlanEstimatedEndingTimeAsString = [dateFormatter stringFromDate:tpMaintenancePlanEstimatedEndingTime];
        
        [operationParam setValue:[NSDictionary dictionaryWithObjectsAndKeys:tpMaintenancePlanDescription, @"Description",
                                  maintenancePlanEstimatedEndingTimeAsString, @"EstimatedTime",
                                  tpTaskImageLocations, @"FileURL",
                                  tpMaintenancePlanParticipants, @"Participants", nil]
                                  forKey:@"Plan"];
    }
    
    // ***** maintenance task rating *****
    if (taskRating !=nil) {
        [operationParam setValue:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:taskRating.totalScore], @"Score",
                                  [NSNumber numberWithInteger:taskRating.attitudeScore], @"AttitudeScore",
                                  [NSNumber numberWithInteger:taskRating.responseScore], @"ResponseScore",
                                  [NSNumber numberWithInteger:taskRating.qualityScore], @"QualityScore",
                                  taskRating.additionalRemark, @"Description", nil]
                          forKey:@"Remark"];
    } else {
        [operationParam setValue:[NSNull null] forKey:@"Remark"];
    }
    
    NSError *err;
    NSData *operationParamAsData = [NSJSONSerialization dataWithJSONObject:operationParam options:NSJSONWritingPrettyPrinted error:&err];
    NSString * operationParamAsString = [[NSString alloc]initWithData:operationParamAsData encoding:NSUTF8StringEncoding];
    NSLog(@"%@", operationParamAsString);
    
    return operationParam;
}


- (NSDictionary *)produceSubmitUserInformationParameterWithUserName:(NSString *) userName
                                                networkRequestToken:(NSString *) requestToken
                                                           userInfo:(WISUser *) userInfo {
    
    NSMutableDictionary *opParam = [NSMutableDictionary dictionary];
    
    // userName and networkRequestToken
    [opParam setValue:[NSDictionary dictionaryWithObjectsAndKeys:userName, @"UserName", requestToken, @"PassWord", nil]
                      forKey:@"User"];
    
    if (userInfo == nil) {
        [opParam setValue:nil forKey:@"UserInformation"];
    } else {
        NSMutableDictionary *userParam = [NSMutableDictionary dictionary];
        
        [userParam setValue:userInfo.userName forKey:@"UserName"];
        [userParam setValue:userInfo.fullName forKey:@"Name"];
        [userParam setValue:userInfo.cellPhoneNumber forKey:@"Mobilephone"];
        [userParam setValue:userInfo.telephoneNumber forKey:@"Telephone"];
        [userParam setValue:userInfo.urgentPhoneNumber forKey:@"UrgentPhone"];
        
        [userParam setValue:[userInfo.birthday toDateStringWithSeparator:@"-"] forKey:@"Birthday"];
        
        if (userInfo.company) {
            [userParam setValue:[NSDictionary dictionaryWithObjectsAndKeys:userInfo.company.companyID, @"CompanyID", userInfo.company.companyName, @"CompanyName", nil] forKey:@"Company"];
        }
        
        [userParam setValue:userInfo.eMail forKey:@"Email"];
        [userParam setValue:(userInfo.gender == GenderMale ? [NSNumber numberWithBool:true] : [NSNumber numberWithBool:false]) forKey:@"Gender"];
        [userParam setValue:userInfo.identityCardNumber forKey:@"IDcard"];
        [userParam setValue:[userInfo.lastUpatedTime toDateTimeString] forKey:@"LastUpdateTime"];
        
        [userParam setValue:userInfo.title forKey:@"Title"];
        [userParam setValue:userInfo.remark forKey:@"Remark"];
        
        /// IMAGE_INFO
        if (!userInfo.imagesInfo) {
            [userParam setValue:[NSArray array] forKey:@"ImageURL"];
        } else {
            if (userInfo.imagesInfo.count <= 0) {
                [userParam setValue:[NSArray array] forKey:@"ImageURL"];
            } else {
                NSMutableArray<NSString *> *urls = [NSMutableArray array];
                for (WISFileInfo *file in userInfo.imagesInfo.allValues) {
                    [urls addObject:file.fileRemoteLocation];
                }
                [userParam setValue:urls forKey:@"ImageURL"];
            }
        }
        [opParam setValue:userParam forKey:@"UserInformation"];
    }
    return opParam;
}


/// Never being used
- (NSDictionary *) produceInspectionTaskOperationParameterWithUserName:(NSString *) userName
                                                   networkRequestToken:(NSString *) requestToken
                                                              deviceID:(NSString *) deviceID
                                                            deviceName:(NSString *) deviceName
                                                            deviceCode:(NSString *) deviceCode
                                                               company:(NSString *) company
                                                        processSegment:(NSString *) processSegment
                                              devicePutIntoServiceTime:(NSDate *) devicePutIntoServiceTime
                                                          deviceRemark:(NSString *) deviceRemark
                                                          deviceTypeID:(NSString *) deviceTypeID
                                                        deviceTypeName:(NSString *) deviceTypeName
                                                       inspectionCycle:(NSInteger) inspectionCycle
                               lastInspectionFinishedTimePlusCycleTime:(NSDate *) lastInspectionFinishedTimePlusCycleTime
                                                 inspectionInformation:(NSString *) inspectionInformation
                                                      inspectionResult:(InspectionResult) inspectionResult
                                           inspectionResultDescription:(NSString *) inspectionResultDescription
                                                            imagesInfo:(NSDictionary<NSString *, WISFileInfo *> *) imagesInfo
                                                inspectionFinishedTime:(NSDate *) inspectionFinishedTime {
    
    NSMutableDictionary *operationParam = [NSMutableDictionary dictionary];
    
    // userName and networkRequestToken
    [operationParam setValue:[NSDictionary dictionaryWithObjectsAndKeys:userName, @"UserName", requestToken, @"PassWord", nil]
                      forKey:@"User"];
    
    NSMutableDictionary *inspectionParam = [NSMutableDictionary dictionary];
    // deviceID
    [inspectionParam setValue:((deviceID == nil) ? [NSNumber numberWithInteger:0] : [NSNumber numberWithInteger:[(NSString *)deviceID integerValue]]) forKey:@"DeviceId"];
    // deviceName
    [inspectionParam setValue:((deviceName == nil) ? @"" : (NSString *)deviceID) forKey:@"DeviceName"];
    // deviceCode
    [inspectionParam setValue:((deviceCode == nil) ? @"" : (NSString *)deviceID) forKey:@"DeviceCode"];
    // company
    [inspectionParam setValue:((company == nil) ? @"" : (NSString *)deviceID) forKey:@"CompanyName"];
    // processSegment
    [inspectionParam setValue:((processSegment == nil) ? @"" : (NSString *)deviceID) forKey:@"AreaName"];
    // devicePutIntoServiceTime
    [inspectionParam setValue:((devicePutIntoServiceTime == nil) ? nil : [devicePutIntoServiceTime toDateTimeString]) forKey:@"DeviceServiceTime"];
    // deviceRemark
    [inspectionParam setValue:((deviceRemark == nil) ? @"" : (NSString *)deviceRemark) forKey:@"DeviceRemark"];
    
    // deviceTypeID
    [inspectionParam setValue:((deviceTypeID == nil) ? [NSNumber numberWithInteger:0] : [NSNumber numberWithInteger:[(NSString *)deviceTypeID integerValue]]) forKey:@"DeviceTypeId"];
    // deviceTypeName
    [inspectionParam setValue:((deviceTypeName == nil) ? @"" : (NSString *)deviceTypeName) forKey:@"DeviceTypeName"];
    // inspectionCycle
    [inspectionParam setValue:[NSNumber numberWithInteger:inspectionCycle] forKey:@"DeviceTypeName"];
    
    // lastInspectionFinishedTimePlusCycleTime
    [inspectionParam setValue:((lastInspectionFinishedTimePlusCycleTime == nil) ? nil : [lastInspectionFinishedTimePlusCycleTime toDateTimeString]) forKey:@"DeadLine"];
    // inspectionInformation
    [inspectionParam setValue:((inspectionInformation == nil) ? @"" : (NSString *)inspectionInformation) forKey:@"InspectionHint"];
    // inspectionResult
    [inspectionParam setValue:[NSNumber numberWithInteger:(NSInteger)inspectionResult] forKey:@"Result"];
    // inspectionResultDescription
    [inspectionParam setValue:((inspectionResultDescription == nil) ? @"" : (NSString *)inspectionResultDescription) forKey:@"Comment"];
    
    // imagesInfo
    NSMutableArray<NSString *> *imagesURL = [NSMutableArray array];
    if (imagesInfo) {
        if (imagesInfo.allValues.count > 0) {
            for(WISFileInfo *imageInfo in imagesInfo.allValues) {
                [imagesURL addObject:imageInfo.fileRemoteLocation];
            }
        }
    }
    [inspectionParam setValue:imagesURL forKey:@"PhotoUrls"];
    
    // inspectionFinishedTime
    [inspectionParam setValue:((inspectionFinishedTime == nil) ? nil : [inspectionFinishedTime toDateTimeString]) forKey:@"InspectionTime"];
    
    /// SET inspectionParam
    [operationParam setValue:inspectionParam forKey:@"Inspection"];
    
    return operationParam;
}


- (NSDictionary *) produceInspectionTasksOperationParameterWithUserName:(NSString *) userName
                                                   networkRequestToken:(NSString *) requestToken
                                                       inspectionTasks:(NSArray<WISInspectionTask *> *)inspectionTasks {
   
    NSMutableDictionary *operationParam = [NSMutableDictionary dictionary];
    
    // userName and networkRequestToken
    [operationParam setValue:[NSDictionary dictionaryWithObjectsAndKeys:userName, @"UserName", requestToken, @"PassWord", nil]
                      forKey:@"User"];
    
    NSMutableArray *inspectionsParam = [NSMutableArray array];
    NSMutableDictionary *inspectionParam = [NSMutableDictionary dictionary];
    
    if (inspectionTasks) {
        if (inspectionTasks.count > 0) {
            for (WISInspectionTask *task in inspectionTasks) {
                
                // ** DEVICE
                // deviceID
                [inspectionParam setValue:((task.device.deviceID == nil) ? [NSNumber numberWithInteger:0] : [NSNumber numberWithInteger:[(NSString *)task.device.deviceID integerValue]]) forKey:@"DeviceId"];
                // deviceName
                [inspectionParam setValue:((task.device.deviceName == nil) ? @"" : (NSString *)task.device.deviceName) forKey:@"DeviceName"];
                // deviceCode
                [inspectionParam setValue:((task.device.deviceCode == nil) ? @"" : (NSString *)task.device.deviceCode) forKey:@"DeviceCode"];
                // company
                [inspectionParam setValue:((task.device.company == nil) ? @"" : (NSString *)task.device.company) forKey:@"CompanyName"];
                // processSegment
                [inspectionParam setValue:((task.device.processSegment == nil) ? @"" : (NSString *)task.device.processSegment) forKey:@"AreaName"];
                // devicePutIntoServiceTime
                [inspectionParam setValue:((task.device.putIntoServiceTime == nil) ? nil : [task.device.putIntoServiceTime toDateTimeString]) forKey:@"DeviceServiceTime"];
                // deviceRemark
                [inspectionParam setValue:((task.device.remark == nil) ? @"" : (NSString *)task.device.remark) forKey:@"DeviceRemark"];
                
                // ** DEVICE TYPE
                // deviceTypeID
                [inspectionParam setValue:((task.device.deviceType.deviceTypeID == nil) ? [NSNumber numberWithInteger:0] : [NSNumber numberWithInteger:[(NSString *)task.device.deviceType.deviceTypeID integerValue]]) forKey:@"DeviceTypeId"];
                // deviceTypeName
                [inspectionParam setValue:((task.device.deviceType.deviceTypeName == nil) ? @"" : (NSString *)task.device.deviceType.deviceTypeName) forKey:@"DeviceTypeName"];
                // inspectionCycle
                [inspectionParam setValue:[NSNumber numberWithInteger:task.device.deviceType.inspectionCycle] forKey:@"CycleTime"];
                
                // ** INSPECTION
                // lastInspectionFinishedTimePlusCycleTime
                [inspectionParam setValue:((task.lastInspectionFinishedTimePlusCycleTime == nil) ? nil : [task.lastInspectionFinishedTimePlusCycleTime toDateTimeString]) forKey:@"DeadLine"];
                // inspectionInformation
                [inspectionParam setValue:((task.device.deviceType.inspectionInformation == nil) ? @"" : (NSString *)task.device.deviceType.inspectionInformation) forKey:@"InspectionHint"];
                // inspectionResult
                [inspectionParam setValue:[NSNumber numberWithInteger:(NSInteger)task.inspectionResult] forKey:@"Result"];
                // inspectionResultDescription
                [inspectionParam setValue:((task.inspectionResultDescription == nil) ? @"" : (NSString *)task.inspectionResultDescription) forKey:@"Comment"];
                
                // imagesInfo
                NSMutableArray<NSString *> *imagesURL = [NSMutableArray array];
                if (task.imagesInfo) {
                    if (task.imagesInfo.allValues.count > 0) {
                        for(WISFileInfo *imageInfo in task.imagesInfo.allValues) {
                            [imagesURL addObject:imageInfo.fileRemoteLocation];
                        }
                    }
                }
                [inspectionParam setValue:imagesURL forKey:@"PhotoUrls"];
                
                // inspectionFinishedTime
                [inspectionParam setValue:((task.inspectionFinishedTime == nil) ? nil : [task.inspectionFinishedTime toDateTimeString]) forKey:@"InspectionTime"];
                
                [inspectionsParam addObject:inspectionParam];
            }
        }
    }
    
    /// SET inspectionParam
    [operationParam setValue:inspectionsParam forKey:@"Inspections"];
    
    return operationParam;
}


/// 根据WISErrorCode, 生成相应的NSError.
- (NSError *) produceErrorObjectWithWISErrorCode:(WISErrorCode)code andCallbackError:(NSError *) callbackError {
    return [self produceErrorObjectWithWISErrorCode:code callbackError:callbackError taskID:@"" andMaintenanceTaskOperationType:NULLOperation];
}


/// 根据WISErrorCode, 生成相应的NSError. 本函数针对扩展了的NSError (参见NSError+WISExtension类), 增加taskID以及操作类型OperationType, 以便测试程序中, 能方便地找到错误源
- (NSError *) produceErrorObjectWithWISErrorCode:(WISErrorCode)code
                                   callbackError:(NSError *)callbackError
                                          taskID:(NSString *)taskID
                 andMaintenanceTaskOperationType:(MaintenanceTaskOperationType) operationType {
    
    NSMutableDictionary *userInfoAll = [NSMutableDictionary dictionary];
    
    if (callbackError && !((NSNull *)callbackError == [NSNull null])) {
        [userInfoAll addEntriesFromDictionary:callbackError.userInfo];
    }
    
    NSError *err = nil;
    NSDictionary *userInfoSelfDefined = nil;
    
    switch (code) {
            /// 函数参数错误
        case ErrorCodeWrongFuncParameters:
            userInfoSelfDefined =
                        @{NSLocalizedDescriptionKey:NSLocalizedString(@"传递给函数的参数有误", nil),
                         NSLocalizedFailureReasonErrorKey:NSLocalizedString(@"未填写用户名或密码", nil),
                         NSLocalizedRecoverySuggestionErrorKey:NSLocalizedString(@"检查传递给函数的参数是否正确", nil),
                         ErrorTaskIDKey:taskID,
                         ErrorOperationTypeKey:[NSNumber numberWithInteger:operationType]};
            
            [userInfoAll addEntriesFromDictionary:userInfoSelfDefined];
            err = [NSError errorWithDomain:WISErrorDomain
                                      code:(NSInteger)ErrorCodeWrongFuncParameters
                                  userInfo:userInfoAll];
            break;
            
            /// 服务器返回的数据与预设值不一致，数据解析失败
        case ErrorCodeIncorrectResponsedDataFormat:
            userInfoSelfDefined =
                        @{NSLocalizedDescriptionKey:NSLocalizedString(@"返回的JSON数据解析失败", nil),
                         NSLocalizedFailureReasonErrorKey:NSLocalizedString(@"返回的数据格式有误，或数据不完整", nil),
                         NSLocalizedRecoverySuggestionErrorKey:NSLocalizedString(@"检查数据库定义的值是否与程序设计一致", nil),
                         ErrorTaskIDKey:taskID,
                         ErrorOperationTypeKey:[NSNumber numberWithInteger:operationType]};
            
            [userInfoAll addEntriesFromDictionary:userInfoSelfDefined];
            err = [[NSError alloc] initWithDomain:WISErrorDomain
                                             code:(NSInteger)ErrorCodeIncorrectResponsedDataFormat
                                         userInfo:userInfoAll];
            break;
            
            /// 服务器返回的为nil，或网络连接异常
        case ErrorCodeResponsedNULLData:
            userInfoSelfDefined =
                        @{NSLocalizedDescriptionKey:NSLocalizedString(@"获得的返回数据为nil", nil),
                         NSLocalizedFailureReasonErrorKey:NSLocalizedString(@"HTTP请求参数错误，或网络连接异常", nil),
                         NSLocalizedRecoverySuggestionErrorKey:NSLocalizedString(@"检查HTTP请求参数与网络连接是否异常", nil),
                         ErrorTaskIDKey:taskID,
                         ErrorOperationTypeKey:[NSNumber numberWithInteger:operationType]};
            
            [userInfoAll addEntriesFromDictionary:userInfoSelfDefined];
            err = [NSError errorWithDomain:WISErrorDomain
                                      code:(NSInteger)ErrorCodeResponsedNULLData
                                  userInfo:userInfoAll];
            break;
            
            /// 登录的用户不存在
        case ErrorCodeSignInUserNotExist:
            userInfoSelfDefined =
                        @{NSLocalizedDescriptionKey:NSLocalizedString(@"用户名不存在", nil),
                         NSLocalizedFailureReasonErrorKey:NSLocalizedString(@"登录的用户名不存在", nil),
                         NSLocalizedRecoverySuggestionErrorKey:NSLocalizedString(@"请检查用户名", nil),
                         ErrorTaskIDKey:taskID,
                         ErrorOperationTypeKey:[NSNumber numberWithInteger:operationType]};
            
            [userInfoAll addEntriesFromDictionary:userInfoSelfDefined];
            err = [[NSError alloc] initWithDomain:WISErrorDomain
                                             code:(NSInteger)ErrorCodeSignInUserNotExist
                                         userInfo:userInfoAll];
            break;
            
            /// 登录密码错误
        case ErrorCodeSignInWrongPassword:
            userInfoSelfDefined =
                        @{NSLocalizedDescriptionKey:NSLocalizedString(@"密码错误", nil),
                         NSLocalizedFailureReasonErrorKey:NSLocalizedString(@"登录密码错误", nil),
                         NSLocalizedRecoverySuggestionErrorKey:NSLocalizedString(@"请检查登录密码", nil),
                         ErrorTaskIDKey:taskID,
                         ErrorOperationTypeKey:[NSNumber numberWithInteger:operationType]};
            
            [userInfoAll addEntriesFromDictionary:userInfoSelfDefined];
            err = [[NSError alloc] initWithDomain:WISErrorDomain
                                             code:(NSInteger)ErrorCodeSignInWrongPassword
                                         userInfo:userInfoAll];
            break;
            
            /// 没有当前登录的用户信息
        case ErrorCodeNoCurrentUserInfo:
            userInfoSelfDefined =
                        @{NSLocalizedDescriptionKey:NSLocalizedString(@"无当前登录的用户信息", nil),
                         NSLocalizedFailureReasonErrorKey:NSLocalizedString(@"未正确登录", nil),
                         NSLocalizedRecoverySuggestionErrorKey:NSLocalizedString(@"请重新登录", nil),
                         ErrorTaskIDKey:taskID,
                         ErrorOperationTypeKey:[NSNumber numberWithInteger:operationType]};
            
            [userInfoAll addEntriesFromDictionary:userInfoSelfDefined];
            err = [[NSError alloc] initWithDomain:WISErrorDomain
                                             code:(NSInteger)ErrorCodeNoCurrentUserInfo
                                         userInfo:userInfoAll];
            break;
            
            /// 操作非法
        case ErrorCodeInvalidOperation:
            userInfoSelfDefined =
                        @{NSLocalizedDescriptionKey:NSLocalizedString(@"操作失败", nil),
                         NSLocalizedFailureReasonErrorKey:NSLocalizedString(@"操作参数有误", nil),
                         NSLocalizedRecoverySuggestionErrorKey:NSLocalizedString(@"请检查该操作的参数", nil),
                         ErrorTaskIDKey:taskID,
                         ErrorOperationTypeKey:[NSNumber numberWithInteger:operationType]};
            
            [userInfoAll addEntriesFromDictionary:userInfoSelfDefined];
            err = [[NSError alloc] initWithDomain:WISErrorDomain
                                             code:(NSInteger)ErrorCodeInvalidOperation
                                         userInfo:userInfoAll];
            break;
            
            /// 网络传输错误
        case ErrorCodeNetworkTransmission:
            userInfoSelfDefined =
                        @{NSLocalizedDescriptionKey:NSLocalizedString(@"网络传输错误", nil),
                         NSLocalizedFailureReasonErrorKey:NSLocalizedString(@"网络参数有误，或网络连接异常", nil),
                         NSLocalizedRecoverySuggestionErrorKey:NSLocalizedString(@"请检查程序中设置的网络参数设置是否与服务器端的定义一致，以及网络连接是否异常", nil),
                         ErrorTaskIDKey:taskID,
                         ErrorOperationTypeKey:[NSNumber numberWithInteger:operationType]};
            
            [userInfoAll addEntriesFromDictionary:userInfoSelfDefined];
            err = [[NSError alloc] initWithDomain:WISErrorDomain
                                             code:(NSInteger)ErrorCodeNetworkTransmission
                                         userInfo:userInfoAll];
            break;
            
        default:
            err = nil;
            break;
    }
    
    return err;
}


/// method works well on windows style file URL, because on windows, the separator of path is "\", while on Mac, the separator is "/"
+ (WISFileInfo *) produceFileInfoWithFileRemoteURL:(NSString *)url {
    WISFileInfo *fileInfo = [[WISFileInfo alloc] init];
    
    NSArray *fileFullNameComponent = [url componentsSeparatedByString:@"\\"];
    NSString *fileNameWithExtension = [fileFullNameComponent objectAtIndex:(fileFullNameComponent.count - 1)];
    
    fileInfo.fileType = [fileNameWithExtension pathExtension];
    fileInfo.fileName = [[fileNameWithExtension componentsSeparatedByString:@"."] objectAtIndex:0];
    fileInfo.fileRemoteLocation = url;
    fileInfo.fileOnDeviceLocation = @"";
    
    return fileInfo;
}

#pragma mark - support method: Archive and Unarchive Current User Info

- (void) updateCurrentUserWithUserInfo:(WISUser *)user {
    self.currentUser = [user copy];
    self.currentUser = self.currentUser;
}

- (void) ArchiveCurrentUserInfo {
    [[[WISFileStoreManager defaultManager] archivingStore] setLocalArchivingStorageDirectoryWithFolderName:preDefinedUserInfoArchivingFolderName key:defaultUserInfoArchivingStorageDirectoryKey];
    
    NSString *currentUserFileFullPath = [self.defaultUserInfoArchivingStorageDirectory stringByAppendingPathComponent:currentUserFileName];
    NSString *networkRequestTokenFileFullPath = [self.defaultUserInfoArchivingStorageDirectory stringByAppendingPathComponent:networkRequestTokenFileName];
    
    WISUser *userInfo = self.currentUser;
    NSString *requestToken = self.networkRequestToken;
    
    [NSKeyedArchiver archiveRootObject:userInfo toFile:currentUserFileFullPath];
    [NSKeyedArchiver archiveRootObject:requestToken toFile:networkRequestTokenFileFullPath];
}

- (void) removeArchivedCurrentUserInfo {
    NSArray<NSString *> *archivingFilesFullPath = [[[WISFileStoreManager defaultManager] archivingStore] filesFullPathInDirectory:self.defaultUserInfoArchivingStorageDirectory];
    
    if (archivingFilesFullPath.count > 0) {
        for (NSString *fileFullPath in archivingFilesFullPath) {
            [[NSFileManager defaultManager] removeItemAtPath:fileFullPath error:nil];
        }
    }
}

- (BOOL) preloadArchivedUserInfo {
    [[[WISFileStoreManager defaultManager] archivingStore] setLocalArchivingStorageDirectoryWithFolderName:preDefinedUserInfoArchivingFolderName key:defaultUserInfoArchivingStorageDirectoryKey];
    
    NSArray<NSString *> *archivingFilesFullPath = [[[WISFileStoreManager defaultManager] archivingStore] filesFullPathInDirectory:self.defaultUserInfoArchivingStorageDirectory];

    
    if (archivingFilesFullPath.count <= 1) {
        [self removeArchivedCurrentUserInfo];
        return false;
        
    } else {
        NSString *archivedFileName;
        for (NSString *fileFullPath in archivingFilesFullPath) {
            archivedFileName = [fileFullPath lastPathComponent];
            if ([archivedFileName isEqualToString: currentUserFileName]) {
                self.currentUser = [[NSKeyedUnarchiver unarchiveObjectWithFile:fileFullPath] copy];
            } else {
                self.networkRequestToken = [[NSKeyedUnarchiver unarchiveObjectWithFile:fileFullPath] copy];
            }
        }
    }
    
    return true;
    
}

- (NSString *) defaultUserInfoArchivingStorageDirectory {
    return [[[WISFileStoreManager defaultManager] archivingStore] localArchivingStorageDirectoryWithKey:defaultUserInfoArchivingStorageDirectoryKey];
}

@end
