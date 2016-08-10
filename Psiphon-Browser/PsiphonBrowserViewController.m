/*
 * Copyright (c) 2016, Psiphon Inc.
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import "PsiphonBrowserViewController.h"

@interface PsiphonBrowserViewController ()

@property (nonatomic, strong) UIAlertView *authAlertView;
@property (nonatomic, strong) JAHPAuthenticatingHTTPProtocol *authenticatingHTTPProtocol;


@end

@implementation PsiphonBrowserViewController

- (void)viewDidLoad {
    [JAHPAuthenticatingHTTPProtocol setDelegate:self];
    [JAHPAuthenticatingHTTPProtocol start];
    
    [super viewDidLoad];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - JAHPAuthenticatingHTTPProtocolDelegate

- (BOOL)authenticatingHTTPProtocol:(JAHPAuthenticatingHTTPProtocol *)authenticatingHTTPProtocol canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    BOOL canAuthenticate = [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic];
    return canAuthenticate;
}


- (JAHPDidCancelAuthenticationChallengeHandler)authenticatingHTTPProtocol:(JAHPAuthenticatingHTTPProtocol *)authenticatingHTTPProtocol didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    self.authenticatingHTTPProtocol = authenticatingHTTPProtocol;
    
    self.authAlertView = [[UIAlertView alloc] initWithTitle:@""
                                                    message:@""
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:
                          @"OK",
                          nil];
    self.authAlertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    [self.authAlertView show];
    
    return ^(JAHPAuthenticatingHTTPProtocol *authenticatingHTTPProtocol, NSURLAuthenticationChallenge *challenge) {
        [self.authAlertView dismissWithClickedButtonIndex:self.authAlertView.cancelButtonIndex
                                                 animated:YES];
        self.authAlertView = nil;
        self.authenticatingHTTPProtocol = nil;
        
        [[[UIAlertView alloc] initWithTitle:@""
                                    message:@"The URL Loading System cancelled authentication"
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    };
}

- (void)authenticatingHTTPProtocol:(JAHPAuthenticatingHTTPProtocol *)authenticatingHTTPProtocol logWithFormat:(NSString *)format arguments:(va_list)arguments {
    NSLog(@"logWithFormat: %@", [[NSString alloc] initWithFormat:format arguments:arguments]);
}

- (void)authenticatingHTTPProtocol:(JAHPAuthenticatingHTTPProtocol *)authenticatingHTTPProtocol logMessage:(NSString *)message {
    NSLog(@"logMessage: %@", message);
}


@end
