//
//  WISFileInfo.h
//  WISConnect
//
//  Created by Jingwei Wu on 3/21/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WISFileInfo : NSObject <NSCopying, NSCoding>
/// Beware! fileName does not include extension
@property (readwrite, strong) NSString *fileName;
/// file extension without "."
@property (readwrite, strong) NSString *fileType;
/// 文件在服务器上的地址 (包括文件名的完整地址)
@property (readwrite, strong) NSString *fileRemoteLocation;
/// 文件在设备上的地址 (备用)
@property (readwrite, strong) NSString *fileOnDeviceLocation;

- (instancetype)init; // __attribute__((unavailable("init method not available")));

- (instancetype)initWithFileName:(NSString *)fileName
                        fileType:(NSString *)fileType
              fileRemoteLocation:(NSString *)fileRemoteLocation
         andFileOnDeviceLocation:(NSString *)fileOnDeviceLocation;

@end
