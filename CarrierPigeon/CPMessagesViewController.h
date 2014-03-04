//
//  CPMessagesViewController.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/3/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PHFComposeBarView.h"
#import "XMPPUserCoreDataStorageObject.h"

@interface CPMessagesViewController : UIViewController <PHFComposeBarViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) XMPPUserCoreDataStorageObject *user;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
