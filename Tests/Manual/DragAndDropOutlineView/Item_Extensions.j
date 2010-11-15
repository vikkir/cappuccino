
#define KEY_GROUPNAME   @"Group"
#define KEY_ENTRIES @"Entries"

@implementation CPObject (ItemStuff)
- (void)insertChildItem:(id)item atIndex:(CPInteger)index { return; }
- (void)removeChildItem:(id)item { return; }
- (void)replaceChildAtIndex:(CPInteger)index withItem:(id)replacment { return; }
- (id)childItemAtIndex:(CPInteger)index { return nil; }
- (CPInteger)indexOfChildItem:(id)item { return CPNotFound; }
- (CPInteger)numberOfChildItems { return 0; }
- (id)itemDescription { return self; }
- (BOOL)isExpandable { return NO; }
- (BOOL)isLeaf { return YES; }
- (CPArray)itemsByFlattening { return [CPArray arrayWithObject:self]; }
- (CPString)className { return [[self class] description]; }
+ (id)newGroup { return [CPDictionary dictionaryWithObjectsAndKeys: @"New Group", KEY_GROUPNAME, [CPMutableArray array], KEY_ENTRIES, nil]; }
+ (id)newLeaf { return [CPMutableString stringWithCString: "New Leaf"]; }
+ (id)newGroupFromLeaf:leaf { return [CPDictionary dictionaryWithObjectsAndKeys: [leaf itemDescription], KEY_GROUPNAME, [CPMutableArray array], KEY_ENTRIES, nil]; }
- (void) sortRecursively: (BOOL) recurse { return; }
- (id)deepMutableCopy { return [self mutableCopy]; }
- (void)setItemDescription:(CPString *)desc { return; }
@end

@implementation CPMutableString (ItemStuff)
- (void)setItemDescription:(CPString)desc { [self setString: desc]; }
@end

@implementation CPArray (ItemStuff)

- (CPArray)itemsByFlattening
{
    var entry = nil,
        entries = [self objectEnumerator],
        flatItems = [CPMutableArray array];
    
    while (entry=[entries nextObject])
        [flatItems addObjectsFromArray: [entry itemsByFlattening]];

    return [CPArray arrayWithArray: flatItems];
}

@end

@implementation CPMutableDictionary (ItemStuff)
- (void)removeChildItem:(id)item { [[self objectForKey: KEY_ENTRIES] removeObjectIdenticalTo: item]; }
- (void)replaceChildAtIndex:(CPInteger)index withItem:(id)item { [[self objectForKey:KEY_ENTRIES] replaceObjectAtIndex:index withObject:item]; }
- (void)insertChildItem:(id)item atIndex:(CPInteger)index { [[self objectForKey: KEY_ENTRIES] insertObject: item atIndex: index]; }
- (id)childItemAtIndex:(CPInteger)index { return [[self objectForKey: KEY_ENTRIES] objectAtIndex: index]; }
- (CPInteger)indexOfChildItem:(id)item { return [[self objectForKey: KEY_ENTRIES] indexOfObjectIdenticalTo: item]; }
- (CPInteger)numberOfChildItems { return [[self objectForKey: KEY_ENTRIES] count]; }
- (id)itemDescription { return [self objectForKey: KEY_GROUPNAME]; }
- (BOOL)isExpandable { return YES; }
- (BOOL)isLeaf { return NO; }
- (CPArray)itemsByFlattening
{
    var entry = nil,
        results = [CPMutableArray arrayWithObject:[self objectForKey: KEY_GROUPNAME]],
        entries = [[self objectForKey: KEY_ENTRIES] objectEnumerator],
        flatItems = [CPMutableArray array];

    while (entry = [entries nextObject])
        [flatItems addObjectsFromArray: [entry itemsByFlattening]];

    [results addObjectsFromArray: flatItems];

    return results;
}

- (void)setItemDescription:(CPString)desc { [self setObject: [desc mutableCopy] forKey: KEY_GROUPNAME]; }
- (void) sortRecursively: (BOOL) recurse
{
    [[self objectForKey: KEY_ENTRIES] sortUsingFunction: _compareEntries context: NULL];
    if (recurse)
    {
        var entry = nil;
        var entries = [[self objectForKey: KEY_ENTRIES] objectEnumerator];
        while ( (entry=[entries nextObject]) )
        {
            if ([entry isKindOfClass: [CPDictionary class]]) [entry sortRecursively: recurse];
        }
    }
}
@end

