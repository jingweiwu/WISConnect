//
//  WISFileStoreManager.m
//  WISConnect
//
//  Created by Jingwei Wu on 3/22/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#import "WISFileStoreManager.h"

@implementation WISFileStoreManager

+ (instancetype)defaultManager {
    static WISFileStoreManager *defaultManagerInstance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultManagerInstance = [[self alloc] initPrivate];
    });
    
    return defaultManagerInstance;
}

// No one should call init
- (instancetype)init {
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[WISFileStoreManager defaultManager]"
                                 userInfo:nil];
    return nil;
}

// Secret designated initializer
- (instancetype)initPrivate {
    if (self = [super init]) {
        _uploadImageStore = [WISLocalDocumentImageStore uploadImageStoreInstance];
        _downloadImageStore = [WISLocalDocumentImageStore downloadImageStoreInstance];
    }
    return self;
}

@end
