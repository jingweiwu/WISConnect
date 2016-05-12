//
//  WISMaintenanceTask.h
//  WISConnect
//
//  Created by Jingwei Wu on 2/21/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#import <Foundation/Foundation.h>

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
@interface WISMaintenanceTask : NSObject <NSCopying>

///
@property (readwrite, strong) NSString *taskID;
@property (readwrite, strong) NSString *taskName;
@property (readwrite, strong) NSString *state;
@property (readwrite, strong) NSMutableArray<WISMaintenanceTaskState *> *passedStates;
@property (readwrite) MaintenanceTaskType taskType;
@property (readwrite, strong) NSString *processSegmentName;
@property (readwrite) WISUser *creator;
@property (readwrite) WISUser *personInCharge;
@property (readwrite, strong) NSString *taskApplicationContent;
@property (readwrite, strong) NSString *taskDescription;
@property (readwrite, strong) NSDate *createdDateTime;
@property (readwrite, strong) NSMutableArray<WISMaintenancePlan *> *maintenancePlans;
@property (readwrite, strong) WISMaintenanceTaskRating *taskRating;
@property (readwrite, strong) NSDictionary<NSString *, NSString *> *validOperations;
@property (readwrite, strong) NSMutableDictionary<NSString *, WISFileInfo *> *imagesInfo;

- (instancetype)init; // __attribute__((unavailable("init method not available")));

- (instancetype)initWithTaskID:(NSString *) taskID
                      taskName:(NSString *) taskName
                     taskState:(NSString *) state
              taskPassedStates:(NSMutableArray<WISMaintenanceTaskState *> *)passedStates
                      taskType:(MaintenanceTaskType) taskType
            processSegmentName:(NSString *) processSegmentName
                       creator:(WISUser *) creator
                personInCharge:(WISUser *) personInCharge
        taskApplicationContent:(NSString *) taskApplicationContent
               taskDescription:(NSString *) description
               createdDateTime:(NSDate *) createdDateTime
               maintenancePlans:(NSMutableArray<WISMaintenancePlan *> *) maintenancePlans
                    taskRating:(WISMaintenanceTaskRating *) taskRating
               validOperations:(NSDictionary<NSString *, NSString *> *) validOperations
                 andImagesInfo:(NSMutableDictionary<NSString *, WISFileInfo *> *) imagesInfo;

- (void) appendImagsInfo:(NSMutableDictionary<NSString *, WISFileInfo *> *) imagesInfo;

@end
