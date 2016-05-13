//
//  MainViewController.h
//  FittFamm
//
//  Created by 雪竜 on 16/5/12.
//  Copyright © 2016年 雪竜. All rights reserved.
//

#include <UIKit/UIKit.h>
#include <HealthKit/HealthKit.h>
#include <Social/Social.h>
#include <Accounts/Accounts.h>

#define __TWITTER_V1_1_REST_UPDATE__ @"https://api.twitter.com/1.1/statuses/update.json"

@interface MainViewController : UIViewController

@property (weak, atomic) IBOutlet UITextField *TextField_HeartrateEntry;
@property (weak, atomic) IBOutlet UILabel *Label_Status;
@property (weak, atomic) IBOutlet UIButton *Button_Send;

@property (strong, atomic) HKHealthStore* HK_Store;

@property (strong, atomic) NSArray* AC_AccountArray;

@property BOOL isHKStoreAccessible;
@property BOOL isACArrayReady;

@end
