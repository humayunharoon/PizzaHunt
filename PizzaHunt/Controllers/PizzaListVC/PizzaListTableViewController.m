//
//  PizzaListTableViewController.m
//  PizzaHunt
//
//  Created by Humayun Haroon on 23/08/2015.
//  Copyright (c) 2015 hh. All rights reserved.
//

#import "PizzaListTableViewController.h"
#import <MBProgressHUD.h>
#import <Foursquare2.h>
#import <INTULocationManager.h>
#import "PizzaPlaceListTableViewCell.h"
#import "PizzaDetailViewController.h"
#import "PizzaPlace.h"
#import "AppDelegate.h"

@interface PizzaListTableViewController ()

@property (strong, nonatomic) NSArray *arrayOfVenues;

@end

@implementation PizzaListTableViewController

#pragma mark - View Lifecycle

- (void)initialSetup
{
	// Load Xib
	UINib *nib = [UINib nibWithNibName:@"PizzaPlaceListTableViewCell" bundle:nil];
	[self.tableView registerNib:nib forCellReuseIdentifier:@"PizzaListCellIdentifier"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	[self initialSetup];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataSavedNotificationReceiver) name:@"CoreDataDetailsUpdated" object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self determineUserLocationAndSearchForPizzaPlaces];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dataSavedNotificationReceiver
{
	NSLog(@"Notification Received");
	
	// prints all the venues stored in core data
	
	NSError *error;
	NSManagedObjectContext *context = ((AppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext;
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"PizzaPlace"
											  inManagedObjectContext:context];
	[fetchRequest setEntity:entity];
	NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
	
	for (PizzaPlace *venue in fetchedObjects) {
		NSLog(@"Core Data Saved Venue: %@ - %@", venue.name, venue.checkIns);
	}
}



#pragma mark - Persistence

- (void)saveDownloadedData
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		
		NSPersistentStoreCoordinator *storeCoordinator = ((AppDelegate *)[[UIApplication sharedApplication] delegate]).persistentStoreCoordinator;
	
		NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] init];
		[managedObjectContext setPersistentStoreCoordinator:storeCoordinator];
		
		for (NSDictionary *venueDictionary in self.arrayOfVenues) {
			
			PizzaPlace *pizzaPlace = [NSEntityDescription insertNewObjectForEntityForName:@"PizzaPlace" inManagedObjectContext:managedObjectContext];
			pizzaPlace.name = [venueDictionary objectForKey:@"name"];
			pizzaPlace.address = [[venueDictionary objectForKey:@"location"] objectForKey:@"address"];
			pizzaPlace.checkIns = [[venueDictionary objectForKey:@"stats"] objectForKey:@"checkinsCount"];
		}
		
		NSError *error;
		if (![managedObjectContext save:&error]) {
			NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
		} else {
			NSLog(@"Data Saved");
			
			dispatch_async(dispatch_get_main_queue(), ^{
				
				// this is posted on the main thead, so any listeners registered on the main thread can catch this
				// and incase UI needs to be updated do that as well.
				[[NSNotificationCenter defaultCenter] postNotificationName:@"CoreDataDetailsUpdated" object:nil];
				
				
			});
			
		}
		
	});
	
	
}

#pragma mark - Location 

- (void)determineUserLocationAndSearchForPizzaPlaces
{
	[MBProgressHUD showHUDAddedTo:self.view animated:YES].labelText = @"Determining Location";
	
	INTULocationManager *locMgr = [INTULocationManager sharedInstance];
	[locMgr requestLocationWithDesiredAccuracy:INTULocationAccuracyNeighborhood
									   timeout:10.0
						  delayUntilAuthorized:YES
										 block:^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
											 if (status == INTULocationStatusSuccess) {
												 [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
												 [self fetchNearbyPizzaPlacesAtLocation:currentLocation];
											 }
											 else if (status == INTULocationStatusTimedOut) {
												 NSLog(@"Oops user location not found");
												 // handle error
											 }
											 else {
												 NSLog(@"Location error");
												 // handle error
												 
												 // the reason for this ugly loop is, when testing with the GPX file
												 // if you dont set it on the simulator immediately, location search will fail.
												 // so you can comfortably set the provided GPX file and it'll then fetch location data and proceed
												 
												 // this would never be done in a real world scenario
												 
												 [self determineUserLocationAndSearchForPizzaPlaces];
											 }
										 }];
}

#pragma mark - Network Foursquare

- (void)fetchNearbyPizzaPlacesAtLocation:(CLLocation *)currentLocation
{
	[MBProgressHUD showHUDAddedTo:self.view animated:YES].labelText = @"Looking for Pizzas";
	
	[Foursquare2 venueSearchNearByLatitude:[NSNumber numberWithFloat:currentLocation.coordinate.latitude] longitude:[NSNumber numberWithFloat:currentLocation.coordinate.longitude] query:nil limit:@5 intent:intentBrowse radius:@5000 categoryId:@"4bf58dd8d48988d1ca941735" callback:^(BOOL success, id result) {
		
		[MBProgressHUD hideHUDForView:self.view animated:YES];
		NSArray *venues = result[@"response"][@"venues"];
		
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
		NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
		self.arrayOfVenues = [venues sortedArrayUsingDescriptors:sortDescriptors];
		
		[self.tableView reloadData];
		[self saveDownloadedData];
		
	}];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.arrayOfVenues.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	PizzaPlaceListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PizzaListCellIdentifier" forIndexPath:indexPath];
	
	NSDictionary *venue = [self.arrayOfVenues objectAtIndex:indexPath.row];
    
	cell.pizzaPlaceNameLabel.text = venue[@"name"];
	cell.checkInsCountLabel.text = [NSString stringWithFormat:@"Check Ins: %@", venue[@"stats"][@"checkinsCount"]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	PizzaDetailViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"PizzaDetailVCIdentifier"];
	controller.venue = [self.arrayOfVenues objectAtIndex:indexPath.row];
	
	[self.navigationController pushViewController:controller animated:YES];
}

@end
