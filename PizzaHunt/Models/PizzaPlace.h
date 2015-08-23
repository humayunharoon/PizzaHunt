//
//  PizzaPlace.h
//  PizzaHunt
//
//  Created by Humayun Haroon on 23/08/2015.
//  Copyright (c) 2015 hh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface PizzaPlace : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSNumber * checkIns;

@end
