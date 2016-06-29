//
//  WISMaintenanceTask.h
//  WISConnect
//
//  Created by Jingwei Wu on 2/21/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WISSorter.h"

@class WISUser, WISMaintenancePlan, WISMaintenanceTaskRating, WISFileInfo;

/**
 * @brief 由服务器定义的当前走流程的维保任务类型
 */
typedef NS_ENUM(NSInteger, MaintenanceTaskType) {
    /// 尚未归类的维保任务
    MaintenanceTaskUnclassified = 0,
    /// 待审批维保任务 - 用于当前正在进行的维保任务查询
    MaintenanceTaskForApproval = 1,
    /// 一般性维保任务 - 用于当前正在进行的维保任务查询
    MaintenanceTaskNormal = 2,
    /// 未归档的维保任务 - 用于历史维保任务查询
    MaintenanceTaskNotArchived = 3,
    /// 已归档的维保任务 - 用于历史维保任务查询
    MaintenanceTaskArchived = 4,
};

/* old definition */
///**
// * @brief 由服务器定义的历史维保任务类型
// */
//typedef NS_ENUM(NSInteger, HistoryMaintenanceTaskType) {
//    /// 已归档的维保任务
//    MaintenanceTaskArchived = 3,
//    /// 未归档的维保任务
//    MaintenanceTaskNotArchived = 4,
//};

@class WISMaintenanceTaskState;
@interface WISMaintenanceTask : NSObject <NSCopying, NSCoding>
/// 维保任务 ID
@property (readwrite, strong) NSString *taskID;
/// 维保任务名称
@property (readwrite, strong) NSString *taskName;
/// 维保任务状态
@property (readwrite, strong) NSString *state;
/// 维保任务 - 是否已归档
@property (readwrite, getter=isArchived, setter=archived:) BOOL archived;
/// 维保任务流转过程的历史状态列表
@property (readwrite, strong) NSMutableArray<WISMaintenanceTaskState *> *passedStates;
/// 维保任务类型, 在WISMaintenanceTask.h中定义
@property (readwrite) MaintenanceTaskType taskType;
/// 维保任务所在工艺段名称
@property (readwrite, strong) NSString *processSegmentName;
/// 维保任务创建人
@property (readwrite) WISUser *creator;
/// 维保任务责任人
@property (readwrite) WISUser *personInCharge;
/// 维保任务详情描述
@property (readwrite, strong) NSString *taskApplicationContent;
/// 维保任务备注说明 - 由前方部长在备注功能中填写
@property (readwrite, strong) NSString *taskComment;
/// 维保任务完成备注 - 由维保人员在维保任务完成时填写
@property (readwrite, strong) NSString *taskFinishedRemark;
/// 维保任务争议原因说明 - 由技术主管在发起争议时填写
@property (readwrite, strong) NSString *disputeProcedureRemark;
/// 维保任务归档说明 - 由技术主管在归档时填写
@property (readwrite, strong) NSString *archivingRemark;
/// 维保任务创建时间
@property (readwrite, strong) NSDate *createdDateTime;
/// 维保任务维保方案清单
@property (readwrite, strong) NSMutableArray<WISMaintenancePlan *> *maintenancePlans;
/// 维保任务评价
@property (readwrite, strong) WISMaintenanceTaskRating *taskRating;
/// 维保任务当前允许的操作列表
@property (readwrite, strong) NSDictionary<NSString *, NSString *> *validOperations;
/// 维保任务图片信息列表 (用于维保任务发起－生产人员添加图片, 以及维保任务结束-维保人员添加图片)
@property (readwrite, strong) NSMutableDictionary<NSString *, WISFileInfo *> *imagesInfo;

- (instancetype)init; // __attribute__((unavailable("init method not available")));

- (instancetype)initWithTaskID:(NSString *) taskID
                      taskName:(NSString *) taskName
                     taskState:(NSString *) state
                    isArchived:(BOOL) archieved
              taskPassedStates:(NSMutableArray<WISMaintenanceTaskState *> *) passedStates
                      taskType:(MaintenanceTaskType) taskType
            processSegmentName:(NSString *) processSegmentName
                       creator:(WISUser *) creator
                personInCharge:(WISUser *) personInCharge
        taskApplicationContent:(NSString *) taskApplicationContent
                   taskComment:(NSString *) comment
            taskFinishedRemark:(NSString *) finishedRemark
        disputeProcedureRemark:(NSString *) disputeProcedureRemark
               archivingRemark:(NSString *) archivingRemark
               createdDateTime:(NSDate *) createdDateTime
              maintenancePlans:(NSMutableArray<WISMaintenancePlan *> *) maintenancePlans
                    taskRating:(WISMaintenanceTaskRating *) taskRating
               validOperations:(NSDictionary<NSString *, NSString *> *) validOperations
                 andImagesInfo:(NSMutableDictionary<NSString *, WISFileInfo *> *) imagesInfo;

- (void) appendImagsInfo:(NSMutableDictionary<NSString *, WISFileInfo *> *) imagesInfo;

+ (arrayForwardSorterWithResult) arrayForwardSorterWithResult;
+ (arrayForwardSorterWithResult) arrayBackwardSorterWithResult;

+ (arrayForwardSorterWithBOOL) arrayForwardWithBOOL;
+ (arrayBackwardSorterWithBOOL) arrayBackwardWithBOOL;

@end
