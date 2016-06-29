//
//  WISInspectionTaskNetworkOperationDelegate.h
//  WisdriIS
//
//  Created by Jingwei Wu on 4/19/16.
//  Copyright © 2016 Wisdri. All rights reserved.
//

#ifndef WISInspectionTaskNetworkOperationDelegate_h
#define WISInspectionTaskNetworkOperationDelegate_h


#endif /* WISInspectionTaskNetworkOperationDelegate_h */

@protocol WISInspectionTaskNetworkOperationDelegate <NSObject>

@required
- (void) networkService: (id)sender DidUpdateInspectionInfoAndResponsedWithData: (NSData *)responsedData;
- (void) networkService: (id)sender DidUpdateInspectionsInfoAndResponsedWithData: (NSData *)responsedData;
- (void) networkService: (id)sender DidUpdateDeviceTypesInfoAndResponsedWithData: (NSData *)responsedData;
- (void) networkService: (id)sender DidUpdateOverDueInspectionsInfoAndResponsedWithData: (NSData *)responsedData;
- (void) networkService: (id)sender DidUpdateHistoricalInspectionsInfoAndResponsedWithData: (NSData *)responsedData;

- (void) networkService: (id)sender DidSubmitInspectionResultAndResponsedWithData: (NSData *)responsedData;

@end
