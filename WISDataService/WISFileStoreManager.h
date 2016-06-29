//
//  WISFileStoreManager.h
//  WISConnect
//
//  Created by Jingwei Wu on 3/22/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WISImageStore.h"
#import "WISArchivingStore.h"

@interface WISFileStoreManager : NSObject

@property (weak) id<WISImageStoreDelegate> uploadImageStore;
@property (weak) id<WISImageStoreDelegate> downloadImageStore;

@property (weak) WISArchivingStore *archivingStore;

+ (instancetype)defaultManager;

- (instancetype)init __attribute__((unavailable("init not available, call shareInstance instead.")));

@end


