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

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // hush SIGPIPE
    signal(SIGPIPE, SIG_IGN);
    
    // Do any additional setup after loading the view, typically from a nib
    
    self.tunnelController = [PsiphonTunnelController sharedInstance];
    self.tunnelController.tunneledAppProtocolDelegate = self;
    [self.tunnelController startTunnel];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    exit(0);
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.psiphon3.Psiphon_Browser" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Psiphon_Browser" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Psiphon_Browser.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - AppDelegate methods

- (NSString *)getHomepage {
    return _homePage;
}

- (NSString *)getDeviceRegion {
    NSString *region = @"";
    
    
   // Only use if class is loaded
    Class MGLTelephony = NSClassFromString(@"CTTelephonyNetworkInfo");
    if (MGLTelephony) {
        id telephonyNetworkInfo = [[MGLTelephony alloc] init];

        SEL selector = NSSelectorFromString(@"subscriberCellularProvider");
        IMP imp = [telephonyNetworkInfo methodForSelector:selector];
        id (*func)(id, SEL) = (void *)imp;
        
        id carrierVendor = func(telephonyNetworkInfo, selector);
        
        // Guard against simulator, iPod Touch, etc.
        if (carrierVendor) {
            selector = NSSelectorFromString(@"isoCountryCode");

            imp = [carrierVendor methodForSelector:selector];
            NSString *(*func)(id, SEL) = (void *)imp;
            region = func(carrierVendor, selector);
        }
    }
    // If country code is not available Telephony get it from the locale
    if(region == nil || region.length <= 0) {
        NSLocale *locale = [NSLocale currentLocale];
        if (locale != nil) {
            region = [locale objectForKey: NSLocaleCountryCode];
        }
    }
    
    return [region uppercaseString];
}

- (void) postLogEntryNotification:(NSString*)format, ...
{
    va_list args;
    va_start(args, format);
    NSString *logEntry = [[NSString alloc] initWithFormat:format arguments:args];
    
    dispatch_async(dispatch_get_main_queue(),^{
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject: logEntry forKey:@"LogEntryKey"];
        NSNotification *notification = [NSNotification notificationWithName:@"NewLogEntryPosted" object:nil userInfo:userInfo];
        [[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostNow
                                                   coalesceMask:NSNotificationNoCoalescing forModes:nil];
    });
}

#pragma mark - TunneledAppProtocol implementation

- (NSString *) getPsiphonConfig {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *bundledConfigPath = [[[ NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"psiphon_config.json"];
    if(![fileManager fileExistsAtPath:bundledConfigPath]) {
        NSLog(@"Config file not found. Aborting now.");
        abort();
    }
    
    //Read in psiphon_config JSON
    NSData *jsonData = [fileManager contentsAtPath:bundledConfigPath];
    NSError *e = nil;
    NSDictionary *readOnly = [NSJSONSerialization JSONObjectWithData: jsonData options: kNilOptions error: &e];
    
    NSMutableDictionary *mutableCopy = [readOnly mutableCopy];
    
    if(e) {
        NSLog(@"Failed to parse config JSON. Aborting now.");
        abort();
    }
    
    //specify DataStoreDirectory path
    mutableCopy[@"DataStoreDirectory"] = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    mutableCopy[@"RemoteServerListDownloadFilename"] = [mutableCopy[@"DataStoreDirectory"] stringByAppendingPathComponent:@"remote_server_list"];
    
    [[NSFileManager defaultManager] createFileAtPath:mutableCopy[@"RemoteServerListDownloadFilename"]
                                            contents:nil
                                          attributes:nil];
    
    //add DeviceRegion
    mutableCopy[@"DeviceRegion"] = [self getDeviceRegion];
    
    //set indistinguishable TLS flag and add TrustedRootCA file path
    NSString * frameworkBundlePath = [[NSBundle bundleForClass:[PsiphonTunnelController class]] resourcePath];
    NSString *bundledTrustedCAPath = [frameworkBundlePath stringByAppendingPathComponent:@"rootCAs.txt"];
    
    if(![fileManager fileExistsAtPath:bundledTrustedCAPath]) {
        NSLog(@"Trusted CAs file not found. Aborting now.");
        abort();
    }
    
    mutableCopy[@"UseIndistinguishableTLS"] = @YES;
    mutableCopy[@"TrustedCACertificatesFilename"] = bundledTrustedCAPath;
    
    
    jsonData = [NSJSONSerialization dataWithJSONObject:mutableCopy
                                               options:0 // non-pretty printing
                                                 error:&e];
    if(e) {
        NSLog(@"Failed to create JSON data from config object. Aborting now.");
        abort();
    }
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (void) onConnected {
    [self onDiagnosticMessage : @"Psiphon connected"];
    [self postLogEntryNotification:@"Connected", nil];
    
}

- (void) onConnecting {
    [self postLogEntryNotification:@"Connecting...", nil];
}

- (void) onDiagnosticMessage: (NSString *) message {
    NSLog(@"%@", message);
    [self postLogEntryNotification:@"%@", message];
    
}
- (void) onAvailableEgressRegions: (NSArray *) regions{
    NSString *message = [regions componentsJoinedByString:@", "];
    [self postLogEntryNotification:@"Available regions: %@", message];
    
}
- (void) onSocksProxyPortInUse: (NSInteger) port{
    [self postLogEntryNotification:@"local SOCKS proxy port %d is in use.", port];
}
- (void) onHttpProxyPortInUse: (NSInteger) port{
    [self postLogEntryNotification:@"local HTTP proxy port %d is in use.", port];
}

- (void) onListeningSocksProxyPort: (NSInteger) port {
    self.tunnelController.listeningSocksProxyPort = port;
    [self postLogEntryNotification:@"local SOCKS proxy is listening on port %d.", port];
}

- (void) onListeningHttpProxyPort: (NSInteger) port{
    [self postLogEntryNotification:@"local HTTP proxy is listening on port %d.", port];
}

- (void) onUpstreamProxyError: (NSString *) message{
    [self postLogEntryNotification:@"Upstream proxy error %@", message];
}

- (void) onHomepage: (NSString *) url{
    [self postLogEntryNotification:@"Homepage: %@", url];
    _homePage = url;
}

- (void) onClientRegion: (NSString *) region{
    [self postLogEntryNotification:@"Client region: %@", region];
}

- (void) onClientUpgradeDownloaded: (NSString *) filename{
    // N/A
}

- (void) onSplitTunnelRegion: (NSString *) region{
    [self postLogEntryNotification:@"Split tunnel region: %@", region];
}

- (void) onUntunneledAddress: (NSString *) address{
    [self postLogEntryNotification:@"Untunnelled address: %@", address];
}

- (void) onBytesTransferred: (long) sent : (long) received{
    [self postLogEntryNotification:@"bytes sent: %d", sent];
    [self postLogEntryNotification:@"bytes received: %d", received];
}
- (void) onStartedWaitingForNetworkConnectivity{
    
}

@end
