//
//  CPMessageDetailTableViewController.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/15/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "CPMessageDetailTableViewController.h"
#import "Chat+Create.h"

@interface CPMessageDetailTableViewController ()

@property (weak, nonatomic) IBOutlet UILabel *message;
@property (weak, nonatomic) IBOutlet UILabel *from;
@property (weak, nonatomic) IBOutlet UILabel *to;
@property (weak, nonatomic) IBOutlet UILabel *carriers;
@property (weak, nonatomic) IBOutlet UILabel *status;
@property (weak, nonatomic) IBOutlet UILabel *sent;
@property (weak, nonatomic) IBOutlet UILabel *delivered;
@property (weak, nonatomic) IBOutlet UILabel *received;
@property (weak, nonatomic) IBOutlet UILabel *read;

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    

    self.message.text = self.chat.messageBody;
    self.from.text = self.chat.fromJID;
    self.to.text = self.chat.toJID;
    self.carriers.text = @"todo";
    
    NSString *statusString;
    
    switch ([self.chat.messageStatus intValue]) {
        case CPChatSendStatusSent:
            statusString = @"sent";
            break;
        case CPChatSendStatusSending:
            statusString = @"sending";
            break;
        case CPChatSendStutusReceivedMessage:
            statusString = @"received";
            break;
        case CPChatStatusOfflinePending:
            statusString = @"pending";
            break;
        case CPChatStatusRelaying:
            statusString = @"relaying";
            break;
        case CPChatStatusRelayed:
            statusString = @"relayed";
            break;
        default:
            statusString = @"unknown";
            break;
    }
    
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
