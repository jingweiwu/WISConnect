//
//  WISInspectionTaskDataOperationDelegate.h
//  WisdriIS
//
//  Created by Jingwei Wu on 4/19/16.
//  Copyright © 2016 Wisdri. All rights reserved.
//

#ifndef WISInspectionTaskDataOperationDelegate_h
#define WISInspectionTaskDataOperationDelegate_h


#endif /* WISInspectionTaskDataOperationDelegate_h */

@protocol WISInspectionTaskDataOperationDelegate <NSObject>

@required
/// Update inspection info
- (void) updateInspectionInfoSucceeded;
- (void) updateInspectionInfoFailedWithError:(NSError *) error;

/// Update inspections info
- (void) updateInspectionsInfoSucceeded;
- (void) updateInspectionsInfoFailedWithError:(NSError *) error;

/// Update device types info
- (void) updateDeviceTypesInfoSucceeded;
- (void) updateDeviceTypesInfoFailedWithError:(NSError *) error;

/// Update over due inspections info
- (void) updateOverDueInspectionsInfoSucceeded;
- (void) updateOverDueInspectionsInfoFailedWithError:(NSError *) error;

/// Update historical inspections info
- (void) updateHistoricalInspectionsInfoSucceeded;
- (void) updateHistoricalInspectionsInfoFailedWithError:(NSError *) error;

/// Submit inspection result
- (void) submitInspectionsResultSucceeded;
- (void) submitInspectionsResultFailedWithError:(NSError *) error;


@optional /* not implemented yet */
/// Update inspection info
- (void) updateInspectionInfoSucceedWithResponsedData:(NSData *) responsedData;
- (void) updateInspectionInfoFailedWithError:(NSError *) error
                                       andResponsedData:(NSData *) responsedData;

/// Update inspections info
- (void) updateInspectionsInfoSucceedWithResponsedData:(NSData *) responsedData;
- (void) updateInspectionsInfoFailedWithError:(NSError *) error
                             andResponsedData:(NSData *) responsedData;

/// Update device types info
- (void) updateDeviceTypesInfoSucceededWithResponsedData:(NSData *) responsedData;
- (void) updateDeviceTypesInfoFailedWithError:(NSError *) error
                             andResponsedData:(NSData *) responsedData;

/// Update over due inspections info
- (void) updateOverDueInspectionsInfoSucceededWithResponsedData:(NSData *) responsedData;
- (void) updateOverDueInspectionsInfoFailedWithError:(NSError *) error
                                    andResponsedData:(NSData *) responsedData;

/// Update historical inspections info
- (void) updateHistoricalInspectionsInfoSucceededWithResponsedData:(NSData *) responsedData;
- (void) updateHistoricalInspectionsInfoFailedWithError:(NSError *) error
                                    andResponsedData:(NSData *) responsedData;

/// Submit inspection result
- (void) submitInspectionsResultSucceededWithResponsedData:(NSData *) responsedData;
- (void) submitInspectionsResultFailedWithError:(NSError *) error
                              andResponsedData:(NSData *) responsedData;

@end