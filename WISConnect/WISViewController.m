//
//  WISViewController.m
//  WISConnect
//
//  Created by Jingwei Wu on 2/18/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#import "WISViewController.h"


@interface WISViewController ()

@property (weak) WISDataManager *dataManager;

@property (strong) NSString * currentSelectedOperation;

@end

@implementation WISViewController

- (void)viewWillAppear:(BOOL)animated {
    self.dataManager = [WISDataManager sharedInstance];
    self.pickerView.delegate = self;
    self.pickerView.dataSource = self;
    self.dataManager.networkingDelegate = self;
    
    self.pickerArray = [[NSArray alloc]initWithObjects:
                        @"登录",
                        @"更新工艺段列表",
                        @"更新人员列表",
                        @"更新任务简要信息",
                        @"更新任务详细信息",
                        @"按数量更新历史数据",
                        @"按日期更新历史数据",
                        @"申请新的维保任务单",
                        /*@"上传文件",
                        @"下载指定文件", */
                        @"保存文件",
                        @"获取文件",
                        @"清除缓存",
                        @"测试提交命令的参数生成",
                        @"打卡",
                        @"获得打卡状态",
                        @"获得打卡记录",
                        @"测试WorkShift",
                        @"更新当前用户详细信息",
                        @"获取当前用户详细信息",
                        @"获取考勤信息",
                        nil];
    
    self.currentSelectedOperation = self.pickerArray[0];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [self.pickerArray count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [self.pickerArray objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.currentSelectedOperation = [self.pickerArray objectAtIndex:row];
}



- (IBAction)receiveMessage:(id)sender {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notificationCenterTest:)
                                                 name:WISSystemSignInSucceededNotification
                                               object:nil];
    
    if([self.currentSelectedOperation isEqualToString:@"登录"]) {
        __block NSString *responsedString = nil;
        __block UIAlertView *alertView;
        
        [self.dataManager signInWithUserName:self.textField01.text
                                 andPassword:self.textField02.text
         completionHandler:^(BOOL completedWithNoError, NSError *error) {
             
             if (completedWithNoError) {
                 responsedString = [[NSString alloc] initWithFormat:@"%@ %@", self.dataManager.currentUser.userName, self.dataManager.currentUser.fullName];
                 NSLog(@"responseData : %@", responsedString);
                 self.labelResult.text = responsedString;
                 alertView = [[UIAlertView alloc] initWithTitle:@"test"
                                                        message:responsedString
                                                       delegate:nil
                                              cancelButtonTitle:@"ok"
                                              otherButtonTitles:nil];
                 [alertView show];
                 
             } else {
                 
                 switch (error.code) {
                    case ErrorCodeWrongFuncParameters:
                         alertView = [[UIAlertView alloc] initWithTitle:@"test"
                                                                message:error.localizedFailureReason
                                                               delegate:nil
                                                      cancelButtonTitle:@"ok"
                                                      otherButtonTitles:nil];
                         [alertView show];
                         break;
                         
                     case ErrorCodeSignInUserNotExist:
                        alertView = [[UIAlertView alloc] initWithTitle:@"test"
                                                                message:error.localizedFailureReason
                                                               delegate:nil
                                                      cancelButtonTitle:@"ok"
                                                      otherButtonTitles:nil];
                        [alertView show];
                        break;
                         
                     case ErrorCodeSignInWrongPassword:
                        alertView = [[UIAlertView alloc] initWithTitle:@"test"
                                                                message:error.localizedFailureReason
                                                               delegate:nil
                                                      cancelButtonTitle:@"ok"
                                                      otherButtonTitles:nil];
                        [alertView show];
                        break;
                         
                     default:
                        break;
                 }
             }
        }];
    }
    
    if([self.currentSelectedOperation isEqualToString:@"更新工艺段列表"]) {
        __block NSString *responsedString = nil;
        __block UIAlertView *alertView;
        
        [self.dataManager updateProcessSegmentWithCompletionHandler:^(BOOL completedWithNoError, NSError *error, NSString *classNameOfUpdatedDataAsString, id updatedData) {
            
            if (completedWithNoError) {
                responsedString = [[NSString alloc] initWithFormat:@"%@", [self.dataManager.processSegments description]];
                NSLog(@"responseData : %@", responsedString);
                self.labelResult.text = responsedString;
                alertView = [[UIAlertView alloc] initWithTitle:@"test"
                                                       message:responsedString
                                                      delegate:nil
                                             cancelButtonTitle:@"ok"
                                             otherButtonTitles:nil];
                [alertView show];
            
            } else {
                
                switch (error.code) {
                    case ErrorCodeResponsedNULLData:
                        alertView = [[UIAlertView alloc] initWithTitle:@"test"
                                                               message:@"返回值为空"
                                                              delegate:nil
                                                     cancelButtonTitle:@"ok"
                                                     otherButtonTitles:nil];
                        [alertView show];
                        break;
                        
                    case ErrorCodeNoCurrentUserInfo:
                        alertView = [[UIAlertView alloc] initWithTitle:@"test"
                                                               message:@"未正确登录！请登录后再进行此项操作"
                                                              delegate:nil
                                                     cancelButtonTitle:@"ok"
                                                     otherButtonTitles:nil];
                        [alertView show];
                        break;
                        
                    default:
                        break;
                }
            }
        }];
    }
    
    if([self.currentSelectedOperation isEqualToString:@"更新人员列表"]) {
        __block NSString *responsedString = nil;
        __block UIAlertView *alertView;
        
        [self.dataManager updateContactUserInfoWithCompletionHandler:^(BOOL completedWithNoError, NSError *error, NSString *classNameOfUpdatedDataAsString, id updatedData) {
            
            if (completedWithNoError) {
                responsedString = [[NSString alloc] initWithFormat:@"%@", [self.dataManager.users description]];
                NSLog(@"responseData : %@", responsedString);
                self.labelResult.text = responsedString;
                alertView = [[UIAlertView alloc] initWithTitle:@"test"
                                                       message:responsedString
                                                      delegate:nil
                                             cancelButtonTitle:@"ok"
                                             otherButtonTitles:nil];
                [alertView show];
                
            } else {
                
                switch (error.code) {
                    case ErrorCodeResponsedNULLData:
                        alertView = [[UIAlertView alloc] initWithTitle:@"test"
                                                               message:@"返回值为空"
                                                              delegate:nil
                                                     cancelButtonTitle:@"ok"
                                                     otherButtonTitles:nil];
                        [alertView show];
                        break;
                        
                    case ErrorCodeNoCurrentUserInfo:
                        alertView = [[UIAlertView alloc] initWithTitle:@"test"
                                                               message:@"未正确登录！请登录后再进行此项操作"
                                                              delegate:nil
                                                     cancelButtonTitle:@"ok"
                                                     otherButtonTitles:nil];
                        [alertView show];
                        break;
                        
                    default:
                        break;
                }
            }
        }];
    }


    if([self.currentSelectedOperation isEqualToString:@"更新任务简要信息"]) {
        
        __block NSString *responsedString = nil;
        __block UIAlertView *alertView;

        [self.dataManager updateMaintenanceTaskBriefInfoWithTaskTypeID:[self.textField01.text integerValue]
         completionHandler:^(BOOL completedWithNoError, NSError *error, NSString *classNameOfUpdatedDataAsString, id updatedData) {
             
             if (completedWithNoError) {
                 responsedString = [[NSString alloc] initWithFormat:@"%@", @""];
                 NSLog(@"responseData : %@", responsedString);
                 

                 self.labelResult.text = responsedString;
                 alertView = [[UIAlertView alloc] initWithTitle:@"test"
                                                        message:responsedString
                                                       delegate:nil
                                              cancelButtonTitle:@"ok"
                                              otherButtonTitles:nil];
                 [alertView show];
                 
             } else {
                 
                 switch (error.code) {
                     case ErrorCodeResponsedNULLData:
                         alertView = [[UIAlertView alloc] initWithTitle:@"test"
                                                                message:@"返回值为空"
                                                               delegate:nil
                                                      cancelButtonTitle:@"ok"
                                                      otherButtonTitles:nil];
                         [alertView show];
                         break;
                         
                     case ErrorCodeNoCurrentUserInfo:
                         alertView = [[UIAlertView alloc] initWithTitle:@"test"
                                                                message:@"未正确登录！请登录后再进行此项操作"
                                                               delegate:nil
                                                      cancelButtonTitle:@"ok"
                                                      otherButtonTitles:nil];
                         [alertView show];
                         break;
                         
                     default:
                         break;
                 }
             }
         }];
    }
    
    if([self.currentSelectedOperation isEqualToString:@"更新任务详细信息"]) {
        
        __block NSString *responsedString = nil;
        __block UIAlertView *alertView;
        
        [self.dataManager updateMaintenanceTaskDetailInfoWithTaskID:self.textField01.text
         completionHandler:^(BOOL completedWithNoError, NSError *error, NSString *classNameOfUpdatedDataAsString, id updatedData) {
                          
             if (completedWithNoError) {
                 responsedString = [[NSString alloc] initWithFormat:@"%@", @""];
                 NSLog(@"responseData : %@", responsedString);
                 self.labelResult.text = responsedString;
                 alertView = [[UIAlertView alloc] initWithTitle:@"test"
                                                        message:responsedString
                                                       delegate:nil
                                              cancelButtonTitle:@"ok"
                                              otherButtonTitles:nil];
                 [alertView show];
                 
             } else {
                 
                 switch (error.code) {
                     case ErrorCodeResponsedNULLData:
                         alertView = [[UIAlertView alloc] initWithTitle:@"test"
                                                                message:@"返回值为空"
                                                               delegate:nil
                                                      cancelButtonTitle:@"ok"
                                                      otherButtonTitles:nil];
                         [alertView show];
                         break;
                         
                     case ErrorCodeNoCurrentUserInfo:
                         alertView = [[UIAlertView alloc] initWithTitle:@"test"
                                                                message:@"未正确登录！请登录后再进行此项操作"
                                                               delegate:nil
                                                      cancelButtonTitle:@"ok"
                                                      otherButtonTitles:nil];
                         [alertView show];
                         break;
                         
                     default:
                         break;
                 }
             }
         }];
    }
    
    if([self.currentSelectedOperation isEqualToString:@"申请新的维保任务单"]) {
        
        __block NSString *responsedString = nil;
        __block UIAlertView *alertView;
        
        [self.dataManager applyNewMaintenanceTaskWithApplicationContent:self.textField01.text
                                                    processSegmentID:self.textField02.text
                                                   applicationImageInfo:nil
         completionHandler:^(BOOL completedWithNoError, NSError *error) {
                        
              if (completedWithNoError) {
                  responsedString = [[NSString alloc] initWithFormat:@"%@", @""];
                  NSLog(@"responseData : %@", responsedString);
                  self.labelResult.text = @"提交任务成功";
                  alertView = [[UIAlertView alloc] initWithTitle:@"test"
                                                         message:@"提交任务成功"
                                                        delegate:nil
                                               cancelButtonTitle:@"ok"
                                               otherButtonTitles:nil];
                  [alertView show];
                  
              } else {
                  
                  switch (error.code) {
                      case ErrorCodeResponsedNULLData:
                          alertView = [[UIAlertView alloc] initWithTitle:@"test"
                                                                 message:@"返回值为空"
                                                                delegate:nil
                                                       cancelButtonTitle:@"ok"
                                                       otherButtonTitles:nil];
                          [alertView show];
                          break;
                          
                      case ErrorCodeNoCurrentUserInfo:
                          alertView = [[UIAlertView alloc] initWithTitle:@"test"
                                                                 message:@"未正确登录！请登录后再进行此项操作"
                                                                delegate:nil
                                                       cancelButtonTitle:@"ok"
                                                       otherButtonTitles:nil];
                          [alertView show];
                          break;
                          
                      default:
                          break;
                  }
              }
         }];
    }
    
    if([self.currentSelectedOperation isEqualToString:@"更新任务详细信息"]) {
        
        __block NSString *responsedString = nil;
        __block UIAlertView *alertView;
        
        [self.dataManager updateMaintenanceTaskDetailInfoWithTaskID:self.textField01.text
        completionHandler:^(BOOL completedWithNoError, NSError *error, NSString *classNameOfUpdatedDataAsString, id updatedData) {
                                                      
            if (completedWithNoError) {
                responsedString = [[NSString alloc] initWithFormat:@"%@", @""];
                NSLog(@"responseData : %@", responsedString);
                self.labelResult.text = responsedString;
                alertView = [[UIAlertView alloc] initWithTitle:@"test"
                                                       message:responsedString
                                                      delegate:nil
                                             cancelButtonTitle:@"ok"
                                             otherButtonTitles:nil];
                [alertView show];
                
            } else {
                
                switch (error.code) {
                    case ErrorCodeResponsedNULLData:
                        alertView = [[UIAlertView alloc] initWithTitle:@"test"
                                                               message:@"返回值为空"
                                                              delegate:nil
                                                     cancelButtonTitle:@"ok"
                                                     otherButtonTitles:nil];
                        [alertView show];
                        break;
                        
                    case ErrorCodeNoCurrentUserInfo:
                        alertView = [[UIAlertView alloc] initWithTitle:@"test"
                                                               message:@"未正确登录！请登录后再进行此项操作"
                                                              delegate:nil
                                                     cancelButtonTitle:@"ok"
                                                     otherButtonTitles:nil];
                        [alertView show];
                        break;
                        
                    default:
                        break;
                }
            }
        }];
    }
    
//    if([self.currentSelectedOperation isEqualToString:@"上传文件"]) {
//
//        NSMutableArray *imageList = [NSMutableArray array];
//
//        ///以下代码读取文件, 测试用
//        NSError *testError = nil;
//
//        NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
//        NSString *cachedFilePath = [documentDirectories firstObject];
//
//        NSString *fileName = @"iOSTest11.jpg";
//
//        NSString *fileFullName = [NSString stringWithFormat:@"%@/%@", @"/Users/jingweiwu/Downloads/", fileName];
//
//        if ([[NSFileManager defaultManager] fileExistsAtPath:fileFullName]) {
//            [imageList addObject:[UIImage imageWithContentsOfFile:fileFullName]];
//        }
//
//        for (int i = 0; i<1; i++) {
//            fileName = @"iOSTest10.jpg";
//
//            fileFullName = [NSString stringWithFormat:@"%@/%@", @"/Users/jingweiwu/Downloads/", fileName];
//
//            [imageList addObject:[UIImage imageWithContentsOfFile:fileFullName]];
//
//            imageList = imageList;
//        }
//        ///读取文件代码到此为止
//
//        NSString *randomKey = nil;
//        if (self.dataManager.maintenanceTasks.count >0) {
//            randomKey = [self.dataManager.maintenanceTasks allKeys][0];
//        }
//
//
//        NSDictionary *imageDic = [NSDictionary dictionaryWithObject:[UIImage imageWithContentsOfFile:fileFullName]
//                                                             forKey:[fileFullName lastPathComponent]];
//        
//        [self.dataManager uploadImageWithImages:imageDic
//
//         progressIndicator:^(NSProgress *transmissionProgress) {
//             NSLog(@"%lld / %lld", transmissionProgress.completedUnitCount, transmissionProgress.totalUnitCount);
//             NSLog(@"%4f", transmissionProgress.fractionCompleted);
//         }
//         
//         completionHandler:^(BOOL completedWithNoError, NSError *error, NSString *classNameOfReceivedDataAsString, id ReceivedData) {
//             // do something
//         }];
//    }
//    
//    
//    if([self.currentSelectedOperation isEqualToString:@"下载指定文件"]) {
//        NSArray *fileLocationsOnServer = @[@"E:\\FTP\\MaintenanceSystem\\UpLoad\\iOSTest01.20160320211807.png"];
//        
//        NSString *randomKey = nil;
//        if (self.dataManager.maintenanceTasks.count >0) {
//            randomKey = [self.dataManager.maintenanceTasks allKeys][0];
//        }
//        
//        [self.dataManager downloadImageWithImageLocations:fileLocationsOnServer
//         
//         progressIndicator:^(NSProgress *transmissionProgress) {
//             NSLog(@"%lld / %lld", transmissionProgress.completedUnitCount, transmissionProgress.totalUnitCount);
//             NSLog(@"%4f", transmissionProgress.fractionCompleted);
//             
//         } completionHandler:^(BOOL completedWithNoError, NSError *error, NSString *classNameOfReceivedDataAsString, id ReceivedData) {
//             // do something
//         }];
//    }
    
    
    if([self.currentSelectedOperation isEqualToString:@"保存文件"]) {
        
        NSMutableDictionary *imageList = [NSMutableDictionary dictionary];
        NSString *fileName = @"iOSTest10.jpg";
        NSString *fileFullName = [NSString stringWithFormat:@"%@/%@", @"/Users/jingweiwu/Downloads/", fileName];
        NSString *fileKey = nil;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:fileFullName]) {
            fileKey = [[fileName componentsSeparatedByString:@"."]objectAtIndex:0];
            
            [imageList addEntriesFromDictionary:[NSDictionary dictionaryWithObject:[UIImage imageWithContentsOfFile:fileFullName] forKey:fileKey]];
        }

        fileName = @"iOSTest12.jpg";
        fileFullName = [NSString stringWithFormat:@"%@/%@", @"/Users/jingweiwu/Downloads/", fileName];
            
        if ([[NSFileManager defaultManager] fileExistsAtPath:fileFullName]) {
            fileKey = [[fileName componentsSeparatedByString:@"."]objectAtIndex:0];
            [imageList addEntriesFromDictionary:[NSDictionary dictionaryWithObject:[UIImage imageWithContentsOfFile:fileFullName] forKey:fileKey]];
        }
        
        imageList = imageList;

        ///读取文件代码到此为止
        
        NSString *randomKey = nil;
        if (self.dataManager.maintenanceTasks.count >0) {
            randomKey = [self.dataManager.maintenanceTasks allKeys][0];
        }
        
        [self.dataManager storeImageOfMaintenanceTaskWithTaskID:nil images:imageList
         
         uploadProgressIndicator:^(NSProgress *transmissionProgress) {
             NSLog(@"%lld / %lld", transmissionProgress.completedUnitCount, transmissionProgress.totalUnitCount);
             NSLog(@"%4f", transmissionProgress.fractionCompleted);
             
         } completionHandler:^(BOOL completedWithNoError, NSError *error, NSString *classNameOfDataAsString, id data) {
             data = data;
         }];
    }
    
    
    if([self.currentSelectedOperation isEqualToString:@"获取文件"]) {
        NSArray *fileLocationsOnServer = @[@"E:\\FTP\\MaintenanceSystem\\UpLoad\\iOSTest01.20160320211807.png",
                                           @"E:\\FTP\\MaintenanceSystem\\UpLoad\\iOSTest11.jpg.20160323162013.png",];
        
        NSMutableArray<WISFileInfo *> *filesInfo = [NSMutableArray array];
        NSMutableDictionary<NSString *, WISFileInfo *> *imagesInfo = [NSMutableDictionary dictionary];
        
        for (NSString *url in fileLocationsOnServer) {
            [filesInfo addObject:[WISDataManager produceFileInfoWithFileRemoteURL:url]];
        }
        
        for (WISFileInfo *info in filesInfo) {
            NSDictionary *dic = [NSDictionary dictionaryWithObject:info forKey:info.fileName];
            [imagesInfo addEntriesFromDictionary:dic];
        }
        
        NSString *randomKey = nil;
        if (self.dataManager.maintenanceTasks.count >0) {
            randomKey = [self.dataManager.maintenanceTasks allKeys][0];
        }
        
        [self.dataManager obtainImageOfMaintenanceTaskWithTaskID:nil imagesInfo:imagesInfo
         downloadProgressIndicator:^(NSProgress *transmissionProgress) {
           NSLog(@"%lld / %lld", transmissionProgress.completedUnitCount, transmissionProgress.totalUnitCount);

           
         } completionHandler:^(BOOL completedWithNoError, NSError *error, NSString *classNameOfDataAsString, id data) {
           data = data;
         }];
    }
    
    
    
    
    if([self.currentSelectedOperation isEqualToString:@"清除缓存"]) {
        [self.dataManager clearCacheOfImages];
    }
    
    if([self.currentSelectedOperation isEqualToString:@"打卡"]) {
        [self.dataManager updateCurrentClockStatusWithCompletionHandler:^(BOOL completedWithNoError, NSError *error, NSString *classNameOfDataAsString, id data) {
            if (completedWithNoError) {
                NSLog(@"获得当前状态为 %ld", [(NSString *)data integerValue]);
            }
        }];

    }
    
    if([self.currentSelectedOperation isEqualToString:@"获得打卡状态"]) {
        [self.dataManager submitClockActionWithCompletionHandler:^(BOOL completedWithNoError, NSError *error, NSString *classNameOfDataAsString, id data) {
            if (completedWithNoError) {
                NSLog(@"打卡, 获得当前状态为 %ld", [(NSString *)data integerValue]);
            }
        }];
    }
    
    if([self.currentSelectedOperation isEqualToString:@"获得打卡记录"]) {
       [self.dataManager updateClockRecordsWithStartDate:[NSDate date] endDate:[NSDate date] completionHandler:^(BOOL completedWithNoError, NSError *error, NSString *classNameOfDataAsString, id data) {
           if (completedWithNoError) {
               
           }
       }];
    }
    
    if([self.currentSelectedOperation isEqualToString:@"测试WorkShift"]) {
        [self.dataManager updateWorkShiftsWithStartDate:[NSDate date] recordNumber:30 completionHandler:^(BOOL completedWithNoError, NSError *error, NSString *classNameOfDataAsString, id data) {
            if (completedWithNoError) {
                NSArray *shifts = (NSArray *)data;
                shifts = shifts;
            }
        }];
    }
    
    if([self.currentSelectedOperation isEqualToString:@"更新当前用户详细信息"]) {
        WISUser *newUser = [[self.dataManager currentUser] copy];
        newUser.urgentPhoneNumber = @"112";
        [self.dataManager submitUserDetailInfoWithNewInfo:newUser completionHandler:^(BOOL completedWithNoError, NSError *error, NSString *classNameOfDataAsString, id data) {
            if (completedWithNoError) {
                WISUser *user = data;
                user = user;
            }
        }];
    }
    
    if([self.currentSelectedOperation isEqualToString:@"获取当前用户详细信息"]) {
        [self.dataManager updateCurrentUserDetailInformationWithCompletionHandler:^(BOOL completedWithNoError, NSError *error, NSString *classNameOfDataAsString, id data) {
            if (completedWithNoError) {
                WISUser *user = data;
                user = user;
            }
        }];
    }
    
    if([self.currentSelectedOperation isEqualToString:@"获取考勤信息"]) {
        [self.dataManager updateAttendanceRecordsWithDate:[NSDate date] completionHandler:^(BOOL completedWithNoError, NSError *error, NSString *classNameOfDataAsString, id data) {
            if (completedWithNoError) {
                NSArray<WISAttendanceRecord *> *attendances = data;
                data = data;
            }
        }];
    }
    
    
    if([self.currentSelectedOperation isEqualToString:@"测试提交命令的参数生成"]) {
//        NSDictionary *operationParams = nil;
//        
//        NSMutableArray*participants = [NSMutableArray array];
//        
//        WISUser *pal01 = [[WISUser alloc]initWithUserName:@"pal01" name:@"pal01Name" telephoneNumber:@"111" cellPhoneNumber:@"" roleCode:@"3" roleName:@"ww" andImagesInfo:nil];
//        WISUser *pal02 = [[WISUser alloc]initWithUserName:@"pal02" name:@"pal02Name" telephoneNumber:@"222" cellPhoneNumber:@"" roleCode:@"4" roleName:@"w4w" andImagesInfo:nil];
//        
//        [participants addObject:pal01];
//        [participants addObject:pal02];
//        
//        NSMutableDictionary *imagesInfo = [NSMutableDictionary dictionary];
//        NSMutableDictionary *taskImagesInfo = [NSMutableDictionary dictionary];
//        WISFileInfo *file01 = [[WISFileInfo alloc]initWithFileName:@"file01" fileType:@"png" fileRemoteLocation:@"location01" andFileOnDeviceLocation:@"deviceLocation01"];
//        WISFileInfo *file02 = [[WISFileInfo alloc]initWithFileName:@"file02" fileType:@"png" fileRemoteLocation:@"location02" andFileOnDeviceLocation:@"deviceLocation02"];
//        WISFileInfo *file03 = [[WISFileInfo alloc]initWithFileName:@"file03" fileType:@"png" fileRemoteLocation:@"location03" andFileOnDeviceLocation:@"deviceLocation03"];
//        [imagesInfo addEntriesFromDictionary:[NSDictionary dictionaryWithObject:file01 forKey:file01.fileName]];
//        [imagesInfo addEntriesFromDictionary:[NSDictionary dictionaryWithObject:file02 forKey:file02.fileName]];
//        
//        [taskImagesInfo addEntriesFromDictionary:[NSDictionary dictionaryWithObject:file03 forKey:file03.fileName]];
//        
//        operationParams = [self.dataManager produceMaintenanceTaskOperationParameterWithUserName:self.dataManager.currentUser.userName
//                                                                             networkRequestToken:self.dataManager.networkRequestToken
//                                                                                          taskID:@""
//                                                                                          remark:@"remark"
//                                                                                   operationType:SubmitApply
//                                                                                taskReceiverName:@"receiverName"
//                                                                              applicationContent:@"applicationContent"
//                                                                                processSegmentID:1
//                                                                            applicationImageInfo:imagesInfo
//                                                              maintenancePlanEstimatedEndingTime:nil
//                                                                      maintenancePlanDescription:@"description"
//                                                                     maintenancePlanParticipants:participants
//                                                                                   taskImageInfo:taskImagesInfo
//                                                                                   andTaskRating:[[WISMaintenanceTaskRating alloc]init]];
//        
//        operationParams = operationParams;
//        
//        NSError *err;
//        
//        NSData *operationParamsAsData = [NSJSONSerialization dataWithJSONObject:operationParams options:NSJSONWritingPrettyPrinted error:&err];
//        NSString *operationParamsAsString = [[NSString alloc]initWithData:operationParamsAsData encoding:NSUTF8StringEncoding];
//        
//        operationParamsAsString = operationParamsAsString;
    }
    
}








- (NSString *)receivedDataInString: (NSNotification *) sender {
//    [[NSNotificationCenter defaultCenter] removeObserver:self
//                                                    name:WISSystemSignInResponsedNotification
//                                                  object:nil];
//    NSLog(@"responseData : %@", sender);
//    
//    NSString *data = (NSString*)sender.object;
//    
//    
//    self.labelResult.text = data;
//    
//    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"test"
//                                                        message:data
//                                                       delegate:nil
//                                              cancelButtonTitle:@"ok"
//                                              otherButtonTitles:nil];
//    [alertView show];
      return nil;
}

//- (void)networkService:(id)sender DidSignInAndResponsedWithData:(NSData *)responsedData {
//    NSString *responsedString = [[NSString alloc] initWithData:responsedData
//                                                      encoding:NSUTF8StringEncoding];
//    
//    NSLog(@"responseData : %@", responsedString);
//    
//         self.labelResult.text = responsedString;
//     
//         UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"test"
//                                                             message:responsedString
//                                                            delegate:nil
//                                                   cancelButtonTitle:@"ok"
//                                                   otherButtonTitles:nil];
//         [alertView show];
//}

-(void) signInSucceeded {
    
}

- (void) signInSucceededwithResponsedData:(NSData *)responsedData {
//    NSString *responsedString = [[NSString alloc] initWithData:responsedData
//                                                      encoding:NSUTF8StringEncoding];
//    
//    NSLog(@"responseData : %@", responsedString);
//    
//    self.labelResult.text = responsedString;
//    
//    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"test"
//                                                        message:responsedString
//                                                       delegate:nil
//                                              cancelButtonTitle:@"ok"
//                                              otherButtonTitles:nil];
//    [alertView show];

}

- (void) signInFailedWithReason:(SignInResult)reason andResponsedData:(NSData *)responsedData {
    
//    UIAlertView *alertView;
//    switch (reason) {
//        case UserNotExist:
//            alertView = [[UIAlertView alloc] initWithTitle:@"test"
//                                                   message:@"用户不存在"
//                                                  delegate:nil
//                                         cancelButtonTitle:@"ok"
//                                         otherButtonTitles:nil];
//            [alertView show];
//            break;
//            
//        case WrongPassword:
//            alertView = [[UIAlertView alloc] initWithTitle:@"test"
//                                                   message:@"密码错误"
//                                                  delegate:nil
//                                         cancelButtonTitle:@"ok"
//                                         otherButtonTitles:nil];
//            [alertView show];
//            break;
//            
//        default:
//            break;
//    }
}

-(void) updateMaintenanceTasksBriefInfoSucceedwithResponsedData:(NSData *)responsedData {
//    NSString *responsedString = [[NSString alloc] initWithData:responsedData
//                                                      encoding:NSUTF8StringEncoding];
//    
//    NSLog(@"responseData : %@", responsedString);
//    
//    self.labelResult.text = responsedString;
//    
//    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"test"
//                                                        message:responsedString
//                                                       delegate:nil
//                                              cancelButtonTitle:@"ok"
//                                              otherButtonTitles:nil];
//    [alertView show];
}




- (void) notificationCenterTest:(NSNotification *)responsed {
    WISDataManager *dataManagerTest = responsed.object;
    NSString *responsedString = [[NSString alloc] initWithFormat:@"%@ %@", dataManagerTest.currentUser.userName, dataManagerTest.currentUser.fullName];
    NSLog(@"responseData : %@", responsedString);
    self.labelResult.text = responsedString;
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"test from notification"
                                           message:responsedString
                                          delegate:nil
                                 cancelButtonTitle:@"ok"
                                 otherButtonTitles:nil];
    [alertView show];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:WISSystemSignInSucceededNotification
                                                  object:nil];
}





- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
- (IBAction)backgroundTapped:(id)sender {
    [self.view endEditing:YES];
}

- (void) networkStatusChangedTo:(NSInteger)status {
    switch ((WISNetworkReachabilityStatus)status) {
        case WISNetworkReachabilityStatusNotReachable:
            self.labelNetworkingStatus.text = @"Not Reachable";
            break;
            
        case WISNetworkReachabilityStatusReachableViaWWAN:
            self.labelNetworkingStatus.text = @"4G";
            break;
            
        case WISNetworkReachabilityStatusReachableViaWiFi:
            self.labelNetworkingStatus.text = @"WiFi";
            break;
            
        case WISNetworkReachabilityStatusUnknown:
        default:
            self.labelNetworkingStatus.text = @"Unknown";
            break;
    }
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
 
 
 /Users/jingweiwu/Documents/XCode Document/Projects/WISConnect/WISConnect/WISViewController.m:36:49: Assigning to 'id<MaintenanceTaskOpDelegate> _Nullable' from incompatible type 'WISViewController *const __strong'
 
 
 
*/

@end
