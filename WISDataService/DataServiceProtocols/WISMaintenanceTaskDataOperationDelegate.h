//
//  WISMaintenanceTaskDataOperationDelegate.h
//  WISConnect
//
//  Created by Jingwei Wu on 2/28/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#ifndef WISMaintenanceTaskDataOperationDelegate_h
#define WISMaintenanceTaskDataOperationDelegate_h

#endif /* WISMaintenanceTaskDataOperationDelegate_h */


@protocol WISMaintenanceTaskDataOperationDelegate <NSObject>

@required
/// Update process segment
- (void) updateProcessSegmentSucceeded;
- (void) updateProcessSegmentFailedWithError:(NSError *) error;

/// Update contact user info
- (void) updateContactUserInfoSucceeded;
- (void) updateContactUserInfoFailedWithError:(NSError *) error;

/// Update relavant user info
- (void) updateRelavantUserInfoSucceeded;
- (void) updateRelavantUserInfoFailedWithError:(NSError *) error;

/// Update maintenance tasks brief info
- (void) updateMaintenanceTasksBriefInfoSucceeded;
- (void) updateMaintenanceTasksBriefInfoFailedWithError:(NSError *) error;

/// Update finished maintenance tasks brief info
- (void) updateFinishedMaintenanceTasksBriefInfoSucceeded;
- (void) updateFinishedMaintenanceTasksBriefInfoFailedWithError:(NSError *) error;

/// Update maintenance tasks less detail info
- (void) updateMaintenanceTaskLessDetailInfoSucceeded;
- (void) updateMaintenanceTaskLessDetailInfoFailedWithError:(NSError *) error;

/// Update maintenance tasks detail info
- (void) updateMaintenanceTaskDetailInfoSucceeded;
- (void) updateMaintenanceTaskDetailInfoFailedWithError:(NSError *) error;

/// Submit a new maintenance task
- (void) submitNewMaintenanceTaskSucceeded;
- (void) submitNewMaintenanceTaskFailedWithError:(NSError *) error;

/// Operations
- (void) OperationOnMaintenanceTaskSucceeded;
- (void) OperationOnMaintenanceTaskFailedWithError:(NSError *) error;



@optional /* not implemented yet */
- (void) updateProcessSegmentSucceededWithResponsedData:(NSData *) responsedData;
- (void) updateProcessSegmentFailedWithError:(NSError *) error
                            andResponsedData:(NSData *) responsedData;

/// Update contact user info
- (void) updateContactUserInfoSucceededWithResponsedData:(NSData *) responsedData;;
- (void) updateContactUserInfoFailedWithError:(NSError *) error
                             andResponsedData:(NSData *) responsedData;

/// Update relavant user info
- (void) updateRelavantUserInfoSucceededWithResponsedData:(NSData *) responsedData;;
- (void) updateRelavantUserInfoFailedWithError:(NSError *) error
                              andResponsedData:(NSData *) responsedData;

/// Update maintenance tasks brief info
- (void) updateMaintenanceTasksBriefInfoSucceedWithResponsedData:(NSData *) responsedData;
- (void) updateMaintenanceTasksBriefInfoFailedWithError:(NSError *) error
                                       andResponsedData:(NSData *) responsedData;

/// Update finished maintenance tasks brief info
- (void) updateFinishedMaintenanceTasksBriefInfoSucceededWithResponsedData:(NSData *) responsedData;
- (void) updateFinishedMaintenanceTasksBriefInfoFailedWithError:(NSError *) error
                                               andResponsedData:(NSData *) responsedData;

/// Update maintenance tasks less detail info
- (void) updateMaintenanceTaskLessDetailInfoSucceedWithResponsedData:(NSData *) responsedData;
- (void) updateMaintenanceTaskLessDetailInfoFailedWithError:(NSError *) error
                                        andResponsedData:(NSData *) responsedData;

/// Update maintenance tasks detail info
- (void) updateMaintenanceTaskDetailInfoSucceedWithResponsedData:(NSData *) responsedData;
- (void) updateMaintenanceTaskDetailInfoFailedWithError:(NSError *) error
                                            andResponsedData:(NSData *) responsedData;

/// Submit a new maintenance task
- (void) submitNewMaintenanceTaskSucceededWithResponsedData:(NSData *) responsedData;
- (void) submitNewMaintenanceTaskFailedWithError:(NSError *) error
                                andResponsedData:(NSData *) responsedData;

/// Operations
- (void) OperationOnMaintenanceTaskSucceededWithResponsedData:(NSData *) responsedData;
- (void) OperationOnMaintenanceTaskFailedWithError:(NSError *) error
                                  andResponsedData:(NSData *) responsedData;

@end
