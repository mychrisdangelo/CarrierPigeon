//
//  CarrierPigeonAppDelegate.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 2/26/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CPAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
