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
#import "Contact+AddRemove.h"
#import "CPMessenger.h"
#import "CPSessionContainer.h"
#import "CPSettingsViewController.h"
#import "CPNetworkStatusAssistant.h"

#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

@interface CPContactsTableViewController () <NSFetchedResultsControllerDelegate, UISearchDisplayDelegate, CPSignInViewControllerPresenterDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSFetchedResultsController *searchFetchedResultsController;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) int servicesRequiringRefreshing;
@property (nonatomic, strong) CPSessionContainer *sessionContainer;

@end

@implementation CPContactsTableViewController

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize searchFetchedResultsController = _searchFetchedResultsController;


- (IBAction)forceOfflineButtonPressed:(UIBarButtonItem *)sender {
    [self.xmppStream disconnect];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.fetchedResultsController = nil;
    [self.tableView reloadData];
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext == nil) {
        _managedObjectContext = ((CPAppDelegate *)([[UIApplication sharedApplication] delegate])).managedObjectContext;
    }
    
    return _managedObjectContext;
}

- (NSFetchedResultsController *)newFetchedResultsControllerWithSearch:(NSString *)searchString
{
    NSManagedObjectContext *moc = self.managedObjectContext;
    NSPredicate *filterPredicate;
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Contact"
                                              inManagedObjectContext:moc];
    
    NSSortDescriptor *s = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];
    NSArray *sortDescriptors = @[s];
    
    NSString *myJID = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
    NSMutableArray *predicateArray = [NSMutableArray array];
    filterPredicate = [NSPredicate predicateWithFormat:@"contactOwnerJidStr = %@", myJID];
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
                                                                      sectionNameKeyPath:nil
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
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshContactsCache) forControlEvents:UIControlEventValueChanged];
    [self.refreshControl addTarget:self action:@selector(setupPeerToPeerSession) forControlEvents:UIControlEventValueChanged];
    [self.refreshControl addTarget:self action:@selector(sendUnsentMessages) forControlEvents:UIControlEventValueChanged];
    [self.refreshControl addTarget:self action:@selector(updateNetworkStatusIndicators) forControlEvents:UIControlEventValueChanged];
    
    if (self.showPadSignInNow) [self performSegueWithIdentifier:@"ShowSignInSegue" sender:self];
    
    [self setSettingsTabBarName];
    [self updateNetworkStatusIndicators];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateNetworkStatusIndicators) name:kNetworkStatusDidChangeNotification object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:kNetworkStatusDidChangeNotification];
}

- (void)updateNetworkStatusIndicators
{
    self.servicesRequiringRefreshing++;
    // UIColor *barTintColor = [CPNetworkStatusAssistant colorForNetworkStatus];
    // [self.navigationController.navigationBar setBarTintColor:barTintColor];
    // [self.view setNeedsDisplay]; // hack: setBarTintColor: wasn't always setting the color immediately
    [self endRefreshing];
}

- (void)setSettingsTabBarName
{
    NSString *myJID = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
    NSArray *parsedJID = [myJID componentsSeparatedByString: @"@"];
    NSString *username = [parsedJID objectAtIndex:0];
    for (UIViewController *eachViewController in self.tabBarController.viewControllers) {
        if ([eachViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navigationController = (UINavigationController *)eachViewController;
            UIViewController *settingsViewController = [navigationController topViewController];
            if ([settingsViewController isMemberOfClass:[CPSettingsViewController class]]) {
                [settingsViewController setTitle:username];
                return;
            }
        }
    }
}

//- (void)showSignInNowIfNecessary
//{
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
//        CPAppDelegate *delegate = (CPAppDelegate *)[[UIApplication sharedApplication] delegate];
//        if (![delegate userHasLoggedInPreviously]) {
//            [self performSegueWithIdentifier:@"ShowSignInSegue" sender:self];
//
//        } else {
//            [delegate connect];
//        }
//    } else {
//        // we're in the iPhone and launching Signin has been taken care of by CPAppDelegate
//    }
//
//}

- (void)endRefreshing
{
    if (--self.servicesRequiringRefreshing == 0) {
        [self.refreshControl endRefreshing];
    }
}

// TODO: this should happen whenever user goes online but for now it's manual
- (void)sendUnsentMessages
{
    self.servicesRequiringRefreshing++;
    
    [CPMessenger sendPendingMessagesWithStream:self.xmppStream];
    
    [self endRefreshing];
}

// TODO: this should happen whenever app turns on and should remain on for as long as possible. for now it's manual
- (void)setupPeerToPeerSession
{
    self.servicesRequiringRefreshing++;
    self.sessionContainer = [CPSessionContainer sharedInstance];
    [self endRefreshing];
}

// TODO: presently only an appending cache
- (void)refreshContactsCache
{
    self.servicesRequiringRefreshing++;
    
    CPAppDelegate *appDelegate = (CPAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext_roster];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPUserCoreDataStorageObject"];
    NSSortDescriptor *s = [[NSSortDescriptor alloc] initWithKey:@"jidStr" ascending:YES];
    [request setSortDescriptors:@[s]];
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    NSString *myJID = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
    
    for (XMPPUserCoreDataStorageObject *each in matches) {
        [Contact addRemoveContactFromXMPPUserCoreDataStorageObject:each forCurrentUser:myJID inManagedObjectContext:self.managedObjectContext removeContact:NO];
    }
    
    [self endRefreshing];
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
            Contact *contact = [self.fetchedResultsController objectAtIndexPath:indexPath];
            cpmtvc.contact = contact;
            cpmtvc.xmppStream = self.xmppStream;
        }
    }
    
    if ([segue.identifier isEqualToString:@"ShowSignInSegue"]) {
        if ([segue.destinationViewController isMemberOfClass:[CPSignInViewController class]]) {
            CPSignInViewController *cpsivc = (CPSignInViewController *)segue.destinationViewController;
            cpsivc.userWantsToLogOut = YES;
            cpsivc.presenterDelegate = self;
        }
    }
}

- (NSFetchedResultsController *)fetchedResultsControllerForTableView:(UITableView *)tableView
{
    return tableView == self.tableView ? self.fetchedResultsController : self.searchFetchedResultsController;
}

- (void)fetchedResultsController:(NSFetchedResultsController *)fetchedResultsController configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)theIndexPath
{
    Contact *contact = [fetchedResultsController objectAtIndexPath:theIndexPath];

	
	cell.textLabel.text = contact.displayName;
	[self configurePhotoForCell:cell contact:contact];
}

#pragma mark - CPSignInViewControllerPresenterDelegate

- (void)CPSignInViewControllerDidSignIn:(CPSignInViewController *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.tabBarController setSelectedIndex:0];
}

#pragma mark - CPAddFriendViewControllerDelegate

- (void)CPAddFriendViewControllerDidFinishAddingFriend:(CPAddFriendViewController *)sender withUserName:(NSString *)userName
{
    [self dismissViewControllerAnimated:YES completion:^{
        NSString *jidString = [NSString stringWithFormat:@"%@@%@", userName, kXMPPDomainName];
        //TODO: before calling addUser, check that the user exists
        //TODO: add a "pending" tag to the newly added contact, which would be removed when the
        // add friend request is accepted.
        // An alternative to this would be to create a separate list that shows all pending friend requests
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

- (void)configurePhotoForCell:(UITableViewCell *)cell contact:(Contact *)contact
{
	// Our xmppRosterStorage will cache photos as they arrive from the xmppvCardAvatarModule.
	// We only need to ask the avatar module for a photo, if the roster doesn't have it.
	
	if (contact.photo != nil)
	{
		cell.imageView.image = contact.photo;
	}
	else
	{
		NSData *photoData = contact.photo;
        cell.imageView.image = [UIImage imageWithData:photoData];
	}
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSInteger)scope
{
    // update the filter, in this case just blow away the FRC and let lazy evaluation create another with the relevant search info
    self.searchFetchedResultsController.delegate = nil;
    self.searchFetchedResultsController = nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id nc = [self.splitViewController.viewControllers lastObject];
    id mvc = [nc topViewController];
    if ([mvc isKindOfClass:[CPMessagesViewController class]]) {
        Contact *contact = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [mvc setContact:contact];
        [mvc setXmppStream:self.xmppStream];
    }
}

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
