/*
 * AppController.j
 * CPColorGradient
 *
 * Created by You on June 12, 2011.
 * Copyright 2011, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
//@import "CPGradient.j"

@implementation AppController : CPObject
{
    CPView view1;

    CPGradient gradient @accessors;

    CPInteger angle @accessors;

    float   stop1  @accessors;
    float   stop2  @accessors;
    float   stop3  @accessors;

    CPColor color1 @accessors;
    CPColor color2 @accessors;
    CPColor color3 @accessors;
}

+ (CPSet)keyPathsForValuesAffectingValueForKey:(CPString)aKey
{
    if (aKey == @"gradient")
        return [CPSet setWithObjects:@"stop1", @"stop2",@"stop3",@"color1",@"color2",@"color3",@"angle"];

    return [CPSet set];
}

- (CPGradient)gradient
{
    return [[CPGradient alloc] initWithColors:[color1, color2, color3] atLocations:[stop1, stop2, stop3]];
}

- (id)init
{
    if (self = [super init])
    {
        color1 = [CPColor redColor];
        color2 = [CPColor blueColor];
        color3 = [CPColor whiteColor];

        stop1 = 0;
        stop2 = 0.5;
        stop3 = 1;

        [self addObserver:self forKeyPath:@"gradient" options:0 context:@"Gradient"];
    }

    return self;
}

- (void)awakeFromCib
{
    [self setAngle:180];
}

- (void)observeValueForKeyPath:(id)keyPath ofObject:(id)object change:(id)change context:(id)context
{
    if (context != @"Gradient")
        return;

//  var rgcolor = [CPColor colorWithRadialGradient:gradient center:CGPointMake(220,220) radius:100];
    var lgcolor = [CPColor colorWithLinearGradient:[self gradient] angle:angle];
    [view1 setBackgroundColor:lgcolor];
}

- (void)setAngle:(int)anAngle
{
    angle = ROUND(anAngle);
}

@end

@implementation CPColorWell (objectValue)

- (id)objectValue
{
    return [self color];
}

- (id)setObjectValue:(id)aValue
{
    [self setColor:aValue];
}

@end