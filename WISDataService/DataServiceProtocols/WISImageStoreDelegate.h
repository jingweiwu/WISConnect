//
//  WISImageStoreDelegate.h
//  WISConnect
//
//  Created by Jingwei Wu on 2/25/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#ifndef WISImageStoreDelegate_h
#define WISImageStoreDelegate_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#endif /* WISImageStoreDelegate_h */


@protocol WISImageStoreDelegate <NSObject>

@required
- (void) setImage:(UIImage *)image forImageName:(NSString *)name;
- (void) setImages:(NSDictionary<NSString *, UIImage *> *) images;

- (UIImage *) imageForImageName:(NSString *)name;
- (NSDictionary<NSString *, UIImage *> *) imagesForImagesName:(NSArray<NSString *> *)imagesName;

- (NSArray<NSString *> *) findImagesNameNotContainedInStoreFrom:(NSArray<NSString *> *)imagesName;

- (void) deleteImageForImageName:(NSString *)name;

- (void) deleteImageForImageNames:(NSArray<NSString *> *)imageNames;

- (void) clearCacheInMemory;
- (void) clearCacheOnDeviceStorage;

- (float) cacheSizeOnDeviceStorage;

@optional

@end