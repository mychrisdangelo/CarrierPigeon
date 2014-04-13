//
//  CPEditProfileTableViewController.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/6/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "XMPPStream.h"
#import "XMPPRoster.h"

@interface CPEditProfileTableViewController : UITableViewController

@property (nonatomic, strong) User *user;
@property (nonatomic, strong) XMPPStream *xmppStream;
@property (nonatomic, strong) XMPPRoster *xmppRoster;

@end
