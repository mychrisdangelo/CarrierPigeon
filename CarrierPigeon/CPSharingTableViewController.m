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

@interface CPSharingTableViewController ()
@property (weak, nonatomic) IBOutlet UITableViewCell *networkStatus;
@property (nonatomic, strong) XMPPStream *xmppStream;
@property (weak, nonatomic) IBOutlet UITableViewCell *nearByPigeonsCell;
@property (nonatomic) int servicesRequiringRefreshing;

@end

@implementation CPSharingTableViewController

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
    
    [self refreshDisplayOfNetworkStatus];
    [self updatePigeonCountInTableView];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(updatePigeonCountInTableView) forControlEvents:UIControlEventValueChanged];
    [self.refreshControl addTarget:self action:@selector(refreshDisplayOfNetworkStatus) forControlEvents:UIControlEventValueChanged];
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

- (void)refreshDisplayOfNetworkStatus
{
    self.servicesRequiringRefreshing++;
    CPNetworkStatus networkStatus = [CPNetworkStatusAssistant networkStatus];
    if (networkStatus & CPNetworkStatusConnectedToXMPPStream) {
        self.networkStatus.textLabel.text = @"Connected";
    } else if (networkStatus & CPNetworkStatusConnectedToPeerPigeons) {
        self.networkStatus.textLabel.text = @"Nearby / Connected Pigeons Connected";
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
