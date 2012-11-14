//
//  DetailViewController.h
//  Filter
//
//  Created by Jakub Hladík on 14.11.12.
//  Copyright (c) 2012 Jakub Hladík. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
