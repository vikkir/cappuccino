@import <Foundation/CPArray.j>
@import <Foundation/CPString.j>
@import <Foundation/CPNumber.j>
@import <Foundation/CPSortDescriptor.j>

var ELEMENTS = 1000,
    REPEATS = 10;

@implementation CPArrayPerformanceTest : OJTestCase
{
    CPArray unsorted;
    CPArray randunsorted;
    CPArray descriptors;
}

- (void)setUp
{
    descriptors = [
        [CPSortDescriptor sortDescriptorWithKey:"a" ascending:NO],
        [CPSortDescriptor sortDescriptorWithKey:"b" ascending:YES]
    ];
    
    unsorted = [self makeUnsorted];
    randunsorted = [self makeUnsortedRandom];
}

- (void)testSortUsingDescriptorsSpeed
{
    var start = new Date();

    for (var i = 0; i < REPEATS; i++)
    {
        var sorted = [unsorted copy];
        [sorted sortUsingDescriptors:descriptors];
    }
    
    var d = (new Date()) - start;    
    start = new Date();
    
    for (var i = 0; i < REPEATS; i++)
    {
        var sorted = [unsorted copy];
        [sorted nativeSortUsingDescriptors:descriptors];
    }

    var nd = (new Date()) - start;

    CPLog.warn(_cmd+" "+ d +"ms native: " + nd + "ms");
}

- (void)testSortRandomUsingDescriptorsSpeed
{
    var start = new Date();

    for (var i = 0; i < REPEATS; i++)
    {
        var sorted = [randunsorted copy];
        [sorted sortUsingDescriptors:descriptors];
    }
    
    var d = (new Date()) - start;
    start = new Date();
    
    for (var i=  0; i < REPEATS; i++)
    {
        var sorted = [randunsorted copy];
        [sorted nativeSortUsingDescriptors:descriptors];
    }

    var nd = new Date() - start;

    CPLog.warn(_cmd+" "+ d +"ms native: " + nd + "ms");
}

- (CPArray)makeUnsortedRandom
{
    var array = [CPArray array];
    for (var i = 0; i < ELEMENTS; i++)
    {
        var s = [Sortable new];
        [s setA:ROUND(RAND()*1000)];
        [s setB:ROUND(RAND()*1000)];
        [array addObject:s];
    }
    
    return array;
}

- (CPArray)makeUnsorted
{
    var array = [CPArray array];
    for (var i = 0; i < ELEMENTS; i++)
    {
        var s = [Sortable new];
        [s setA:(i % 5)];
        [s setB:(ELEMENTS - i)];
        [array addObject:s];
    }
    
    return array;
}

@end

@implementation Sortable : CPObject
{
    int a @accessors;
    int b @accessors;
}

@end

@implementation CPArray (NativeSort)

- (CPArray)nativeSortUsingDescriptors:(CPArray)descriptors
{
    var compareObjectsUsingDescriptors = function (lhs, rhs)
    {
        var result = CPOrderedSame,
            i = 0,
            n = [descriptors count];
    
        while (i < n && result === CPOrderedSame)
            result = [descriptors[i++] compareObject:lhs withObject:rhs];
    
        return result;
    }
    
    sort(compareObjectsUsingDescriptors);
}

@end
