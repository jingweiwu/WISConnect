//
//  WISDataManager.h
//  WISConnect
//
//  Created by Jingwei Wu on 2/25/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WISNetworkService.h"

#import "WISSystemDataNotification.h"
#import "WISMaintenanceTaskDataNotification.h"
#import "WISInspectionTaskDataNotification.h"

#import "WISSystemDataOperationDelegate.h"
#import "WISMaintenanceTaskDataOperationDelegate.h"
#import "WISInspectionTaskDataOperationDelegate.h"
#import "WISNetworkingDelegate.h"

#import "NSError+WISExtension.h"
#import "NSDate+WISExtension.h"
// #import "WISDataException.h"

#import "WISMaintenancePlan.h"
#import "WISMaintenanceTask.h"
#import "WISMaintenanceTaskState.h"
#import "WISUser.h"
#import "WISMaintenanceTaskRating.h"
#import "WISFileInfo.h"
#import "WISInspectionTask.h"

#import "WISCompany.h"
#import "WISClockRecord.h"
#import "WISAttendanceRecord.h"


#import "WISFileStoreManager.h"
#import "WISSorter.h"


#pragma mark - Pre-defined enums and constants


/**
 * @brief 由服务器定义的操作, 对应请求里的OperationID
 */
typedef NS_ENUM(NSInteger, MaintenanceTaskOperationType) {
    /// undefined operation
    NULLOperation = -10,
    /// 提交维保任务申请
    SubmitApply = 0,
    /// 生产人员拒绝确认维保任务已完成
    DeclineToConfirm = 1,
    /// 接单
    AcceptMaintenanceTask = 2,
    /// 拒绝接收转单
    RefuseToReceiveTask = 3,
    /// 无响应
    NoResponse = 4,
    /// 转单
    PassOn = 5,
    /// 提交维保方案
    SubmitMaintenancePlan = 6,
    /// 开始快速处理流程
    StartFastProcedure = 7,
    /// (工程师)任务完成
    TaskComplete = 8,
    /// 同意
    Approve = 9,
    /// 申请复审(技术主管提交厂级负责人审批)
    ApplyForRecheck = 10,
    /// 拒绝
    Reject = 11,
    /// 继续维保(技术主管)
    Continue = 12,
    /// 确认(生产人员确认任务完成)
    Confirm = 13,
    /// 取消
    Cancel = 14,
    /// 存档
    Archive = 15,
    /// 变更
    Modify = 16,
    /// 发起争议流程
    StartDisputeProcedure = 17,
    /// 备注
    Remark = 18,
    /// 接受转单
    AcceptPassOnTask = 20,
    /// 接受转单(该转单由前方部长发起)
    AcceptAssignedPassOnTask = 21,
    /// 转单(前方部长转单)
    Assign = 22,
};


//
// old version of MaintenanceTaskOperationType till 2016.03.21
//
//typedef NS_ENUM(NSInteger, MaintenanceTaskOperationType) {
//    /// undefined operation
//    NULLOperation = -10,
//    /// 提交
//    Submit = 0,
//    /// 同意
//    Approve = 1,
//    /// 拒绝
//    Reject = 2,
//    /// 接单
//    AcceptMaintenanceTask = 3,
//    /// 无响应
//    NoResponse = 4,
//    /// 确认
//    Confirm = 5,
//    /// 撤销
//    Cancel = 6,
//    /// 归档
//    Archive = 7,
//    /// 变更
//    Modify = 8,
//    /// 转单
//    PassOn = 9,
//    /// 开始快速处理流程
//    StartFastProcedure = 10,
//    /// 开始争议流程
//    StartDisputeProcedure = 11,
//    
//};


/**
 * @brief 由服务器定义的登录操作结果返回值
 */
typedef NS_ENUM (NSInteger, SignInResult) {
    /// 登录成功 default
    SignInSuccessful = 0,
    /// 登录的用户不存在
    UserNotExist = -1,
    /// 登录密码错误
    WrongPassword = -2,
};

/**
 * @brief 由服务器定义的操作请求[包括数据获取请求(Update)操作与数据提交(Operation)请求操作]结果返回值
 */
typedef NS_ENUM (NSInteger, RequestResult) {
    /// 请求成功
    RequestSuccessful = 1,
    /// 请求失败
    RequestFailed = 0,
};

/**
 * @brief 由服务器定义的操作请求[包括数据获取请求(Update)操作与数据提交(Operation)请求操作]结果返回值
 */
typedef NS_ENUM (NSInteger, RoleCode) {
    /// 技术主管
    TechManager = 0,
    /// 厂级负责人
    FactoryManager = 1,
    /// 前方部长
    FieldManager = 2,
    /// 值班经理
    DutyManager = 3,
    /// 工程师
    Engineer = 4,
    /// 生产操作人员
    Operator = 5,
    /// 电工
    Technician = 6,
};

/**
 * @brief 由服务器定义的操作系统类型
 */
typedef NS_ENUM(NSInteger, OperatingSystem) {
    OSType_Android = 1,
    OSType_iOS = 2,    /// default
};

/**
 * @brief 由服务器定义的打卡状态
 */
typedef NS_ENUM(NSInteger, ClockStatus) {
    /// 未定义
    UndefinedClockStatus = 0,
    /// 打卡 - 上班中
    ClockedIn = 1,
    /// 打卡 - 下班中
    ClockedOff = 2,
};

/**
 * @brief WIS程序内定义的错误代码，对应的是NSError对象的code属性。
 */
typedef NS_ENUM (NSInteger, WISErrorCode) {
    /// 函数参数错误
    ErrorCodeWrongFuncParameters = 2,
    /// 服务器返回的数据与预设值不一致，数据解析失败
    ErrorCodeIncorrectResponsedDataFormat = 1,
    /// 服务器返回的为nil，或网络连接异常
    ErrorCodeResponsedNULLData = 0,
    /// 登录的用户不存在
    ErrorCodeSignInUserNotExist = -1,
    /// 登录密码错误
    ErrorCodeSignInWrongPassword = -2,
    /// 没有当前登录的用户信息
    ErrorCodeNoCurrentUserInfo = -11,
    /// 操作非法
    ErrorCodeInvalidOperation = -12,
    /// 网络传输错误
    ErrorCodeNetworkTransmission = -21,
};

/**
 * @brief 当前网络状态的属性。
 */
typedef NS_ENUM(NSInteger, WISNetworkReachabilityStatus) {
    WISNetworkReachabilityStatusUnknown          = -1,
    WISNetworkReachabilityStatusNotReachable     = 0,
    WISNetworkReachabilityStatusReachableViaWWAN = 1,
    WISNetworkReachabilityStatusReachableViaWiFi = 2,
};


/// WIS错误域定义
FOUNDATION_EXPORT NSString *const WISErrorDomain;
// FOUNDATION_EXPORT NSDictionary *const WISRoleCodeDictionary;

typedef void (^WISSystemSignInHandler)(BOOL completedWithNoError, NSError *error);

typedef void (^WISSystemOperationHandler)(BOOL completedWithNoError, NSError *error, NSString *classNameOfDataAsString, id data);

typedef void (^WISSystemDataTransmissionProgressIndicator)(NSProgress * transmissionProgress);
typedef void (^WISSystemDataTransmissionHandler)(BOOL completedWithNoError, NSError *error, NSString *classNameOfReceivedDataAsString, id receivedData);

// for maintenance task
typedef void (^WISMaintenanceTaskUpdateInfoHandler)(BOOL completedWithNoError, NSError *error, NSString *classNameOfUpdatedDataAsString, id updatedData);

typedef void (^WISMaintenanceTaskOperationHandler)(BOOL completedWithNoError, NSError *error);

// for inspection task
typedef void (^WISInspectionTaskUpdateInfoHandler)(BOOL completedWithNoError, NSError *error, NSString *classNameOfUpdatedDataAsString, id updatedData);

typedef void (^WISInspectionTaskOperationHandler)(BOOL completedWithNoError, NSError *error);


#pragma mark - class WISDataManager declaration
/**
 * WISDataManager Definition
 */
@interface WISDataManager : NSObject

/// 当前网络状态
@property (readonly, nonatomic, assign) WISNetworkReachabilityStatus networkReachabilityStatus;

@property (readonly) WISUser *currentUser;
@property (readonly) NSString *networkRequestToken;

/// 角色对照表
@property (readonly) NSArray<NSString *> const *roleCodes;
@property (readonly) NSDictionary<NSString *, NSString *> const *roleNameDictionary;

@property (readonly) NSMutableDictionary <NSString *, WISUser *> *users;
/// @brief key是WISMainenanceTask类中的TaskID属性
@property (readonly) NSMutableDictionary <NSString *, WISMaintenanceTask *> *maintenanceTasks;

 @property (readonly) NSMutableDictionary <NSString *, WISInspectionTask *> *inspectionTasks;
 @property (readonly) NSMutableDictionary <NSString *, WISInspectionTask *> *overDueInspectionTasks;

 @property (readonly) NSMutableDictionary <NSString *, WISDeviceType *> *deviceTypes;

/**
 * @brief key是服务器端定义的工艺段ID.
 * @warning key在服务器端定义的为int型. 为了存成NSDictionary格式, 本地转换为了NSString型. 在跟服务器交互过程中, 注意类型的转换.
 */
@property (readonly) NSMutableDictionary <NSString *, NSString *> *processSegments;

/// delegates
@property (weak) id<WISSystemDataOperationDelegate> systemDataDelegate;
@property (weak) id<WISMaintenanceTaskDataOperationDelegate> maintenanceTaskOpDelegate;
@property (weak) id<WISInspectionTaskDataOperationDelegate> inspectionTaskOpDelegate;
@property (weak) id<WISNetworkingDelegate> networkingDelegate;

#pragma mark - Initializer

+ (WISDataManager *)sharedInstance;

- (instancetype)init __attribute__((unavailable("init not available, call shareInstance instead.")));


#pragma mark - Sign In

/**
 * @brief 用户登录时调用的方法
 *
 * @discussion 操作成功后，函数发送通知WISSystemSignInSucceededNotification; 操作失败后，函数发送通知WISSystemSignInFailedNotification.
 *
 * @discussion 操作失败后, 函数可能返回以下五种错误代码: ErrorCodeResponsedNULLData, ErrorCodeIncorrectResponsedDataFormat, ErrorCodeSignInUserNotExist, ErrorCodeSignInWrongPassword, ErrorCodeWrongFuncParameters.
 *
 * @param userName 登录的用户名
 * @param password 登录的密码
 * @param handler 登录返回后处理的块. 块包含两个参数: 
    1. (BOOL)completedWithNoError (操作成功返回TRUE, 操作失败返回FALSE); 
    2. (NSError *)error (如果操作成功，则error的值为nil，如果操作失败，则error包含了操作失败的信息, 用于调试和使用中确定操作失败原因. 其中, error.code属性为错误代码，由enum类型WISErrorCode定义; error.localizedDescription属性为故障描述; error.localizedFailureReason属性为故障原因说明; error.localizedRecoverySuggestion属性为建议的解决方法).
 *
 * @warning 调用后如果登录成功，该方法会相应地为WISDataManager中的属性currentUser赋值. currentUser将作为后续网络访问的参数。因此，必须首先调用该方法，保证currentUser属性能被正确赋值，否则无法完成后续操作.
 *
 */
- (NSURLSessionDataTask *) signInWithUserName:(NSString *)userName
                                  andPassword:(NSString *)password
                            completionHandler:(WISSystemSignInHandler)handler;

/**
 * @brief 用户修改用户密码的方法
 *
 * @discussion 操作成功后，函数发送通知WISSystemChangingPasswordSucceededNotification; 操作失败后，函数发送通知WISSystemChangingPasswordFailedNotification.
 *
 * @discussion 操作失败后, 函数可能返回以下五种错误代码: ErrorCodeResponsedNULLData, ErrorCodeIncorrectResponsedDataFormat, ErrorCodeInvalidOperation, ErrorCodeNoCurrentUserInfo, ErrorCodeSignInWrongPassword.
 *
 * @param currentPassword 当前的登录密码
 * @param newPassword 新的登录的密码
 * @param handler 返回后处理的块. 块包含四个参数:
 1. (BOOL)completedWithNoError (操作成功返回TRUE，操作失败返回FALSE);
 2. (NSError *)error (如果操作成功，则error的值为nil，如果操作失败，则error包含了操作失败的信息，用于调试和使用中确定操作失败原因。其中，error.code属性为错误代码，由enum类型WISErrorCode定义; error.localizedDescription属性为故障描述;error.localizedFailureReason属性为故障原因说明; error.localizedRecoverySuggestion属性为建议的解决方法);
 3. (NSString *)classNameOfUpdatedDataAsString handler返回查询获得的数据, 该参数表示数据对象的类名;
 4. (id)data 查询获得的处理过的数据 (本函数中未使用).
 *
 * @warning 调用成功后，该方法会相应地修改WISDataManager中的属性networkRequestToken赋值. 
 *
 */
- (NSURLSessionDataTask *) changePasswordWithCurrentPassword:(NSString *)currentPassword
                                                 newPassword:(NSString *)newPassword
                                          compeletionHandler:(WISSystemOperationHandler)handler;


#pragma mark - USER DETAIL Operations
- (NSURLSessionDataTask *) submitUserDetailInfoWithNewInfo:(WISUser *)newUserInfo
                                         completionHandler:(WISSystemOperationHandler)handler;

- (NSURLSessionDataTask *) updateCurrentUserDetailInformationWithCompletionHandler:(WISSystemOperationHandler)handler;


#pragma mark - CLOCK Operations
- (NSURLSessionDataTask *) submitClockActionWithCompletionHandler:(WISSystemOperationHandler)handler;

- (NSURLSessionDataTask *) updateCurrentClockStatusWithCompletionHandler:(WISSystemOperationHandler)handler;

- (NSURLSessionDataTask *) updateClockRecordsWithStartDate:(NSDate *)startDate
                                                   endDate:(NSDate *)endDate
                                         completionHandler:(WISSystemOperationHandler)handler;

- (NSURLSessionDataTask *) updateWorkShiftsWithStartDate:(NSDate *)startDate
                                            recordNumber:(NSInteger)number
                                       completionHandler:(WISSystemOperationHandler)handler;

- (NSURLSessionDataTask *) updateAttendanceRecordsWithDate:(NSDate *)date
                                         completionHandler:(WISSystemOperationHandler)handler;


#pragma mark - Image Storage and Obtaining Operations

/// 保存用户的图片 (当前APP使用者, 或更新了用户列表中的用户所产生的用户头像图片均应使用该函数保存)
// 函数将图片数据保存在本地缓存, 并上传服务器
- (NSURLSessionUploadTask *) storeImageOfUserWithUserName:(NSString *)userName
                                                   images:(NSDictionary<NSString *,UIImage *> *)images
                                  uploadProgressIndicator:(WISSystemDataTransmissionProgressIndicator)progress
                                        completionHandler:(WISSystemOperationHandler)handler;


/// 获取用户的图片 (当前APP使用者, 或更新了用户列表中的用户所需的用户头像图片均应使用该函数获取)
/// 图片数据来自本地缓存. 如果缓存中没有, 则从服务器下载并保存到缓存, 再从缓存获取. 函数仅会下载缓存中不存在的图片
- (NSURLSessionDownloadTask *) obtainImageOfUserWithUserName:(NSString *)userName
                                                  imagesInfo:(NSDictionary<NSString *,WISFileInfo *> *)imagesInfo
                                   downloadProgressIndicator:(WISSystemDataTransmissionProgressIndicator)progress
                                           completionHandler:(WISSystemOperationHandler)handler;


// 保存维保任务单的图片
// 函数将图片数据保存在本地缓存, 并上传服务器
- (NSURLSessionUploadTask *) storeImageOfMaintenanceTaskWithTaskID:(NSString *)taskID
                                                            images:(NSDictionary<NSString *,UIImage *> *)images
                                           uploadProgressIndicator:(WISSystemDataTransmissionProgressIndicator)progress
                                                 completionHandler:(WISSystemOperationHandler)handler;


/// 获取维保任务单的图片
/// 图片数据来自本地缓存. 如果缓存中没有, 则从服务器下载并保存到缓存, 再从缓存获取. 函数仅会下载缓存中不存在的图片
- (NSURLSessionDownloadTask *) obtainImageOfMaintenanceTaskWithTaskID:(NSString *)taskID
                                                           imagesInfo:(NSDictionary<NSString *,WISFileInfo *> *)imagesInfo
                                            downloadProgressIndicator:(WISSystemDataTransmissionProgressIndicator)progress
                                                    completionHandler:(WISSystemOperationHandler)handler;


- (NSURLSessionUploadTask *) uploadImageWithImages:(NSDictionary<NSString *, UIImage *> *)images
                                 progressIndicator:(WISSystemDataTransmissionProgressIndicator)progress
                                 completionHandler:(WISSystemDataTransmissionHandler)handler;


/// 清除图片本地缓存 (内存／本地路径)
- (void) clearCacheOfImages;
/// 获取下载图片本地缓存数据文件的大小
- (float) cacheSizeOnDeviceStorage;


#pragma mark - Global Level Operations
/**
 * @brief 获取工艺段方法
 
 * @discussion 操作成功后，函数发送通知WISUpdateProcessSegmentSucceededNotification; 操作失败后，函数发送通知WISUpdateProcessSegmentSFailedNotification.
 *
 * @discussion 操作失败后, 函数可能返回以下四种错误代码: ErrorCodeResponsedNULLData, ErrorCodeIncorrectResponsedDataFormat, ErrorCodeInvalidOperation, ErrorCodeNoCurrentUserInfo.
 *
 * @param handler 网络操作返回后处理的块。块包含四个参数: 
    1. (BOOL)completedWithNoError (操作成功返回TRUE，操作失败返回FALSE); 
    2. (NSError *)error (如果操作成功，则error的值为nil，如果操作失败，则error包含了操作失败的信息，用于调试和使用中确定操作失败原因。其中，error.code属性为错误代码，由enum类型WISErrorCode定义; error.localizedDescription属性为故障描述;error.localizedFailureReason属性为故障原因说明; error.localizedRecoverySuggestion属性为建议的解决方法); 
    3. (NSString *)classNameOfUpdatedDataAsString handler返回查询获得的数据, 该参数表示数据对象的类名; 
    4. (id)updatedData 查询获得的处理过的数据 (NSDictionary类型).
 */
- (NSURLSessionDataTask *) updateProcessSegmentWithCompletionHandler:(WISMaintenanceTaskUpdateInfoHandler)handler;

- (NSURLSessionDataTask *) updateContactUserInfoWithCompletionHandler:(WISMaintenanceTaskUpdateInfoHandler)handler;

- (NSURLSessionDataTask *) updateRelavantUserInfoWithCompletionHandler:(WISMaintenanceTaskUpdateInfoHandler)handler;


- (NSURLSessionDataTask *) submitUserClientID:(NSString *)clientID completionHandler:(WISMaintenanceTaskOperationHandler)handler;


#pragma mark - Maintenance Task Info Update & Operations
/**
 * @description 获取维保任务列表 (返回任务简要信息)
 *
 * @discussion 操作成功后，函数发送通知WISUpdateMaintenanceTaskBriefInfoSucceededNotification; 操作失败后，函数发送通知WISUpdateMaintenanceTaskBriefInfoFailedNotification.
 *
 * @discussion 操作失败后, 函数可能返回以下四种错误代码: ErrorCodeResponsedNULLData, ErrorCodeIncorrectResponsedDataFormat, ErrorCodeInvalidOperation, ErrorCodeNoCurrentUserInfo.
 
 * @param taskTypeID 需要获取任务的类型, 由enum类型MaintenanceTaskType定义
 * @param handler 网络操作返回后处理的块。块包含四个参数:
    1. (BOOL)completedWithNoError (操作成功返回TRUE，操作失败返回FALSE); 
    2. (NSError *)error (如果操作成功，则error的值为nil，如果操作失败，则error包含了操作失败的信息，用于调试和使用中确定操作失败原因。其中，error.code属性为错误代码，由enum类型WISErrorCode定义; error.localizedDescription属性为故障描述;error.localizedFailureReason属性为故障原因说明; error.localizedRecoverySuggestion属性为建议的解决方法); 
    3. (NSString *)classNameOfUpdatedDataAsString handler返回查询获得的数据, 该参数表示数据对象的类名; 
    4. (id)updatedData 查询获得的处理过的数据 (WISMaintenanceTask的NSArray类型列表).
 */
- (NSURLSessionDataTask *) updateMaintenanceTaskBriefInfoWithTaskTypeID:(MaintenanceTaskType)taskTypeID
                                                      completionHandler:(WISMaintenanceTaskUpdateInfoHandler)handler;


/// Update Finished Maintenance Task Brief Information Operation And Response Method
- (NSURLSessionDataTask *) updateFinishedMaintenanceTaskBriefInfoWithTaskTypeID:(MaintenanceTaskType)taskTypeID
                                                             recordNumberInPage:(NSInteger)numberInPage
                                                                      pageIndex:(NSInteger)index
                                                              completionHandler:(WISMaintenanceTaskUpdateInfoHandler)handler;

/**
 * @description 获取某一项维保任务的详细信息
 *
 * @discussion 操作成功后，函数发送通知WISUpdateMaintenanceTaskDetailInfoSucceededNotification; 操作失败后，函数发送通知WISUpdateMaintenanceTaskDetailInfoFailedNotification.
 *
 * @discussion 操作失败后, 函数可能返回以下四种错误代码: ErrorCodeResponsedNULLData, ErrorCodeIncorrectResponsedDataFormat, ErrorCodeInvalidOperation, ErrorCodeNoCurrentUserInfo.
 
 * @param taskID 需要获取任务的ID.
 * @param handler 网络操作返回后处理的块。块包含四个参数:
    1. (BOOL)completedWithNoError (操作成功返回TRUE，操作失败返回FALSE);
    2. (NSError *)error (如果操作成功，则error的值为nil，如果操作失败，则error包含了操作失败的信息，用于调试和使用中确定操作失败原因。其中，error.code属性为错误代码，由enum类型WISErrorCode定义; error.localizedDescription属性为故障描述;error.localizedFailureReason属性为故障原因说明; error.localizedRecoverySuggestion属性为建议的解决方法);
    3. (NSString *)classNameOfUpdatedDataAsString handler返回查询获得的数据, 该参数表示数据对象的类名;
    4. (id)updatedData 查询获得的处理过的数据 (WISMaintenanceTask类型).
 */
- (NSURLSessionDataTask *) updateMaintenanceTaskLessDetailInfoWithTaskID:(NSString *)taskID
                                                       completionHandler:(WISMaintenanceTaskUpdateInfoHandler)handler
__attribute__((deprecated("Use \"updateMaintenanceTaskDetailInfoWithTaskID: completionHandler:\" instead.")));


- (NSURLSessionDataTask *) updateMaintenanceTaskDetailInfoWithTaskID:(NSString *)taskID
                                                   completionHandler:(WISMaintenanceTaskUpdateInfoHandler)handler;

/**
 * @description 申请新的维保任务单
 *
 * @discussion 操作成功后，函数发送通知WISOperationOnMaintenanceTaskSucceededNotification; 操作失败后，函数发送通知WISOperationOnMaintenanceTaskFailedNotification.
 *
 * @discussion 操作失败后, 函数可能返回以下四种错误代码: ErrorCodeResponsedNULLData, ErrorCodeIncorrectResponsedDataFormat, ErrorCodeInvalidOperation, ErrorCodeNoCurrentUserInfo.
 
 * @param applicationContent 新任务单维保的内容.
 * @param processSegmentID 维保单任务所在工艺段
 * @param applicationImageInfo 新任务单附图的信息. 上传图片时返回
 * @param handler 网络操作返回后处理的块。块包含两个参数:
 1. (BOOL)completedWithNoError (操作成功返回TRUE，操作失败返回FALSE);
 2. (NSError *)error (如果操作成功，则error的值为nil，如果操作失败，则error包含了操作失败的信息，用于调试和使用中确定操作失败原因。其中，error.code属性为错误代码，由enum类型WISErrorCode定义; error.localizedDescription属性为故障描述;error.localizedFailureReason属性为故障原因说明; error.localizedRecoverySuggestion属性为建议的解决方法); error.taskIDOfOperation属性为操作对应的任务ID, 对于新建任务单, TaskID为""; error.operationType属性为操作的类型, 对于新建任务单, OperationType为Submit.
 */
- (NSURLSessionDataTask *) applyNewMaintenanceTaskWithApplicationContent:(NSString *)applicationContent
                                                        processSegmentID:(NSString *)processSegmentID
                                                    applicationImageInfo:(NSDictionary<NSString *, WISFileInfo *> *)applicationImagesInfo
                                                       completionHandler:(WISMaintenanceTaskOperationHandler)handler;


/**
 * @description 维保任务单的操作
 *
 * @discussion 操作成功后，函数发送通知WISOperationOnMaintenanceTaskSucceededNotification; 操作失败后，函数发送通知WISOperationOnMaintenanceTaskFailedNotification.
 *
 * @discussion 操作失败后, 函数可能返回以下四种错误代码: ErrorCodeResponsedNULLData, ErrorCodeIncorrectResponsedDataFormat, ErrorCodeInvalidOperation, ErrorCodeNoCurrentUserInfo.
 
 * @param taskID 操作的维保任务单ID.
 * @param remark 维保任务单的备注项. 由前方部长和技术主管填写. 用于对任务单执行过程的重要内容记录, 以及对完结归档任务单的类型分类(关键词).
 * @param operationType 操作类型. 由enum MaintenanceTaskOperationType定义. 任务单可执行的操作由服务器返回.
 * @param taskReceiverName 转单操作中, 接单人的UserName. 其他类型操作请设为"".
 * @param maintenancePlanEstimatedEndingTime 任务单维保方案的计划完成时间.
 * @param maintenancePlanDescription 维保方案说明.
 * @param maintenancePlanParticipantsName 维保任务参与者列表.
 * @param taskImagesInfo 维保方案中的图片信息. 上传图片时返回
 * @param taskRating 任务单完成确认时, 生产操作人员的评分项.
 * @param handler 网络操作返回后处理的块。块包含两个参数:
 1. (BOOL)completedWithNoError (操作成功返回TRUE，操作失败返回FALSE);
 2. (NSError *)error (如果操作成功，则error的值为nil，如果操作失败，则error包含了操作失败的信息，用于调试和使用中确定操作失败原因。其中，error.code属性为错误代码，由enum类型WISErrorCode定义; error.localizedDescription属性为故障描述;error.localizedFailureReason属性为故障原因说明; error.localizedRecoverySuggestion属性为建议的解决方法); error.taskIDOfOperation属性为操作对应的任务ID, 对于新建任务单, TaskID为""; error.operationType属性为操作的类型, 对于新建任务单, OperationType为SubmitApply.
 */
- (NSURLSessionDataTask *) maintenanceTaskOperationWithTaskID:(NSString *) taskID
                                                       remark:(NSString *) remark
                                                operationType:(MaintenanceTaskOperationType) operationType
                                             taskReceiverName:(NSString *) taskReceiverName /*转单时用. 非转单时填@""*/
                           maintenancePlanEstimatedEndingTime:(NSDate *) maintenancePlanEstimatedEndingTime
                                   maintenancePlanDescription:(NSString *) maintenancePlanDescription
                                  maintenancePlanParticipants:(NSArray <WISUser *> *) maintenancePlanParticipants
                                                taskImageInfo:(NSDictionary<NSString *, WISFileInfo *> *)taskImagesInfo
                                                   taskRating:(WISMaintenanceTaskRating *) taskRating
                                         andCompletionHandler:(WISMaintenanceTaskOperationHandler) handler;


#pragma mark - Inspection Task Update Info & Operations

- (NSURLSessionDataTask *) updateInspectionInfoWithDeviceID:(NSString *) deviceID completionHandler:(WISInspectionTaskUpdateInfoHandler) handler;

- (NSURLSessionDataTask *) updateInspectionsInfoWithCompletionHandler:(WISInspectionTaskUpdateInfoHandler) handler;

- (NSURLSessionDataTask *) updateDeviceTypesInfoWithCompletionHandler:(WISInspectionTaskUpdateInfoHandler) handler;

- (NSURLSessionDataTask *) updateOverDueInspectionsInfoWithCompletionHandler:(WISInspectionTaskUpdateInfoHandler) handler;

- (NSURLSessionDataTask *) updateHistoricalInspectionsInfoWithStartDate:(NSDate *)startDate
                                                                endDate:(NSDate *)endDate
                                                     recordNumberInPage:(NSInteger)numberInPage
                                                              pageIndex:(NSInteger)index
                                                      completionHandler:(WISInspectionTaskUpdateInfoHandler)handler;

- (NSURLSessionDataTask *) submitInspectionResult:(NSArray<WISInspectionTask *> *)inspectionTasks completionHandler:(WISInspectionTaskOperationHandler) handler;

#pragma mark - Tool Method

+ (WISFileInfo *) produceFileInfoWithFileRemoteURL:(NSString *)url;


#pragma mark - support method: Archive and Unarchive Current User Info

- (void) updateCurrentUserWithUserInfo:(WISUser *)user;

- (void) ArchiveCurrentUserInfo;

- (void) removeArchivedCurrentUserInfo;

- (BOOL) preloadArchivedUserInfo;

@end
