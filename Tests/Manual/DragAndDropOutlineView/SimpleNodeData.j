
@implementation SimpleNodeData : CPObject
{
    CPString       name @accessors(property=name);
    CPImage       image @accessors(property=image);
    BOOL      container @accessors(property=container);
    BOOL     expandable @accessors(property=expandable);
    BOOL     selectable @accessors(property=selectable);
}

- (id)init
{
    self = [super init];
    name = @"Untitled";
    expandable = YES;
    selectable = YES;
    container = YES;

    return self;
}

- (id)initWithName:(CPString)aName
{
    self = [self init];
    name = aName;

    return self;
}

+ (SimpleNodeData)nodeDataWithName:(CPString)aName
{
    return [[SimpleNodeData alloc] initWithName:aName];
}

- (CPComparisonResult)compare:(id)anOther
{
    // We want the data to be sorted by name, so we compare [self name] to [other name]
    if ([anOther isKindOfClass:[SimpleNodeData class]])
        return [name compare:[anOther name]];

    return CPOrderedAscending;
}

- (CPString)description
{
    return [CPString stringWithFormat:@"%@ - '%@' expandable: %d, selectable: %d, container: %d", [super description], name, expandable, selectable, container];
}

@end

