
@implementation ImageAndTextView : _CPImageAndTextView
{
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self _initShared];
    }

    return self;
}

- (void)_initShared
{
    [self setLineBreakMode:CPLineBreakByTruncatingTail];
    [self setImagePosition:CPImageLeft];
    [self setAlignment:CPLeftTextAlignment];
    [self setVerticalAlignment:CPCenterVerticalTextAlignment];
}

- (id)initWithCoder:(CPCoder)coder
{
    self = [super initWithCoder:coder];
    [self _initShared];

    return self;
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [super encodeWithCoder:coder];
}

- (id)objectValue
{
    return [self text];
}

- (void)setObjectValue:(id)value
{
    [self setText:value];
}

- (void)setThemeState:(CPThemeState)state
{
    if (state === CPThemeStateSelectedDataView)
    {
        [self setTextColor:[CPColor whiteColor]];
        [self setFont:[CPFont boldSystemFontOfSize:12]];
    }
    else if (state === CPThemeStateGroupRow)
    {
        [self setBackgroundColor:[CPColor grayColor]];
    }

    [super setThemeState:state];
}

- (void)unsetThemeState:(CPThemeState)state
{
    if (state === CPThemeStateSelectedDataView)
    {
        [self setTextColor:[CPColor blackColor]];
        [self setFont:[CPFont systemFontOfSize:12]];
    }

    [super unsetThemeState:state];
}

/*
- (CPInteger)hitTestForEvent:(CPEvent)event inRect:(CPRect)cellFrame ofView:(CPView)controlView
{
    var point = [controlView convertPoint:[event locationInWindow] fromView:nil];
    // If we have an image, we need to see if the user clicked on the image portion.
    if (image != nil)
    {
        // This code closely mimics drawWithFrame:inView:
        var imageSize = [image size];
        var imageFrame;
        CPDivideRect(cellFrame, &imageFrame, &cellFrame, 3 + imageSize.width, CPMinXEdge);

        imageFrame.origin.x += 3;
        imageFrame.size = imageSize;
        // If the point is in the image rect, then it is a content hit
        if (CPMouseInRect(point, imageFrame, [controlView isFlipped]))
        {
            // We consider this just a content area. It is not trackable, nor it it editable text. If it was, we would or in the additional items.
            // By returning the correct parts, we allow CPTableView to correctly begin an edit when the text portion is clicked on.
            return CPCellHitContentArea;
        }
    }
    // At this point, the cellFrame has been modified to exclude the portion for the image. Let the superclass handle the hit testing at this point.
    return [super hitTestForEvent:event inRect:cellFrame ofView:controlView];
}
*/
@end

