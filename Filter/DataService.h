//
//  DataService.h
//  Filter
//
//  Created by Jakub Hladík on 14.11.12.
//  Copyright (c) 2012 Jakub Hladík. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataService : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

+ (DataService *)sharedService;

- (void)words:(void (^)(NSArray *))onSuccess;
- (void)wordsSorted:(void (^)(NSArray *))onSuccess;
- (void)wordsFiltered:(void (^)(NSArray *))onSuccess;

@end
