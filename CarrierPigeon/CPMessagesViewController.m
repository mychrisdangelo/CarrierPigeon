//
//  CPMessagesViewController.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/3/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//
//  Sources:
//  http://stackoverflow.com/questions/4471289/how-to-filter-nsfetchedresultscontroller-coredata-with-uisearchdisplaycontroll
//  Apple Documentation Sample: "MultipeerGroupChat"

#import "CPMessagesViewController.h"
#import "CPAppDelegate.h"
#import "Chat+Create.h"
#import "CPHelperFunctions.h"
#import "MessageView.h"
#import <PHFComposeBarView.h>
#import "CPMessenger.h"
#import "CPMessageDetailTableViewController.h"
#import "CPNetworkStatusAssistant.h"

@interface CPMessagesViewController () <UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate, PHFComposeBarViewDelegate, UISplitViewControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSString *myJid;
@property (weak, nonatomic) IBOutlet UIView *composeViewContainer;
@property (readonly, nonatomic) PHFComposeBarView *composeBarView;
@property (nonatomic, strong) UIColor *sendButtonColor;

@end

@implementation CPMessagesViewController

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize myJid = _myJid;
@synthesize composeBarView = _composeBarView;
@synthesize contact = _contact;

- (void)setSendButtonColor:(UIColor *)sendButtonColor
{
    if (sendButtonColor == _sendButtonColor) {
        return;
    }
    
    _sendButtonColor = sendButtonColor;
    [self.composeBarView setButtonTintColor:_sendButtonColor];
}

- (void)setContact:(Contact *)contact
{
    if (_contact != contact) {
        _contact = contact;
    }
    
    self.title = [CPHelperFunctions parseOutHostIfInDisplayName:_contact.displayName];
    if (self.view.window) {
        [self loadMessages];
    }
}

- (NSString *)myJid
{
    return _myJid = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext == nil) {
        _managedObjectContext = ((CPAppDelegate *)([[UIApplication sharedApplication] delegate])).managedObjectContext;
    }
    
    return _managedObjectContext;
}

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Chat" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSMutableArray *predicateArray = [NSMutableArray array];
    
    [predicateArray addObject:[NSPredicate predicateWithFormat:@"fromJID == %@ AND toJID == %@ AND chatOwner == %@ AND reallyFromJID == nil", self.contact.jidStr, self.myJid, self.myJid]];
    [predicateArray addObject:[NSPredicate predicateWithFormat:@"fromJID == %@ AND toJID == %@ AND chatOwner == %@ AND reallyFromJID == nil", self.myJid, self.contact.jidStr, self.myJid]];
    
    NSPredicate *filterPredicate = nil;
    if (filterPredicate) {
        filterPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:filterPredicate, [NSCompoundPredicate orPredicateWithSubpredicates:predicateArray], nil]];
    } else {
        filterPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:predicateArray];
    }
    [fetchRequest setPredicate:filterPredicate];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                managedObjectContext:self.managedObjectContext
                                                                                                  sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    _fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![_fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
    
    return _fetchedResultsController;
}

- (void)fetchedResultsController:(NSFetchedResultsController *)fetchedResultsController configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)theIndexPath
{
    Chat *chat = [fetchedResultsController objectAtIndexPath:theIndexPath];
    MessageView *messageView = (MessageView *)[cell viewWithTag:MESSAGE_VIEW_TAG];
    messageView.chat = chat;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)loadMessages
{
    self.fetchedResultsController = nil; // force reload
    [self.tableView reloadData];
    [self scrollToLastRowWithAnimation:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    if (self.contact) [self loadMessages];
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.composeViewContainer.frame.size.height, 0);
    [self.view addSubview:self.composeBarView];
    [self.composeViewContainer removeFromSuperview];
    [self updateNetworkStatusIndicatorsInMessagesView];
    self.splitViewController.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateNetworkStatusIndicatorsInMessagesView) name:kNetworkStatusDidChangeNotification object:nil];
}

- (void)updateNetworkStatusIndicatorsInMessagesView
{
    self.sendButtonColor = [CPNetworkStatusAssistant colorForNetworkStatusWithLightColor:NO];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:kNetworkStatusDidChangeNotification];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    CPAppDelegate *delegate = (CPAppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.conversationFromUserCurrentlyViewing = self.contact.jidStr;
    
    // Listen for will show/hide notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)scrollToLastRowWithAnimation:(BOOL)animated
{
    NSInteger numberOfRows = 0;
    NSArray *sections = self.fetchedResultsController.sections;
    if(sections.count > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:0];
        numberOfRows = [sectionInfo numberOfObjects];
    }
    
    if (numberOfRows != 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(numberOfRows - 1) inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:animated];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    CPAppDelegate *delegate = (CPAppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.conversationFromUserCurrentlyViewing = nil;
    
    // Stop listening for keyboard notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowMessageDetail"]) {
        if ([segue.destinationViewController isMemberOfClass:[CPMessageDetailTableViewController class]]) {
            CPMessageDetailTableViewController *mdtvc = (CPMessageDetailTableViewController *)segue.destinationViewController;
            NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
            mdtvc.chat = [self.fetchedResultsController objectAtIndexPath:indexPath];
        }
    }
}

- (PHFComposeBarView *)composeBarView {
    if (!_composeBarView) {
        CGRect frame = self.composeViewContainer.frame;
        _composeBarView = [[PHFComposeBarView alloc] initWithFrame:frame];
        [_composeBarView setMaxLinesCount:5];
        [_composeBarView setPlaceholder:@"Send a message"];
        // TODO: Add in image sending
        // [_composeBarView setUtilityButtonImage:[UIImage imageNamed:@"Camera"]];
        [_composeBarView setDelegate:self];
    }
    
    return _composeBarView;
}

#pragma mark - PHFComposeBarViewDelegate

- (void)composeBarView:(PHFComposeBarView *)composeBarView
   willChangeFromFrame:(CGRect)startFrame
               toFrame:(CGRect)endFrame
              duration:(NSTimeInterval)animationDuration
        animationCurve:(UIViewAnimationCurve)animationCurve
{
    // Animate up or down
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    CGFloat difference = endFrame.size.height - startFrame.size.height;
    
    UIEdgeInsets insets = self.tableView.contentInset;
    insets.bottom +=difference;
    self.tableView.contentInset = insets;
    self.tableView.scrollIndicatorInsets = insets;
    [self scrollToLastRowWithAnimation:YES];
    
    [UIView commitAnimations];
    

}

- (void)composeBarView:(PHFComposeBarView *)composeBarView
    didChangeFromFrame:(CGRect)startFrame
               toFrame:(CGRect)endFrame
{
    
}

- (void)composeBarViewDidPressButton:(PHFComposeBarView *)composeBarView {
    if (![composeBarView.textView.text isEqualToString:@""]) {        
        [CPMessenger sendMessage:self.composeBarView.text
                            from:self.myJid
                              to:self.contact.jidStr
                      deviceUser:self.myJid
                    onXMPPStream:self.xmppStream
          inManagedObjectContext:self.managedObjectContext];
        
    }
    
    composeBarView.textView.text = @"";
}

- (void)composeBarViewDidPressUtilityButton:(PHFComposeBarView *)composeBarView {
    NSLog(@"utitility button pressed");
}

#pragma mark - UISplitViewController

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation{
    return NO;
}

#pragma mark - TableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    NSArray *sections = self.fetchedResultsController.sections;
    if(sections.count > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
        numberOfRows = [sectionInfo numberOfObjects];
    }
    
    return numberOfRows;
}

// Return the height of the row based on the type of transfer and custom view it contains
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Chat *chat = [self.fetchedResultsController objectAtIndexPath:indexPath];
    return [MessageView viewHeightForChat:chat];
}

#pragma mark - TableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"MessagesTableViewCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:CellIdentifier];
	}
    
    // Configure the cell...
    [self fetchedResultsController:self.fetchedResultsController configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (IBAction)userSwipedDownGesture:(UISwipeGestureRecognizer *)sender {
    [self.composeBarView.textView resignFirstResponder];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)theIndexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
    [self scrollToLastRowWithAnimation:YES];
}

#pragma mark - Toolbar animation helpers

// Helper method for moving the toolbar frame based on user action
- (void)moveToolBarUp:(BOOL)up forKeyboardNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    
    // Get animation info from userInfo
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardFrame;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];
    
    // Animate up or down
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    [self.composeBarView setFrame:CGRectMake(self.composeBarView.frame.origin.x, self.composeBarView.frame.origin.y + (keyboardFrame.size.height * (up ? -1 : 1)), self.composeBarView.frame.size.width, self.composeBarView.frame.size.height)];
    
    UIEdgeInsets insets = UIEdgeInsetsMake(self.navigationController.navigationBar.frame.size.height + 20.0, 0, (up ? (self.composeBarView.frame.size.height + keyboardFrame.size.height) : self.composeBarView.frame.size.height), 0);
    self.tableView.contentInset = insets;
    self.tableView.scrollIndicatorInsets = insets;
    
    if (up) [self scrollToLastRowWithAnimation:YES];

    [UIView commitAnimations];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    // move the toolbar frame up as keyboard animates into view
    [self moveToolBarUp:YES forKeyboardNotification:notification];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    // move the toolbar frame down as keyboard animates into view
    [self moveToolBarUp:NO forKeyboardNotification:notification];
}

@end
