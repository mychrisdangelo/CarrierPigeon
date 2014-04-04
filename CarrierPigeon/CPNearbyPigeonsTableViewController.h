//
//  CPNearbyPigeonsTableViewController.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/4/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CPNearbyPigeonsTableViewController : UITableViewController

@property (nonatomic) NSArray *nearbyPigeons;
@property (nonatomic) NSSet *nearbyPigeonsConnected;

@end
