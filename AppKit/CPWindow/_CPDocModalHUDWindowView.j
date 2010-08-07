/*
 * _CPDocModalHUDWindowView.j
 * AppKit
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */
 
var _CPHUDWindowViewBackgroundColor = nil;
    
@implementation _CPDocModalHUDWindowView : _CPWindowView
{
}

+ (void)initialize
{
    if (self != [_CPDocModalHUDWindowView class])
        return;

    if (_CPHUDWindowViewBackgroundColor == nil)
    {    
        var bundle = [CPBundle bundleForClass:[_CPHUDWindowView class]];
 
        _CPHUDWindowViewBackgroundColor = [CPColor colorWithPatternImage:[[CPNinePartImage alloc] initWithImageSlices:
        [        
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/HUD/CPWindowHUDBackground0.png"] size:CPSizeMake(7.0, 37.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/HUD/CPWindowHUDBackground1.png"] size:CPSizeMake(1.0, 37.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/HUD/CPWindowHUDBackground2.png"] size:CPSizeMake(7.0, 37.0)],
            
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/HUD/CPWindowHUDBackground3.png"] size:CPSizeMake(7.0, 1.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/HUD/CPWindowHUDBackground4.png"] size:CPSizeMake(2.0, 2.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/HUD/CPWindowHUDBackground5.png"] size:CPSizeMake(7.0, 1.0)],
            
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/HUD/CPWindowHUDBackground6.png"] size:CPSizeMake(7.0, 3.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/HUD/CPWindowHUDBackground7.png"] size:CPSizeMake(1.0, 3.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/HUD/CPWindowHUDBackground8.png"] size:CPSizeMake(7.0, 3.0)]
        ]]];
    }
}

+ (CGRect)contentRectForFrameRect:(CGRect)aFrameRect
{
    return aFrameRect;
}

+ (CGRect)frameRectForContentRect:(CGRect)aContentRect
{    
    return aContentRect;
}

- (CGRect)contentRectForFrameRect:(CGRect)aFrameRect
{    
    return aFrameRect;
}

- (CGRect)frameRectForContentRect:(CGRect)aContentRect
{    
    return aContentRect;
}

- (id)initWithFrame:(CPRect)aFrame styleMask:(unsigned)aStyleMask
{
    self = [super initWithFrame:aFrame styleMask:aStyleMask];
    
    if (self)
    {
        [self setBackgroundColor:_CPHUDWindowViewBackgroundColor];
        [self setResizeIndicatorOffset:CGSizeMake(5.0, 5.0)];
    }
    
    return self;
}

- (void)viewDidMoveToWindow
{
}

- (void)setTitle:(CPString)aTitle
{
}

- (_CPToolbarView)toolbarView
{
    return nil;
}

- (CPColor)toolbarLabelColor
{
    return nil;
}

- (CPColor)toolbarLabelShadowColor
{
    return nil;
}

- (CGSize)toolbarOffset
{
    return CGSizeMake(0.0, 0.0);
}

- (void)tile
{
    [super tile];
}

@end

