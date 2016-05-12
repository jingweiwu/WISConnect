//
//  WISNetworkServiceMisc.h
//  WISConnect
//
//  Created by Jingwei Wu on 2/19/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#ifndef WISNetworkServiceMisc_h
#define WISNetworkServiceMisc_h
#endif /* WISNetworkServiceMisc_h */

#import <Foundation/Foundation.h>


typedef enum {
    SignIn = 0,         // default
    GetTaskBriefInfo,
    GetTaskDetailInfo,
    GetAreas,
    CreateNewTask,
    GetHistoryTasksInfoByNumber,
    GetHistoryTasksInfoByDateRange,
    GetPermissionsForCurrentUser,
    SubmitCommand,
}OperationContractType;

