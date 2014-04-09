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
#import "CPContactsTableViewCell.h"
#import "Chat.h"
#import "NSDate+Helper.h"
#import "TSMessage.h"
#import "TSMessageView.h"

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
@property (nonatomic, strong) NSString *myJID;

@end

@implementation CPContactsTableViewController

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize searchFetchedResultsController = _searchFetchedResultsController;

- (NSString *)myJID
{
    if (_myJID == nil) {
        _myJID = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
    }
    
    return _myJID;
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
    
    NSSortDescriptor *lastMessage = [[NSSortDescriptor alloc] initWithKey:@"lastMessageAuthoredOrReceived.timeStamp" ascending:NO];
    NSSortDescriptor *userNameAlpha = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];
    NSArray *sortDescriptors = @[lastMessage, userNameAlpha];
    
    NSMutableArray *predicateArray = [NSMutableArray array];
    filterPredicate = [NSPredicate predicateWithFormat:@"contactOwnerJidStr = %@", self.myJID];
    if (searchString.length) {
        // your search predicate(s) are added to this array
        [predicateArray addObject:[NSPredicate predicateWithFormat:@"displayName CONTAINS[cd] %@", searchString]];
        [predicateArray addObject:[NSPredicate predicateWithFormat:@"ANY messagesReceived.messageBody CONTAINS[cd] %@", searchString]];
        [predicateArray addObject:[NSPredicate predicateWithFormat:@"ANY messagesAuthored.messageBody CONTAINS[cd] %@", searchString]];
        
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
    self.refreshControl.backgroundColor = [CPNetworkStatusAssistant colorForNetworkStatusWithLightColor:NO];
    [self.refreshControl addTarget:self action:@selector(refreshContactsCache) forControlEvents:UIControlEventValueChanged];
    [self.refreshControl addTarget:self action:@selector(setupPeerToPeerSession) forControlEvents:UIControlEventValueChanged];
    [self.refreshControl addTarget:self action:@selector(sendUnsentMessages) forControlEvents:UIControlEventValueChanged];
    [self.refreshControl addTarget:self action:@selector(updateNetworkStatusIndicatorsInContactsView) forControlEvents:UIControlEventValueChanged];
    
    if (self.showPadSignInNow) [self performSegueWithIdentifier:@"ShowSignInSegue" sender:self];
    
    [self.xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self setSettingsTabBarName];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateNetworkStatusIndicatorsInContactsView) name:kNetworkStatusDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showBannerAlert:) name:kCurrentUserRecivingMessageInAConversationTheyAreNotViewingCurrentlyNotification object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:kNetworkStatusDidChangeNotification];
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:kCurrentUserRecivingMessageInAConversationTheyAreNotViewingCurrentlyNotification];
}

// TODO: For use in banner callback. Currently not used because knowledge of the current tableview is necessary to avoid potential crash
- (Contact *)getContactFromJID:(NSString *)jid
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Contact"];
    NSString *stringWithDomainName = [NSString stringWithFormat:@"%@@%@", jid, kXMPPDomainName];
    request.predicate = [NSPredicate predicateWithFormat:@"contactOwnerJidStr = %@ AND jidStr = %@", self.myJID, stringWithDomainName];
    
    NSError *error = nil;
    NSArray *matches = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if ([matches count] == 1) {
        return [matches lastObject];
    } else {
        return nil;
    }
}

- (void)showBannerAlert:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    UIViewController *vc = [self.navigationController visibleViewController];
    [TSMessage showNotificationInViewController:vc
                                          title:userInfo[@"body"]
                                       subtitle:userInfo[@"parsedDisplayName"]
                                          image:nil
                                           type:TSMessageNotificationTypeSuccess
                                       duration:3.0
                                       callback:NULL
                                    buttonTitle:nil
                                 buttonCallback:NULL
                                     atPosition:TSMessageNotificationPositionTop
                           canBeDismissedByUser:YES];
}

- (void)updateNetworkStatusIndicatorsInContactsView
{
    self.servicesRequiringRefreshing++;
    self.refreshControl.backgroundColor = [CPNetworkStatusAssistant colorForNetworkStatusWithLightColor:NO];
    [self endRefreshing];
}

- (void)setSettingsTabBarName
{
    NSArray *parsedJID = [self.myJID componentsSeparatedByString: @"@"];
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
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    for (XMPPUserCoreDataStorageObject *each in matches) {
        [Contact addRemoveContactFromXMPPUserCoreDataStorageObject:each forCurrentUser:self.myJID inManagedObjectContext:self.managedObjectContext removeContact:NO];
    }
    
    [self endRefreshing];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UITableView *)tableViewForCell:(UITableViewCell *)cell
{
    UIView *superView = cell.superview;
    while (superView != nil) {
            if([superView isKindOfClass:[UITableView class]]) {
                return (UITableView *)superView;
            }
            superView = superView.superview;
    }
    
    return nil;
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
            if ([sender isKindOfClass:[UITableViewCell class]]) {
                UITableViewCell *cell = (UITableViewCell *)sender;
                UITableView *tableView = nil;
                if ((tableView = [self tableViewForCell:cell])) {
                    NSIndexPath *indexPath = [tableView indexPathForCell:cell];
                    Contact *contact = [[self fetchedResultsControllerForTableView:tableView] objectAtIndexPath:indexPath];
                    cpmtvc.contact = contact;
                    cpmtvc.xmppStream = self.xmppStream;
                }
            }
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

- (void)fetchedResultsController:(NSFetchedResultsController *)fetchedResultsController configureCell:(CPContactsTableViewCell *)cell atIndexPath:(NSIndexPath *)theIndexPath
{
    Contact *contact = [fetchedResultsController objectAtIndexPath:theIndexPath];
	cell.authorLabel.text = [CPHelperFunctions parseOutHostIfInDisplayName:contact.displayName];
    
    NSString *messageLabelText;
    NSString *messageBody = [contact.lastMessageAuthoredOrReceived messageBody];
    if ([contact.lastMessageAuthoredOrReceived.authorOfMessage.jidStr isEqualToString:contact.jidStr]) {
        messageLabelText = messageBody;
    } else if (messageBody) {
        // there is a message body and it is not from the other person so it is from me
        messageLabelText = [NSString stringWithFormat:@"Me: %@", messageBody];
    }
    
    cell.messageBodyLabel.text = messageLabelText;
    NSDate *timeStamp = nil;
    if ((timeStamp = contact.lastMessageAuthoredOrReceived.timeStamp)) {
        // NSDate+Helper doesn't accept nil
        cell.dateLabel.text = [NSDate stringForDisplayFromDate:contact.lastMessageAuthoredOrReceived.timeStamp];
    } else {
        cell.dateLabel.text = @"";
    }

    
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*
     * Subtle point here: the cell identifier is pulled out from the tableview as defined in the storyboard.
     * tableView:cellForRowAtIndexPath: is called both for the standard table and the searchDisplayController created
     * table. In order to get the cells in the style we need we will always generate cells of the type from the storyboard.
     * http://stackoverflow.com/questions/10189243/custom-cellidentifier-is-null-when-using-search-display-controller
     */
    return self.tableView.rowHeight;
}

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
	
    /*
     * See note in tableView:heightForRowAtIndexPath: the same subtelty in choosing self.tableView here applies.
     */
	CPContactsTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[CPContactsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
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
        Contact *contact = [[self fetchedResultsControllerForTableView:tableView] objectAtIndexPath:indexPath];
        [mvc setContact:contact];
        [mvc setXmppStream:self.xmppStream];
    } else {
        // we are in iPhone
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [self performSegueWithIdentifier:@"ShowContactMessages" sender:cell];
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
            [self fetchedResultsController:controller configureCell:(CPContactsTableViewCell *)[tableView cellForRowAtIndexPath:theIndexPath] atIndexPath:theIndexPath];
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

#pragma mark - XMPPRosterDelegate

- (void)xmppRosterDidEndPopulating:(XMPPRoster *)sender
{
    [self refreshContactsCache];
}

@end
