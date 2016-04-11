//
//  CustomTableViewCell.h
//  ScreenCrush
//
//  Created by Wesley Hovanec on 7/7/15.
//  Copyright (c) 2015 Wesley Hovanec. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *customImageView;
@property (weak, nonatomic) IBOutlet UILabel *customTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *customDateLabel;

@end
