//
//  CPMessagesTableViewController.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/3/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PHFComposeBarView.h"
#import "XMPPUserCoreDataStorageObject.h"

@interface CPMessagesTableViewController : UITableViewController <PHFComposeBarViewDelegate>

@property (nonatomic, strong) XMPPUserCoreDataStorageObject *user;

@end
