//
//  MasterViewController.h
//  Filter
//
//  Created by Jakub Hladík on 14.11.12.
//  Copyright (c) 2012 Jakub Hladík. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreData/CoreData.h>

@interface MasterViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
