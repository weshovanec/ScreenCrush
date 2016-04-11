//
//  ArticleManager.m
//  ScreenCrush
//
//  Created by Wesley Hovanec on 7/7/15.
//  Copyright (c) 2015 Wesley Hovanec. All rights reserved.
//

#import "ArticleManager.h"
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@implementation ArticleManager
{
    NSMutableDictionary *imageURLSessions;
    NSMutableDictionary *textURLSessions;
    NSManagedObjectContext *context;
    NSManagedObjectModel *model;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        imageURLSessions = [[NSMutableDictionary alloc] init];
        textURLSessions = [[NSMutableDictionary alloc] init];
        if (context == nil) {
            model = [NSManagedObjectModel mergedModelFromBundles:nil];
            NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
            NSError *error = nil;
            if (![psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[NSURL fileURLWithPath:[self archivePath]] options:nil error:&error]) {
//                NSLog(@"Error: %@", error.localizedDescription);
            }
            context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            [context setPersistentStoreCoordinator:psc];
            
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            NSEntityDescription *description = [[model entitiesByName] objectForKey:@"Article"];
            [request setEntity:description];
            error = nil;
            NSArray *result = [context executeFetchRequest:request error:&error];
            if(!result){
//                NSLog(@"Error: %@", error.localizedDescription);
            }
            self.articles = [result mutableCopy];
            [self sortArticlesByDate];
        }
    }
    return self;
}

-(void) saveChanges
{
    NSError *error = nil;
    BOOL successful = [context save:&error];
    if(!successful){
//        NSLog(@"Error: %@", error.localizedDescription);
    }
}

-(NSString*)archivePath
{
    NSArray *documentsDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [documentsDirectories objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"store.data"];
}

+(ArticleManager *)sharedArticleManager {
    static ArticleManager *_sharedArticleManager = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _sharedArticleManager = [[ArticleManager alloc] init];
    });
    return _sharedArticleManager;
}

-(void)checkForUpdates {
    NSURL *url = [NSURL URLWithString:@"http://screencrush.com/restapp/site/screencrush.com/uri/latest"];
    NSURLSession *updateSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    NSURLSessionDownloadTask *updateSessionDownloadTask = [updateSession downloadTaskWithURL:url];
    [updateSessionDownloadTask resume];
}

-(void)sortArticlesByDate {
    /*
    if (self.articles.count < 10) {
        return;
    }
    NSMutableArray *minuteArray = [[NSMutableArray alloc] init];
    NSMutableArray *minutesArray = [[NSMutableArray alloc] init];
    NSMutableArray *lowMinutesArray = [[NSMutableArray alloc] init];
    NSMutableArray *hourArray = [[NSMutableArray alloc] init];
    NSMutableArray *hoursArray = [[NSMutableArray alloc] init];
    NSMutableArray *lowHoursArray = [[NSMutableArray alloc] init];
    NSMutableArray *dayArray = [[NSMutableArray alloc] init];
    NSMutableArray *newArray = [[NSMutableArray alloc] init];
    for (Article *article in self.articles) {
        if ([article.date containsString:@"second"]) {
            [newArray addObject:article];
        }
        else if ([article.date containsString:@"minutes"] && article.date.length > 13) {
            [minutesArray addObject:article];
        }
        else if ([article.date containsString:@"minutes"]) {
            [lowMinutesArray addObject:article];
        }
        else if ([article.date containsString:@"minute"]) {
            [minuteArray insertObject:article atIndex:0];
        }
        else if ([article.date containsString:@"hours"] && article.date.length > 11) {
            [hoursArray addObject:article];
        }
        else if ([article.date containsString:@"hours"]) {
            [lowHoursArray addObject:article];
        }
        else if ([article.date containsString:@"hour"]) {
            [hourArray insertObject:article atIndex:0];
        }
        else if ([article.date containsString:@"day"]) {
            [dayArray insertObject:article atIndex:0];
        }
    }
    NSMutableArray *allDatesArray = [[NSMutableArray alloc] initWithArray:@[dayArray, hoursArray, lowHoursArray, hourArray, minutesArray, lowMinutesArray, minuteArray]];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    for (NSMutableArray *array in [allDatesArray reverseObjectEnumerator]) {
        [array sortUsingDescriptors:@[sortDescriptor]];
        for (Article *art in [array reverseObjectEnumerator]) {
            [newArray addObject:art];
        }
    }
     */
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES];
    [self.articles sortUsingDescriptors:@[sortDescriptor]];
}

#pragma mark Async Methods

//You could use AFNetworking or something similar for asynchronous downloads but I wanted to try and create my own way of asynchronous downloading with NSURLSession. The image downloads will start and stop when they enter or leave the view. The article text downloads will stop if you go back from the ArticleView before the task finishes.

-(void)downloadImageForCellAtIndex:(NSInteger)index {
    if ([imageURLSessions objectForKey:[NSNumber numberWithInteger:index]] == nil) {
        NSURLSession *imageSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
        NSURLSessionDownloadTask *imageSessionDownloadTask = [imageSession downloadTaskWithURL:[NSURL URLWithString:[[self.articles objectAtIndex:index] imageURL]]];
//        Keeping track of the download tasks to attach the image to the correct article
        [imageURLSessions setObject:imageSessionDownloadTask forKey:[NSNumber numberWithInteger:index]];
        [imageSessionDownloadTask resume];
    }
    else {
        [[imageURLSessions objectForKey:[NSNumber numberWithInteger:index]] resume];
    }
}

-(void)pauseDownloadImageForCellAtIndex:(NSInteger)index {
    [[imageURLSessions objectForKey:[NSNumber numberWithInteger:index]] suspend];
}

-(void)downloadArticleTextForArticle:(Article *)article {
    if ([textURLSessions objectForKey:[NSNumber numberWithInteger:[self.articles indexOfObject:article]]] == nil) {
        NSURL *articleTextURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://screencrush.com/restapp/site/screencrush.com/uri/%@", [article.url stringByReplacingOccurrencesOfString:@"http://screencrush.com/" withString:@""]]];
        NSURLSession *articleTextSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
        NSURLSessionDownloadTask *articleTextDownloadTask = [articleTextSession downloadTaskWithURL:articleTextURL];
//        Keeping track of the download tasks to attach the data to the correct article
        [textURLSessions setObject:articleTextDownloadTask forKey:[NSNumber numberWithInteger:[self.articles indexOfObject:article]]];
        [articleTextDownloadTask resume];
    }
    else {
        [[textURLSessions objectForKey:[NSNumber numberWithInteger:[self.articles indexOfObject:article]]] resume];
    }
}

-(void)pauseDownloadArticleTextForArticle:(Article *)article {
    [[textURLSessions objectForKey:[NSNumber numberWithInteger:[self.articles indexOfObject:article]]] suspend];
}

#pragma mark NSURLSession/DownloadTask delegate

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
//    Is it an image? If so, store it with its Article
    if ([[imageURLSessions allKeysForObject:downloadTask] count] > 0) {
        [[self.articles objectAtIndex:[[[imageURLSessions allKeysForObject:downloadTask] firstObject] integerValue]] setImageData:[NSData dataWithContentsOfURL:location]];
    }
//    Is it the text? If so, store it with its Article
    else if ([[textURLSessions allKeysForObject:downloadTask] count] > 0) {
        Article *currentArticle = [self.articles objectAtIndex:[[[textURLSessions allKeysForObject:downloadTask] firstObject] integerValue]];
        NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:[[NSData alloc] initWithContentsOfURL:location] options:0 error:nil];
        NSDictionary *articleTextDictionaries = [returnedData valueForKeyPath:@"gizmo.gizmos.single/singleGizmo.data.podContent"];
        for (NSDictionary *text in articleTextDictionaries) {
            if ([[text valueForKey:@"type"] isEqualToString:@"singlePostText"]) {
                if (currentArticle.articleText == nil) {
                    currentArticle.articleText = [[NSString alloc] init];
                }
                else if (![[text valueForKeyPath:@"data.text"] containsString:@"<strong>"]) {
                    currentArticle.articleText = [currentArticle.articleText stringByAppendingString:[text valueForKeyPath:@"data.text"]];
                }
            }
        }
    }
//    It must be a list of articles
    else {
        NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:[[NSData alloc] initWithContentsOfURL:location] options:0 error:nil];
        NSDictionary *articles = [returnedData valueForKeyPath:@"gizmo.gizmos.row-standard.data"];
        NSMutableArray *newArticles = [[NSMutableArray alloc] init];
        int i = 0;
        for (NSDictionary *dic in articles) {
            if (self.articles.count == 0) {
                [newArticles addObject:dic];
            }
            else {
                for (Article *art in self.articles) {
                    if ([[dic valueForKey:@"url"] isEqualToString:art.url]) {
                        art.date = [dic valueForKey:@"date"];
                        art.index = [NSNumber numberWithInt:i];
                        break;
                    }
                    else if (art == [self.articles lastObject]) {
                        [newArticles addObject:dic];
                    }
                    i++;
                }
            }
        }
        for (NSDictionary *dictionary in [newArticles reverseObjectEnumerator]) {
            [self createNewArticleFromDictionary:dictionary];
        }
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [self saveChanges];
    });
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    //    AlertController for errors
    if (error && ![error.localizedDescription isEqualToString:@"The request timed out."]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadError" object:self userInfo:@{@"error" : error}];
    }
    else if (!error) {
        if ([[imageURLSessions allKeysForObject:task] count] > 0) {
            [imageURLSessions removeObjectForKey:[[imageURLSessions allKeysForObject:task] objectAtIndex:0]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshImages" object:self];
        }
        else if ([[textURLSessions allKeysForObject:task] count] > 0) {
            [textURLSessions removeObjectForKey:[[textURLSessions allKeysForObject:task] objectAtIndex:0]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshArticleText" object:self];
        }
        else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshTableView" object:self];
        }
    }
}

-(void)createNewArticleFromDictionary:(NSDictionary *)dictionary {
    Article *article = (Article *)[NSEntityDescription insertNewObjectForEntityForName:@"Article" inManagedObjectContext:context];
    article.title = [dictionary valueForKey:@"title"];
//    I'm sure there is a third party library for stripping this stuff out. Seeing as it is a prototype, I'm not terribly worried about this, but I did do some of the obvious ones manually.
    article.title = [article.title stringByReplacingOccurrencesOfString:@"&mdash;" withString:@"—"];
    article.title = [article.title stringByReplacingOccurrencesOfString:@"&ndash;" withString:@"-"];
    article.title = [article.title stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    article.title = [article.title stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
    article.title = [article.title stringByReplacingOccurrencesOfString:@"&apos;" withString:@"'"];
    article.title = [article.title stringByReplacingOccurrencesOfString:@"&lsquo;" withString:@"'"];
    article.title = [article.title stringByReplacingOccurrencesOfString:@"&CloseCurlyQuote;" withString:@"'"];
    article.date = [dictionary valueForKey:@"date"];
    for (Article *art in self.articles) {
        art.index = @([art.index intValue] + 1);
    }
    article.index = [NSNumber numberWithInt:0];
    article.url = [dictionary valueForKey:@"url"];
    article.imageURL = [dictionary valueForKey:@"thumbnail_guid"];
    article.imageCaption = [dictionary valueForKey:@"thumbnail_caption"];
    NSDictionary *authorsDictionary = [dictionary valueForKey:@"authors"];
    for (NSDictionary *author in authorsDictionary) {
        if (article.author == nil) {
            article.author = [[NSString alloc] init];
        }
        article.author = [article.author stringByAppendingString:[NSString stringWithFormat:@"%@, ", [author valueForKey:@"name"]]];
    }
    //    Keep the newest article at the top and remove the oldest one
    if (self.articles.count == 10) {
        [context deleteObject:[self.articles lastObject]];
        [self.articles removeLastObject];
    }
    [self.articles insertObject:article atIndex:0];
}

@end
