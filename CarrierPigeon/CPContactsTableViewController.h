//
//  CPContactsTableViewController.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/2/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XMPPStream.h"
#import "XMPPRoster.h"
#import "CPAddFriendViewController.h"

@interface CPContactsTableViewController : UITableViewController <CPAddFriendViewControllerDelegate>

@property (nonatomic, strong) XMPPStream *xmppStream;
@property (nonatomic, strong) XMPPRoster *xmppRoster;
@property (nonatomic) BOOL userNeedsToSignIn;

- (void)logoutAndShowSignInNow;

@end
