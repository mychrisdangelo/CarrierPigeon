//
//  CPMessagesViewController.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/3/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XMPPUserCoreDataStorageObject.h"
#import "XMPPStream.h"

@interface CPMessagesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) XMPPUserCoreDataStorageObject *user;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) XMPPStream *xmppStream;

@end
