//
//  ArticleViewController.m
//  ScreenCrush
//
//  Created by Wesley Hovanec on 7/8/15.
//  Copyright (c) 2015 Wesley Hovanec. All rights reserved.
//

#import "ArticleViewController.h"
#import "ArticleManager.h"
#import <Social/Social.h>

@interface ArticleViewController ()

@end

@implementation ArticleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserverForName:@"RefreshArticleText" object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self reloadWebView];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:@"RefreshImages" object:nil queue:nil usingBlock:^(NSNotification *note) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = [UIImage imageWithData:self.article.imageData];
        });
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:@"DownloadError" object:nil queue:nil usingBlock:^(NSNotification *note) {
        if (self.isViewLoaded && self.view.window) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:[NSString stringWithFormat:@"%@", [[note.userInfo valueForKey:@"error"] localizedDescription]] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Cancel action") style:UIAlertActionStyleCancel handler:nil];
            [alert addAction:ok];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:alert animated:YES completion:nil];
            });
        }
    }];
    self.titleLabel.text = self.article.title;
    self.authorLabel.text = [NSString stringWithFormat:@"by %@%@", self.article.author, self.article.date];
    self.imageView.image = [UIImage imageWithData:self.article.imageData];
    if (self.article.imageCaption != nil) {
        self.imageCaptionLabel.text = [NSString stringWithFormat:@"Photograph: %@", self.article.imageCaption];
    }
    else {
        self.imageCaptionLabel.text = nil;
    }
    if (self.article.articleText == nil) {
        [[ArticleManager sharedArticleManager] downloadArticleTextForArticle:self.article];
    }
    else {
        [self reloadWebView];
    }
    self.webView.delegate = self;
    self.webView.scrollView.scrollEnabled = NO;
    self.webView.scrollView.bounces = NO;
//    The pictures seemed to be uniformly this ratio
    self.imageViewHeightConstraint.constant = self.view.frame.size.width * .667;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self reloadWebView];
    self.imageViewHeightConstraint.constant = size.width * .667;
}

-(void)reloadWebView {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.webView loadHTMLString:[NSString stringWithFormat:@"<html><style type=\"text/css\">body{font-size: 16; font-family: \"Gill Sans\";}</style><body>%@</body></html>", self.article.articleText] baseURL:nil];
    });
}

#pragma mark WebView Delegate

//Resizing the webView according to content
-(void)webViewDidFinishLoad:(UIWebView *)webView {
    self.webViewHeightConstraint.constant = [self.webView sizeThatFits:CGSizeZero].height;
}

//Stopped navigation from HTML links in the articles
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([[request.URL absoluteString] containsString:@"http"]) {
        return NO;
    }
    return YES;
}

#pragma mark Social Media

//Social media integration
- (IBAction)shareButton:(id)sender {
    if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook] && ![SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        UIAlertController *shareAlert = [UIAlertController alertControllerWithTitle:@"Share" message:@"Please sign in with Facebook or Twitter to use this feature" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [shareAlert addAction:cancelButton];
        [self presentViewController:shareAlert animated:YES completion:nil];
    }
    else {
        UIAlertController *shareAlert = [UIAlertController alertControllerWithTitle:@"Share" message:@"Share on social media." preferredStyle:UIAlertControllerStyleAlert];
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
            UIAlertAction *fbButton = [UIAlertAction actionWithTitle:@"Facebook" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                SLComposeViewController *facebookSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
                [facebookSheet setInitialText:[NSString stringWithFormat:@"%@", self.article.title]];
                [facebookSheet addImage:[UIImage imageWithData:self.article.imageData]];
                [facebookSheet addURL:[NSURL URLWithString:self.article.url]];
                [self presentViewController:facebookSheet animated:YES completion:nil];
            }];
            [shareAlert addAction:fbButton];
        }
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
            UIAlertAction *twButton = [UIAlertAction actionWithTitle:@"Twitter" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                SLComposeViewController *twitterSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
                [twitterSheet setInitialText:[NSString stringWithFormat:@"%@", self.article.title]];
                [twitterSheet addImage:[UIImage imageWithData:self.article.imageData]];
                [twitterSheet addURL:[NSURL URLWithString:self.article.url]];
                [self presentViewController:twitterSheet animated:YES completion:nil];
            }];
            [shareAlert addAction:twButton];
        }
        UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [shareAlert addAction:cancelButton];
        [self presentViewController:shareAlert animated:YES completion:nil];
    }
}

@end



