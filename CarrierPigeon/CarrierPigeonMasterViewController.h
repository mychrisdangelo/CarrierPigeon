//
//  CarrierPigeonMasterViewController.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 2/26/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CarrierPigeonDetailViewController;

#import <CoreData/CoreData.h>

@interface CarrierPigeonMasterViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) CarrierPigeonDetailViewController *detailViewController;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
