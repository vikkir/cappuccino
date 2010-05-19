/*
 * CPDatePicker.j
 * AppKit
 *
 * Created by cacaodev on April 12, 2010.
 *
 * The MIT License
 *
 * Copyright (c) 2010 cacaodev
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

@import <AppKit/CPControl.j>
@import <AppKit/CGGradient.j>

var CPSingleDateMode = 0,
    CPRangeDateMode = 1;
    
var CPTextFieldAndStepperDatePickerStyle = 0,
    CPClockAndCalendarDatePickerStyle = 1,
    CPTextFieldDatePickerStyle = 2;
    
var CPHourMinuteDatePickerElementFlag       = 0x000c,
    CPHourMinuteSecondDatePickerElementFlag = 0x000e,
    CPTimeZoneDatePickerElementFlag         = 0x0010,
    CPYearMonthDatePickerElementFlag        = 0x00c0,
    CPYearMonthDayDatePickerElementFlag     = 0x00e0,
    CPEraDatePickerElementFlag              = 0x0100;

var HEADER_HEIGHT = 37.0;

var _monthNames = [@"January", @"February", @"March", @"April", @"May", @"June", @"July", @"August", @"September", @"October", @"November", @"December"],
    _dayNamesShort = [@"mon", @"tue", @"wed", @"thu", @"fri", @"sat", @"sun"],
    _dayNamesShortUS = [@"sun", @"mon", @"tue", @"wed", @"thu", @"fri", @"sat"];

var firstWeekdayIsMonday = nil;

@implementation CPDate (CPDatePickerAdditions)

+ (CPDate)dateWithTimeInterval:(CPInteger)aTimeInterval sinceDate:(CPDate)aDate
{
    return [[self alloc] initWithTimeInterval:aTimeInterval sinceDate:aDate];
}

- (int)daysInMonth
{
    return 32 - new Date(self.getFullYear(), self.getMonth(), 32).getDate();
}

- (int)monthInYear
{
    return self.getMonth();
}

- (void)resetToMidnight
{
    self.setHours(12);
    self.setMinutes(0);
    self.setSeconds(0);
    self.setMilliseconds(0);
}

- (void)resetToFirstDay
{
    [self resetToMidnight];
    self.setDate(1);
}

@end

@implementation CPDatePicker : CPControl
{
// @private
    CPView      headerView @accessors(readonly);
    CPView      holderView;    
    CPView      currentMonthView;

// @public
    id          _delegate @accessors(property=delegate);
    CPColor     _backgroundColor @accessors(property=backgroundColor);
    CPColor     _textColor @accessors(property=textColor);
    CPInteger   _timeInterval;
    CPInteger   _datePickerMode @accessors(property=datePickerMode);
    CPDate      _minDate @accessors(property=minDate);
    CPDate      _maxDate @accessors(property=maxDate);

    CPInteger   startSelectionIndex;
    CPInteger   currentSelectionIndex;
    CPArray     slideViews;
    CPViewAnimation viewAnimation @accessors;
    BOOL        animate @accessors;

/*
    CPInteger   _datePickerStyle @accessors(property=datePickerStyle);
    CPInteger   _datePickerElements @accessors(property=datePickerElements);
    BOOL        _bezeled @accessors(getter=isBezeled, setter=setBezeled:);
    BOOL        _bordered @accessors(getter=isBordered, setter=setBordered:);
    BOOL        _drawsBackground @accessors(property=drawsBackground);
    CPCalendar  _calendar @accessors(property=calendar);
    CPLocale    _locale @accessors(propery=locale);
    CPTimeZone  _timeZone @accessors(property=timeZone);
*/
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        _datePickerMode = CPSingleDateMode;
//        _datePickerStyle = CPClockAndCalendarDatePickerStyle;
//        _datePickerElements = CPYearMonthDayDatePickerElementFlag;
        _timeInterval = 0;
        _minDate = [CPDate distantPast];
        _maxDate = [CPDate distantFuture];
        animate = YES;

        var bounds = [self bounds];

        headerView = [[_CPDatePickerHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(bounds), HEADER_HEIGHT) datePicker:self];
        [headerView setAutoresizingMask:CPViewWidthSizable];
        [self addSubview:headerView];

        holderView = [[CPView alloc] initWithFrame:CGRectMake(0, HEADER_HEIGHT, CGRectGetWidth(bounds), CGRectGetHeight(bounds) - HEADER_HEIGHT)];
        [holderView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

        slideViews = [CPArray array];
        var viewFrame = [holderView bounds];
        for (var i = 0; i < 3; i++)
        {
            viewFrame.origin.y = CGRectGetHeight(viewFrame) * (i - 1);
            var monthView = [[_CPDatePickerMonthView alloc] initWithFrame:viewFrame datePicker:self];
            [monthView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
            [holderView addSubview:monthView];
            [slideViews addObject:monthView];
        }
        
        currentMonthView = slideViews[1];
        [self addSubview:holderView];

        viewAnimation = [[[CPDatePicker animationClass] alloc] initWithDuration:0.6 animationCurve:CPAnimationEaseInOut];
        [viewAnimation setDelegate:self];

        // Default to today's date.
        [self setDateValue:[CPDate date]];
        //[self _updateCachedMonths];

        [self setNeedsLayout];
    }

    return self;
}

+ (BOOL)firstWeekdayIsMonday
{
    if (firstWeekdayIsMonday == nil)
        firstWeekdayIsMonday = navigator.language.indexOf("en") === CPNotFound;

    return firstWeekdayIsMonday;
}

+ (Class)animationClass
{
    return [CPViewAnimation class];
}

- (BOOL)becomeFirstResponder
{
    return YES;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

// Manage UI Events
- (void)mouseDown:(CPEvent)anEvent
{
    var tileIndex = [currentMonthView indexOfTileForEvent:anEvent],
        startDate = [[[currentMonthView dayTiles] objectAtIndex:tileIndex] date],
        timeInterval = 0,
        dateValue;

    startSelectionIndex = tileIndex;   

    if ([self  shouldSelectRange] && (dateValue = [self dateValue]))
    {
        timeInterval = [startDate timeIntervalSinceDate:dateValue];
        startDate = dateValue;
    }

    [self _setDateValue:startDate timeInterval:timeInterval];
}

- (void)setObjectValue:(id)value
{
    [self setDateValue:value];    
}

- (void)mouseUp:(CPEvent)anEvent
{
    currentSelectionIndex = nil;
    [self _sendAction];
}

- (BOOL)shouldSelectRange
{
    return (_datePickerMode == CPRangeDateMode && [[CPApp currentEvent] modifierFlags] & CPShiftKeyMask);
}

- (void)mouseDragged:(CPEvent)anEvent
{
    var tileIndex = [currentMonthView indexOfTileForEvent:anEvent];

    if (currentSelectionIndex == tileIndex)
        return;

    currentSelectionIndex = tileIndex;

    if (_datePickerMode == CPSingleDateMode)
        startSelectionIndex = currentSelectionIndex;

    [self _setDateValueFromIndex:startSelectionIndex toIndex:currentSelectionIndex];
}

- (void)keyDown:(CPEvent)anEvent
{
    [self interpretKeyEvents:[CPArray arrayWithObject:anEvent]];
}

- (void)moveDown:(id)sender
{
    [self moveByDays:7];
}

- (void)moveUp:(id)sender
{
    [self moveByDays:-7];
}

- (void)moveRight:(id)sender
{
    [self moveByDays:1];
}

- (void)moveLeft:(id)sender
{
    [self moveByDays:-1];
}

- (void)moveByDays:(CPInteger)days
{
    var ti = 3600*24*days;

    if ([self  shouldSelectRange])
        [self setTimeInterval:[self timeInterval] + ti];
    else
        [self setDateValue:[CPDate dateWithTimeInterval:ti sinceDate:[self dateValue]]];

    [self _sendAction];
}

- (void)_displayMonth:(CPDate)aMonthDate selectedDate:(CPDate)aSelectedDate
{
    var monthDate = [aMonthDate copy];
    [monthDate resetToFirstDay];

    if ([[currentMonthView date] isEqual:monthDate])
    {
        [currentMonthView _selectDate:aSelectedDate timeInterval:_timeInterval];
        return;
    }

    if (animate && [monthDate isEqual:[currentMonthView previousMonth]])
        [self _slideMonthWithDirection:-1  selectedDate:aSelectedDate];
    else if (animate && [monthDate isEqual:[currentMonthView nextMonth]])
        [self _slideMonthWithDirection:1  selectedDate:aSelectedDate];
    else
    {
        [currentMonthView setMonthForDate:monthDate];
        [self _updateCachedMonths];
        [currentMonthView _selectDate:aSelectedDate timeInterval:_timeInterval];
    }

    [headerView setMonthForDate:monthDate];
}

- (void)_slideMonthWithDirection:(CPInteger)direction selectedDate:(CPDate)aDate
{
    if ([viewAnimation isAnimating])
        return;

    // Set date on the current month
    [currentMonthView _selectDate:aDate timeInterval:_timeInterval];

    rotate(slideViews, - direction);
    // Set date on the to be exposed month
    [slideViews[1] _selectDate:aDate timeInterval:_timeInterval];
    
    var anims = [CPArray array],
        VIEW_HEIGHT = CGRectGetHeight([currentMonthView bounds]),
        startIndex = (2 + direction) % 3,
        anims = [CPArray array];
    
    for (var i = startIndex; i < startIndex + 2; i++)
    {
        var view = slideViews[i],
            startFrame = [view frame],
            endFrame = CGRectMakeCopy(startFrame);
            endFrame.origin.y = (i - 1)* VIEW_HEIGHT;

        var anim = [CPDictionary dictionaryWithObjectsAndKeys:view, CPViewAnimationTargetKey, startFrame, CPViewAnimationStartFrameKey, endFrame, CPViewAnimationEndFrameKey];

        [anims addObject:anim];
    }

    [viewAnimation setViewAnimations:anims];
    [viewAnimation startAnimation];
}

- (void)animationDidEnd:(CPAnimation)animation
{
    var VIEW_HEIGHT = CGRectGetHeight([currentMonthView bounds]),
        count = [slideViews count];

    while(count--)
        [slideViews[count] setFrameOrigin:CGPointMake(0, (count - 1) * VIEW_HEIGHT)];
    
    [self _updateCachedMonths];
}

- (void)_slideMonth:(id)sender
{
    var direction = [sender tag],
        current = slideViews[1],
        date = (direction == -1) ? [current previousMonth]:[current nextMonth];

    [self _displayMonth:date selectedDate:[self dateValue]];
}

- (void)_updateCachedMonths
{
    currentMonthView = slideViews[1];

    var previousMonthView = slideViews[0],
        nextMonthView = slideViews[2];

    [previousMonthView setMonthForDate:[currentMonthView previousMonth]];
    [previousMonthView _selectDate:nil timeInterval:0];

    [nextMonthView setMonthForDate:[currentMonthView nextMonth]];
    [nextMonthView _selectDate:nil timeInterval:0];
}

- (void)_setDateValue:(CPDate)aStartDate timeInterval:(CPInteger)aTimeInterval
{
    aStartDate = new Date(MIN(MAX(aStartDate, _minDate), _maxDate));
    aTimeInterval = MAX(MIN(aTimeInterval, [_maxDate timeIntervalSinceDate:aStartDate]), [_minDate timeIntervalSinceDate:aStartDate]);

    if (_delegate && [_delegate respondsToSelector:@selector(datePicker:validateProposedDateValue:timeInterval:)])
    {
        // constrain timeInterval also
        var aStartDateRef = function ref(x){if (typeof x == 'undefined') return aStartDate; aStartDate = x;}
        var aTimeIntervalRef = function ref(x){if (typeof x == 'undefined') return aTimeInterval; aTimeInterval = x;}

        [_delegate datePicker:self validateProposedDateValue:aStartDateRef timeInterval:aTimeIntervalRef];
    }

    [super setObjectValue:aStartDate];
    _timeInterval = (_datePickerMode == CPSingleDateMode)? 0 : aTimeInterval;
    
    [self _displayMonth:aStartDate selectedDate:aStartDate];
}

- (void)_setDateValueFromIndex:(CPInteger)startIndex toIndex:(CPInteger)endIndex
{
    var dayTiles = [currentMonthView dayTiles],
        startDate = [dayTiles[startIndex] date],
        endDate = [dayTiles[endIndex] date],
        timeInterval = [endDate timeIntervalSinceDate:startDate];

    [self _setDateValue:startDate timeInterval:timeInterval];
}

- (void)setDateValue:(CPDate)aDate
{
    if (aDate == nil)
        return;

    [self _setDateValue:aDate timeInterval:_timeInterval];
}

- (CPDate)dateValue
{
    return [super objectValue];
}

- (void)setTimeInterval:(CPInteger)timeInterval
{
    if (_datePickerMode == CPSingleDateMode)
        return;

    [self _setDateValue:[self dateValue] timeInterval:timeInterval];
}

- (CPInteger)timeInterval
{
    return _timeInterval;
}

- (void)_sendAction
{
    var action = [self action],
        target = [self target];

    if (action && target)
        [self sendAction:action to:target];
}

@end

var WEEKDAY_LABEL_HEIGHT  = 20,
    WEEKDAY_LABEL_OFFSET = 20;

@implementation _CPDatePickerHeaderView : CPControl
{
    CPTextField title;
    CPControl   previousControl @accessors(readonly);
    CPControl   nextControl @accessors(readonly);
    CPArray     dayLabels;

    CGGradient  _headerGradient;
}

- (id)initWithFrame:(CGRect)aFrame datePicker:(CPDatePicker)datePicker
{
    if (self = [super initWithFrame:aFrame])
    {
        title = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
        [title setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin];
        [title setFont:[CPFont boldSystemFontOfSize:12.0]];
        [title setTextColor:[CPColor colorWithWhite:0.15 alpha:1]];
        [title setTextShadowColor:[CPColor whiteColor]];
        [title setTextShadowOffset:CGSizeMake(0.0, 1.0)];

        [self addSubview:title];

        previousControl = [[_CPDatePickerHeaderArrowControl alloc] initWithFrame:CGRectMake(10, 9, 10, 10)];
        [previousControl setDirection:-1];
        [previousControl setAutoresizingMask:CPViewMaxXMargin];
        [self addSubview:previousControl];

        nextControl = [[_CPDatePickerHeaderArrowControl alloc] initWithFrame:CGRectMake(CGRectGetMaxX([self bounds]) - 21, 9, 10, 10)];
        [nextControl setDirection:1];
        [nextControl setAutoresizingMask:CPViewMinXMargin];
        [self addSubview:nextControl];

        [previousControl setTarget:datePicker];
        [previousControl setAction:@selector(_slideMonth:)];

        [nextControl setTarget:datePicker];
        [nextControl setAction:@selector(_slideMonth:)];

        dayLabels = [CPArray array];
        var dayNames = ([CPDatePicker firstWeekdayIsMonday]) ? _dayNamesShort : _dayNamesShortUS;

        for (var i = 0; i < [dayNames count]; i++)
        {
            var label = [_CPDatePickerLabel labelWithTitle:[dayNames objectAtIndex:i]];
            [dayLabels addObject:label];
            [self addSubview:label];
        }

        _headerGradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), [238.0/255.0, 241.0/255.0, 244.0/255.0, 1.0, 219.0/255.0, 225.0/255.0, 231.0/255.0, 1.0], [0, 1], 2);

        [self setNeedsLayout];
    }

    return self;
}

- (void)setMonthForDate:(CPDate)aDate
{
    [title setStringValue:[CPString stringWithFormat:@"%s %i", _monthNames[aDate.getUTCMonth()], aDate.getUTCFullYear()]];
    [title sizeToFit];
    [title setCenter:CGPointMake(CGRectGetMidX([self bounds]), 13)];
}

- (void)layoutSubviews
{
    var bounds = [self bounds],
        width = CGRectGetWidth(bounds);
            
    // Arrows
    var buttonOrigin = CGSizeMake(5,5);
    [previousControl setFrameOrigin:CGPointMake(buttonOrigin.width + 5, buttonOrigin.height)];
    [nextControl setFrameOrigin:CGPointMake(width - 16 - buttonOrigin.width - 5, buttonOrigin.height)];

    // Weekday label
    var numberOfLabels = [dayLabels count],
        labelWidth = width / numberOfLabels;

    for (var i = 0; i < numberOfLabels; i++)
        [dayLabels[i] setFrame:CGRectMake(i * labelWidth, WEEKDAY_LABEL_OFFSET, labelWidth, WEEKDAY_LABEL_HEIGHT)];
}

- (void)drawRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        rect = [self bounds],
        minX = CGRectGetMinX(rect),
        maxY = CGRectGetHeight(rect);

    CGContextAddRect(context, rect);
    CGContextDrawLinearGradient(context, _headerGradient, CGPointMake(0, 0), CGPointMake(0, maxY), 0);

    [[CPColor colorWithCalibratedRed:161/255 green:171/255 blue:186/255 alpha:1] setStroke];
    var path = [CPBezierPath bezierPath];
    [path setLineWidth:0.5];
    [path moveToPoint:CGPointMake(0, maxY)];
    [path lineToPoint:CGPointMake(CGRectGetMaxX(rect), maxY)];
    [path closePath];
    [path stroke];

    CGContextTranslateCTM(context, 0, 1);
    [[CPColor whiteColor] setStroke];
    [path setLineWidth:0.5];
    [path stroke]; 
}

@end

@implementation _CPDatePickerLabel : CPTextField
{
}

+ (_CPDatePickerLabel)labelWithTitle:(CPString)aTitle
{
    var label = [[_CPDatePickerLabel alloc] initWithFrame:CGRectMakeZero()];
    [label setTitle:aTitle];
    return label;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [self setValue:CPCenterTextAlignment forThemeAttribute:@"alignment"];
        [self setFont:[CPFont systemFontOfSize:10]];
        [self setTextColor:[CPColor blackColor]];
        [self setTextShadowColor:[CPColor whiteColor]];
        [self setTextShadowOffset:CGSizeMake(0,1)];
    }

    return self;
}

- (void)setTitle:(CPString)aTitle
{
    [self setStringValue:aTitle];
    [self sizeToFit];
}

- (void)didMoveToSuperview
{
    [self setNeedsLayout];
}

@end


@implementation _CPDatePickerHeaderArrowControl : CPControl 
{
    CPInteger direction @accessors;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [self setValue:CGSizeMake(16.0, 16.0) forThemeAttribute:@"min-size"];
        [self setValue:CGSizeMake(16.0, 16.0) forThemeAttribute:@"max-size"];
    }
    return self;
}

- (void)drawRect:(CGRect)aRect
{
    var bounds = [self bounds],
        context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextBeginPath(context);

    CGContextTranslateCTM(context, CGRectGetWidth(bounds) / 2.0, CGRectGetHeight(bounds) / 2.0);
    CGContextRotateCTM(context, - direction * Math.PI/2);
    CGContextTranslateCTM(context, -CGRectGetWidth(bounds) / 2.0, -CGRectGetHeight(bounds) / 2.0);

    // Center, but crisp.
    CGContextTranslateCTM(context, FLOOR((CGRectGetWidth(bounds) - 9.0) / 2.0), FLOOR((CGRectGetHeight(bounds) - 8.0) / 2.0));

    CGContextMoveToPoint(context, 0.0, 0.0);
    CGContextAddLineToPoint(context, 9.0, 0.0);
    CGContextAddLineToPoint(context, 4.5, 8.0);
    CGContextAddLineToPoint(context, 0.0, 0.0);

    CGContextClosePath(context);
    
    var isHighlighted = [self hasThemeState:CPThemeStateHighlighted];
    var color = isHighlighted ? [CPColor blackColor] : [CPColor grayColor];
    
    CGContextSetFillColor(context, color);
    CGContextFillPath(context);
}

@end

/*
 * LPCalendarView
 * LPKit
 *
 * Created by Ludwig Pettersson on September 21, 2009.
 *
 * The MIT License
 *
 * Copyright (c) 2009 Ludwig Pettersson
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

var immutableDistantFuture = [CPDate distantFuture];

@implementation _CPDatePickerMonthView : CPView
{
    CPDatePicker    _datePicker;

    CPDate          date @accessors;
    CPDate          previousMonth @accessors(readonly);
    CPDate          nextMonth @accessors(readonly);
                                        
    CPArray         dayTiles @accessors;
    
    CGGradient      _calendarGradient;
}

- (id)initWithFrame:(CGRect)aFrame datePicker:(CPDatePicker)aDatePicker
{
    if (self = [super initWithFrame:aFrame])
    {
        _datePicker = aDatePicker;
        dayTiles = [CPArray array];
                        
        // Create tiles
        for (var i = 0; i < 42; i++)
        {
            var dayView = [_CPDatePickerDayView dayViewWithDatePicker:_datePicker];
            [self addSubview:dayView];
            [dayTiles addObject:dayView];        
        }

        _calendarGradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), [219.0/255.0, 225.0/255.0, 231.0/255.0, 1.0, 200.0/255.0, 205.0/255.0, 211.0/255.0, 1.0], [0, 1], 2);

        [self setNeedsLayout];
    }
    
    return self;
}

- (void)setMonthForDate:(CPDate)aDate
{
    // Make a copy of the date
    date = [aDate copy];
    
    if (![aDate isEqualToDate:immutableDistantFuture])
    {    
        // Reset the date to the first day of the month & midnight
        date.setDate(1);
        [date resetToMidnight];
    
        // There must be a better way to do this.
        _firstDay = [date copy];
        _firstDay.setDate(1);
    
        previousMonth = new Date(_firstDay.getTime() - 86400000);
        previousMonth.setDate(1);
        nextMonth = new Date(_firstDay.getTime() + (([date daysInMonth] + 1) * 86400000));
        nextMonth.setDate(1);
    }
    
    [self reloadData];
}

- (void)tileSize
{
    var bounds = [self bounds];
    return CGSizeMake(ROUND(CGRectGetWidth(bounds) / 7), ROUND(CGRectGetHeight(bounds) / 6));
}

- (int)startOfWeekForDate:(CPDate)aDate
{
    var day = aDate.getDay();
    
    if ([CPDatePicker firstWeekdayIsMonday])
        return (day + 6) % 7;
    
    return day;
}

- (void)reloadData
{
    if (!date)
        return;

    var currentMonth = date,
        startOfMonthDay = [self startOfWeekForDate:currentMonth];

    var daysInPreviousMonth = [previousMonth daysInMonth],
        firstDayToShowInPreviousMonth = daysInPreviousMonth - startOfMonthDay;

    var currentDate = new Date(previousMonth.getFullYear(), previousMonth.getMonth(), firstDayToShowInPreviousMonth);
    
    var tilesCount = [dayTiles count],
        tileIndex;

    var now = [CPDate date],
        presentDay = now.getDate(),
        isPresentMonth = now.getMonth() === currentMonth.getMonth() 
                      && now.getFullYear() === currentMonth.getFullYear();
    
    for (tileIndex = 0; tileIndex < tilesCount; tileIndex++)
    {
        var dayTile = dayTiles[tileIndex];
        
        // Increment to next day
        currentDate.setTime(currentDate.getTime() + 90000000);
        [currentDate resetToMidnight];
        [dayTile setDate:currentDate];
        
        [dayTile setDisabled:currentDate.getMonth() != currentMonth.getMonth()];        
        [dayTile setHighlighted:isPresentMonth && currentDate.getDate() === presentDay];          
    }
}

- (void)tile
{
    var tileSize = [self tileSize],
        width = tileSize.width,
        height = tileSize.height,
        
        tilesCount = [dayTiles count],
        tileIndex;
    
    for (tileIndex = 0; tileIndex < tilesCount; tileIndex++)
    {
        var dayInWeek = tileIndex % 7,
            weekInMonth = (tileIndex - dayInWeek) / 7,
            tileFrame = CGRectMake(dayInWeek * width, weekInMonth * height, width, height);
        
        [dayTiles[tileIndex] setFrame:tileFrame];                
    }
}

- (void)setNeedsLayout
{
    [self tile];
}

- (CPInteger)indexOfTileForEvent:(CPEvent)anEvent
{
    var locationInView = [self convertPoint:[anEvent locationInWindow] fromView:nil],
        tileSize = [self tileSize];
   
    // Get the week row
    var rowIndex = FLOOR(locationInView.y / tileSize.height),
        columnIndex = FLOOR(locationInView.x / tileSize.width);
        
    columnIndex = MIN(MAX(columnIndex, 0), 6);
    rowIndex = MIN(MAX(rowIndex, 0), 5);
        
    var tileIndex = (rowIndex * 7) + columnIndex;

    return tileIndex;
}

- (void)_selectDate:(CPDate)aStartDate timeInterval:(CPInteger)interval
{
//    if (aStartDate && (aStartDate.getMonth() != date.getMonth() || aStartDate.getFullYear() != date.getFullYear()))
//        return;
        
    aStartDate = [aStartDate copy];
        
    // Replace hours / minutes / seconds
    [aStartDate resetToMidnight];
        
    var tilesCount = [dayTiles count];

    for (var i = 0; i < tilesCount; i++)
    {
        var tile = dayTiles[i],
            tileDate = [tile date],
            selected = NO;
        
        if (tileDate.getMonth() !== date.getMonth())
            continue;

        [tileDate resetToMidnight];
                    
        if (aStartDate)
        {
            var ti = [tileDate timeIntervalSinceDate:aStartDate];
            selected = (ti >= 0 && ti <= interval) || (ti <= 0 && ti >= interval);
        }
        
        [tile setIsLeft:selected && (ABS(ti) < 3600*24)];
        [tile setIsRight:selected && (ti == interval)];
        [tile setSelected:selected];
    }
}

- (void)drawRect:(CGRect)aRect
{
	var context = [[CPGraphicsContext currentContext] graphicsPort],
	    bounds = [self bounds],
	    width = CGRectGetWidth(bounds),
	    height = CGRectGetHeight(bounds),
	    tileSize = [self tileSize];

    CGContextSaveGState(context);

    CGContextAddRect(context, bounds);
    CGContextDrawLinearGradient(context, _calendarGradient, CGPointMake(0, 0), CGPointMake(0, height), 0);
	
   	var path = [CPBezierPath bezierPath];
    [path setLineWidth:1];
    
    // Horizontal lines
    for (var i = 0; i < 6; i++)
    {
        var y = i * (tileSize.height);
        [path moveToPoint:CGPointMake(0, y)];
        [path lineToPoint:CGPointMake(width, y)];
    }
    
    // Vertical lines
    for (var i = 0; i < 7; i++)
    {
        var x = i * (tileSize.width);
        [path moveToPoint:CGPointMake(x, 0)];
        [path lineToPoint:CGPointMake(x, height)];
    }

    [path closePath];
    
  	[[CPColor whiteColor] setStroke];
    [path stroke];
    
    CGContextTranslateCTM(context, -0.5, -0.5);

    [[CPColor colorWithCalibratedRed:161/255 green:171/255 blue:186/255 alpha:1] setStroke];
    [path stroke];
    
    CGContextRestoreGState(context);
}

@end

@implementation _CPDatePickerDayView : CPControl
{   
    CPDatePicker    _datePicker @accessors(property=datePicker);

    CPDate          date @accessors;
    CPTextField     textField;
    
    BOOL            isDisabled; 
    BOOL            isSelected;
    BOOL            isHighlighted;    
    BOOL            _isLeft;
    BOOL            _isRight;
        
    CPColor         bezelColor;
    CPColor         disabledBezelColor;
    CPColor         highlightedBezelColor;
    CPColor         selectedBezelColor;
    CPColor         selectedHighlightedBezelColor;
    CPColor         disabledSelectedBezelColor;
    
    CGGradient      _dayGradient;
}

+ (id)dayViewWithDatePicker:(CPDatePicker)aDatePicker
{
    var dayView = [[self alloc] initWithFrame:CGRectMakeZero()];
    [dayView setDatePicker:aDatePicker];
    return dayView;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [self setHitTests:NO];
        date = [CPDate date];
        
        textField = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
        [textField setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];

        // Normal
        bezelColor = [CPColor colorWithWhite:0.6 alpha:0.2];
        
        [textField setValue:[CPFont boldSystemFontOfSize:14.0] forThemeAttribute:@"font" inState:CPThemeStateNormal];
        [textField setValue:[CPColor colorWithHexString:@"333"] forThemeAttribute:@"text-color" inState:CPThemeStateNormal];
        [textField setValue:[CPColor colorWithWhite:1 alpha:0.8] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
        [textField setValue:CGSizeMake(1.0, 1.0) forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal];
        
        // Highlighted
        highlightedBezelColor = [CPColor colorWithWhite:0.5 alpha:0.5];
        [textField setValue:[CPColor colorWithHexString:@"555"] forThemeAttribute:@"text-color" inState:CPThemeStateHighlighted];
        
        // Selected
        selectedBezelColor = [CPColor colorWithCalibratedRed:88/255 green:145/255 blue:244/255 alpha:1];
        
        [textField setValue:[CPColor colorWithHexString:@"fff"] forThemeAttribute:@"text-color" inState:CPThemeStateSelected];
        [textField setValue:[CPColor colorWithWhite:0 alpha:0.4] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelected];
        
        // Selected & Highlighted
        selectedHighlightedBezelColor = [CPColor colorWithCalibratedRed:58/255 green:115/255 blue:214/255 alpha:1];
        
        // Disabled
        [textField setValue:[CPColor colorWithWhite:0 alpha:0.3] forThemeAttribute:@"text-color" inState:CPThemeStateDisabled];
        disabledBezelColor = [CPColor clearColor];

        _dayGradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), [0, 0, 0, 0.3, 0, 0, 0, 0.1, 0, 0, 0, 0], [0,0.5,1], 3);

        [self addSubview:textField];
        [self setNeedsLayout];
    }
    
    return self;
}

- (void)setSelected:(BOOL)shouldBeSelected
{
    if (isSelected === shouldBeSelected)
        return;
    
    isSelected = shouldBeSelected;
    
    if (shouldBeSelected)
        [self setThemeState:CPThemeStateSelected];
    else
        [self unsetThemeState:CPThemeStateSelected];
}

- (void)setDisabled:(BOOL)shouldBeDisabled
{
    if (isDisabled === shouldBeDisabled)
        return;
    
    isDisabled = shouldBeDisabled;
    
    if (isDisabled)
        [self setThemeState:CPThemeStateDisabled];
    else
        [self unsetThemeState:CPThemeStateDisabled];
}

- (void)setHighlighted:(BOOL)shouldBeHighlighted
{
    if (isHighlighted === shouldBeHighlighted)
        return;
    
    isHighlighted = shouldBeHighlighted;

    if (shouldBeHighlighted)
        [self setThemeState:CPThemeStateHighlighted];
    else
        [self unsetThemeState:CPThemeStateHighlighted];
}

- (void)setThemeState:(CPThemeState)aState
{
    [textField setThemeState:aState];
    [super setThemeState:aState];   
}

- (void)unsetThemeState:(CPThemeState)aState
{
    [textField unsetThemeState:aState];
    [super unsetThemeState:aState];   
}

- (void)setDate:(CPDate)aDate
{
    if (date.getTime() === aDate.getTime())
        return;
        
    // Update date
    date.setTime(aDate.getTime());
        
    var bounds = [self bounds];    
    // Update & Position the new label
    [textField setStringValue:[date.getDate() stringValue]];
    [textField sizeToFit];    
    [textField setCenter:CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))];
}

- (void)setIsLeft:(BOOL)isLeft
{
    _isLeft = isLeft;
    [self setNeedsDisplay:YES];
}

- (void)setIsRight:(BOOL)isRight
{
    _isRight = isRight;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        state = [self themeState],
        bounds = [self bounds],
        color;
    
    if (state == CPThemeStateNormal)
        color = bezelColor;
    else if (state & CPThemeStateDisabled)
        color = disabledBezelColor;
    else if (state == CPThemeStateHighlighted)
        color = highlightedBezelColor;
    else if (state == CPThemeStateSelected)
        color = selectedBezelColor;
    else if (state & (CPThemeStateHighlighted | CPThemeStateSelected))
        color = selectedHighlightedBezelColor;
    
    //CGContextSaveGState(context);
    [color setFill];
    CGContextFillRect(context, bounds);

    if (state == CPThemeStateSelected || state == (CPThemeStateSelected | CPThemeStateHighlighted))
    {     
        CGContextAddRect(context, bounds);
        CGContextDrawLinearGradient(context, _dayGradient, CGPointMake(0, 0), CGPointMake(0, 6), 0);
        CGContextDrawLinearGradient(context, _dayGradient, CGPointMake(0, CGRectGetHeight(bounds)), CGPointMake(0, CGRectGetHeight(bounds) - 2), 0);

        if (_isLeft)
            CGContextDrawLinearGradient(context, _dayGradient, CGPointMake(0, 0), CGPointMake(3, 0), 0);
        if (_isRight)
            CGContextDrawLinearGradient(context, _dayGradient, CGPointMake(CGRectGetWidth(bounds), 0), CGPointMake(CGRectGetWidth(bounds) - 2, 0), 0);
    }
    //CGContextRestoreGState(context);
}

@end

var rotate = function(ar /*array*/, p /* integer, positive integer rotate to the right, negative to the left... */){
    var a = ar; //v1.0
    for(var l = a.length, p = (Math.abs(p) >= l && (p %= l), p < 0 && (p += l), p), i, x; p; p = (Math.ceil(l / p) - 1) * p - l + (l = p))
        for(i = l; i > p; x = a[--i], a[i] = a[i - p], a[i - p] = x);
    return a;
};