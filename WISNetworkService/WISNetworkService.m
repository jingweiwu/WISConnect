//
//  WISNetworkService.m
//  WISConnect
//
//  Created by Jingwei Wu on 2/19/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#import "WISNetworkService.h"
#import "AFNetworking.h"


#pragma mark - Private Interface
@interface WISNetworkService (/*Private Method*/)

@property (readwrite, nonatomic, getter=isNetworkReachabilityStatusMonitoringON) BOOL networkReachabilityStatusMonitoringIsON;

@property (readwrite) NSInteger networkActivityCount;
///
@property (readwrite) RequestType requestType;

@property (readwrite) NSString *dataHostName;
@property (readwrite) NSString *dataUriServerName;

@property (readwrite) NSString *fileHostName;
@property (readwrite) NSString *fileUriServerName;

@property (readwrite) AFHTTPSessionManager *networkRequestManager;
@property (readwrite) AFHTTPSessionManager *networkFileDataManager;

@property (nonatomic, strong) NSArray<NSString *> const *commandStrings;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> const *uriTemplates;

/**
 @brief Initialiazer
 */
- (instancetype)init;

- (instancetype)initWithDataHostName:(NSString *)dataHostName
                   dataUriServerName:(NSString *)dataUriServerName
                        fileHostName:(NSString *)fileHostName
                andFileUriServerName:(NSString *)fileUriServerName;

@end

#pragma mark - Implementation
@implementation WISNetworkService

#pragma mark - Initializer
/// Shared Instance
+ (instancetype) sharedInstance {
    static WISNetworkService *sharedNetworkServiceInstance;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken,^(void) {
        sharedNetworkServiceInstance = [[self alloc] init];
    });
    return sharedNetworkServiceInstance;
}

- (instancetype) init {
    return [self initWithDataHostName:[NSString stringWithFormat:@"http://120.27.145.72:9000"]
                    dataUriServerName:[NSString stringWithFormat:@"/MaintenanceService.svc"]
                         fileHostName:[NSString stringWithFormat:@"http://120.27.145.72:9000"]
                 andFileUriServerName:[NSString stringWithFormat:@"/MaintenanceService.svc"]];
}

- (instancetype) initWithDataHostName:(NSString *)dataHostName
                    dataUriServerName:(NSString *)dataUriServerName
                         fileHostName:(NSString *)fileHostName
                 andFileUriServerName:(NSString *)fileUriServerName {
    if (self = [super init]) {
        _dataHostName = [dataHostName copy];
        _dataUriServerName = [dataUriServerName copy];
        
        _fileHostName = [fileHostName copy];
        _fileUriServerName = [fileUriServerName copy];
        
        _networkActivityCount = 0;
        
        self.requestType = SignIn;
        
        /// Define commandStrings and uriTemplates. The content will be no changed during the whole app life.
        self.commandStrings = @[@"SignIn",
                                @"ChangingPassword",
                                
                                @"UpdateCurrentUserDetailInfo",
                                @"SubmitCurrentUserDetailInfo",
                                
                                @"SubmitUserClientID",
                                
                                @"UpdateMaintenanceTaskBriefInfo",
                                @"UpdateMaintenanceTaskDetailInfo",
                                @"UpdateMaintenanceTaskMoreDetailInfo",
                                @"UpdateMaintenanceAreas",
                                @"UpdateHistoryMaintenanceTasksInfoInPages",
                                @"UpdateHistoryMaintenanceTasksInfoByNumber",
                                @"UpdateHistoryMaintenanceTasksInfoByDateRange",
                                @"UpdateUserInfo",
                                @"UpdateRelavantUserInfo",
                                
                                @"SubmitCommand",
                                
                                @"UpdateInspectionInfo",
                                @"UpdateInspectionsInfo",
                                @"UpdateDeviceTypesInfo",
                                @"UpdateOverDueInspectionsInfo",
                                @"UpdateHistoricalInspectionsInfo",
                                
                                @"SubmitInspectionResult",
                                
                                @"UpdateCurrentClockStatus",
                                @"UpdateClockRecords",
                                @"UpdateWorkShifts",
                                @"UpdateAttendanceRecords",
                                
                                @"SubmitClockAction",
                                ];
        
        self.uriTemplates = @{self.commandStrings[SignIn]: @"/User/LogIn",
                              self.commandStrings[ChangingPassword]:@"/User/UpdatePassword",
                              
                              self.commandStrings[UpdateCurrentUserDetailInfo]:@"/User/GetUserDetail",
                              self.commandStrings[SubmitCurrentUserDetailInfo]:@"/User/UpdateUserInformation",
                              
                              self.commandStrings[SubmitUserClientID]:@"/User/UpdateUserClient",
                              
                              self.commandStrings[UpdateMaintenanceTaskBriefInfo]:@"/Task/GetTaskSummary",
                              self.commandStrings[UpdateMaintenanceTaskLessDetailInfo]:@"/Task/GetTaskDetails",
                              self.commandStrings[UpdateMaintenanceTaskDetailInfo]:@"/Task/GetTaskDetailsN",
                              self.commandStrings[UpdateMaintenanceAreas]:@"/Task/GetAreas",
                              self.commandStrings[UpdateHistoryMaintenanceTasksInfoInPages]:@"/Task/GetHistorys",
                              self.commandStrings[UpdateHistoryMaintenanceTasksInfoByNumber]:@"/Task/GetHistorys",
                              self.commandStrings[UpdateHistoryMaintenanceTasksInfoByDateRange]:@"/Task/GetHistorys",
                              self.commandStrings[UpdateContactUserInfo]:@"/User/GetUsers",
                              self.commandStrings[UpdateRelavantUserInfo]:@"/User/GetRelavantUsers",
                              
                              self.commandStrings[SubmitCommand]:@"/Command/SubmitCommand",
                              
                              self.commandStrings[UpdateInspectionInfo]:@"/Inspection/GetInspection",
                              self.commandStrings[UpdateInspectionsInfo]:@"/Inspection/GetInspections",
                              self.commandStrings[UpdateDeviceTypesInfo]:@"/Inspection/GetAllDeviceTypes",
                              self.commandStrings[UpdateOverDueInspectionsInfo]:@"/Inspection/GetOverDueInspections",
                              self.commandStrings[UpdateHistoricalInspectionsInfo]:@"/Inspection/GetHistoryInspections",
                              
                              self.commandStrings[SubmitInspectionResult]:@"/Inspection/SubmitInspection",
                              
                              self.commandStrings[UpdateCurrentClockStatus]:@"/User/GetClockStatus",
                              self.commandStrings[UpdateClockRecords]:@"/User/GetClockRecords",
                              self.commandStrings[UpdateWorkShifts]:@"/User/GetShifts",
                              self.commandStrings[UpdateAttendanceRecords]:@"/User/GetMyStaffStatus",
                              
                              self.commandStrings[SubmitClockAction]:@"/User/Clock",
                              };
        
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        ///
        _networkRequestManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:self.dataHostName]
                                                          sessionConfiguration:sessionConfiguration];
        
        _networkRequestManager.responseSerializer = [AFJSONResponseSerializer serializer];
        _networkRequestManager.requestSerializer = [AFJSONRequestSerializer serializer];
        // [_networkRequestManager willChangeValueForKey:@"timeoutInterval"];
        // _networkRequestManager.requestSerializer.timeoutInterval = 10;
        // [_networkRequestManager didChangeValueForKey:@"timeoutInterval"];
        [_networkRequestManager.requestSerializer setTimeoutInterval:10];
        
        ///
        _networkFileDataManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:self.fileHostName]
                                                           sessionConfiguration:sessionConfiguration];
        
        _networkFileDataManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        _networkFileDataManager.requestSerializer = [AFHTTPRequestSerializer serializer];
        // [_networkFileDataManager willChangeValueForKey:@"timeoutInterval"];
        // _networkFileDataManager.requestSerializer.timeoutInterval = 10;
        // [_networkFileDataManager didChangeValueForKey:@"timeoutInterval"];
        [_networkFileDataManager.requestSerializer setTimeoutInterval:20];
    }
    return self;
}

- (NSInteger) networkReachabilityStatusAsInteger {
    return (NSInteger)[[AFNetworkReachabilityManager sharedManager] networkReachabilityStatus];
}

#pragma mark - Network Reachability Monitoring
///
- (void) setNetworkReachabilityStatusChangeHandler:(WISNetworkReachabilityStatusChangedHandler)handler {
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        handler((NSInteger)status);
        NSLog(@"Reachability: %@", AFStringFromNetworkReachabilityStatus(status));
    }];
}

- (void) startNetworkingReachabilityStatusMonitoring {
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    self.networkReachabilityStatusMonitoringIsON = TRUE;
}

- (void) stopNetworkingReachabilityStatusMonitoring {
    [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
    self.networkReachabilityStatusMonitoringIsON = FALSE;
}

- (BOOL) isNetworkReachabilityStatusMonitoringON {
    return self.networkReachabilityStatusMonitoringIsON;
}


#pragma mark - Network Activity Counting
- (void) increaseNetworkActivityCount {
    dispatch_async(dispatch_get_main_queue(), ^{
        _networkActivityCount += 1;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = (_networkActivityCount > 0);
    });
}

- (void) decreaseNetworkActivityCount {
    dispatch_async(dispatch_get_main_queue(), ^{
        _networkActivityCount -= 1;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = (_networkActivityCount > 0);
    });
    
}

#pragma mark - Network Request and Data Transmission
- (NSURLSessionDataTask*) dataRequestWithRequestType:(RequestType) requestType
                                              params:(NSDictionary *)params
                                       andUriSetting:(NSArray<NSString *> *)uriSettings
                                   completionHandler:(WISNetworkHandler) handler {
    
    NSMutableString *path = [NSMutableString stringWithFormat:@"%@", self.dataUriServerName];
    
    /// 合成URI
    [path appendString:self.uriTemplates[self.commandStrings[requestType]]];
    
    switch (requestType) {
            ///
            /// *** SYSTEM DATA
            ///
        case SignIn:
            // ** fall-through **
        case ChangingPassword:
            // ** fall-through **
        case UpdateCurrentUserDetailInfo:
            // ** fall-through **
        case SubmitCurrentUserDetailInfo:
            break;
        case SubmitUserClientID:
            [path appendFormat:@"%@OS=%@&ID=%@", @"?", uriSettings[0], uriSettings[1]];
            break;
            
            ///
            /// *** CLOCK SERVICE
            ///
        case SubmitClockAction:
            // ** fall-through **
        case UpdateCurrentClockStatus:
            break;
            
        case UpdateClockRecords:
            [path appendFormat:@"%@start=%@&end=%@", @"?", uriSettings[0], uriSettings[1]];
            break;
            
        case UpdateWorkShifts:
            [path appendFormat:@"%@start=%@&num=%@", @"?", uriSettings[0], uriSettings[1]];
            break;
            
        case UpdateAttendanceRecords:
            [path appendFormat:@"%@date=%@", @"?", uriSettings[0]];
            break;
            
            ///
            /// *** MAITENANCE TASK
            ///
        case UpdateMaintenanceAreas:
            // ** fall-through **
        case UpdateContactUserInfo:
            // ** fall-through **
        case UpdateRelavantUserInfo:
            // ** fall-through **
        case SubmitCommand:
            break;
            
            
        case UpdateMaintenanceTaskBriefInfo:
            // ** fall-through **
        case UpdateMaintenanceTaskLessDetailInfo:
            [path appendFormat:@"%@%@", @"/", uriSettings[0]];
            break;
            
        case UpdateMaintenanceTaskDetailInfo:
            [path appendFormat:@"%@%@", @"/", uriSettings[0]];
            break;
            
        case UpdateHistoryMaintenanceTasksInfoInPages:
            [path appendFormat:@"%@typeID=%@&size=%@&index=%@", @"?", uriSettings[0], uriSettings[1], uriSettings[2]];
            break;
            
        case UpdateHistoryMaintenanceTasksInfoByNumber:
            [path appendFormat:@"%@%@%@%@", @"/", uriSettings[0], @"/", uriSettings[1]];
            break;
            
        case UpdateHistoryMaintenanceTasksInfoByDateRange:
            [path appendFormat:@"%@%@%@startTime=%@&endTime=%@",
                @"/", uriSettings[0], @"/", uriSettings[1], uriSettings[2]];
            break;
            
            ///
            /// *** INSPECTION
            ///
        case UpdateInspectionInfo:
            [path appendFormat:@"%@id=%@", @"?", uriSettings[0]];
            break;

        case UpdateInspectionsInfo:
            // ** fall-through **
        case UpdateDeviceTypesInfo:
            // ** fall-through **
        case UpdateOverDueInspectionsInfo:
            break;
            
        case UpdateHistoricalInspectionsInfo:
            [path appendFormat:@"%@startDate=%@&endDate=%@&pageSize=%@&pageIndex=%@", @"?", uriSettings[0], uriSettings[1], uriSettings[2], uriSettings[3]];
            break;
            
        case SubmitInspectionResult:
            break;
        
        default:
            break;
    }
    
    NSError *errorWithJSON;
    /// these two variables below are not used in current content
    NSData *paramsAsData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:&errorWithJSON];
    NSString *paramsAsString = [[NSString alloc] initWithData:paramsAsData encoding:NSUTF8StringEncoding];
    NSLog(@"%@", paramsAsString);
    
    __block NSURLSessionDataTask *dataTask = [self.networkRequestManager POST:path
                                                                   parameters:params
    /// ** PROGRESS
    progress:^(NSProgress * _Nonnull uploadProgress) {
        ;// do nothing
    /// ** SUCCESS
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (!responseObject) {
            [[NSNotificationCenter defaultCenter] postNotificationName:WISNetworkResponsedNULLDataNotification                                                                object:(NSData *)responseObject];
            
            if ([self.opDelegate respondsToSelector:@selector(networkService:ResponsedNULLData:)]) {
                [self.opDelegate networkService:self ResponsedNULLData:responseObject];
            }
            
            handler(requestType, nil, nil);
            
        } else {
        
            NSError *errorWithData = nil;
            NSData *responsedData = nil;
            
            /// ** When _networkRequestManager.responseSerializer set to AFJSONResponseSerializer, Using statement below, convert JSON object to Data for high level operation.
            responsedData = [NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingPrettyPrinted error:&errorWithData];
            
            /// ** When _networkRequestManager.responseSerializer set to AFHTTPResponseSerializer, Using statement below, to bring back original Data as return value.
            // responsedData = responseObject;
            
            if (errorWithData) {
                [[NSNotificationCenter defaultCenter] postNotificationName:WISNetworkResponsedDataParseErrorNotification                                                                object:(NSData *)responseObject];
                
                [self.opDelegate networkService:self FailedToParseResponsedData:responseObject WithError:errorWithData];
                
                handler(requestType, nil, errorWithData);
                
            } else {
                switch (requestType) {
                        
                        ///
                        /// *** SYSTEM DATA
                        ///
                        /// 登录
                    case SignIn:
                        [[NSNotificationCenter defaultCenter] postNotificationName:WISSystemSignInResponsedNotification                                                                object:(NSData *)responsedData];
                        
                        if ([self.opDelegate respondsToSelector:@selector(networkService:DidSignInAndResponsedWithData:)]) {
                            [self.opDelegate networkService:self DidSignInAndResponsedWithData:responsedData];
                        }
                        break;
                        
                        /// 修改密码
                    case ChangingPassword:
                        [[NSNotificationCenter defaultCenter] postNotificationName:WISSystemChangingPasswordResponsedNotification                                                                object:(NSData *)responsedData];
                        
                        if ([self.opDelegate respondsToSelector:@selector(networkService:DidChangePasswordAndResponsedWithData:)]) {
                            [self.opDelegate networkService:self DidChangePasswordAndResponsedWithData:responsedData];
                        }
                        break;
                        
                        /// 获取当前用户的详细信息
                    case UpdateCurrentUserDetailInfo:
                        [[NSNotificationCenter defaultCenter] postNotificationName:WISSystemUpdateCurrentUserDetailInfoResponsedNotification                                                                object:(NSData *)responsedData];
                        
                        if ([self.opDelegate respondsToSelector:@selector(networkService:DidUpdateCurrentUserDetailInfoAndResponsedWithData:)]) {
                            [self.opDelegate networkService:self DidUpdateCurrentUserDetailInfoAndResponsedWithData:responsedData];
                        }
                        break;
                        
                        /// 提交对当前用户详细信息的修改
                    case SubmitCurrentUserDetailInfo:
                        [[NSNotificationCenter defaultCenter] postNotificationName:WISSystemSubmitCurrentUserDetailInfoResponsedNotification                                                                object:(NSData *)responsedData];
                        
                        if ([self.opDelegate respondsToSelector:@selector(networkService:DidSubmitCurrentUserDetailInfoAndResponsedWithData:)]) {
                            [self.opDelegate networkService:self DidSubmitCurrentUserDetailInfoAndResponsedWithData:responsedData];
                        }
                        break;
                        
                        ///
                        /// *** CLOCK SERVICE
                        ///
                        /// 打卡请求
                    case SubmitClockAction:
                        [[NSNotificationCenter defaultCenter] postNotificationName:WISSystemSubmitClockActionResponsedNotification                                                                object:(NSData *)responsedData];
                        
                        if ([self.opDelegate respondsToSelector:@selector(networkService:DidSubmitClockActionAndResponseWithData:)]) {
                            [self.opDelegate networkService:self DidSubmitClockActionAndResponseWithData:responsedData];
                        }
                        break;
                        
                        /// 获取当前打卡状态
                    case UpdateCurrentClockStatus:
                        [[NSNotificationCenter defaultCenter] postNotificationName:WISSystemUpdateCurrentClockStatusResponsedNotification                                                                object:(NSData *)responsedData];
                        
                        if ([self.opDelegate respondsToSelector:@selector(networkService:DidUpdateCurrentClockStatusAndResponseWithData:)]) {
                            [self.opDelegate networkService:self DidUpdateCurrentClockStatusAndResponseWithData:responsedData];
                        }
                        break;
                        
                        /// 获取打卡记录
                    case UpdateClockRecords:
                        [[NSNotificationCenter defaultCenter] postNotificationName:WISSystemUpdateClockRecordsResponsedNotification                                                                object:(NSData *)responsedData];
                        
                        if ([self.opDelegate respondsToSelector:@selector(networkService:DidUpdateClockRecordsAndResponseWithData:)]) {
                            [self.opDelegate networkService:self DidUpdateClockRecordsAndResponseWithData:responsedData];
                        }
                        break;
                        
                        /// 获取排班纪录
                    case UpdateWorkShifts:
                        [[NSNotificationCenter defaultCenter] postNotificationName:WISSystemUpdateWorkShiftsResponsedNotification                                                                object:(NSData *)responsedData];
                        
                        if ([self.opDelegate respondsToSelector:@selector(networkService:DidUpdateWorkShiftsAndResponseWithData:)]) {
                            [self.opDelegate networkService:self DidUpdateWorkShiftsAndResponseWithData:responsedData];
                        }
                        break;
                        
                        /// 获取考勤信息
                    case UpdateAttendanceRecords:
                        [[NSNotificationCenter defaultCenter] postNotificationName:WISSystemUpdateAttendanceRecordsResponsedNotification                                                                object:(NSData *)responsedData];
                        
                        if ([self.opDelegate respondsToSelector:@selector(networkService:DidUpdateAttendanceRecordsAndResponseWithData:)]) {
                            [self.opDelegate networkService:self DidUpdateAttendanceRecordsAndResponseWithData:responsedData];
                        }
                        break;
                        
                        ///
                        /// *** MAITENANCE TASK
                        ///
                        /// 获取任务简要信息
                    case UpdateMaintenanceTaskBriefInfo:
                        [[NSNotificationCenter defaultCenter]
                         postNotificationName:WISUpdateMaintenanceTaskBriefInfoResponsedNotification                                                                object:(NSData *)responsedData];
                        
                        if ([self.opDelegate respondsToSelector:@selector(networkService:DidUpdateMaintenanceTaskBriefInfoAndResponsedWithData:)]) {
                            [self.opDelegate networkService:self DidUpdateMaintenanceTaskBriefInfoAndResponsedWithData:responsedData];
                        }
                        break;
                        
                        /// 获取任务详细信息 - LESS
                    case UpdateMaintenanceTaskLessDetailInfo:
                        [[NSNotificationCenter defaultCenter]
                         postNotificationName:WISUpdateMaintenanceTaskLessDetailInfoResponsedNotification                                                                object:(NSData *)responsedData];
                        
                        if ([self.opDelegate respondsToSelector:@selector(networkService:DidUpdateMaintenanceTaskLessDetailInfoAndResponsedWithData:)]) {
                            [self.opDelegate networkService:self DidUpdateMaintenanceTaskLessDetailInfoAndResponsedWithData:responsedData];
                           }
                        break;
                        
                        /// 获取任务详细信息
                    case UpdateMaintenanceTaskDetailInfo:
                        [[NSNotificationCenter defaultCenter]
                         postNotificationName:WISUpdateMaintenanceTaskDetailInfoResponsedNotification                                                                object:(NSData *)responsedData];
                        
                        if ([self.opDelegate respondsToSelector:@selector(networkService:DidUpdateMaintenanceTaskDetailInfoAndResponsedWithData:)]) {
                            [self.opDelegate networkService:self DidUpdateMaintenanceTaskDetailInfoAndResponsedWithData:responsedData];
                        }
                        break;
                        
                        // 获取任务历史信息 - 分页
                    case UpdateHistoryMaintenanceTasksInfoInPages:
                        [[NSNotificationCenter defaultCenter]
                         postNotificationName:WISUpdateHistoryMaintenanceTasksInfoInPagesResponsedNotification                                                                object:(NSData *)responsedData];
                        
                        if ([self.opDelegate respondsToSelector:@selector(networkService:DidUpdateHistroyMaintenanceTasksInfoInPagesAndResponsedWithData:)]) {
                            [self.opDelegate networkService:self
                                DidUpdateHistroyMaintenanceTasksInfoInPagesAndResponsedWithData:responsedData];
                        }
                        break;
                        
                        // 在服务器上注册ClientID
                    case SubmitUserClientID:
                        [[NSNotificationCenter defaultCenter]
                         postNotificationName:WISSubmitClientIDResponsedNotification object:(NSData *)responsedData];
                        
                        if ([self.opDelegate respondsToSelector:@selector(networkService:DidSubmitClientIDAndResponesdWithData:)]) {
                            [self.opDelegate networkService:self DidSubmitClientIDAndResponesdWithData:responsedData];
                        }
                        break;
                        
                        /// 获取任务历史信息 - 按刷新数量
                    case UpdateHistoryMaintenanceTasksInfoByNumber:
                        [[NSNotificationCenter defaultCenter]
                         postNotificationName:WISUpdateHistoryMaintenanceTasksInfoByNumberResponsedNotification                                                                object:(NSData *)responsedData];
                        
                        if ([self.opDelegate respondsToSelector:@selector(networkService:DidUpdateHistroyMaintenanceTasksInfoByNumberAndResponsedWithData:)]) {
                            [self.opDelegate networkService:self DidUpdateHistroyMaintenanceTasksInfoByNumberAndResponsedWithData:responsedData];
                        }
                        break;
                        
                        /// 获取任务历史信息 - 按时间范围
                    case UpdateHistoryMaintenanceTasksInfoByDateRange:
                        [[NSNotificationCenter defaultCenter]
                         postNotificationName:WISUpdateHistoryMaintenanceTasksInfoByDateRangeResponsedNotification                                                                object:(NSData *)responsedData];
                        
                        if ([self.opDelegate respondsToSelector:@selector(networkService:DidUpdateHistroyMaintenanceTasksInfoByDateRangeAndResponsedWithData:)]) {
                            [self.opDelegate networkService:self DidUpdateHistroyMaintenanceTasksInfoByDateRangeAndResponsedWithData:responsedData];
                        }
                        break;
                        
                        /// 获取工艺段信息
                    case UpdateMaintenanceAreas:
                        [[NSNotificationCenter defaultCenter]
                         postNotificationName:WISUpdateMaintenanceAreasResponsedNotification
                         object:(NSData *)responsedData];
                        
                        if ([self.opDelegate respondsToSelector:@selector(networkService:DidUpdateMaintenanceAreasAndResponsedWithData:)]) {
                            [self.opDelegate networkService:self DidUpdateMaintenanceAreasAndResponsedWithData:responsedData];
                        }
                        break;
                        
                        /// 获取人员信息
                    case UpdateContactUserInfo:
                        [[NSNotificationCenter defaultCenter]
                         postNotificationName:WISUpdateUserInfoResponsedNotification
                         object:(NSData *)responsedData];
                        
                        if ([self.opDelegate respondsToSelector:@selector(networkService:DidUpdateUserInfoAndResponsedWithData:)]) {
                            [self.opDelegate networkService:self DidUpdateUserInfoAndResponsedWithData:responsedData];
                        }
                        break;
                        
                        /// 获取维保任务参与相关人员信息
                    case UpdateRelavantUserInfo:
                        [[NSNotificationCenter defaultCenter]
                         postNotificationName:WISUpdateRelavantUserInfoResponsedNotification
                         object:(NSData *)responsedData];
                        
                        if ([self.opDelegate respondsToSelector:@selector(networkService:DidUpdateRelavantUserInfoAndResponsedWithData:)]) {
                            [self.opDelegate networkService:self DidUpdateRelavantUserInfoAndResponsedWithData:responsedData];
                        }
                        break;
                        
                        /// 提交命令
                    case SubmitCommand:
                        [[NSNotificationCenter defaultCenter]
                         postNotificationName:WISSubmitCommandOnMaintenanceTaskResponsedNotification
                         object:(NSData *)responsedData];
                        
                        if ([self.opDelegate respondsToSelector:@selector(networkService:DidSubmitCommandOnMaintenanceTaskAndResponsedWithData:)]) {
                            [self.opDelegate networkService:self DidSubmitCommandOnMaintenanceTaskAndResponsedWithData:responsedData];
                        }
                        break;
                        
                        ///
                        /// *** INSPECTION
                        ///
                        /// 获取点检设备(单个)信息
                    case UpdateInspectionInfo:
                        [[NSNotificationCenter defaultCenter]
                         postNotificationName:WISUpdateInspectionInfoResponsedNotification
                         object:(NSData *)responsedData];
                        
                        if ([self.opDelegate respondsToSelector:@selector(networkService:DidUpdateInspectionInfoAndResponsedWithData:)]) {
                            [self.opDelegate networkService:self DidUpdateInspectionInfoAndResponsedWithData:responsedData];
                        }
                        break;
                        
                        /// 获取点检设备(多个)信息
                    case UpdateInspectionsInfo:
                        [[NSNotificationCenter defaultCenter]
                         postNotificationName:WISUpdateInspectionsInfoResponsedNotification
                         object:(NSData *)responsedData];
                        
                        if ([self.opDelegate respondsToSelector:@selector(networkService:DidUpdateInspectionsInfoAndResponsedWithData:)]) {
                            [self.opDelegate networkService:self DidUpdateInspectionsInfoAndResponsedWithData:responsedData];
                        }
                        break;
                        
                        /// 获取设备类型信息
                    case UpdateDeviceTypesInfo:
                        [[NSNotificationCenter defaultCenter]
                         postNotificationName:WISUpdateDeviceTypesInfoResponsedNotification
                         object:(NSData *)responsedData];
                        
                        if ([self.opDelegate respondsToSelector:@selector(networkService:DidUpdateDeviceTypesInfoAndResponsedWithData:)]) {
                            [self.opDelegate networkService:self DidUpdateDeviceTypesInfoAndResponsedWithData:responsedData];
                        }
                        break;
                        
                        /// 获取逾期未点检设备(多个)信息
                    case UpdateOverDueInspectionsInfo:
                        [[NSNotificationCenter defaultCenter]
                         postNotificationName:WISUpdateOverDueInspectionsInfoResponsedNotification
                         object:(NSData *)responsedData];
                        
                        if ([self.opDelegate respondsToSelector:@selector(networkService:DidUpdateOverDueInspectionsInfoAndResponsedWithData:)]) {
                            [self.opDelegate networkService:self DidUpdateOverDueInspectionsInfoAndResponsedWithData:responsedData];
                        }
                        break;
                        
                        /// 获取历史点检任务(多个)信息
                    case UpdateHistoricalInspectionsInfo:
                        [[NSNotificationCenter defaultCenter]
                         postNotificationName:WISUpdateHistoricalInspectionsInfoResponsedNotification
                         object:(NSData *)responsedData];
                        
                        if ([self.opDelegate respondsToSelector:@selector(networkService:DidUpdateHistoricalInspectionsInfoAndResponsedWithData:)]) {
                            [self.opDelegate networkService:self DidUpdateHistoricalInspectionsInfoAndResponsedWithData:responsedData];
                        }
                        break;
                        
                        /// 提交设备点检结果
                    case SubmitInspectionResult:
                        [[NSNotificationCenter defaultCenter]
                         postNotificationName:WISSubmitInspectionResultResponsedNotification
                         object:(NSData *)responsedData];
                        
                        if ([self.opDelegate respondsToSelector:@selector(networkService:DidSubmitInspectionResultAndResponsedWithData:)]) {
                            [self.opDelegate networkService:self DidSubmitInspectionResultAndResponsedWithData:responsedData];
                        }
                        break;
                        
                    default:
                        // @throw [[NSException alloc] initWithName:@"请求异常" reason:@"请求的类型未定义" userInfo:nil];
                        break;
                }
            }
            NSLog(@"responsedDataOriginal: %@", [[NSString alloc] initWithData:responsedData encoding:NSUTF8StringEncoding]);
            handler(requestType, responsedData, nil);
        }
        NSLog(@"\nTask Info:%@\n%@", [task.currentRequest URL], [task.currentRequest allHTTPHeaderFields]);
        
        [self decreaseNetworkActivityCount];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        handler(requestType, nil, error);
        NSLog(@"\nTask Info:%@\n%@", [task.currentRequest URL], [task.currentRequest allHTTPHeaderFields]);
        NSLog(@"\nhttp body:%@\n", [task.currentRequest HTTPBody]);
        NSLog(@"\nhttp stream:%@\n", [task.currentRequest HTTPBodyStream]);
        NSLog(@"\nhttp method:%@\n", [task.currentRequest HTTPMethod]);
        [self decreaseNetworkActivityCount];
    }];
    [self increaseNetworkActivityCount];
    
    return dataTask;
}


- (NSURLSessionUploadTask*) uploadRequestWithFileContentType:(FileContentType)fileContentType
                                                      params:(NSDictionary *)params
                                                  uriSetting:(NSArray<NSString *> *)uriSettings
                                               andUploadData:(NSData *)data
                                           progressIndicator:(WISNetworkTranmissionProgressIndicator)progress
                                           completionHandler:(WISNetworkFileTransmissionHandler)handler {
    
    NSMutableString *path = [NSMutableString stringWithFormat:@"%@", self.dataUriServerName];
    
    /// 合成URI
    [path appendString:@"/File/Upload"];
    
    if (uriSettings) {
        switch (fileContentType) {
            case ImageOfMaintenanceTask:
                [path appendFormat:@"%@%@", @"/", uriSettings[0]];
                break;
                
            default:
                break;
        }
    }
    /**
     * Trun NSData object into a local file as cache
     */
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachedFilePath = [documentDirectories firstObject];
    NSString *uuidString = [[[NSUUID alloc]init]UUIDString];
    NSString *cachedFileName = [NSString stringWithFormat:@"cacheFile-%@", uuidString];
    
    NSString *fileFullName = [NSString stringWithFormat:@"%@/%@", cachedFilePath, cachedFileName];
    
    fileFullName = fileFullName;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileFullName]) {
        [[NSFileManager defaultManager] createFileAtPath:fileFullName contents:nil attributes:nil];
    }
    
    if([data writeToFile:fileFullName atomically:YES]){
        NSLog(@"write file successfully!");
    } else {
        NSLog(@"write file failed");
    }
   
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", self.networkFileDataManager.baseURL, path]];
    NSMutableURLRequest *uploadRequest = [NSMutableURLRequest requestWithURL:URL];
    
    [uploadRequest setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [uploadRequest setHTTPMethod:@"POST"];
    
    /// ** tried to upload data from cached file, but it does not work till now. 2016.03.20
    NSString *fileFullNameForURL = [NSString stringWithFormat:@"%@%@", @"file:/", fileFullName];
    NSURL *filePath = [NSURL fileURLWithPath:fileFullNameForURL];
    /// **
    
    self.networkFileDataManager.requestSerializer = [AFHTTPRequestSerializer serializer];
    self.networkFileDataManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    __block NSURLSessionUploadTask *uploadTask = [self.networkFileDataManager uploadTaskWithRequest:uploadRequest fromData:data
       // PROGRESS
       progress:^(NSProgress * _Nonnull uploadProgress) {
           progress(uploadProgress);
        
       // COMPLETION HANDLER
       } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
           
           NSLog(@"\nuploadTask Info:%@\n%@", [uploadTask.currentRequest URL], [uploadTask.currentRequest allHTTPHeaderFields]);
           NSLog(@"\nhttp body:%@\n", [uploadTask.currentRequest HTTPBody]);
           NSLog(@"\nhttp stream:%@\n", [uploadTask.currentRequest HTTPBodyStream]);
           NSLog(@"\nhttp method:%@\n", [uploadTask.currentRequest HTTPMethod]);
           
           if (error) {
               NSLog(@"\nuploadTask Error occurs:%@\n", error);
               handler(nil, error);
               
           } else {
               
               NSData *responsedData = responseObject;
               
               if (!responsedData) {
                   [[NSNotificationCenter defaultCenter] postNotificationName:WISNetworkResponsedNULLDataNotification                                                                object:(NSData *)responsedData];
                   
                   [self.opDelegate networkService:self ResponsedNULLData:responsedData];
                   
               } else {
                   /// for debuging
                   NSError *errorWithData = nil;
                   NSString *responsedDataAsString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                   
                   NSDictionary *responsedDataAsDictionary = [NSJSONSerialization JSONObjectWithData:responseObject
                                                                                             options:NSJSONReadingMutableContainers
                                                                                               error:&errorWithData];
                   
                   switch (fileContentType) {
                           /// 维保任务单的图片
                       case ImageOfMaintenanceTask:
                           [[NSNotificationCenter defaultCenter] postNotificationName:WISUploadImagesResponsedNotification                                                                object:(NSData *)responsedData];
                           
                           [self.opDelegate networkService:self DidUploadImagesResponsedWithData:responsedData];
                           break;
                           
                       default:
                           // @throw [[NSException alloc] initWithName:@"请求异常" reason:@"请求的类型未定义" userInfo:nil];
                           break;
                   }
               }
               
               NSLog(@"Upload Data Successfully!");
               NSLog(@"responseDataOriginal : %@", [[NSString alloc] initWithData:responsedData encoding:NSUTF8StringEncoding]);
               
               handler(responsedData, nil);
           }
       
           /// delete cache file of current upload task
           NSError *deleteFileError = nil;
           if ([[NSFileManager defaultManager] fileExistsAtPath:fileFullName]) {
               [[NSFileManager defaultManager] removeItemAtPath:fileFullName error:&deleteFileError];
           }
           [self decreaseNetworkActivityCount];
       }];
    
    [uploadTask resume];
    [self increaseNetworkActivityCount];
    
    return uploadTask;
}



- (NSURLSessionDataTask*) downloadRequestWithFileContentType2:(FileContentType)fileContentType
                                                      params:(NSDictionary *)params
                                                  uriSetting:(NSArray<NSString *> *)uriSettings
                                           progressIndicator:(WISNetworkTranmissionProgressIndicator)progress
                                           completionHandler:(WISNetworkFileTransmissionHandler)handler {
    
    NSMutableString *path = [NSMutableString stringWithFormat:@"%@", self.dataUriServerName];
    
    /// 合成URI
    [path appendString:@"/File/Download"];
    
    if (uriSettings) {
        switch (fileContentType) {
            case ImageOfMaintenanceTask:
                [path appendFormat:@"%@%@", @"/", uriSettings[0]];
                break;
                
            default:
                break;
        }
    }
    
    self.networkFileDataManager.requestSerializer = [AFJSONRequestSerializer serializer];
    self.networkFileDataManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", self.networkFileDataManager.baseURL, path]];
    NSMutableURLRequest *downloadRequest = [NSMutableURLRequest requestWithURL:URL];
    
    NSError *errorInJSON = nil;
    
    NSData *paramsAsData = [NSJSONSerialization  dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:&errorInJSON];
    // ** for test-purpose only
    NSString *paramsAsString = [[NSString alloc] initWithData:paramsAsData encoding:NSUTF8StringEncoding];
    
    [downloadRequest setHTTPMethod:@"POST"];
    [downloadRequest setHTTPBody:paramsAsData];
    [downloadRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    __block NSURLSessionDataTask *downloadTask = [self.networkFileDataManager dataTaskWithRequest:downloadRequest
     /// UPLOAD PROGRESS
     uploadProgress:^(NSProgress * _Nonnull uploadProgress) {
         NSLog(@"upload %lld - %lld", uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
         // do nothing
    
     /// DOWNLOAD PROGRESS
     } downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
         progress(downloadProgress);
         NSLog(@"download %lld - %lld", downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
       
     /// COMPLETION HANDLER
     } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
         NSLog(@"\ndownloadTask Info:%@\n%@", [downloadTask.currentRequest URL], [downloadTask.currentRequest allHTTPHeaderFields]);
         NSLog(@"\nhttp body:%@\n", [downloadTask.currentRequest HTTPBody]);
         NSLog(@"\nhttp stream:%@\n", [downloadTask.currentRequest HTTPBodyStream]);
         NSLog(@"\nhttp method:%@\n", [downloadTask.currentRequest HTTPMethod]);
         
         if (error) {
             NSLog(@"\ndownloadTask Error occurs:%@\n", error);
             handler(nil, error);
             
         } else {
             
             NSData *responsedData = responseObject;
             
             if (!responsedData) {
                 [[NSNotificationCenter defaultCenter] postNotificationName:WISNetworkResponsedNULLDataNotification                                                                object:(NSData *)responsedData];
                 
                 [self.opDelegate networkService:self ResponsedNULLData:responsedData];
                 
             } else {
                 
                 switch (fileContentType) {
                         /// 维保任务单的图片
                     case ImageOfMaintenanceTask:
                         [[NSNotificationCenter defaultCenter] postNotificationName:WISDownloadImagesResponsedNotification                                                                object:(NSData *)responsedData];
                         
                         [self.opDelegate networkService:self DidDownloadImagesResponsedWithData:responsedData];
                         break;
                         
                     default:
                         // @throw [[NSException alloc] initWithName:@"请求异常" reason:@"请求的类型未定义" userInfo:nil];
                         break;
                 }
             }
             
             NSLog(@"Download Data Successfully!");
             NSLog(@"responseDataOriginal : %@", [[NSString alloc] initWithData:responsedData encoding:NSUTF8StringEncoding]);
             
             handler(responsedData, nil);
         }
         [self decreaseNetworkActivityCount];
     }];
    
    [downloadTask resume];
    [self increaseNetworkActivityCount];
    
    return downloadTask;

    
    
    
/** //////////////////////////////////
    // Another work-well Code Below, NEVER EVER Delete them!
    
//    [self.networkFileDataManager POST:path
//                           parameters:params
//     // PROGRESS
//     progress:^(NSProgress * _Nonnull uploadProgress) {
//         progress(uploadProgress);
//         
//     // SUCCESS
//     } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//         handler(responseObject, nil);
//         
//     // FAILURE
//     } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//         handler(nil, error);
//     }];
*/
}

///
/// 调用了download的专用块. 该函数与上面的同名函数(为了区分，上面的同名函数加上了2)同样好用
///
- (NSURLSessionDownloadTask*) downloadRequestWithFileContentType:(FileContentType)fileContentType
                                                      params:(NSDictionary *)params
                                                  uriSetting:(NSArray<NSString *> *)uriSettings
                                           progressIndicator:(WISNetworkTranmissionProgressIndicator)progress
                                           completionHandler:(WISNetworkFileTransmissionHandler)handler {
    
    NSMutableString *path = [NSMutableString stringWithFormat:@"%@", self.dataUriServerName];
    
    /// 合成URI
    [path appendString:@"/File/Download"];
    
    if (uriSettings) {
        switch (fileContentType) {
            case ImageOfMaintenanceTask:
                [path appendFormat:@"%@%@", @"/", uriSettings[0]];
                break;
                
            default:
                break;
        }
    }
    
    self.networkFileDataManager.requestSerializer = [AFJSONRequestSerializer serializer];
    self.networkFileDataManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", self.networkFileDataManager.baseURL, path]];
    NSMutableURLRequest *downloadRequest = [NSMutableURLRequest requestWithURL:URL];
    
    NSError *errorInJSON = nil;
    
    NSData *paramsAsData = [NSJSONSerialization  dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:&errorInJSON];
    // ** for test-purpose only
    NSString *paramsAsString = [[NSString alloc] initWithData:paramsAsData encoding:NSUTF8StringEncoding];
    
    [downloadRequest setHTTPMethod:@"POST"];
    [downloadRequest setHTTPBody:paramsAsData];
    [downloadRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    __block NSURLSessionDownloadTask *downloadTask = [self.networkFileDataManager downloadTaskWithRequest:downloadRequest
     /// DOWNLOAD PROGRESS
     progress:^(NSProgress * _Nonnull downloadProgress) {
         progress(downloadProgress);
         NSLog(@"download progress: %lld - %lld", downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
             
     } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
         NSURL *cachesDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
         NSString *suggestedFileName = [response suggestedFilename];
         suggestedFileName = [NSString stringWithFormat:@"%@%@%@",suggestedFileName, @"-", [[NSUUID UUID]UUIDString]];
         NSURL *target = [cachesDirectoryURL URLByAppendingPathComponent:suggestedFileName];
         NSLog(@"target filePath: %@", target.absoluteString);
         return target;
         
     /// COMPLETION HANDLER
     } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
         NSLog(@"\ndownloadTask Info:%@\n%@", [downloadTask.currentRequest URL], [downloadTask.currentRequest allHTTPHeaderFields]);
         NSLog(@"\nhttp body:%@\n", [downloadTask.currentRequest HTTPBody]);
         NSLog(@"\nhttp stream:%@\n", [downloadTask.currentRequest HTTPBodyStream]);
         NSLog(@"\nhttp method:%@\n", [downloadTask.currentRequest HTTPMethod]);
         
         if (error) {
             NSLog(@"\ndownloadTask Error occurs:%@\n", error);
             handler(nil, error);
             
         } else {
             
             NSData *responsedData = [NSData dataWithContentsOfURL:filePath];
             NSLog(@"downloaded data file path: %@", filePath.absoluteString);
             
             NSError *deleteError;
             if ([[NSFileManager defaultManager] removeItemAtURL:filePath error:&deleteError] != YES) {
                 NSLog(@"Unable to delete file, beacause: %@", [deleteError localizedDescription]);
             } else {
                 NSLog(@"delete file at %@", filePath.absoluteString);
             }
             
             if (!responsedData) {
                 [[NSNotificationCenter defaultCenter] postNotificationName:WISNetworkResponsedNULLDataNotification                                                                object:(NSData *)responsedData];
                 
                 [self.opDelegate networkService:self ResponsedNULLData:responsedData];
                 
             } else {
                 
                 switch (fileContentType) {
                         /// 维保任务单的图片
                     case ImageOfMaintenanceTask:
                         [[NSNotificationCenter defaultCenter] postNotificationName:WISDownloadImagesResponsedNotification                                                                object:(NSData *)responsedData];
                         
                         [self.opDelegate networkService:self DidDownloadImagesResponsedWithData:responsedData];
                         break;
                         
                     default:
                         // @throw [[NSException alloc] initWithName:@"请求异常" reason:@"请求的类型未定义" userInfo:nil];
                         break;
                 }
             }
             
             NSLog(@"Download Data Successfully!");
             NSLog(@"responseDataOriginal : %@", [[NSString alloc] initWithData:responsedData encoding:NSUTF8StringEncoding]);
             
             handler(responsedData, nil);
         }
         [self decreaseNetworkActivityCount];
     }];
    
    [downloadTask resume];
    [self increaseNetworkActivityCount];
    
    return downloadTask;
}


    
//////////////////////////////////////////////////////////////////////////////////////

//**  Code snippet below using method at much high level, but doesn't work properly, because when organizing data in multipartFormData format, the Content-Type of HTTP header being set to "Multipart/Form-Data" by default automatically, and cannot change in normal programming way. To hack the AFNetworking Framework itself may let it work, but I don't think it's a right way to go.
//**
    
    
//    [self.networkFileDataManager POST:path
//                           parameters:nil
//     constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
//        switch (fileContentType) {
//            case ImageOfMaintenanceTask:
//                [formData appendPartWithFileData:data name:@"uploadDatas" fileName:@"uploadDatas" mimeType:@"application/octet-stream"];
//                // [formData appendPartWithFileData:data name:@"uploadDatas" fileName:@"uploadDatas" mimeType:@"multipart/form-data"];
//                // [formData appendPartWithFormData:data name:@"uploadFormDatas"];
//                
//                // [formData appendPartWithInputStream:uploadStream name:@"uploadStream" fileName:@"uploadStream" length:data.length mimeType:@"application/stream"];
//                
//                
//                break;
//                
//            default:
//                break;
//        }
//        
//     } progress:^(NSProgress * _Nonnull uploadProgress) {
//         progress(uploadProgress);
//         
//     } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//         NSLog(@"sucess:%@\n%@", [task.currentRequest URL], [task.currentRequest allHTTPHeaderFields]);
//         NSLog(@"\nhttp body:%@\n%@", [task.currentRequest HTTPBody]);
//         NSLog(@"\nhttp stream:%@\n%@", [task.currentRequest HTTPBodyStream]);
//         NSLog(@"\nhttp method:%@\n%@", [task.currentRequest HTTPMethod]);
//         
//         NSError *errorWithData = nil;
//         NSString *responsedDataAsString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
//
//         NSDictionary *responsedDataAsDictionary = [NSJSONSerialization JSONObjectWithData:responseObject
//                                                                                   options:NSJSONReadingMutableContainers
//                                                                                     error:&errorWithData];
//         
//         NSData *responsedData = responseObject;
//         
//         if (!responsedData) {
//             [[NSNotificationCenter defaultCenter] postNotificationName:WISNetworkResponsedNULLDataNotification                                                                object:(NSData *)responsedData];
//             
//             [self.opDelegate networkService:self ResponsedNULLData:responsedData];
//             
//         } else {
//             switch (fileContentType) {
//                     /// 维保任务单的图片
//                 case ImageOfMaintenanceTask:
//                     [[NSNotificationCenter defaultCenter] postNotificationName:WISUploadImageOfMaintenanceTaskResponsedNotification                                                                object:(NSData *)responsedData];
//                     
//                     [self.opDelegate networkService:self DidUploadImageOfMaintenanceTaskAndResponsedWithData:responsedData];
//                     break;
//                     
//                 default:
//                     // @throw [[NSException alloc] initWithName:@"请求异常" reason:@"请求的类型未定义" userInfo:nil];
//                     break;
//             }
//         }
//         
//         NSLog(@"Upload Data Successfully!");
//         
//         NSLog(@"responseDataOriginal : %@", [[NSString alloc] initWithData:responsedData
//                                                                   encoding:NSUTF8StringEncoding]);
//         
//         handler(responsedData, nil);
//        
//     } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//         NSLog(@"failed:%@\n%@", [task.currentRequest URL], [task.currentRequest allHTTPHeaderFields]);
//         handler(nil, error);
//     }];
//////////////////////////////////////////////////////////////////////////////////////




//
//- (void) downloadRequestWithFileContentType:(FileContentType)fileContentType
//                                     params:(NSDictionary *)params
//                              andUriSetting:(NSArray<NSString *> *)uriSettings
//                          completionHandler:(WISNetworkFileTransmissionHandler)handler {
//    
//    NSMutableString *path = [NSMutableString stringWithString:self.fileUriServerName];
//    
//    /// 合成URI
//    [path appendString:@"/File/Download"];
//    
//    switch (fileContentType) {
//        case ImageOfMaintenanceTask:
//            [path appendFormat:@"%@%@", @"/", uriSettings[0]];
//            break;
//            
//        default:
//            break;
//    }
//    
//    MKNetworkRequest *downloadRequest = [self.networkFileHost requestWithPath:path
//                                                                   params:params
//                                                               httpMethod:@"POST"];
//    
//    downloadRequest.parameterEncoding = MKNKParameterEncodingJSON;
//    // request.cacheable = TRUE;
//    
//    [downloadRequest addCompletionHandler:^(MKNetworkRequest *completedRequest) {
//        
//        NSData *responsedData = [completedRequest responseData];
//        
//        if (!responsedData) {
//            [[NSNotificationCenter defaultCenter] postNotificationName:WISNetworkResponsedNULLDataNotification                                                                object:(NSData *)responsedData];
//            
//            [self.opDelegate networkService:self ResponsedNULLData:responsedData];
//        
//        } else {
//            switch (fileContentType) {
//                    /// 维保任务单的图片
//                case ImageOfMaintenanceTask:
//                    [[NSNotificationCenter defaultCenter] postNotificationName:WISDownloadImageOfMaintenanceTaskResponsedNotification                                                                object:(NSData *)responsedData];
//                    
//                    [self.opDelegate networkService:self DidDownloadImageOfMaintenanceTaskAndResponsedWithData:responsedData];
//                    break;
//                    
//                default:
//                    // @throw [[NSException alloc] initWithName:@"请求异常" reason:@"请求的类型未定义" userInfo:nil];
//                    break;
//            }
//        }
//        
//        NSLog(@"responseDataOriginal : %@", [[NSString alloc] initWithData:responsedData
//                                                                  encoding:NSUTF8StringEncoding]);
//        
//        handler(responsedData, completedRequest.error);
//    }];
//    
//    [self.networkFileHost startDownloadRequest:downloadRequest];
//}


@end
