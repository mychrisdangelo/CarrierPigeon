//
//  CPMessageDetailTableViewController.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/15/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "CPMessageDetailTableViewController.h"
#import "Chat+Create.h"
#import "CPPigeonPeerTableViewController.h"

@interface CPMessageDetailTableViewController ()

@property (weak, nonatomic) IBOutlet UILabel *message;
@property (weak, nonatomic) IBOutlet UILabel *from;
@property (weak, nonatomic) IBOutlet UILabel *to;
@property (weak, nonatomic) IBOutlet UILabel *reallyFrom;
@property (weak, nonatomic) IBOutlet UILabel *status;
@property (weak, nonatomic) IBOutlet UILabel *sent;
@property (weak, nonatomic) IBOutlet UILabel *delivered;
@property (weak, nonatomic) IBOutlet UILabel *received;
@property (weak, nonatomic) IBOutlet UILabel *read;
@property (weak, nonatomic) IBOutlet UITableViewCell *carrierCell;
@property (weak, nonatomic) IBOutlet UILabel *reallyFromID;
@property (weak, nonatomic) IBOutlet UILabel *ownerSendID;

@end

@implementation CPMessageDetailTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowCarriers"]) {
        if ([segue.destinationViewController isMemberOfClass:[CPPigeonPeerTableViewController class]]) {
            CPPigeonPeerTableViewController *pptvc = (CPPigeonPeerTableViewController *)segue.destinationViewController;
            pptvc.pigeonPeers = [self.chat.pigeonsCarryingMessage allObjects];
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.message.text = self.chat.messageBody;
    self.from.text = [CPHelperFunctions parseOutHostIfInDisplayName:self.chat.fromJID];
    self.to.text = [CPHelperFunctions parseOutHostIfInDisplayName:self.chat.toJID];
    NSString *reallyFrom = self.chat.reallyFromJID ? self.chat.reallyFromJID : self.chat.fromJID;
    self.reallyFrom.text = [CPHelperFunctions parseOutHostIfInDisplayName:reallyFrom];
    
    // setup carrierCell
    int pigeonsCarryingMessageCount = (int)[self.chat.pigeonsCarryingMessage count];
    NSString *carriersCountDescription = nil;
    if (!pigeonsCarryingMessageCount) {
        carriersCountDescription = @"None";
        self.carrierCell.userInteractionEnabled = NO;
        self.carrierCell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        carriersCountDescription = [NSString stringWithFormat:@"%d", pigeonsCarryingMessageCount];
        self.carrierCell.userInteractionEnabled = YES;
        self.carrierCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    self.carrierCell.detailTextLabel.text = carriersCountDescription;
    
    
    NSString *statusString = [Chat stringForMessageStatus:[self.chat.messageStatus intValue]];
    
    NSDate *senderSentTimestamp = self.chat.senderSentTimestamp ? self.chat.senderSentTimestamp : nil;
    NSDate *serverReceivedTimestamp = self.chat.serverReceivedTimestamp ? self.chat.serverReceivedTimestamp : nil;
    NSDate *receiverReceivedTimestamp = self.chat.receiverReceivedTimestamp ? self.chat.receiverReceivedTimestamp : nil;
    
    // date is stored as UTC, needs to be changed to the user's timezone
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"h:mm a dd-MM-yyyy"];
    [dateFormatter setTimeZone:timeZone];
    
    NSString *senderSentTimestampString = [dateFormatter stringFromDate:senderSentTimestamp];
    NSString *serverReceivedTimestampString = [dateFormatter stringFromDate:serverReceivedTimestamp];
    NSString *receiverReceivedTimestampString = [dateFormatter stringFromDate:receiverReceivedTimestamp];
    
    self.status.text = statusString;
    self.sent.text = senderSentTimestampString;
    self.delivered.text = serverReceivedTimestampString;
    self.received.text = receiverReceivedTimestampString;
    self.read.text = @"";
    
    self.ownerSendID.text = self.chat.chatIDNumberPerOwner ? [self.chat.chatIDNumberPerOwner stringValue] : @"n/a";
    self.reallyFromID.text = self.chat.reallyFromChatIDNumber ? [self.chat.reallyFromChatIDNumber stringValue] : @"n/a";
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
