//
//  CPAddFriendViewController.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/2/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CPAddFriendViewController;

@protocol CPAddFriendViewControllerDelegate <NSObject>
- (void)CPAddFriendViewControllerDidFinishAddingFriend:(CPAddFriendViewController *)sender withUserName:(NSString *)userName;
- (void)CPAddFriendViewControllerDidCancel:(CPAddFriendViewController *)sender;
@end

@interface CPAddFriendViewController : UIViewController

@property (nonatomic, weak) id<CPAddFriendViewControllerDelegate> delegate;

@end
