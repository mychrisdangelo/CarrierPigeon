//
//  CPContactsTableViewController.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/2/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//
//  Sources:
//  Some Images in the storybarod come free frome: http://www.pixellove.com
//  http://stackoverflow.com/questions/4471289/how-to-filter-nsfetchedresultscontroller-coredata-with-uisearchdisplaycontroll

#import "CPContactsTableViewController.h"
#import "DDLog.h"
#import <CoreData/CoreData.h>
#import "CPAppDelegate.h"
#import "XMPPUserCoreDataStorageObject.h"
#import "CPAppDelegate.h"
#import "CPMessagesViewController.h"

#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

@interface CPContactsTableViewController () <NSFetchedResultsControllerDelegate, UISearchDisplayDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSFetchedResultsController *searchFetchedResultsController;

@end

@implementation CPContactsTableViewController

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize searchFetchedResultsController = _searchFetchedResultsController;

- (NSFetchedResultsController *)newFetchedResultsControllerWithSearch:(NSString *)searchString
{
    CPAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *moc = [appDelegate managedObjectContext_roster];
    NSPredicate *filterPredicate;
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject"
                                              inManagedObjectContext:moc];
    
    NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"sectionNum" ascending:YES];
    NSSortDescriptor *sd2 = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];
    
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sd1, sd2, nil];
    
    NSMutableArray *predicateArray = [NSMutableArray array];
    if (searchString.length) {
        // your search predicate(s) are added to this array
        [predicateArray addObject:[NSPredicate predicateWithFormat:@"displayName CONTAINS[cd] %@", searchString]];
        // finally add the filter predicate for this view
        if (filterPredicate) {
            filterPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:filterPredicate, [NSCompoundPredicate orPredicateWithSubpredicates:predicateArray], nil]];
        } else {
            filterPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:predicateArray];
        }
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setPredicate:filterPredicate];
    [fetchRequest setEntity:entity];
    [fetchRequest setSortDescriptors:sortDescriptors];
    [fetchRequest setFetchBatchSize:10];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:moc
                                                                      sectionNameKeyPath:@"sectionNum"
                                                                               cacheName:nil];
    
    
    [_fetchedResultsController setDelegate:self];
    
    
    NSError *error = nil;
    if (![_fetchedResultsController performFetch:&error])
    {
        DDLogError(@"Error performing fetch: %@", error);
    }
	
	return _fetchedResultsController;
}

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    _fetchedResultsController = [self newFetchedResultsControllerWithSearch:nil];
    return _fetchedResultsController;
}

- (NSFetchedResultsController *)searchFetchedResultsController
{
    if (_searchFetchedResultsController != nil) {
        return _searchFetchedResultsController;
    }
    
    _searchFetchedResultsController = [self newFetchedResultsControllerWithSearch:self.searchDisplayController.searchBar.text];
    return _searchFetchedResultsController;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowAddFriendController"]) {
        if ([segue.destinationViewController isMemberOfClass:[CPAddFriendViewController class]]) {
            CPAddFriendViewController *cpadfvc = (CPAddFriendViewController *)segue.destinationViewController;
            cpadfvc.delegate = self;
        }
    }
    
    if ([segue.identifier isEqualToString:@"ShowContactMessages"]) {
        if ([segue.destinationViewController isMemberOfClass:[CPMessagesViewController class]]) {
            CPMessagesViewController *cpmtvc = (CPMessagesViewController *)segue.destinationViewController;
            NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
            XMPPUserCoreDataStorageObject *user = [self.fetchedResultsController objectAtIndexPath:indexPath];
            cpmtvc.user = user;
            cpmtvc.xmppStream = self.xmppStream;
        }
    }
}

- (NSFetchedResultsController *)fetchedResultsControllerForTableView:(UITableView *)tableView
{
    return tableView == self.tableView ? self.fetchedResultsController : self.searchFetchedResultsController;
}

- (void)fetchedResultsController:(NSFetchedResultsController *)fetchedResultsController configureCell:(UITableViewCell *)theCell atIndexPath:(NSIndexPath *)theIndexPath
{
    XMPPUserCoreDataStorageObject *user = [fetchedResultsController objectAtIndexPath:theIndexPath];
	
	theCell.textLabel.text = user.displayName;
	[self configurePhotoForCell:theCell user:user];
}

#pragma mark - CPAddFriendViewControllerDelegate

- (void)CPAddFriendViewControllerDidFinishAddingFriend:(CPAddFriendViewController *)sender withUserName:(NSString *)userName
{
    [self dismissViewControllerAnimated:YES completion:^{
        NSString *jidString = [NSString stringWithFormat:@"%@@%@", userName, kXMPPServer];
        [self.xmppRoster addUser:[XMPPJID jidWithString:jidString] withNickname:userName];
        [self.xmppRoster subscribePresenceToUser:[XMPPJID jidWithString:jidString]];
    }];
}

- (void)CPAddFriendViewControllerDidCancel:(CPAddFriendViewController *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[[self fetchedResultsControllerForTableView:tableView] sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    NSFetchedResultsController *fetchController = [self fetchedResultsControllerForTableView:tableView];
    NSArray *sections = fetchController.sections;
    if(sections.count > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
        numberOfRows = [sectionInfo numberOfObjects];
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"ContactsCell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:CellIdentifier];
	}
	
    [self fetchedResultsController:[self fetchedResultsControllerForTableView:tableView] configureCell:cell atIndexPath:indexPath];	
	return cell;
}

- (void)configurePhotoForCell:(UITableViewCell *)cell user:(XMPPUserCoreDataStorageObject *)user
{
	// Our xmppRosterStorage will cache photos as they arrive from the xmppvCardAvatarModule.
	// We only need to ask the avatar module for a photo, if the roster doesn't have it.
	
	if (user.photo != nil)
	{
		cell.imageView.image = user.photo;
	}
	else
	{
        CPAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
		NSData *photoData = [appDelegate.xmppvCardAvatarModule photoDataForJID:user.jid];
        
		if (photoData != nil)
			cell.imageView.image = [UIImage imageWithData:photoData];
		else
			cell.imageView.image = [UIImage imageNamed:@"defaultPerson"];
	}
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSInteger)scope
{
    // update the filter, in this case just blow away the FRC and let lazy evaluation create another with the relevant search info
    self.searchFetchedResultsController.delegate = nil;
    self.searchFetchedResultsController = nil;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

#pragma mark - UISearchDisplayDelegate

- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView;
{
    // search is done so get rid of the search FRC and reclaim memory
    self.searchFetchedResultsController.delegate = nil;
    self.searchFetchedResultsController = nil;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString
                               scope:[self.searchDisplayController.searchBar selectedScopeButtonIndex]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text]
                               scope:[self.searchDisplayController.searchBar selectedScopeButtonIndex]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    UITableView *tableView = controller == self.fetchedResultsController ? self.tableView : self.searchDisplayController.searchResultsTableView;
    [tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    UITableView *tableView = controller == self.fetchedResultsController ? self.tableView : self.searchDisplayController.searchResultsTableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)theIndexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = controller == self.fetchedResultsController ? self.tableView : self.searchDisplayController.searchResultsTableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:theIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeUpdate:
            [self fetchedResultsController:controller configureCell:[tableView cellForRowAtIndexPath:theIndexPath] atIndexPath:theIndexPath];
            break;
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:theIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    UITableView *tableView = controller == self.fetchedResultsController ? self.tableView : self.searchDisplayController.searchResultsTableView;
    [tableView endUpdates];
}


@end
