//
//  CPMessageDetailTableViewController.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 3/15/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "CPMessageDetailTableViewController.h"
#import "Chat+Create.h"
#import "PigeonPeer.h"

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
@property (weak, nonatomic) IBOutlet UILabel *carriers;

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

+ (NSString *)stringOfPigeonPeerSet:(NSSet *)pigeonPeers
{
    NSMutableString *stringOfPigeonNames = [[NSMutableString alloc] init];
    NSArray *pigeonPeersAsArray = [pigeonPeers allObjects];
    PigeonPeer *eachPeer = nil;
    for (int i = 0; i < [pigeonPeersAsArray count]; i++) {
        eachPeer = pigeonPeersAsArray[i];
        [stringOfPigeonNames appendString:[NSString stringWithFormat:@"%@, ", eachPeer.jidStr]];
        if (i == ([pigeonPeersAsArray count] - 1)) {
            [stringOfPigeonNames appendString:eachPeer.jidStr];
        }
    }
    
    return [stringOfPigeonNames copy];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.message.text = self.chat.messageBody;
    self.from.text = self.chat.fromJID;
    self.to.text = self.chat.toJID;
    self.reallyFrom.text = self.chat.reallyFromJID ? self.chat.reallyFromJID : self.chat.fromJID;
    self.carriers.text = [CPMessageDetailTableViewController stringOfPigeonPeerSet:self.chat.pigeonsCarryingMessage];
    
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
