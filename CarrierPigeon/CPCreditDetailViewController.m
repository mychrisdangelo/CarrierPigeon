//
//  CPCreditDetailViewController.m
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/26/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#import "CPCreditDetailViewController.h"

@interface CPCreditDetailViewController () <UIWebViewDelegate>

@end

@implementation CPCreditDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

// TODO: this is lazy but fast and enough for what we need
- (NSString *)getURLStringForLicenseForTitleString
{
    NSString *titleString = self.title;
    
    if ([titleString isEqualToString:@"NSDate-Helper"]) {
        return @"https://github.com/billymeltdown/nsdate-helper";
    }
    
    if ([titleString isEqualToString:@"HexColors"]) {
        return @"https://github.com/mRs-/HexColors";
    }
    
    if ([titleString isEqualToString:@"PHFComposeBarView"]) {
        return @"https://github.com/fphilipe/PHFComposeBarView";
    }
    
    if ([titleString isEqualToString:@"TSMessages"]) {
        return @"https://github.com/toursprung/TSMessages";
    }
    
    if ([titleString isEqualToString:@"XMPPFramework"]) {
        return @"https://github.com/robbiehanson/XMPPFramework";
    }
    
    return nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSURL *url = [NSURL URLWithString:[self getURLStringForLicenseForTitleString]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    UIApplication *application = [UIApplication sharedApplication];
    application.networkActivityIndicatorVisible = YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    UIApplication *application = [UIApplication sharedApplication];
    application.networkActivityIndicatorVisible = NO;
    if (error) NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    UIApplication *application = [UIApplication sharedApplication];
    application.networkActivityIndicatorVisible = NO;
}

@end
