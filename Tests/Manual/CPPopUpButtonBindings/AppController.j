/*
 * AppController.j
 * CPPopUpButtonBindings
 *
 * Created by You on December 2, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
@import "CPPopUpButton.j"

@implementation AppController : CPObject
{
    @outlet CPWindow mainWindow;
    CPArray people @accessors;
}

- (void)awakeFromCib
{
    [mainWindow setFullBridge:YES];

    var array = [];
    [array addObject:[CPDictionary dictionaryWithObjectsAndKeys:@"John",@"name",@"Butcher",@"job",@"john@meat.com",@"email"]];
    [array addObject:[CPDictionary dictionaryWithObjectsAndKeys:@"Alberto",@"name",@"Seller",@"job",@"alberto@gmail.com",@"email"]];
    [array addObject:[CPDictionary dictionaryWithObjectsAndKeys:@"Barack",@"name",@"President",@"job",@"barack@whitehouse.gov",@"email"]];

    [self setPeople:array];
}

@end

