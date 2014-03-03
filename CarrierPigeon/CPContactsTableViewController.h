//
//  CPContactsTableViewController.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/2/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XMPPStream.h"

@interface CPContactsTableViewController : UITableViewController

@property (nonatomic, strong) XMPPStream *xmppStream;

@end
