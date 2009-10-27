/*
 * AppController.j
 * test
 *
 * Created by cacaodev.
 * Copyright 2008. All rights reserved.
 */

@import <Foundation/CPObject.j>

@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
	var startColor = [CPColor randomColor];
	var endColor = [CPColor randomColor];

	var count = 4;
	while(count--)
	{
	    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(50 + (3 -count)*250,50 + ((count+1) % 2)*200,400,400) styleMask:CPTitledWindowMask|CPResizableWindowMask];
	    var contentView = [theWindow contentView];
	    var bounds = [contentView bounds];

		var gradientView = [[CanvasGradientView alloc] initWithFrame:CGRectMake(10, 10, CPRectGetWidth(bounds) - 20, CPRectGetHeight(bounds) - 20) startColor:startColor endColor:endColor];
		[gradientView setTag:count];

	    [gradientView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
	    [contentView addSubview:gradientView];

	    [theWindow orderFront:self];
    }
}

@end


@implementation CanvasGradientView : CPView
{
	CPGradient gradient;
}

- (id)initWithFrame:(CGRect)frame startColor:(CPColor)startColor endColor:(CPColor)endColor
{
	self = [super initWithFrame:frame];
	if (self)
	{
		gradient = [[CPGradient alloc] initWithStartingColor:startColor endingColor:endColor];
	}

	return self;
}

- (void)drawRect:(CGRect)rect
{
	switch ([self tag])
	{
		case 0 : [gradient drawInRect:rect angle:45];
		          break;

		case 1 : [gradient drawFromPoint:CGPointMake(0,0) toPoint:CGPointMake(0,rect.size.height) options:0];
		          break;

		case 2 : [gradient drawInRect:rect relativeCenterPosition:CGPointMake(0,0)];
		          break;

		case 3 : var center = CGPointMake(CGRectGetWidth(rect)/2,CGRectGetHeight(rect)/2);
				 [gradient drawFromCenter:center radius:0 toCenter:center radius:100 options:0];
                  break;

		default : break;
	}

//  BEZIER PATH (NOT FULLY IMPLEMENTED)
//	[gradient drawInBezierPath:[CPBezierPath bezierPathWithOvalInRect:rect] angle:40];
//	[gradient drawInBezierPath:[CPBezierPath bezierPathWithOvalInRect:rect] relativeCenterPosition:CGPointMake(0,0)];
}

@end

