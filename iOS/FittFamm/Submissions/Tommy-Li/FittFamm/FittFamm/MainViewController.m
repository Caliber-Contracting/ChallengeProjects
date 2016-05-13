//
//  MainViewController.m
//  FittFamm
//
//  Created by 雪竜 on 16/5/12.
//  Copyright © 2016年 雪竜. All rights reserved.
//

#include "MainViewController.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	_HK_Store = [[HKHealthStore alloc] init];
	[self requestAccessToHealthKit];
	[self checkTwitterInfo];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) writeHeartRate
{
	if (!_isHKStoreAccessible) {
		[self requestAccessToHealthKit];
		return;
	}
	
	double UserHeartRate = [_TextField_HeartrateEntry.text doubleValue];
	
	HKUnit *BPMUnit = [[HKUnit countUnit] unitDividedByUnit:[HKUnit minuteUnit]];
	HKQuantity *BPMQuantity = [HKQuantity quantityWithUnit:BPMUnit doubleValue:UserHeartRate];
	HKQuantityType *BPMType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
	NSDate *now = [NSDate date];
	
	HKQuantitySample *BPMEntrySample = [HKQuantitySample quantitySampleWithType:BPMType quantity:BPMQuantity startDate:now endDate:now];
	
	[_HK_Store saveObject:BPMEntrySample withCompletion:^(BOOL success, NSError * _Nullable error) {
		
		if (success)
		{
			[self updateStatusOnBackground:@"Write sample to HealthKit was successful. Attempting to post tweet. "];
			[self postTweetWithDouble:UserHeartRate];
		}
		else
		{
			NSString *formattedErr = @"Write sample to HealthKit failed: ";
			[self updateStatusOnBackground:[formattedErr stringByAppendingString:error.localizedDescription]];
		}
	}];
	
}

- (void)postTweetWithDouble:(double) value
{
	if (!_isACArrayReady) {
		[self checkTwitterInfo];
		return;
	}
	
	ACAccount *defaultAC = _AC_AccountArray[0];
	NSDictionary* message = @{@"status": [@"My current heart rate: " stringByAppendingString:[NSString stringWithFormat:@"%g", value]]};
	NSURL *PostTweetAddr = [NSURL URLWithString:__TWITTER_V1_1_REST_UPDATE__];
	
	SLRequest *PostTweetReq = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:PostTweetAddr parameters:message];
	
	PostTweetReq.account = defaultAC;
	
	[PostTweetReq performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
		if (error) {
			NSString *formattedErr = @"Post tweet failed: ";
			[self updateStatusOnBackground:[formattedErr stringByAppendingString:error.localizedDescription]];
		}
		else
		{
			NSLog(@"Twitter HTTP response: %li", (long)[urlResponse statusCode]);
			if ([urlResponse statusCode] == 200) {
				[self updateStatusOnBackground:@"Post tweet successful. "];
			}
			else
			{
				[self updateStatusOnBackground:@"Post tweet met an exception. "];
			}
		}
	}];
}

- (void)requestAccessToHealthKit {
	[_Label_Status setText:@"Requesting access to HealthKit"];
	
	if ([HKHealthStore isHealthDataAvailable] == false) {
		[_Label_Status setText:@"HealthKit is not available on this device"];
		[self disableSelectables];
		_isHKStoreAccessible = false;
	}
	
	NSArray *writeTypes = @[[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate]];
	
	[_HK_Store requestAuthorizationToShareTypes:[NSSet setWithArray:writeTypes] readTypes:[NSSet setWithArray:writeTypes] completion:^(BOOL success, NSError * _Nullable error) {
		_isHKStoreAccessible = success;
		
		if (success)
		{
			[self updateStatusOnBackground:@"HealthKit is ready"];
			NSLog(@"HealthKit is ready");
		}
		else
		{
			[self updateStatusOnBackground:@"Please grant access to HealthKit in Settings. After that, tap \"Send\" to retry. "];
		}
	}];
	
}

- (void)checkTwitterInfo{
	
	ACAccountStore *acStore = [[ACAccountStore alloc] init];
	ACAccountType *acType = [acStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
	
	[acStore requestAccessToAccountsWithType:acType options:NULL completion:^(BOOL success, NSError *err)
	 {
		 _isACArrayReady = success;
		 
		 if (success)
		 {
			 _AC_AccountArray = [acStore accountsWithAccountType:acType];
			 if (_AC_AccountArray.count > 0)
			 {
				 [self updateStatusOnBackground:@"Twitter access is ready"];
				 NSLog(@"Twitter access is ready");
			 }
			 else
			 {
				 _isACArrayReady = false;
				 [self updateStatusOnBackground:@"Please add at least one Twitter account in Settings. After that, tap \"Send\" to retry. "];
			 }
		 }
		 else
		 {
			 [self updateStatusOnBackground:@"Please grant access to Twitter accounts in Settings. After that, tap \"Send\" to retry. "];
		 }
	 }
	 ];
	
}

- (IBAction)Action_Button_Send:(id)sender {
	[self writeHeartRate];
}

- (void)disableSelectables
{
	dispatch_async(dispatch_get_main_queue(), ^{
		_TextField_HeartrateEntry.enabled = false;
		_Button_Send.enabled = false;
	});
}

- (void)enableSelectables
{
	dispatch_async(dispatch_get_main_queue(), ^{
		_TextField_HeartrateEntry.enabled = true;
		_Button_Send.enabled = true;
	});
}

- (void)updateStatusOnBackground:(NSString*) message
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[_Label_Status setText:message];
	});
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
