//
//  DataService.m
//  Filter
//
//  Created by Jakub Hladík on 14.11.12.
//  Copyright (c) 2012 Jakub Hladík. All rights reserved.
//

#import "DataService.h"
#import "Word.h"

@implementation DataService

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

+ (DataService *)sharedService
{
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[DataService alloc] init];
    });
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)setup
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"my_awesome_wordlist" ofType:nil];
    NSError *error;
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:&error];
    
    NSArray *rawWordArray = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    NSMutableArray *wordArray = [NSMutableArray array];
    for (NSString *word in rawWordArray) {
        NSString *trimmedWord = [word stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        [wordArray addObject:trimmedWord];
    }
    
    [self insertWordsFromArray:wordArray];
}

- (void)insertWordsFromArray:(NSArray *)anArray
{
    NSUInteger counter = 0;
    for (NSString *word in anArray) {
        
        Word *newWord = [NSEntityDescription insertNewObjectForEntityForName:[[Word class] description]
                                      inManagedObjectContext:self.managedObjectContext];
        newWord.title = word;
        [self saveContext];
        
        counter++;
        if (counter > 10) {
            break;
        }
    }
}

- (void)words:(void (^)(NSArray *))onSuccess
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[[Word class] description]];
    NSError *error;
    NSArray *fetchedArray = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if (!error && onSuccess) {
        onSuccess(fetchedArray);
    }
}

- (void)wordsSorted:(void (^)(NSArray *))onSuccess
{
    NSMutableArray *array = [NSMutableArray array];
    __block NSMutableArray *blockArray = array;
    [self words:^(NSArray *anArray) {
        [blockArray addObjectsFromArray:anArray];
    }];

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title"
                                                                     ascending:YES
                                                                    comparator:^NSComparisonResult(id obj1, id obj2) {
      return [((NSString *)obj1) compare:obj2];
    }];
    
    NSArray *sortedArray = [array sortedArrayUsingDescriptors:@[ sortDescriptor ]];

    if (onSuccess) {
        onSuccess(sortedArray);
    }
}

- (void)wordsFiltered:(void (^)(NSArray *))onSuccess
{
    NSMutableArray *array = [NSMutableArray array];
    __block NSMutableArray *blockArray = array;
    [self words:^(NSArray *anArray) {
        [blockArray addObjectsFromArray:anArray];
    }];
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        if ([evaluatedObject isKindOfClass:[Word class]]) {
            NSUInteger length = ((Word *)evaluatedObject).title.length;
            return length > 5;
        }
        
        return NO;
    }];
    
    NSArray *filteredArray = [array filteredArrayUsingPredicate:predicate];
    
    if (onSuccess) {
        onSuccess(filteredArray);
    }
}

- (void)async
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSManagedObjectContext *asyncContext = [[NSManagedObjectContext alloc] init];
        asyncContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    });
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Filter" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Filter.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


@end
