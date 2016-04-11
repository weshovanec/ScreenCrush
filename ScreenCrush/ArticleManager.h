//
//  ArticleManager.h
//  ScreenCrush
//
//  Created by Wesley Hovanec on 7/7/15.
//  Copyright (c) 2015 Wesley Hovanec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Article.h"

@interface ArticleManager : NSObject <NSURLSessionDownloadDelegate>

@property (strong, nonatomic) NSMutableArray *articles;

+(ArticleManager *)sharedArticleManager;

-(void)checkForUpdates;
-(void)downloadArticleTextForArticle:(Article *)article;
-(void)pauseDownloadArticleTextForArticle:(Article *)article;
-(void)downloadImageForCellAtIndex:(NSInteger)index;
-(void)pauseDownloadImageForCellAtIndex:(NSInteger)index;
-(void)sortArticlesByDate;

@end
