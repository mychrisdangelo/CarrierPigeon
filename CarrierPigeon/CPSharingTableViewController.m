//
//  CPSharingTableViewController.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/17/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "CPSharingTableViewController.h"
#import "CPAppDelegate.h"
#import "XMPP.h"
#import "CPNearbyPigeonsTableViewController.h"
#import "CPSessionContainer.h"
#import "CPNetworkStatusAssistant.h"
#import "Chat.h"
#import "PigeonPeer.h"

typedef NS_ENUM(NSInteger, CPMessageSentCategory) {
    CPMessageSentDirectly,
    CPMessageSentViaPigeons,
    CPMessageSentForPigeons
};

@interface CPSharingTableViewController ()

@property (weak, nonatomic) IBOutlet UITableViewCell *networkStatus;
@property (nonatomic, strong) XMPPStream *xmppStream;
@property (weak, nonatomic) IBOutlet UITableViewCell *nearByPigeonsCell;
@property (nonatomic) int servicesRequiringRefreshing;
@property (nonatomic, strong) NSString *myJid;
@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (weak, nonatomic) IBOutlet UILabel *messagesSentDirectlyLabel;
@property (weak, nonatomic) IBOutlet UILabel *messagesSentViaPigeonsLabel;
@property (weak, nonatomic) IBOutlet UILabel *messagesSentForPigeonsLabel;

@end

@implementation CPSharingTableViewController

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext == nil) {
        _managedObjectContext = ((CPAppDelegate *)([[UIApplication sharedApplication] delegate])).managedObjectContext;
    }
    
    return _managedObjectContext;
}

- (NSString *)myJid
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
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
    
    CPAppDelegate *delegate = (CPAppDelegate *)[UIApplication sharedApplication].delegate;
    self.xmppStream = delegate.xmppStream;
    [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(updatePigeonCountInTableView) forControlEvents:UIControlEventValueChanged];
    [self.refreshControl addTarget:self action:@selector(refreshDisplayOfNetworkStatus) forControlEvents:UIControlEventValueChanged];
    [self.refreshControl addTarget:self action:@selector(updateNetworkUsageStatistics) forControlEvents:UIControlEventValueChanged];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self refreshDisplayOfNetworkStatus];
    [self updatePigeonCountInTableView];
    [self updateNetworkUsageStatistics];
}

- (void)endRefreshing
{
    if (--self.servicesRequiringRefreshing == 0) {
        [self.refreshControl endRefreshing];
    }
}

- (void)updatePigeonCountInTableView
{
    self.servicesRequiringRefreshing++;
    int currentPeersCount = (int)[[[CPSessionContainer sharedInstance] peersInRange] count];
    int connectedPeersCount = (int)[[[CPSessionContainer sharedInstance] peersInRangeConnected] count];
    self.nearByPigeonsCell.detailTextLabel.text = [NSString stringWithFormat:@"%d / %d", connectedPeersCount, currentPeersCount];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:0]; // getting indexPathForCell doesn't work in static table it seems
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self endRefreshing];
}

- (void)updateNetworkUsageStatistics
{
    self.servicesRequiringRefreshing++;
    self.messagesSentDirectlyLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[self messagesSent:CPMessageSentDirectly]];
    self.messagesSentViaPigeonsLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[self messagesSent:CPMessageSentViaPigeons]];
    self.messagesSentForPigeonsLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[self messagesSent:CPMessageSentForPigeons]];
    [self endRefreshing];
}

- (void)refreshDisplayOfNetworkStatus
{
    self.servicesRequiringRefreshing++;
    CPNetworkStatus networkStatus = [CPNetworkStatusAssistant networkStatus];
    if (networkStatus & CPNetworkStatusConnectedToXMPPStream) {
        self.networkStatus.textLabel.text = @"Connected";
    } else if (networkStatus & CPNetworkStatusConnectedToPeerPigeons) {
        self.networkStatus.textLabel.text = @"Nearby Pigeons Connected";
    } else {
        self.networkStatus.textLabel.text = @"No network connection";
    }
    
    [self.networkStatus.textLabel setTextColor:[CPNetworkStatusAssistant colorForNetworkStatusWithLightColor:NO]];
    
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    [self endRefreshing];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowNearbyPigeons"]) {
        if ([segue.destinationViewController isMemberOfClass:[CPNearbyPigeonsTableViewController class]]) {
            CPNearbyPigeonsTableViewController *nptvc = (CPNearbyPigeonsTableViewController *)segue.destinationViewController;
            CPSessionContainer *sc = [CPSessionContainer sharedInstance];
            nptvc.nearbyPigeons = [[sc peersInRange] allObjects];
            nptvc.nearbyPigeonsConnected = [[sc peersInRangeConnected] copy];
        }
    }
}

- (NSUInteger)messagesSent:(CPMessageSentCategory)sentCategory
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Chat" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    switch (sentCategory) {
        case CPMessageSentDirectly:
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"fromJID == %@ AND chatOwner == %@ AND pigeonsCarryingMessage.@count >= 0", self.myJid, self.myJid]];
            break;
        case CPMessageSentViaPigeons:
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"fromJID == %@ AND chatOwner == %@ AND pigeonsCarryingMessage.@count >= 1", self.myJid, self.myJid]];
            break;
        case CPMessageSentForPigeons:
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"fromJID == %@ AND chatOwner == %@ AND reallyFromJID != nil", self.myJid, self.myJid]];
            break;
        default:
            NSLog(@"%s unhandled case", __PRETTY_FUNCTION__);
            break;
    }
    
    NSError *error = nil;
    return [self.managedObjectContext countForFetchRequest:fetchRequest error:&error];
}

#pragma mark - XMPPStreamDelegate

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    [self refreshDisplayOfNetworkStatus];
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    [self refreshDisplayOfNetworkStatus];
}


@end
