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

@interface CPSharingTableViewController ()
@property (weak, nonatomic) IBOutlet UITableViewCell *networkStatus;
@property (nonatomic, strong) XMPPStream *xmppStream;
@property (weak, nonatomic) IBOutlet UILabel *nearbyPigeonsDetailLabel;

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
    
    int currentPeersCount = (int)[[[CPSessionContainer sharedInstance] currentPeers] count];
    self.nearbyPigeonsDetailLabel.text = [NSString stringWithFormat:@"%d", currentPeersCount];
    
}

- (void)refreshDisplayOfNetworkStatus
{
    if ([self.xmppStream isConnected]) {
        self.networkStatus.imageView.image = [UIImage imageNamed:@"GreenCircle"];
        self.networkStatus.textLabel.text = @"Connected";
    } else {
        self.networkStatus.imageView.image = [UIImage imageNamed:@"RedCircle"];
        self.networkStatus.textLabel.text = @"No network connection";
        // todo: handle case of @"YellowCircle" when there is no network but there is a connection to other users
    }
    
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
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
            nptvc.nearbyPigeons = [[[CPSessionContainer sharedInstance] currentPeers] allObjects];
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
