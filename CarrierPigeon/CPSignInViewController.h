//
//  CPSignInViewController.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/2/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CPSignInViewControllerDelegate <NSObject>

- (void)credentialsStored;

@end



@interface CPSignInViewController : UIViewController

@property (nonatomic, strong) id<CPSignInViewControllerDelegate> delegate;

@end
