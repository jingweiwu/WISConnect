//
//  WISSystemNetworkOperationDelegate.h
//  WISConnect
//
//  Created by Jingwei Wu on 2/28/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#ifndef WISSystemNetworkOperationDelegate_h
#define WISSystemNetworkOperationDelegate_h

#endif /* WISSystemNetworkOperationDelegate_h */


@protocol WISSystemNetworkOperationDelegate <NSObject>

@optional
- (void) networkService: (id)sender DidSignInAndResponsedWithData: (NSData *)responsedData;
- (void) networkService: (id)sender DidChangePasswordAndResponsedWithData: (NSData *)responsedData;

- (void) networkService: (id)sender DidUpdateCurrentUserDetailInfoAndResponsedWithData: (NSData *)responsedData;
- (void) networkService: (id)sender DidSubmitCurrentUserDetailInfoAndResponsedWithData: (NSData *)responsedData;


- (void) networkService: (id)sender DidUpdateCurrentClockStatusAndResponseWithData: (NSData *)responsedData;
- (void) networkService: (id)sender DidUpdateClockRecordsAndResponseWithData: (NSData *)responsedData;
- (void) networkService: (id)sender DidUpdateWorkShiftsAndResponseWithData: (NSData *)responsedData;
- (void) networkService: (id)sender DidUpdateAttendanceRecordsAndResponseWithData:(NSData *)responsedData;
- (void) networkService: (id)sender DidSubmitClockActionAndResponseWithData: (NSData *)responsedData;


- (void) networkService: (id)sender ResponsedNULLData:(NSData *)responsedData;
- (void) networkService: (id)sender FailedToParseResponsedData:(NSData *)responsedData WithError:(NSError *)error;

- (void) networkService: (id)sender DidUploadImagesResponsedWithData:(NSData *)responsedData;
- (void) networkService: (id)sender DidDownloadImagesResponsedWithData:(NSData *)responsedData;

- (void) networkService: (id)sender DidSubmitClientIDAndResponesdWithData:(NSData *)responsedData;

@end