//
//  WISMaintenanceTaskNetworkOperationDelegate.h
//  WISConnect
//
//  Created by Jingwei Wu on 2/28/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#ifndef WISMaintenanceTaskNetworkOperationDelegate_h
#define WISMaintenanceTaskNetworkOperationDelegate_h

#endif /* WISMaintenanceTaskNetworkOperationDelegate_h */


@protocol WISMaintenanceTaskNetworkOperationDelegate <NSObject>

@required
- (void) networkService: (id)sender DidUpdateMaintenanceTaskBriefInfoAndResponsedWithData: (NSData *)responsedData;
- (void) networkService: (id)sender DidUpdateMaintenanceTaskLessDetailInfoAndResponsedWithData: (NSData *)responsedData;
- (void) networkService: (id)sender DidUpdateMaintenanceTaskDetailInfoAndResponsedWithData: (NSData *)responsedData;
- (void) networkService: (id)sender DidUpdateMaintenanceAreasAndResponsedWithData: (NSData *)responsedData;

- (void) networkService: (id)sender DidUpdateHistroyMaintenanceTasksInfoInPagesAndResponsedWithData: (NSData *)responsedData;

- (void) networkService: (id)sender DidUpdateHistroyMaintenanceTasksInfoByNumberAndResponsedWithData: (NSData *)responsedData;
- (void) networkService: (id)sender DidUpdateHistroyMaintenanceTasksInfoByDateRangeAndResponsedWithData: (NSData *)responsedData;

- (void) networkService: (id)sender DidUpdateUserInfoAndResponsedWithData:(NSData *)responsedData;
- (void) networkService: (id)sender DidUpdateRelavantUserInfoAndResponsedWithData:(NSData *)responsedData;

- (void) networkService: (id)sender DidSubmitCommandOnMaintenanceTaskAndResponsedWithData:(NSData *)responsedData;

@end
