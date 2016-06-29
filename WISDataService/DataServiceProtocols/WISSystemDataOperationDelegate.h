//
//  WISSystemDataOperationDelegate.h
//  WISConnect
//
//  Created by Jingwei Wu on 2/28/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#ifndef WISSystemDataOperationDelegate_h
#define WISSystemDataOperationDelegate_h

#endif /* WISSystemDataOperationDelegate_h */

@protocol WISSystemDataOperationDelegate <NSObject>

@required
/// SignIn
- (void) signInSucceeded;
- (void) signInFailedWithError:(NSError *) error;

/// Changing password
- (void) changePasswordSucceeded;
- (void) changePasswordFailedWithError:(NSError *) error;


/// Update current user detail info
- (void) updateCurrentUserDetailInfoSucceeded;
- (void) updateCurrentUserDetailInfoFailedWithError:(NSError *) error;

/// Submit current user detail info
- (void) submitCurrentUserDetailInfoSucceeded;
- (void) submitCurrentUserDetailInfoFailedWithError:(NSError *) error;

///CLOCK
- (void) updateCurrentClockStatusSucceeded;
- (void) updateCurrentClockStatusFailedWithError:(NSError *) error;

- (void) updateClockRecordsSucceeded;
- (void) updateClockRecordsFailedWithError:(NSError *) error;

- (void) updateWorkShiftsSucceeded;
- (void) updateWorkShiftsFailedWithError:(NSError *) error;

- (void) updateAttendanceRecordsSucceeded;
- (void) updateAttendanceRecordsFailedWithError:(NSError *) error;

- (void) submitClockActionSucceeded;
- (void) submitClockActionFailedWithError:(NSError *) error;

/// Upload images
- (void) uploadImagesSucceeded;
- (void) uploadImagesFailedWithError:(NSError *) error;

/// Download images
- (void) downloadImagesSucceeded;
- (void) downloadImagesFailedWithError:(NSError *) error;

/// Submit User Client ID
- (void) SubmiteUserClientIDSucceeded;
- (void) SubmiteUserClientIDFailedWithError:(NSError *) error;

@optional
/// SignIn
- (void) signInSucceededWithResponsedData:(NSData *) responsedData;
- (void) signInFailedWithError:(NSError *) error andResponsedData:(NSData *) responsedData;

/// Changing password
- (void) changePasswordSucceededWithResponsedData:(NSData *) responsedData;
- (void) changePasswordFailedWithError:(NSError *) error andResponsedData:(NSData *) responsedData;


/// Update current user detail info
- (void) updateCurrentUserDetailInfoSucceededWithResponsedData:(NSData *) responsedData;
- (void) updateCurrentUserDetailInfoFailedWithError:(NSError *) error andResponsedData:(NSData *) responsedData;

/// Submit current user detail info
- (void) submitCurrentUserDetailInfoSucceededWithResponsedData:(NSData *) responsedData;
- (void) submitCurrentUserDetailInfoFailedWithError:(NSError *) error andResponsedData:(NSData *) responsedData;

/// CLOCK
- (void) updateCurrentClockStatusSucceededWithResponsedData:(NSData *) responsedData;
- (void) updateCurrentClockStatusFailedWithError:(NSError *) error andResponsedData:(NSData *) responsedData;

- (void) updateClockRecordsSucceededWithResponsedData:(NSData *) responsedData;
- (void) updateClockRecordsFailedWithError:(NSError *) error andResponsedData:(NSData *) responsedData;

- (void) updateWorkShiftsSucceededWithResponsedData:(NSData *) responsedData;
- (void) updateWorkShiftsFailedWithError:(NSError *) error andResponsedData:(NSData *) responsedData;

- (void) updateAttendanceRecordsSucceededWithResponsedData:(NSData *) responsedData;
- (void) updateAttendanceRecordsFailedWithError:(NSError *) error andResponsedData:(NSData *) responsedData;

- (void) submitClockActionSucceededWithResponsedData:(NSData *) responsedData;
- (void) submitClockActionFailedWithError:(NSError *) error andResponsedData:(NSData *) responsedData;

/// Upload images
- (void) uploadImagesSucceededWithResponsedData:(NSData *) responsedData;
- (void) uploadImagesFailedWithError:(NSError *) error andResponsedData:(NSData *) responsedData;


/// Download images
- (void) downloadImagesSucceededWithResponsedData:(NSData *) responsedData;
- (void) downloadImagesFailedWithError:(NSError *) error andResponsedData:(NSData *) responsedData;


/// Submit User Client ID
- (void) SubmiteUserClientIDSucceededWithResponsedData:(NSData *) responsedData;
- (void) SubmiteUserClientIDFailedWithError:(NSError *) error
                           andResponsedData:(NSData *) responsedData;

@end