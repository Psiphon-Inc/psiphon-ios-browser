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
#import "LogViewController.h"
#import "FeedbackViewController.h"


@interface LogViewController ()

@property (strong, nonatomic) NSMutableArray *logQueue;
@property (strong, nonatomic) UIFont *messageFont;

@end


@implementation LogViewController
{
    __weak IBOutlet UISegmentedControl *segmentedControl;
    IBOutlet UITableView *loggingTableView;
    enum {
        OPEN_BROWSER_BUTTON = 0,
        FEEDBACK_BUTTON
    };
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Disable 'open browser' button until tunnels are established
    [segmentedControl setEnabled:NO forSegmentAtIndex:0];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNewLogEntryNotification:)
                                                 name:@"NewLogEntryPosted"
                                               object:nil];
    
    _messageFont = [UIFont systemFontOfSize:14];
}

-(void) receivedNewLogEntryNotification:(NSNotification*) aNotification
{
    if ([[aNotification name] isEqualToString: @"NewLogEntryPosted"])
    {
        NSDictionary *userInfo = aNotification.userInfo;
        if( userInfo )
        {
            NSString* logEntry = [userInfo objectForKey:@"LogEntryKey"];
            if(logEntry)
            {
                if (_logQueue == nil) {
                    _logQueue = [[NSMutableArray alloc] init];
                }
                [_logQueue addObject: logEntry];
                
                [loggingTableView setContentOffset:CGPointMake(0, CGFLOAT_MAX)];
                
                [loggingTableView reloadData];
            }
            
            // Observe 'Connected' message
            if ([logEntry  isEqual: @"Connected"]) {
                [segmentedControl setEnabled:YES forSegmentAtIndex:0];
            }
        }
    }
}

- (IBAction)segmentedControlButtonPressed:(id)sender {
    UISegmentedControl *cntrl = (UISegmentedControl *)sender;
    
    if (cntrl.selectedSegmentIndex == OPEN_BROWSER_BUTTON) {
        PsiphonBrowserViewController *browserViewController = [[PsiphonBrowserViewController alloc] initWithNibName:nil bundle:nil];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:browserViewController];
        navController.navigationBar.hidden = YES;
        
        AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication]delegate];
        
        NSString *homepage = [appDelegate getHomepage];
        
        NSString *pageToLoad = homepage ? homepage : @"";
        
        [self presentViewController:navController animated:YES completion:^{
            [browserViewController addTabWithAddress:pageToLoad];
        }];
    } else if (cntrl.selectedSegmentIndex == FEEDBACK_BUTTON) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"FeedbackViewController"];
        vc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentViewController:vc animated:YES completion:nil];
    } else {
        // Do nothing
    }
    [cntrl setSelectedSegmentIndex:-1];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_logQueue count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.font = _messageFont;
    }
    
    // Configure the cell...
    NSString *message = [_logQueue objectAtIndex:indexPath.row];
    
    cell.textLabel.text = message;
    cell.textLabel.font = _messageFont;
    cell.textLabel.numberOfLines = 0;
    
    return cell;
}

// Prevent logs from getting truncated in tableView UI
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellText = [_logQueue objectAtIndex:indexPath.row];
    NSAttributedString *attributedText =
    [[NSAttributedString alloc]
     initWithString:cellText
     attributes:@
     {
     NSFontAttributeName: _messageFont
     }];
    CGRect rect = [attributedText boundingRectWithSize:CGSizeMake(tableView.bounds.size.width, CGFLOAT_MAX)
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                               context:nil];
    return rect.size.height + 20;
}

@end

