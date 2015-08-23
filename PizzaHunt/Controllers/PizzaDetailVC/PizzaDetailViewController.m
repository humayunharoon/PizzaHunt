//
//  PizzaDetailViewController.m
//  PizzaHunt
//
//  Created by Humayun Haroon on 23/08/2015.
//  Copyright (c) 2015 hh. All rights reserved.
//

#import "PizzaDetailViewController.h"

@interface PizzaDetailViewController ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;

@end

@implementation PizzaDetailViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self updateInfo];
}

- (void)updateInfo
{
	self.nameLabel.text = [self.venue objectForKey:@"name"];
	self.addressLabel.text = [[self.venue objectForKey:@"location"] objectForKey:@"address"];
}


@end
