//
//  WISImageStore.h
//  WISConnect
//
//  Created by Jingwei Wu on 2/25/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WISImageStoreDelegate.h"

@class UIImage;

FOUNDATION_EXPORT NSString * const defaultLocalImageStorageDirectoryKey;


@interface WISLocalDocumentImageStore : NSObject <WISImageStoreDelegate>

+ (instancetype)downloadImageStoreInstance;
+ (instancetype)uploadImageStoreInstance;

- (instancetype)init __attribute__((unavailable("init not available, call shareInstance instead.")));

- (void)setImage:(UIImage *)image forImageName:(NSString *)name;
- (void)setImages:(NSDictionary<NSString *, UIImage *> *) images;

- (UIImage *) imageForImageName:(NSString *)name;
- (NSDictionary<NSString *, UIImage *> *)imagesForImagesName:(NSArray<NSString *> *)imagesName;

- (NSArray<NSString *> *)findImagesNameNotContainedInStoreFrom:(NSArray<NSString *> *)imagesName;

- (void)deleteImageForImageName:(NSString *)name;

- (void)deleteImageForImageNames:(NSArray<NSString *> *)imageNames;

- (void)clearCacheInMemory;
- (void)clearCacheOnDeviceStorage;

- (float)cacheSizeOnDeviceStorage;

@end
