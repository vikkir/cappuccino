/*
 * AppController.j
 * CPDatePicker
 *
 * Created by cacaodev on April 12, 2010.
 * Copyright 2010, cacaodev All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <AppKit/CPDatePicker.j>

@import "CPViewAnimationTransition.j"

@implementation AppController : CPObject
{
    CPDatePicker    picker;
    CPPopUpButton   validationPopUp;
    CPTextField     dateField;
    CPTextField     intervalField;
    CPButton        minButton;
    CPButton        maxButton;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    picker = [[DatePicker alloc] initWithFrame:CGRectMake(250, 0, 256, 184)];
    [picker setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
    [picker setDelegate:self];
    [picker setTarget:self];
    [picker setAnimate:NO];
    [picker setAction:@selector(updateDescription:)];
    //[picker setDateValue:nil];
    [contentView addSubview:picker];

    var animateBox = [[CPCheckBox alloc] initWithFrame:CGRectMake(550,10,200,22)];
    [animateBox setTitle:@"Animate"];
    [animateBox setAction:@selector(animatePicker:)];
    [animateBox setTarget:self];
    [contentView addSubview:animateBox];

    var modePopUp = [[CPPopUpButton alloc] initWithFrame:CGRectMake(550,40,150,24)];
    [modePopUp addItemWithTitle:@"CPSingleDateMode"];
    [modePopUp addItemWithTitle:@"CPRangeDateMode"];
    [modePopUp setAction:@selector(setMode:)];
    [modePopUp setTarget:self];
    [contentView addSubview:modePopUp];
    
    validationPopUp = [[CPPopUpButton alloc] initWithFrame:CGRectMake(550,80,150,24)];
    [validationPopUp addItemWithTitle:@"Select Any Day"];
    [validationPopUp addItemWithTitle:@"Select Week Days"];
    [validationPopUp addItemWithTitle:@"Select Week-End"];
    [validationPopUp setTarget:self];
    [validationPopUp setAction:@selector(didSelectValidation:)];
    [contentView addSubview:validationPopUp];

    minButton = [[CPButton alloc] initWithFrame:CGRectMake(550,120,100,24)];
    [minButton setTitle:@"Set Min Date"];
    [minButton setAction:@selector(setMinDate:)];
    [minButton setTarget:self];
    [contentView addSubview:minButton];

    maxButton = [[CPButton alloc] initWithFrame:CGRectMake(670,120,100,24)];
    [maxButton setTitle:@"Set Max Date"];
    [maxButton setAction:@selector(setMaxDate:)];
    [maxButton setTarget:self];
    [contentView addSubview:maxButton];

    var resetButton = [[CPButton alloc] initWithFrame:CGRectMake(790,120,100,24)];
    [resetButton setTitle:@"Reset"];
    [resetButton setAction:@selector(resetMinMaxDate:)];
    [resetButton setTarget:self];
    [contentView addSubview:resetButton];

    dateField = [[CPTextField alloc] initWithFrame:CGRectMake(550,150,300,24)];
    [dateField setPlaceholderString:@"Date Value"];
    [dateField setFont:[CPFont boldSystemFontOfSize:13]];
    [contentView addSubview:dateField];

    intervalField = [[CPTextField alloc] initWithFrame:CGRectMake(550,170,300,24)];
    [intervalField setPlaceholderString:@"Time Interval"];
    [intervalField setFont:[CPFont boldSystemFontOfSize:13]];
    [contentView addSubview:intervalField];
    
    [theWindow makeFirstResponder:picker];
    [theWindow orderFront:self];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

- (void)animatePicker:(id)sender
{
    [picker setAnimate:[sender state]];
}

- (void)setMode:(id)sender
{
    [picker setDatePickerMode:[sender indexOfSelectedItem]];
}

- (void)setMinDate:(id)sender
{
    [picker setMinDate:[picker dateValue]];
    [sender setEnabled:NO];
}

- (void)setMaxDate:(id)sender
{
    [picker setMaxDate:[picker dateValue]];
    [sender setEnabled:NO];
}

- (void)resetMinMaxDate:(id)sender
{
    [picker setMinDate:[CPDate distantPast]];
    [picker setMaxDate:[CPDate distantFuture]];
    [minButton setEnabled:YES];
    [maxButton setEnabled:YES];
}

- (void)updateDescription:(id)sender
{
    [dateField setStringValue:@"Date: " + [[picker dateValue] description]];
    [intervalField setStringValue:@"Time interval: " + [picker timeInterval] + "s (" + ([picker timeInterval]/3600/24) + " days)"];
}

- (void)didSelectValidation:(id)sender
{
    [picker setDateValue:nil];
}

- (void)datePicker:(CPDatePicker)aDatePickerCell validateProposedDateValue:(Function)proposedDateValue timeInterval:(Function)proposedTimeInterval
{
    var oldDate = proposedDateValue(),
        type = [validationPopUp indexOfSelectedItem],
        newDate,
        newInterval;
    
    switch (type)
    {
        case 0: break;
        case 1: newDate = new Date(oldDate.getTime() - ((oldDate.getDay() - 1) * 86400000));
                newInterval = 3600 * 24 *4;
                break;                
        case 2: newDate = new Date(oldDate.getTime() - ((oldDate.getDay() - 6) * 86400000))
                newInterval = 3600 * 24 *1;
                break;                
    }
    
    proposedDateValue(newDate);
    proposedTimeInterval(newInterval);
}

@end

@implementation DatePicker : CPDatePicker
{
}

+ (Class)animationClass
{
    if (!CPBrowserIsEngine(CPWebKitBrowserEngine))
        return [CPViewAnimation class];
    
    return [CPViewAnimationTransition class];
}

@end