//
//  Article.h
//  ScreenCrush
//
//  Created by Wesley Hovanec on 7/22/15.
//  Copyright (c) 2015 Wesley Hovanec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Article : NSManagedObject

@property (nonatomic, retain) NSString * articleText;
@property (nonatomic, retain) NSString * author;
@property (nonatomic, retain) NSString * date;
@property (nonatomic, retain) NSString * imageCaption;
@property (nonatomic, retain) NSData * imageData;
@property (nonatomic, retain) NSString * imageURL;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSNumber * index;

@end
