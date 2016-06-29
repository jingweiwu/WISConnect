//
//  WISFileInfo.m
//  WISConnect
//
//  Created by Jingwei Wu on 3/21/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#import "WISFileInfo.h"


NSString *const fileNameEncodingKey = @"fileName";
NSString *const fileTypeEncodingKey = @"fileType";
NSString *const fileRemoteLocationEncodingKey = @"fileRemoteLocation";
NSString *const fileOnDeviceLocationEncodingKey = @"fileOnDeviceLocation";

@interface WISFileInfo ()

@end

@implementation WISFileInfo

- (instancetype)init {
    return [self initWithFileName:@""
                         fileType:@""
               fileRemoteLocation:@""
          andFileOnDeviceLocation:@""];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _fileName = (NSString *)[aDecoder decodeObjectForKey:fileNameEncodingKey];
        _fileType = (NSString *)[aDecoder decodeObjectForKey:fileTypeEncodingKey];
        _fileRemoteLocation = (NSString *)[aDecoder decodeObjectForKey:fileRemoteLocationEncodingKey];
        _fileOnDeviceLocation = (NSString *)[aDecoder decodeObjectForKey:fileOnDeviceLocationEncodingKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.fileName forKey:fileNameEncodingKey];
    [aCoder encodeObject:self.fileType forKey:fileTypeEncodingKey];
    [aCoder encodeObject:self.fileRemoteLocation forKey:fileRemoteLocationEncodingKey];
    [aCoder encodeObject:self.fileOnDeviceLocation forKey:fileOnDeviceLocationEncodingKey];
}


- (instancetype)initWithFileName:(NSString *)fileName
                        fileType:(NSString *)fileType
              fileRemoteLocation:(NSString *)fileRemoteLocation
         andFileOnDeviceLocation:(NSString *)fileOnDeviceLocation {
    
    if (self = [super init]) {
        _fileName = fileName;
        _fileType = fileType;
        _fileRemoteLocation = fileRemoteLocation;
        _fileOnDeviceLocation = fileOnDeviceLocation;
    }
    return self;
}

- (id) copyWithZone:(NSZone *)zone {
    WISFileInfo * fileInfo = [[[self class] allocWithZone:zone] initWithFileName:[self.fileName copy]
                                                                        fileType:[self.fileType copy]
                                                              fileRemoteLocation:[self.fileRemoteLocation copy]
                                                         andFileOnDeviceLocation:[self.fileOnDeviceLocation copy]];
    return fileInfo;
}


@end
