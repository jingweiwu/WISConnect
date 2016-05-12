//
//  WISImageStore.m
//  WISConnect
//
//  Created by Jingwei Wu on 2/25/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WISLocalDocumentImageStore.h"

NSString * const defaultLocalImageStorageDirectoryKey = @"defaultLocalImageStorageDirectoryKey";


@interface WISLocalDocumentImageStore ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, UIImage *> *dictionaryOfImage;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *localImageStorageDirectories;

@end

@implementation WISLocalDocumentImageStore

#pragma mark - initializer
+ (instancetype)downloadImageStoreInstance {
    static WISLocalDocumentImageStore *shareLocalDocumentDownloadImageStoreInstance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareLocalDocumentDownloadImageStoreInstance = [[self alloc] initImageStore:@"/DownloadImages"];
    });
    
    return shareLocalDocumentDownloadImageStoreInstance;
}

+ (instancetype)uploadImageStoreInstance {
    static WISLocalDocumentImageStore *shareLocalDocumentUploadImageStoreInstance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareLocalDocumentUploadImageStoreInstance = [[self alloc] initImageStore:@"/UploadImages"];
    });
    
    return shareLocalDocumentUploadImageStoreInstance;
}

// No one should call init
- (instancetype)init {
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[WISLocalDocumentImageStore sharedInstance]"
                                 userInfo:nil];
    return nil;
}

// Secret designated initializer
- (instancetype)initImageStore:(NSString *)defineStorageDirectory {
    if (self = [super init]) {
        _dictionaryOfImage = [NSMutableDictionary dictionary];
        _localImageStorageDirectories = [NSMutableDictionary dictionary];
        
        NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDirectory = [documentDirectories firstObject];
        
        NSString *imageStorageDirectory = [NSString stringWithFormat:@"%@%@", documentDirectory, defineStorageDirectory];
        BOOL isDirectory;
        NSError *createPathError;
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:imageStorageDirectory isDirectory:&isDirectory]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:imageStorageDirectory
                                      withIntermediateDirectories:NO attributes:nil
                                                            error:&createPathError];
        }
        
        [_localImageStorageDirectories setValue:imageStorageDirectory forKey:defaultLocalImageStorageDirectoryKey] ;
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self
               selector:@selector(clearCacheInMemory:)
                   name:UIApplicationDidReceiveMemoryWarningNotification
                 object:nil];
    }
    return self;
}

#pragma mark - image saving and loading
- (void)setImage:(UIImage *)image forImageName:(NSString *)imageName
{
    if (image && imageName) {
        if (![self.dictionaryOfImage valueForKey:imageName]) {
            [self.dictionaryOfImage setValue:image forKey:imageName];
        }
        
        // Create full path for image
        NSString *imagePath = [self imageDefaultStoragePathWithImageName:imageName];
        
        // Write it to full path
        if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
            BOOL isDirectory;
            NSError *createPathError;
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:[self imageDefaultStoragePath] isDirectory:&isDirectory]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:[self imageDefaultStoragePath]
                                          withIntermediateDirectories:NO attributes:nil
                                                                error:&createPathError];
            }
            
            // Turn image into JPEG data
            NSData *data = UIImagePNGRepresentation(image);
            BOOL datawrited = [data writeToFile:imagePath atomically:YES];
            
            if (datawrited) {
                NSLog(@"data write to path: %@", imagePath);
            } else {
                NSLog(@"failed write to path: %@", imagePath);
            }
        }
    }
}


- (void)setImages:(NSDictionary<NSString *, UIImage *> *) images {
    if (images && !((NSNull *)images == [NSNull null])) {
        if (images.count > 0) {
            NSArray<NSString *> *imageNames = [images allKeys];
            
            for (NSString *imageName in imageNames) {
                if (images[imageName]) {
                    [self setImage:images[imageName] forImageName:imageName];
                }
            }
        }
    }
}


- (UIImage *)imageForImageName:(NSString *)imageName {
    UIImage *findedImage = nil;
    // If possible, get it from the dictionary
    if (imageName) {
        findedImage = self.dictionaryOfImage[imageName];
    }
    
    if (!findedImage) {
        NSString *imagePath = [self imageDefaultStoragePathWithImageName:imageName];
        
        // Create UIImage object from file
        findedImage = [UIImage imageWithContentsOfFile:imagePath];
        
        // If we found an image on the file system, place it into the cache
        if (findedImage) {
            self.dictionaryOfImage[imageName] = findedImage;
        } else {
            NSLog(@"Unable to find image neither in memory nor in local file system. \nImage path is as follows:\n %@", imagePath);
        }
    }
    return findedImage;
}


/// if image not exist in local storage, the value for imageName not include in Dictionary.
- (NSDictionary<NSString *, UIImage *> *)imagesForImagesName:(NSArray<NSString *> *)imagesName {
    
    NSMutableDictionary<NSString *, UIImage *> *images = [NSMutableDictionary dictionary];
    
    if (imagesName.count > 0) {
        for (NSString *imageName in imagesName) {
            UIImage *image = [self imageForImageName:imageName];
            
            if (image && ![images valueForKey:imageName]) {
                [images setValue:image forKey:imageName];
            }
        }
    }
    
    return images;
 }

- (NSArray<NSString *> *)findImagesNameNotContainedInStoreFrom:(NSArray<NSString *> *)imagesName {
    
    NSMutableArray<NSString *> *imagesNameNotContainedInStore = [NSMutableArray array];
    
    if (imagesName.count > 0) {
        for (NSString *imageName in imagesName) {
            UIImage *image = [self imageForImageName:imageName];
            if (!image) {
                [imagesNameNotContainedInStore addObject:imageName];
            }
        }
    }
    return imagesNameNotContainedInStore;
}


- (void)deleteImageForImageName:(NSString *)imageName {
    if (!imageName) {
        return;
    }
    [self.dictionaryOfImage removeObjectForKey:imageName];
    
    NSString *imagePath = [self imageDefaultStoragePathWithImageName:imageName];
    [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
}


- (void)deleteImageForImageNames:(NSArray<NSString *> *)imageNames {
    if(!imageNames) {
        return;
    }
    
    if (imageNames.count > 0) {
        for (NSString *imageName in imageNames) {
            [self deleteImageForImageName:imageName];
        }
    }
}


#pragma mark - Support method
- (NSString *)imageDefaultStoragePath {
    return self.localImageStorageDirectories[defaultLocalImageStorageDirectoryKey];
}

- (NSString *)imageDefaultStoragePathWithImageName:(NSString *)imageName {
    return [self.localImageStorageDirectories[defaultLocalImageStorageDirectoryKey] stringByAppendingPathComponent:imageName];
}


- (void)clearCacheInMemory {
    [self clearCacheInMemory:nil];
}

- (void)clearCacheOnDeviceStorage {
    [self clearCacheOnDeviceStorage:[NSString stringWithString:self.localImageStorageDirectories[defaultLocalImageStorageDirectoryKey]]];
}


- (void)clearCacheOnDeviceStorage:(NSString *)imageStorageDirectory {
    NSLog(@"flushing image files out of the device storage");
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:imageStorageDirectory error:&error];
}


- (unsigned long long)fileSizeAtPath:(NSString*) filePath{
    
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]) {
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}

/**
 * @brief unit of return value is MB (Mega-Byte).
 *
**/
- (float)folderSizeAtDirectory:(NSString *)directory {
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:directory]) return 0.0f;
    
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:directory] objectEnumerator];
    
    NSString* fileName;
    long long folderSize = 0.0;
    
    while ((fileName = [childFilesEnumerator nextObject]) != nil) {
        NSString* fileAbsolutePath = [directory stringByAppendingPathComponent:fileName];
        folderSize += [self fileSizeAtPath:fileAbsolutePath];
    }
    
    return folderSize/(1024.0 * 1024);
}

/**
 * @brief unit of return value is kB (kilo-Byte).
 *
 **/
- (float) cacheSizeOnDeviceStorage {
    return [self folderSizeAtDirectory:[NSString stringWithString:self.localImageStorageDirectories[defaultLocalImageStorageDirectoryKey]]];
}


#pragma mark - Notification selector
- (void)clearCacheInMemory:(NSNotification *)notification {
    NSLog(@"flushing %lu images out of the cache", (unsigned long)[self.dictionaryOfImage count]);
    [self.dictionaryOfImage removeAllObjects];
}


@end