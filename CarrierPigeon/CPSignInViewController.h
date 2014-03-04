//
//  CPSignInViewController.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/2/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//
//  Sources:
//  http://www.amazon.com/Mastering-The-XMPP-Framework-Applications-ebook/dp/B00HS5X6WE
//  https://developer.apple.com/library/ios/samplecode/GenericKeychain/Listings/Classes_KeychainItemWrapper_h.html

#import <UIKit/UIKit.h>
#import "XMPPStream.h"
#import "XMPPRoster.h"

@class CPSignInViewController;

@protocol CPSignInViewControllerDelegate <NSObject>
- (void)CPSignInViewControllerDidStoreCredentials:(CPSignInViewController *)sender;
@end



@interface CPSignInViewController : UIViewController

@property (nonatomic, strong) id<CPSignInViewControllerDelegate> delegate;
@property (nonatomic, strong) XMPPStream *xmppStream;
@property (nonatomic, strong) XMPPRoster *xmppRoster;
@property (nonatomic) BOOL autoLoginHasBegun;
@property (nonatomic) BOOL userWantsToLogOut;

@end
