//
//  WISSystemCommNotification.h
//  WISConnect
//
//  Created by Jingwei Wu on 2/28/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#ifndef WISSystemNetworkNotification_h
#define WISSystemNetworkNotification_h

#import <Foundation/Foundation.h>

#endif /* WISSystemNetworkNotification_h */

/// NetworkService Notifications
///

/// @brief LogIn operation responsed
FOUNDATION_EXPORT NSString *const WISSystemSignInResponsedNotification;
FOUNDATION_EXPORT NSString *const WISSystemChangingPasswordResponsedNotification;

FOUNDATION_EXPORT NSString *const WISSystemUpdateCurrentUserDetailInfoResponsedNotification;
FOUNDATION_EXPORT NSString *const WISSystemSubmitCurrentUserDetailInfoResponsedNotification;

FOUNDATION_EXPORT NSString *const WISSystemUpdateCurrentClockStatusResponsedNotification;
FOUNDATION_EXPORT NSString *const WISSystemUpdateClockRecordsResponsedNotification;
FOUNDATION_EXPORT NSString *const WISSystemUpdateWorkShiftsResponsedNotification;
FOUNDATION_EXPORT NSString *const WISSystemUpdateAttendanceRecordsResponsedNotification;
FOUNDATION_EXPORT NSString *const WISSystemSubmitClockActionResponsedNotification;

FOUNDATION_EXPORT NSString *const WISNetworkResponsedNULLDataNotification;
FOUNDATION_EXPORT NSString *const WISNetworkResponsedDataParseErrorNotification;

FOUNDATION_EXPORT NSString *const WISUploadImagesResponsedNotification;
FOUNDATION_EXPORT NSString *const WISDownloadImagesResponsedNotification;

FOUNDATION_EXPORT NSString *const WISSubmitClientIDResponsedNotification;