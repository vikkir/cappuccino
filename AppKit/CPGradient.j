@import <Foundation/CPObject.j>
@import <Foundation/CPArray.j>
@import <Foundation/CPException.j>

@import <AppKit/CPColor.j>
@import <AppKit/CPGraphicsContext.j>
@import <AppKit/CGGradient.j>

var CPGradientDrawingOptions;
CPGradientDrawsBeforeStartingLocation = 1 << 0;
CPGradientDrawsAfterEndingLocation = 1 << 1;

var cssVendorPrefix = nil;

@implementation CPGradient : CPObject
{
    CPArray      _colors;
    CPArray      _locations;
    CGGradient   _CGGradient;
}

- (id)initWithStartingColor:(CPColor)startingColor endingColor:(CPColor)endingColor
{
    return [self initWithColors:[startingColor, endingColor] atLocations:[0,1]];
}

- (id)initWithColors:(CPArray)colors
{
    var count = [colors count],
        locations = [CPArray array];

    for (var i = 0; i < count; i++)
    {
        var stop = i / (count - 1);
        [locations addObject:stop];
    }

    return [self initWithColors:colors atLocations:locations];
}

- (id)initWithColorsAndLocations:(CPColor)firstColor, ...
{
    var argc = arguments.length;
    if (argc % 2)
        [CPException raise:CPinvalidArgumentException reason:"A gradient needs the same number of colors and locations"];

    var colors = [CPArray array],
        locations = [CPArray array];

    for (var i = 0; i < argc; i+= 2)
    {
        [colors addObject:arguments[i]];
        [locations addObject:arguments[i+1]];
    }

    return [self initWithColors:colors atLocations:locations];
}

- (id)initWithColors:(CPArray)colors atLocations:(CPArray)locations
{
    var count = [colors count];
    if (count < 2)
        [CPException raise:CPinvalidArgumentException reason:"A gradient needs at least 2 colors and 2 locations"];

    self = [super init];
    if (self != nil)
    {
        if (count > 2 && CPBrowserIsEngine(CPInternetExplorerBrowserEngine))
        {
            CPLogConsole("This browser supports only 2 colors, extra colors ignored");
            _colors = colors.slice(0,2);
            _locations = [0, 1];
        }
        else
        {
            _colors = colors;
            _locations = locations;
        }

        _CGGradient = nil;
    }

    return self;
}

- (int)numberOfColorStops
{
    return [_locations count];
}

- (void)getColor:({CPColor})aColor location:({float})aLocation atIndex:(int)anIndex
{
    aColor = _colors[anIndex];
    aLocation = _locations[anIndex];
}

- (CGGradient)CGGradient
{
    if (_CGGradient == nil)
    {
        var count = [self numberOfColorStops],
            components = [];

        for (var i = 0; i < count; i++)
            components = components.concat([_colors[i] components]);

        _CGGradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), components, _locations, count);
    }

    return _CGGradient;
}

#pragma mark Drawing Linear Gradients

- (void)drawFromPoint:(CPPoint)startingPoint toPoint:(CPPoint)endingPoint options:(CPGradientDrawingOptions)options
{
    var context = [[CPGraphicsContext currentContext] graphicsPort];
    if (CPFeatureIsCompatible(CPHTMLCanvasFeature)) // CGContextDrawLinearGradient is broken in VML
    {
       CGContextSaveGState(context);

       var canvas = context.canvas;
       CGContextClipToRect(context, CGRectMake(0, 0, canvas.width, canvas.height));
       CGContextDrawLinearGradient(context, [self CGGradient], startingPoint, endingPoint, options);

       CGContextRestoreGState(context);
    }
}

// This is from Cocotron. Thanks Cocotron !

- (void)drawInRect:(CPRect)rect angle:(float)angle
{
    if ([_colors count] < 2 || rect.size.width == 0)
        return;

    var start,
        end,
        tanSize;

    angle = angle % 360; // fmod

    if (angle < 90)
    {
        start = CGPointMake(rect.origin.x, rect.origin.y);
        tanSize = CGPointMake(rect.size.width, rect.size.height);
    }
    else if (angle < 180)
    {
        start = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y);
        tanSize = CGPointMake(-rect.size.width, rect.size.height);
    }
    else if (angle < 270)
    {
        start = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
        tanSize = CGPointMake(-rect.size.width, -rect.size.height);
    }
    else
    {
        start = CGPointMake(rect.origin.x, rect.origin.y + rect.size.height);
        tanSize = CGPointMake(rect.size.width, -rect.size.height);
    }

    var radAngle = angle / 180 * PI;
    var distanceToEnd = COS(ATAN2(tanSize.y,tanSize.x) - radAngle) *
        SQRT(rect.size.width * rect.size.width + rect.size.height * rect.size.height);
    end = CGPointMake(COS(radAngle) * distanceToEnd + start.x, SIN(radAngle) * distanceToEnd + start.y);

    [self drawFromPoint:start toPoint:end options:0];
}

- (void)drawInBezierPath:(CPBezierPath)bezierPath angle:(CGFloat)angle
{
    CPLogConsole(_cmd + " Unimplemented method");
/*
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        rect = [bezierPath bounds]; // Unimplemented

    CGContextSaveGState(context);

    [bezierPath addClip]; // Unimplemented
    [self drawInRect:rect angle:angle];

    CGContextRestoreGState(context);
*/
}

#pragma mark Drawing Radial Gradients

- (void)drawFromCenter:(CPPoint)startCenter radius:(float)startRadius toCenter:(CPPoint)endCenter radius:(float)endRadius options:(CPGradientDrawingOptions)options
{
    var context = [[CPGraphicsContext currentContext] graphicsPort];
    if (CPFeatureIsCompatible(CPHTMLCanvasFeature)) // CGContextDrawRadialGradient unimplemented in VML
    {
       CGContextSaveGState(context);

       var canvas = context.canvas;
       CGContextClipToRect(context, CGRectMake(0, 0, canvas.width, canvas.height));
       CGContextDrawRadialGradient(context, [self CGGradient], startCenter, startRadius, endCenter, endRadius, options);

       CGContextRestoreGState(context);
    }
}

- (void)drawInRect:(CPRect)rect relativeCenterPosition:(CPPoint)relativeCenterPosition
{
    var startCenter = CGPointMake(CGRectGetWidth(rect)/2,CGRectGetHeight(rect)/2),
        endCenter = CGPointMake(startCenter.x * (relativeCenterPosition.x + 1), startCenter.y * (relativeCenterPosition.y + 1)),
        endRadius = 2 * SQRT(POW(CGRectGetWidth(rect)/2 * (ABS(relativeCenterPosition.x) + 1),2) + POW(CGRectGetHeight(rect)/2* (ABS(relativeCenterPosition.y) + 1),2));

    var context = [[CPGraphicsContext currentContext] graphicsPort];
    CGContextClipToRect(context, rect);
    [self drawFromCenter:startCenter radius:0 toCenter:endCenter radius:endRadius options:0];
}

- (void)drawInBezierPath:(CPBezierPath )bezierPath relativeCenterPosition:(CPPoint)center
{
    CPLogConsole(_cmd + " Unimplemented method");
/*
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        rect = [bezierPath bounds]; // Unimplemented

    [bezierPath addClip]; // Unimplemented
    [self drawInRect:rect relativeCenterPosition:relativeCenterPosition];
*/
}

- (CPString)_colorStops
{
    var count = _locations.length,
        result = "";

    for (var i = 0; i < count; i++)
         result+= ", " + [_colors[i] cssString] + " " + (_locations[i] * 100) + "%";

    return result;
}

- (CPString)_webkitOldColorStops
{
    var count = _locations.length,
        result = "";

    for (var i = 0; i < count; i++)
         result+= ", color-stop(" + _locations[i] + "," + [_colors[i] cssString] + ")";

    return result;
}

// TODO: This should be in CPCompatibility.j
+ (CPString)cssVendorPrefix
{
    if (cssVendorPrefix == nil)
    {
        if (CPBrowserIsEngine(CPWebKitBrowserEngine))
            cssVendorPrefix = "-webkit-"; // WebKit 535+ Safari 5.1+
        else if (CPBrowserIsEngine(CPGeckoBrowserEngine))
            cssVendorPrefix = "-moz-"; // FF 3.6+
        else if (CPBrowserIsEngine(CPOperaBrowserEngine))
            cssVendorPrefix = "-o-"; // Opera 10.11 +
        else if (CPBrowserIsEngine(CPInternetExplorerBrowserEngine))
            cssVendorPrefix = "-msie-"; // IE 10+
        else
            cssVendorPrefix = "";
    }

    return cssVendorPrefix;
}

@end

@implementation CPColor (CPGradient)

+ (CPColor)colorWithLinearGradient:(CPGradient)aGradient angle:(CPInteger)anAngle
{
    return [[CPColor alloc] _initWithLinearGradient:aGradient angle:anAngle];
}

+ (CPColor)colorWithRadialGradient:(CPGradient)aGradient center:(CGPoint)center radius:(CPInteger)radius
{
    return [[CPColor alloc] _initWithRadialGradient:aGradient center:center radius:radius];
}

- (id)_initWithLinearGradient:(CPGradient)aGradient angle:(CPInteger)anAngle
{
    var supportsGradient = CPFeatureIsCompatible(CPHTML5GradientFeature),
                    isIE = CPBrowserIsEngine(CPInternetExplorerBrowserEngine),
                isWebKit = CPBrowserIsEngine(CPWebKitBrowserEngine);

    if (!supportsGradient && !isIE && !isWebKit)
        return [self _initSolidColorForGradient:aGradient];

    self = [super init];

    if (self)
    {
        var cssString;
        if (supportsGradient)
        {
            var colorsString = [aGradient _colorStops];
            cssString = [CPGradient cssVendorPrefix] + "linear-gradient(" + anAngle + "deg" + colorsString + ")";
        }
        else
        {
            var direction = Math.round((anAngle % 360) / 90),
                colors = aGradient._colors;

            if (anAngle % 90 !== 0)
                CPLogConsole("This browser only supports ~90° gradient angles. Angle forced to " + (direction * 90) + "°.");

            if (isIE) // Supported since IE7
            {
                var gradType = (direction + 1) % 2,
                    sIndex = (direction == 1 || direction == 2) ? 1 : 0,
                    colorStops = ",startColorstr=#" + [colors[sIndex] hexString] + ", endColorstr=#" + [colors[1 - sIndex] hexString];

                cssString = "progid:DXImageTransform.Microsoft.Gradient(GradientType=" + gradType + colorStops + ")";
            }

            if (isWebKit) // Supported since Safari 3
            {
                var d = [0, 0, 0, 0],
                    colorStops = [aGradient _webkitOldColorStops];

                d[3 - (direction + 1) % 4] = 100;

                cssString = "-webkit-gradient(linear, " + d[0] + "% " + d[1] + "%, " + d[2] + "% " + d[3] + "%" + colorStops + ")";
            }
        }

        _cssString = cssString;
        _components = [0.0, 0.0, 0.0, 1.0];
        _isGradient = YES;
    }

    return self;
}

- (id)_initWithRadialGradient:(CPGradient)aGradient center:(CGPoint)center radius:(CPInteger)radius
{
    if (!CPFeatureIsCompatible(CPHTML5GradientFeature))
        return [self _initSolidColorForGradient:aGradient];

    self = [super init];

    if (self)
    {
        var colorsString = [aGradient _cssColorsString];
        _cssString = [CPGradient cssVendorPrefix] + "radial-gradient(" + center.x + "px " + center.y + "px, " + radius + "px "+ radius + "px" + colorsString + ")";
        _components = [0.0, 0.0, 0.0, 1.0];
        _isGradient = YES;
    }

    return self;
}

- (CPColor)_initSolidColorForGradient:(CPGradient)aGradient
{
    CPLogConsole("This browser does not support this type of css gradient. Using a solid color instead.");

    var colors = aGradient._colors,
        scomp = [colors[0] components],
        ecomp = [colors[1] components],
        midcomp = [];

    for (var i = 0; i < 4; i++)
    {
        var c = (scomp[i] + ecomp[i]) / 2;
        midcomp.push(c);
    }

    return [self _initWithRGBA:midcomp];
}

@end