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

#import <Foundation/Foundation.h>
#import <Psi/Psi.h>

@protocol TunneledAppProtocol
- (NSString *) getPsiphonConfig;
- (void) onDiagnosticMessage: (NSString *) message;
- (void) onAvailableEgressRegions: (NSArray *) regions;
- (void) onSocksProxyPortInUse: (NSInteger) port;
- (void) onHttpProxyPortInUse: (NSInteger) port;
- (void) onListeningSocksProxyPort: (NSInteger) port;
- (void) onListeningHttpProxyPort: (NSInteger) port;
- (void) onUpstreamProxyError: (NSString *) message;
- (void) onConnecting;
- (void) onConnected;
- (void) onHomepage: (NSString *) url;
- (void) onClientRegion: (NSString *) region;
- (void) onClientUpgradeDownloaded: (NSString *) filename;
- (void) onSplitTunnelRegion: (NSString *) region;
- (void) onUntunneledAddress: (NSString *) address;
- (void) onBytesTransferred: (long) sent : (long) received;
- (void) onStartedWaitingForNetworkConnectivity;
@end


@interface TunnelController : NSObject<GoPsiPsiphonProvider>

@property (weak) id <TunneledAppProtocol> tunneledAppProtocolDelegate;
@property (nonatomic) NSInteger listeningSocksProxyPort;
@property (nonatomic) NSArray *homepages;


+ (id) sharedInstance;

-(void) startTunnel;
-(void) stopTunnel;

@end
