@import <Foundation/CPArray.j>
@import <Foundation/CPString.j>
@import <Foundation/CPNumber.j>
@import <Foundation/CPSortDescriptor.j>

@implementation CPArray (CPSortDescriptorTurboSpeed)

- (CPArray)_sortedArrayUsingDescriptors:(CPArray)descriptors
{
    var sorted = [self copy];

    [sorted _sortUsingDescriptors:descriptors];

    return sorted;
}

- (void)_sortUsingDescriptors:(CPArray)descriptors
{
    [self _sortUsingFunction:compareObjectsUsingDescriptors context:descriptors];
}

// Iterative mergesort based on
// http://www.inf.fh-flensburg.de/lang/algorithmen/sortieren/merge/mergiter.htm
/*!
    Sorts the receiver array using a JavaScript function as a comparator, and a specified context.
    @param aFunction a JavaScript function that will be called to compare objects
    @param aContext an object that will be passed to \c aFunction with comparison
*/
- (void)_sortUsingFunction:(Function)aFunction context:(id)aContext
{
    var h, i, j, k, l, m, n = [self count];
    var A, B = [];
     
    for (h = 1; h < n; h += h)
    {
        for (m = n - 1 - h; m >= 0; m -= h + h)
        {
            l = m - h + 1;
            if (l < 0)
                l = 0;
            
            for (i = 0, j = l; j <= m; i++, j++)
                B[i] = self[j];
            
            for (i = 0, k = l; k < j && j <= m + h; k++)
            {
                A = self[j];
                if (aFunction(A, B[i], aContext) == CPOrderedDescending)
                    self[k] = B[i++];
                else
                {
                    self[k] = A;
                    j++;
                }
            }
            
            while (k < j)
                self[k++] = B[i++];
        }
    }
}

@end

@implementation CPArrayPerformance : OJTestCase

- (void)testSortUsingDescriptorsSpeed
{

    var ELEMENTS = 1000,
        REPEATS = 10,
        array = [];
    for (var i=0; i<ELEMENTS; i++) {
        var s = [Sortable new];
        [s setA:(i % 5)];
        [s setB:(ELEMENTS-i)];
        array.push(s);
    }

    var descriptors = [
        [CPSortDescriptor sortDescriptorWithKey:"a" ascending:NO],
        [CPSortDescriptor sortDescriptorWithKey:"b" ascending:YES]
    ];

    var start = (new Date).getTime();

    for (var i=0; i<REPEATS; i++)
    {
        var sorted = [array sortedArrayUsingDescriptors:descriptors];

        // Verify it really got sorted.
        for (var j=0; j<ELEMENTS; j++) {
            var expectedA = 4-FLOOR(j * 5 / ELEMENTS);
            if (sorted[j].a != expectedA)
                [self fail:"a out of order: "+expectedA+" != "+sorted[j].a];
            var expectedB = (5-expectedA) + 5 * (j % (ELEMENTS / 5))
            if (sorted[j].b != expectedB)
                [self fail:"b out of order: "+expectedB+" != "+sorted[j].b];
        }
    }

    var end = (new Date).getTime();

    CPLog.warn(_cmd + " " + (end-start)+"ms");
}

- (void)testNewSortUsingDescriptorsSpeed
{

    var ELEMENTS = 1000,
        REPEATS = 10,
        array = [];
    for (var i=0; i<ELEMENTS; i++) {
        var s = [Sortable new];
        [s setA:(i % 5)];
        [s setB:(ELEMENTS-i)];
        array.push(s);
    }

    var descriptors = [
        [CPSortDescriptor sortDescriptorWithKey:"a" ascending:NO],
        [CPSortDescriptor sortDescriptorWithKey:"b" ascending:YES]
    ];

    var start = (new Date).getTime();

    for (var i=0; i<REPEATS; i++)
    {
        var sorted = [array _sortedArrayUsingDescriptors:descriptors];

        // Verify it really got sorted.
        for (var j=0; j<ELEMENTS; j++) {
            var expectedA = 4-FLOOR(j * 5 / ELEMENTS);
            if (sorted[j].a != expectedA)
                [self fail:"a out of order: "+expectedA+" != "+sorted[j].a];
            var expectedB = (5-expectedA) + 5 * (j % (ELEMENTS / 5))
            if (sorted[j].b != expectedB)
                [self fail:"b out of order: "+expectedB+" != "+sorted[j].b];
        }
    }

    var end = (new Date).getTime();

    CPLog.warn(_cmd + " " + (end-start)+"ms");
}

@end

@implementation Sortable : CPObject
{
    int a @accessors;
    int b @accessors;
}

@end

var selectorCompare = function selectorCompare(object1, object2, selector)
{
    return [object1 performSelector:selector withObject:object2];
}

// sort using sort descriptors
var compareObjectsUsingDescriptors= function compareObjectsUsingDescriptors(lhs, rhs, descriptors)
{ 
    var result,
        i = 0,  
        n = [descriptors count];
        
    while (i < n && result == CPOrderedSame);
       result = [descriptors[i++] compareObject:lhs withObject:rhs];
    
    return result;
}
