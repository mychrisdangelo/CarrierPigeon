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

- (NSString *)parseOutHostIfInDisplayName:(NSString *)displayName
{
    NSArray *parsedJID = [displayName componentsSeparatedByString: @"@"];
    NSString *username = [parsedJID objectAtIndex:0];
    return username;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.message.text = self.chat.messageBody;
    self.from.text = [self parseOutHostIfInDisplayName:self.chat.fromJID];
    self.to.text = [self parseOutHostIfInDisplayName:self.chat.toJID];
    NSString *reallyFrom = self.chat.reallyFromJID ? self.chat.reallyFromJID : self.chat.fromJID;
    self.reallyFrom.text = [self parseOutHostIfInDisplayName:reallyFrom];
    
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
    
    self.status.text = statusString;
    self.sent.text = @"todo";
    self.delivered.text = @"todo";
    self.received.text = @"todo";
    self.read.text = @"todo";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
