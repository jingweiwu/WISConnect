//
//  WISArchivingStore.h
//  WisdriIS
//
//  Created by Jingwei Wu on 5/28/16.
//  Copyright © 2016 Wisdri. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WISArchivingStore : NSObject

+ (instancetype)sharedInstance;

- (instancetype)init __attribute__((unavailable("init not available, call shareInstance instead.")));

- (BOOL)setLocalArchivingStorageDirectoryWithFolderName:(NSString *) folderName
                                                    key:(NSString *) key;

- (NSString *)localArchivingStorageDirectoryWithKey:(NSString *) key;

- (NSArray<NSString *> *)filesFullPathInDirectory:(NSString *)directory;

@end
