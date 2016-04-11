//
//  TableViewController.m
//  ScreenCrush
//
//  Created by Wesley Hovanec on 7/7/15.
//  Copyright (c) 2015 Wesley Hovanec. All rights reserved.
//

#import "TableViewController.h"
#import "CustomTableViewCell.h"
#import "ArticleManager.h"
#import "ArticleViewController.h"
#import "Article.h"

@interface TableViewController ()

@end

@implementation TableViewController
{
    UIRefreshControl *refreshControl;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:@"CustomTableViewCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
    [self checkForUpdates];
//    Pull to Refresh
    refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.backgroundColor = [UIColor lightGrayColor];
    refreshControl.tintColor = [UIColor blackColor];
    [refreshControl addTarget:self action:@selector(checkForUpdates) forControlEvents:UIControlEventValueChanged];
    [self setRefreshControl:refreshControl];
//    Notifications for refreshing the table view after downloading data
    [[NSNotificationCenter defaultCenter] addObserverForName:@"RefreshTableView" object:nil queue:nil usingBlock:^(NSNotification *note) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadTableViewAfterSorting];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"MMM d, h:mm a";
            NSString *updateText = [NSString stringWithFormat:@"Last Updated on %@", [formatter stringFromDate:[NSDate date]]];
            refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:updateText];
            [refreshControl endRefreshing];
        });
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:@"RefreshImages" object:nil queue:nil usingBlock:^(NSNotification *note) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:@"DownloadError" object:nil queue:nil usingBlock:^(NSNotification *note) {
        if ([refreshControl isRefreshing]) {
            [refreshControl endRefreshing];
        }
        if (self.isViewLoaded && self.view.window) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:[NSString stringWithFormat:@"%@", [[note.userInfo valueForKey:@"error"] localizedDescription]] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Cancel action") style:UIAlertActionStyleCancel handler:nil];
            [alert addAction:ok];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:alert animated:YES completion:nil];
            });
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)checkForUpdates {
    [[ArticleManager sharedArticleManager] checkForUpdates];
}

-(void)reloadTableViewAfterSorting {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[ArticleManager sharedArticleManager] sortArticlesByDate];
        [self.tableView reloadData];
    });
}

#pragma mark - TableView Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[ArticleManager sharedArticleManager] articles] count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CustomTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    Article *temp = [[[ArticleManager sharedArticleManager] articles] objectAtIndex:indexPath.row];
    if (temp.imageData == nil) {
        cell.customImageView.image = nil;
        [[ArticleManager sharedArticleManager] downloadImageForCellAtIndex:indexPath.row];
    }
    else {
        cell.customImageView.image = [UIImage imageWithData:temp.imageData];
    }
    cell.customTitleLabel.text = temp.title;
    cell.customDateLabel.text = temp.date;
    return cell;
}

#pragma mark TableView Delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"ArticleViewSegue" sender:self];
}

-(void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [[ArticleManager sharedArticleManager] pauseDownloadImageForCellAtIndex:indexPath.row];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    Article *article = [[[ArticleManager sharedArticleManager] articles] objectAtIndex:[[self.tableView indexPathForSelectedRow] row]];
    if (article.imageData == nil) {
        [[ArticleManager sharedArticleManager] downloadImageForCellAtIndex:[[self.tableView indexPathForSelectedRow] row]];
    }
    ArticleViewController *avc = [segue destinationViewController];
    avc.article = article;
}


@end
