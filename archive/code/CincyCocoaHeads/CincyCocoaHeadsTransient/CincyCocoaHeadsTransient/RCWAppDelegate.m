//
//  RCWAppDelegate.m
//  CincyCocoaHeadsTransient
//
//  Created by Josh Smith on 8/16/13.
//  Copyright (c) 2013 Josh Smith. All rights reserved.
//

#import "RCWAppDelegate.h"
#import <Security/Security.h>
#import "KeychainItemWrapper.h"
#import "RCWMainViewController.h"

@interface AccountingDocument : UIManagedDocument
- (void) logMessage:(NSString *) message;
- (void) setup;
@end

@implementation AccountingDocument

- (void) logMessage:(NSString *)message {
    [self.managedObjectContext performBlock:^{
        NSManagedObject *msg = [NSEntityDescription insertNewObjectForEntityForName:@"Accounting"inManagedObjectContext:self.managedObjectContext];
        [msg setValue:message forKey:@"message"];
        [msg setValue:[NSDate date] forKey:@"when"];
    }];
}

- (void) shouldLog:(NSNotification *) note
{
    NSSet *updatedObjects = [[note userInfo] objectForKey:NSUpdatedObjectsKey];
    NSSet *deletedObjects = [[note userInfo] objectForKey:NSDeletedObjectsKey];
    NSSet *insertedObjects = [[note userInfo] objectForKey:NSInsertedObjectsKey];
    
    NSString *lmessage = [NSString stringWithFormat:@"hey, something happend %@ %@ %@",updatedObjects,
                          deletedObjects, insertedObjects];
    [self logMessage:lmessage];
}

- (void) setup {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(shouldLog:)
                   name:NSManagedObjectContextObjectsDidChangeNotification
                 object:nil];
}

@end

@implementation RCWAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (void) setupMasterKey {
    KeychainItemWrapper *w = [[KeychainItemWrapper alloc] initWithIdentifier:@"com.cincy.app" accessGroup:nil];
    NSString *s = [w objectForKey:(id)CFBridgingRelease(kSecValueData)];
    if ([s isEqualToString:@""]) {
        [w setObject:[[NSProcessInfo processInfo] globallyUniqueString] forKey:(id)CFBridgingRelease(kSecValueData)];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    RCWMainViewController *controller = (RCWMainViewController *)self.window.rootViewController;
    controller.managedObjectContext = self.managedObjectContext;
    [self setupMasterKey];
    
    NSURL *accounting = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"accountinglogs.sqlite"];
    
    AccountingDocument *adoc = [[AccountingDocument alloc] initWithFileURL:accounting];
    [adoc setup];
    [self setValue:adoc forKey:@"AccountingData"];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
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
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"CincyCocoaHeadsTransient" withExtension:@"momd"];
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSError *error = nil;

    // DATA Security
    [fm setAttributes:@{NSFileProtectionKey: NSFileProtectionComplete } ofItemAtPath:[modelURL absoluteString] error:&error];
    
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
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"CincyCocoaHeadsTransient.sqlite"];

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
    
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm setAttributes:@{ NSFileProtectionKey : NSFileProtectionComplete }
         ofItemAtPath:[storeURL path] error:&error];
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void) applicationProtectedDataDidBecomeAvailable:(UIApplication *)application {
    NSLog(@"Hey, I've got data!");
}

- (void) applicationProtectedDataWillBecomeUnavailable:(UIApplication *)application {
    NSLog(@"Danger, data will be encrypted");
}

@end
