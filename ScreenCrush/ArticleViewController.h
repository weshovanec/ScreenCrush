//
//  ArticleViewController.h
//  ScreenCrush
//
//  Created by Wesley Hovanec on 7/8/15.
//  Copyright (c) 2015 Wesley Hovanec. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Article.h"

@interface ArticleViewController : UIViewController <UIWebViewDelegate>

@property (strong, nonatomic) Article *article;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *imageCaptionLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *webViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end
