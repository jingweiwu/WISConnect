//
//  WISViewController.h
//  WISConnect
//
//  Created by Jingwei Wu on 2/18/16.
//  Copyright © 2016 Jingwei Wu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WISDataManager.h"

@interface WISViewController : UIViewController <WISNetworkingDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>
@property (weak, nonatomic) IBOutlet UILabel *labelResult;
@property (weak, nonatomic) IBOutlet UILabel *labelNetworkingStatus;

@property (weak, nonatomic) IBOutlet UITextField *textField01;
@property (weak, nonatomic) IBOutlet UITextField *textField02;
@property (weak, nonatomic) IBOutlet UITextField *textField03;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;

@property (strong) NSArray *pickerArray;

@end
