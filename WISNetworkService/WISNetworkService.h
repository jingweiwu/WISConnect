//
//  WISNetworkService.h
//  WISConnect
//
//  Created by Jingwei Wu on 2/19/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WISSystemNetworkNotification.h"
#import "WISMaintenanceTaskNetworkNotification.h"
#import "WISInspectionTaskNetworkNotification.h"

#import "WISSystemNetworkOperationDelegate.h"
#import "WISMaintenanceTaskNetworkOperationDelegate.h"
#import "WISInspectionTaskNetworkOperationDelegate.h"

#import "WISNetworkException.h"


typedef NS_ENUM (NSUInteger, RequestType) {
    // default
    SignIn = 0,
    ChangingPassword,
    
    UpdateCurrentUserDetailInfo,
    SubmitCurrentUserDetailInfo,
    
    SubmitUserClientID,
    
    UpdateMaintenanceTaskBriefInfo,
    UpdateMaintenanceTaskLessDetailInfo,
    UpdateMaintenanceTaskDetailInfo,
    UpdateMaintenanceAreas,
    UpdateHistoryMaintenanceTasksInfoInPages,
    // Obsolete
    UpdateHistoryMaintenanceTasksInfoByNumber,
    // Obsolete
    UpdateHistoryMaintenanceTasksInfoByDateRange,
    UpdateContactUserInfo,
    UpdateRelavantUserInfo,
    
    SubmitCommand,
    
    // INSPECTION
    UpdateInspectionInfo,
    UpdateInspectionsInfo,
    UpdateDeviceTypesInfo,
    UpdateOverDueInspectionsInfo,
    UpdateHistoricalInspectionsInfo,
    
    SubmitInspectionResult,
    
    // CLOCK SERVICE
    UpdateCurrentClockStatus,
    UpdateClockRecords,
    UpdateWorkShifts,
    UpdateAttendanceRecords,
    
    SubmitClockAction,
};

typedef NS_ENUM (NSUInteger, FileContentType) {
    ImageOfMaintenanceTask = 0,         /// default
};


typedef void (^WISNetworkReachabilityStatusChangedHandler)(NSInteger statusAsInteger);

typedef void (^WISNetworkHandler)(RequestType requestType, NSData * responsedData, NSError *networkError);

typedef void (^WISNetworkTranmissionProgressIndicator)(NSProgress * transmissionProgress);
typedef void (^WISNetworkFileTransmissionHandler)(NSData * responsedData, NSError *networkError);


#pragma mark -
#pragma mark WISNetworkService Interface

@interface WISNetworkService : NSObject

/// 当前网络状态
@property (readonly, nonatomic, assign) NSInteger networkReachabilityStatusAsInteger;

@property (readonly, nonatomic, getter=isNetworkReachabilityStatusMonitoringON) BOOL networkReachabilityStatusMonitoringIsON;

@property (readonly) RequestType requestType;

@property (readonly) NSString *dataHostName;
@property (readonly) NSString *dataUriServerName;

@property (weak) id<WISSystemNetworkOperationDelegate, WISMaintenanceTaskNetworkOperationDelegate, WISInspectionTaskNetworkOperationDelegate> opDelegate;

/**
 @brief Singleton Method
 @return WISNetworkService instance
 */
+ (WISNetworkService *)sharedInstance;

- (instancetype)init __attribute__((unavailable("init not available, call shareInstance instead.")));

- (instancetype)initWithDataHostName:(NSString *)dataHostName
                   uriDataServerName:(NSString *)uriDataServerName
                        fileHostName:(NSString *)fileHostName
                andUriFileServerName:(NSString *)uriFileServerName __attribute__((unavailable("init not available, call shareInstance instead.")));


- (void) setNetworkReachabilityStatusChangeHandler:(WISNetworkReachabilityStatusChangedHandler)handler;

- (void) startNetworkingReachabilityStatusMonitoring;
- (void) stopNetworkingReachabilityStatusMonitoring;

- (BOOL) isNetworkReachabilityStatusMonitoringON;


- (NSURLSessionDataTask*) dataRequestWithRequestType:(RequestType) requestType
                                              params:(NSDictionary *)params
                                       andUriSetting:(NSArray<NSString *> *)uriSettings
                                   completionHandler:(WISNetworkHandler) handler;


- (NSURLSessionUploadTask*) uploadRequestWithFileContentType:(FileContentType)fileContentType
                                                      params:(NSDictionary *)params
                                                  uriSetting:(NSArray<NSString *> *)uriSettings
                                               andUploadData:(NSData *)data
                                           progressIndicator:(WISNetworkTranmissionProgressIndicator)progress
                                           completionHandler:(WISNetworkFileTransmissionHandler)handler;


- (NSURLSessionDownloadTask*) downloadRequestWithFileContentType:(FileContentType)fileContentType
                                                      params:(NSDictionary *)params
                                                  uriSetting:(NSArray<NSString *> *)uriSettings
                                           progressIndicator:(WISNetworkTranmissionProgressIndicator)progress
                                           completionHandler:(WISNetworkFileTransmissionHandler)handler;

@end
