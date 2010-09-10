
@import <AppKit/AppKit.j>

[CPApplication sharedApplication]

var redColor = [CPColor redColor];

@implementation CPColorWellTest : OJTestCase
{
    CPColorWell well;
}

- (void)setUp
{
    well = [[CPColorWell alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
}

- (void)testSetObjectValue
{
    [well setObjectValue:redColor];
    [self assertTrue:[well objectValue] == redColor message:@"[self objectValue] should return the value set with -setObjectValue:"];
    [self assertTrue:[well color] == redColor message:@"[self color] should return the value set with -setObjectValue:"];

    [well setColor:redColor];
    [self assertTrue:[well objectValue] == redColor message:@"[self objectValue] should return the value set with -setColor:"];
    [self assertTrue:[well color] == redColor message:@"[self color] should return the value set with -setColor:"];    
}

@end
