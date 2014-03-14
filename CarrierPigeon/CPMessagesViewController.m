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

@interface CPMessagesViewController () <UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate, UITextFieldDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) IBOutlet UIToolbar *toolBar;
@property (weak, nonatomic) IBOutlet UITextField *composeTextField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cameraButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSString *myJid;

@end

@implementation CPMessagesViewController

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize myJid = _myJid;

- (NSString *)myJid
{
    if (_myJid == nil) {
        _myJid = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
    }
    
    return _myJid;
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
    
    [predicateArray addObject:[NSPredicate predicateWithFormat:@"fromJID == %@ AND toJID == %@", self.user.jidStr, self.myJid]];
    [predicateArray addObject:[NSPredicate predicateWithFormat:@"fromJID == %@ AND toJID == %@", self.myJid, self.user.jidStr]];
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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.title = self.user.displayName;
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.toolBar.frame.size.height, 0);
    [self scrollToLastRowWithAnimation:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:(numberOfRows - 1) inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:animated];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // Stop listening for keyboard notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)sendMessage:(id)sender
{
    if (![self.composeTextField.text isEqualToString:@""]) {
        NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
        NSString *messageBody = self.composeTextField.text;
        [body setStringValue:messageBody];
        NSXMLElement *messageElement = [NSXMLElement elementWithName:@"message"];
        [messageElement addAttributeWithName:@"type" stringValue:@"chat"];
        [messageElement addAttributeWithName:@"to" stringValue:self.user.jidStr];
        [messageElement addChild:body];
        NSXMLElement *status = [NSXMLElement elementWithName:@"active" xmlns:@"http://jabber.org/protocol/chatstates"];
        [messageElement addChild:status];
        [self.xmppStream sendElement:messageElement];

        XMPPMessage *message = [XMPPMessage messageFromElement:messageElement];
        [Chat addChatWithXMPPMessage:message fromUser:self.myJid toUser:self.user.jidStr deviceUser:self.myJid inManagedObjectContext:self.managedObjectContext];
    }
    
    self.composeTextField.text = @"";
    self.sendButton.enabled = NO;
}

- (IBAction)sendButtonPressed:(UIBarButtonItem *)sender {
    [self sendMessage:sender];
    [self.composeTextField resignFirstResponder];
}

- (IBAction)cameraButtonPressed:(UIBarButtonItem *)sender {
    NSLog(@"utitility button pressed");
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
    [self.composeTextField resignFirstResponder];
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

#pragma mark - UITextFieldDelegate methods

// Override to dynamically enable/disable the send button based on user typing
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSUInteger length = self.composeTextField.text.length - range.length + string.length;
    if (length > 0) {
        self.sendButton.enabled = YES;
    }
    else {
        self.sendButton.enabled = NO;
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self sendMessage:textField];
    return YES;
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
    
    [self.toolBar setFrame:CGRectMake(self.toolBar.frame.origin.x, self.toolBar.frame.origin.y + (keyboardFrame.size.height * (up ? -1 : 1)), self.toolBar.frame.size.width, self.toolBar.frame.size.height)];
    
    UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, (up ? (self.toolBar.frame.size.height + keyboardFrame.size.height) : self.toolBar.frame.size.height), 0);
    self.tableView.contentInset = insets;
    self.tableView.scrollIndicatorInsets = insets;

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
