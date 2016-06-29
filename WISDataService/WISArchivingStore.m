//
//  WISArchivingStore.m
//  WisdriIS
//
//  Created by Jingwei Wu on 5/28/16.
//  Copyright © 2016 Wisdri. All rights reserved.
//

#import "WISArchivingStore.h"

@interface WISArchivingStore()

@property (readwrite, strong) NSMutableDictionary<NSString*, NSString *> *localArchivingStorageDirectories;

@end


@implementation WISArchivingStore

+ (instancetype)sharedInstance {
    static WISArchivingStore *shareLocalArchivingStoreInstance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareLocalArchivingStoreInstance = [[self alloc] initDefault];
    });
    
    return shareLocalArchivingStoreInstance;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[WISArchivingStore sharedInstance]"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initDefault {
    if (self = [super init]) {
        _localArchivingStorageDirectories = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL)setLocalArchivingStorageDirectoryWithFolderName:(NSString *) folderName
                                                    key:(NSString *) key {
    
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [documentDirectories firstObject];
    NSString *archivingStorageDirectory = [documentDirectory stringByAppendingPathComponent:folderName];
    NSError *error;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:archivingStorageDirectory]) {
        if([[NSFileManager defaultManager] createDirectoryAtPath:archivingStorageDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            // do nothing
        }
    }
    
    [self.localArchivingStorageDirectories setValue:archivingStorageDirectory forKey:key];
    return YES;
}

- (NSString *)localArchivingStorageDirectoryWithKey:(NSString *) key {
    return _localArchivingStorageDirectories[key];
}

- (NSArray<NSString *> *)filesFullPathInDirectory:(NSString *)directory {
    NSArray<NSString *> *filesName;
    NSMutableArray<NSString *> *filesFullPath = [NSMutableArray array];
    
    filesName = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:nil];
    
    if (filesName.count > 0) {
        NSString *fileFullPath;
        for (NSString *fileName in filesName) {
            fileFullPath = [directory stringByAppendingPathComponent:fileName];
            if ([[NSFileManager defaultManager] fileExistsAtPath:fileFullPath]) {
                [filesFullPath addObject:fileFullPath];
            }
        }
    }
    return filesFullPath;
}



@end
