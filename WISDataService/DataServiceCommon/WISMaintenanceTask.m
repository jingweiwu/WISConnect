//
//  WISMaintenanceTask.m
//  WISConnect
//
//  Created by Jingwei Wu on 2/21/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#import "WISMaintenanceTask.h"
#import "WISUser.h"
#import "WISMaintenancePlan.h"
#import "WISMaintenanceTaskRating.h"

@interface WISMaintenanceTask ()

@end

@implementation WISMaintenanceTask

-(instancetype)init {
    return [self initWithTaskID:@""
                       taskName:@""
                      taskState:@""
               taskPassedStates:[NSMutableArray array]
                       taskType:MaintenanceTaskUnclassified
             processSegmentName:@""
                        creator:[[WISUser alloc]init]
                 personInCharge:[[WISUser alloc]init]
         taskApplicationContent:@""
                taskDescription:@""
                createdDateTime:[NSDate date]
                maintenancePlans:[NSMutableArray array]
                     taskRating:[[WISMaintenanceTaskRating alloc]init]
                validOperations:[NSDictionary dictionary]
                  andImagesInfo:[NSMutableDictionary dictionary]];
}

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
                 andImagesInfo:(NSMutableDictionary<NSString *, WISFileInfo *> *) imagesInfo {
    if (self = [super init]) {
        _taskID = taskID;
        _taskName = taskName;
        _state = state;
        _passedStates = passedStates;
        _taskType = taskType;
        _processSegmentName = processSegmentName;
        _creator = creator;
        _personInCharge = personInCharge;
        _taskApplicationContent = taskApplicationContent;
        _taskDescription = description;
        _createdDateTime = createdDateTime;
        _maintenancePlans = maintenancePlans;
        _taskRating = taskRating;
        _validOperations = [NSMutableDictionary dictionaryWithDictionary:validOperations];
        _imagesInfo = [NSMutableDictionary dictionaryWithDictionary:imagesInfo];
    }
    return self;
}

- (id) copyWithZone:(NSZone *)zone {
    WISMaintenanceTask *task = [[[self class] allocWithZone:zone] initWithTaskID:[self.taskID copy]
                                                                        taskName:[self.taskName copy]
                                                                       taskState:[self.state copy]
                                                                taskPassedStates:[self.passedStates mutableCopy]
                                                                        taskType:_taskType
                                                              processSegmentName:[self.processSegmentName copy]
                                                                         creator:[self.creator copy]
                                                                  personInCharge:[self.personInCharge copy]
                                                          taskApplicationContent:[self.taskApplicationContent copy]
                                                                 taskDescription:[self.taskDescription copy]
                                                                 createdDateTime:[self.createdDateTime copy]
                                                                 maintenancePlans:[self.maintenancePlans mutableCopy]
                                                                      taskRating:[self.taskRating copy]
                                                                 validOperations:[self.validOperations copy]
                                                                   andImagesInfo:[self.imagesInfo copy]];
    
    return task;
}

- (void) appendImagsInfo:(NSMutableDictionary<NSString *, WISFileInfo *> *) imagesInfo {
    [self.imagesInfo addEntriesFromDictionary:imagesInfo];
    self.imagesInfo = self.imagesInfo;
}

@end
