//
//  WISNetworkDelegate.h
//  WISConnect
//
//  Created by Jingwei Wu on 3/29/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#ifndef WISNetworkingDelegate_h
#define WISNetworkingDelegate_h


#endif /* WISNetworkDelegate_h */

@protocol WISNetworkingDelegate <NSObject>
@required
- (void) networkStatusChangedTo:(NSInteger)status;
@end