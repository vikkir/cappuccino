/*
 * AppController.j
 * DragAndDropOutlineView
 *
 * Created by cacaodev on February 22, 2010.
 * Copyright 2010, All rights reserved.
 *
 * Based on http://developer.apple.com/mac/library/samplecode/DragNDropOutlineView/
*/

@import <AppKit/AppKit.j>
@import <Foundation/Foundation.j>
@import <AppKit/CPScrollView.j>

@import "SimpleNodeData.j"
@import "ImageAndTextView.j"
@import "BadgedOutlineView.j"

var SIMPLE_PBOARD_TYPE           = @"MyCustomOutlineViewPboardType",
    COLUMNID_NAME                = @"NameColumn",
    COLUMNID_IS_EXPANDABLE       = @"IsExpandableColumn",
    COLUMID_IS_SELECTABLE        = @"IsSelectableColumn",
    COLUMNID_NODE_KIND           = @"NodeKindColumn",

    NAME_KEY                     = @"Name",
    CHILDREN_KEY                 = @"Children";

@implementation CPDictionary (ReadFile)

+ (id)dictionaryWithContentsOfURL:(CPURL)url
{
    var request = [CPURLRequest requestWithURL:url];
    var data = [CPURLConnection sendSynchronousRequest:request returningResponse:NULL];
    if (data)
    {
        var dict = [CPPropertyListSerialization propertyListFromData:data format:CPPropertyListXMLFormat_v1_0];
        return dict;
    }

    return nil;
}

@end

@implementation AppController : CPObject
{
    CPTreeNode rootTreeNode;
    CPArray draggedNodes;
    CPMutableArray iconImages;

    BadgedOutlineView outlineView;
    CPCheckBox allowOnDropOnContainerCheck;
    CPCheckBox allowOnDropOnLeafCheck;
    CPCheckBox allowBetweenDropCheck;
    CPCheckBox allowButtonCellsToChangeSelection;
    CPCheckBox onlyAcceptDropOnRoot;
    CPCheckBox useGroupRowLook;
    CPCheckBox useBadges;
    CPTextField selectionOutput;

    CPMenu outlineViewContextMenu;
    CPMenu expandableColumnMenu;
}

- (id)init
{
    if (self = [super init])
    {
        // Load our initial outline view data from the "InitInfo" dictionary.
        var initInfoPath = [[CPBundle mainBundle] pathForResource:@"InitInfo.dict"],
            dictionary = [CPDictionary dictionaryWithContentsOfURL:initInfoPath];
        
        rootTreeNode = [self treeNodeFromDictionary:dictionary];
    }

    return self;
}

- (void)applicationDidFinishLaunching:(CPNotification)notification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(100,40,500,500) styleMask:CPTitledWindowMask|CPResizableWindowMask],
        contentView = [theWindow contentView];

    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0,0,500,220)];
    [scrollView setAutoresizingMask:CPViewWidthSizable];

    outlineView = [[BadgedOutlineView alloc] initWithFrame:[scrollView bounds]];
    [outlineView setSourceListDataSource:self];
    [outlineView setAction:@selector(outlineViewAction:)];
    [outlineView setTarget:self];
    [outlineView setDataSource:self];
    [outlineView setDelegate:self];
    [outlineView setAllowsMultipleSelection:YES];
    [outlineView setRowHeight:25.0];
    [outlineView setUsesAlternatingRowBackgroundColors:YES];

    var column = [[CPTableColumn alloc] initWithIdentifier:COLUMNID_NAME];
    [column setWidth:240];
    [[column headerView] setStringValue:@"Name"];
    [column setDataView:[[ImageAndTextView alloc] initWithFrame:CGRectMakeZero()]];
    [outlineView addTableColumn:column];
    [outlineView setOutlineTableColumn:column];

    var column = [[CPTableColumn alloc] initWithIdentifier:COLUMNID_IS_EXPANDABLE];
    [column setWidth:90];
    [[column headerView] setStringValue:@"Expandable?"];
    var checkBox = [[CPCheckBox alloc] initWithFrame:CGRectMakeZero()];
    [checkBox setAutoresizingMask:CPViewHeightSizable];
    [column setDataView:checkBox];
    [outlineView addTableColumn:column];

    var column = [[CPTableColumn alloc] initWithIdentifier:COLUMID_IS_SELECTABLE];
    [column setWidth:90];
    [[column headerView] setStringValue:@"Selectable?"];
    var checkBox = [[CPCheckBox alloc] initWithFrame:CGRectMakeZero()];
    [column setDataView:checkBox];
    [outlineView addTableColumn:column];

    var column = [[CPTableColumn alloc] initWithIdentifier:COLUMNID_NODE_KIND];
    [column setWidth:150];
    [[column headerView] setStringValue:@"Kind"];
    [outlineView addTableColumn:column];

    // Register to get our custom type, strings, and filenames. Try dragging each into the view!
    [outlineView registerForDraggedTypes:[CPArray arrayWithObjects:SIMPLE_PBOARD_TYPE, CPStringPboardType]];
//  [outlineView setAutoresizesOutlineColumn:NO];

    [scrollView setDocumentView:outlineView];
    [contentView addSubview:scrollView];

    selectionOutput = [[CPTextField alloc] initWithFrame:CGRectMake(10,230,470,20)];
    [selectionOutput setAutoresizingMask:CPViewWidthSizable];
    [contentView addSubview:selectionOutput];

    var box = [[CPBox alloc] initWithFrame:CGRectMake(15,260,470,220)];
    [box setAutoresizingMask:CPViewWidthSizable];

    allowBetweenDropCheck = [[CPCheckBox alloc] initWithFrame:CGRectMake(10,10,300,20)];
    [allowBetweenDropCheck setTitle:@"Allow \"Between\" Drops"];
    [[box contentView] addSubview:allowBetweenDropCheck];

    allowOnDropOnContainerCheck = [[CPCheckBox alloc] initWithFrame:CGRectMake(10,40,300,20)];
    [allowOnDropOnContainerCheck setTitle:@"Allow \"On\" Drops On Container Items"];
    [[box contentView] addSubview:allowOnDropOnContainerCheck];

    allowOnDropOnLeafCheck = [[CPCheckBox alloc] initWithFrame:CGRectMake(10,70,300,20)];
    [allowOnDropOnLeafCheck setTitle:@"Allow \"On\" Drops On Leaf Items"];
    [[box contentView] addSubview:allowOnDropOnLeafCheck];

    onlyAcceptDropOnRoot = [[CPCheckBox alloc] initWithFrame:CGRectMake(10,100,300,20)];
    [onlyAcceptDropOnRoot setTitle:@"Only Allowed To Drop On Root Item (Whole View)"];
    [[box contentView] addSubview:onlyAcceptDropOnRoot];

    allowButtonCellsToChangeSelection = [[CPCheckBox alloc] initWithFrame:CGRectMake(10,130,400,20)];
    [allowButtonCellsToChangeSelection setTitle:@"Allow \"Check Box Button Cells\" to change row selection"];
    [allowButtonCellsToChangeSelection setState:1];
    [allowButtonCellsToChangeSelection setEnabled:NO];
    [[box contentView] addSubview:allowButtonCellsToChangeSelection];

    useGroupRowLook = [[CPCheckBox alloc] initWithFrame:CGRectMake(10,160,300,20)];
    [useGroupRowLook setTitle:@"use GroupRow Look"];
    [[box contentView] addSubview:useGroupRowLook];

    useBadges = [[CPCheckBox alloc] initWithFrame:CGRectMake(10,190,300,20)];
    [useBadges setTitle:@"Show badges"];
    [useBadges setTarget:self];
    [useBadges setAction:@selector(useBadges:)];
    [[box contentView] addSubview:useBadges];

    [contentView addSubview:box];
    [theWindow orderFront:nil];
}

- (CPArray)draggedNodes
{
    return draggedNodes;
}

- (CPArray)selectedNodes
{
    return [outlineView selectedItems];
}

- (BOOL)allowOnDropOnContainer
{
    return [allowOnDropOnContainerCheck state];
}

- (BOOL)allowOnDropOnLeaf
{
    return [allowOnDropOnLeafCheck state];
}

- (BOOL)allowBetweenDrop
{
    return [allowBetweenDropCheck state];
}

- (BOOL)onlyAcceptDropOnRoot
{
    return [onlyAcceptDropOnRoot state];
}

- (BOOL)useBadges
{
    return [useBadges state];
}
// ================================================================
// Target / action methods.
// ================================================================

- (void)addContainer:(id)sender
{
    // Create a new model object, and insert it into our tree structure
    var childNodeData = [[SimpleNodeData alloc] initWithName:@"New Container"];
    [self addNewDataToSelection:childNodeData];
    [childNodeData release];
}

- (void)addLeaf:(id)sender
{
    var childNodeData = [[SimpleNodeData alloc] initWithName:@"New Leaf"];
    childNodeData.container = NO;
    [self addNewDataToSelection:childNodeData];
    [childNodeData release];
}

- (void)outlineViewAction:(id)sender
{
    // This message is sent from the outlineView as it's action (see the connection in IB).
    var selectedNodes = [self selectedNodes];

    if ([selectedNodes count] > 1)
    {
        [selectionOutput setStringValue: @"Multiple Rows Selected"];
    }
    else if ([selectedNodes count] == 1)
    {
        var data = [[selectedNodes lastObject] representedObject];
        [selectionOutput setStringValue:[data description]];
    }
    else
    {
        [selectionOutput setStringValue: @"Nothing Selected"];
    }
}

- (void)deleteSelections:(id)sender
{
    // Remove all the selected nodes
    var selectedItems = [outlineView selectedItems],
        count = [selectedItems count];

    while (count--)
    {
        var node = [selectedItems objectAtIndex:count];
        [[[node parentNode] mutableChildNodes] removeObject:node];
    }

    [outlineView deselectAll:nil];
    [outlineView reloadData];
}

- (IBAction)sortData:(id)sender
{
    var itemsToSelect = [self selectedNodes];

    // Create a sort descriptor to do the sorting. Use a 'nil' key to sort on the objects themselves. This will by default use the method "compare:" on the representedObjects in the CPTreeNode.
    var sortDescriptor = [[CPSortDescriptor alloc] initWithKey:nil ascending:YES];
    [rootTreeNode sortWithSortDescriptors:[CPArray arrayWithObject:sortDescriptor] recursively:YES];

    [outlineView reloadData];
    [outlineView setSelectedItems:itemsToSelect];
}

- (BOOL)validateMenuItem:(CPMenuItem)menuItem
{
    if ([menuItem action] == @selector(deleteSelections:))
    {
        // The delete selection item should be disabled if nothing is selected.
        if ([[self selectedNodes] count] > 0)
            return YES;
        else
            return NO;
    }

    return YES;
}

// ================================================================
//  CPOutlineView data source methods. (The required ones)
// ================================================================

// The CPOutlineView uses 'nil' to indicate the root item. We return our root tree node for that case.
- (CPArray)childrenForItem:(id)item
{
    if (item == nil)
        return [rootTreeNode childNodes];
    else
        return [item childNodes];
}

// Required methods.
- (id)outlineView:(CPOutlineView)theOutlineView child:(CPInteger)index ofItem:(id)item
{
    // 'item' may potentially be nil for the root item.
    var children = [self childrenForItem:item];
    // This will return an CPTreeNode with our model object as the representedObject
    return [children objectAtIndex:index];
}

- (BOOL)outlineView:(CPOutlineView)theOutlineView isItemExpandable:(id)item
{
    // 'item' will always be non-nil. It is an CPTreeNode, since those are always the objects we give CPOutlineView. We access our model object from it.
    var nodeData = [item representedObject];
    // We can expand items if the model tells us it is a container
    return nodeData.container;
}

- (CPInteger)outlineView:(CPOutlineView)theOutlineView numberOfChildrenOfItem:(id)item
{
    // 'item' may potentially be nil for the root item.
    var children = [self childrenForItem:item];
    return [children count];
}

- (BOOL)sourceList:(CPOutlineView)aSourceList itemHasBadge:(id)item
{
	return [self useBadges] && [self outlineView:aSourceList numberOfChildrenOfItem:item] > 0;
}

- (CPInteger)sourceList:(CPOutlineView)aSourceList badgeValueForItem:(id)item
{
	return [self outlineView:aSourceList numberOfChildrenOfItem:item];
}

- (CPInteger)sourceList:(CPOutlineView)aSourceList badgeBackgroundColorForItem:(id)item
{
    if ([self outlineView:aSourceList numberOfChildrenOfItem:item] > 3)
        return [CPColor redColor];

    return nil;
}

- (CPInteger)sourceList:(CPOutlineView)aSourceList badgeTextColorForItem:(id)item
{
    if ([self outlineView:aSourceList numberOfChildrenOfItem:item] > 3)
        return [CPColor yellowColor];

    return nil;
}

- (id)outlineView:(CPOutlineView)theOutlineView objectValueForTableColumn:(CPTableColumn)tableColumn byItem:(id)item
{
    var objectValue = nil,
        nodeData = [item representedObject];

    // The return value from this method is used to configure the state of the items cell via setObjectValue:
    if (tableColumn == nil || [[tableColumn identifier] isEqualToString:COLUMNID_NAME])
        objectValue = nodeData.name;
    else if ([[tableColumn identifier] isEqualToString:COLUMNID_IS_EXPANDABLE])
    {
        // Here, object value will be used to set the state of a check box.
        var isExpandable = nodeData.container && nodeData.expandable;
        objectValue = isExpandable ? CPOnState : CPOffState;
    }
    else if ([[tableColumn identifier] isEqualToString:COLUMNID_NODE_KIND])
        objectValue = (nodeData.container) ? @"Container" : @"Leaf";
    else if ([[tableColumn identifier] isEqualToString:COLUMID_IS_SELECTABLE])
        // Again -- this object value will set the state of the check box.
        objectValue = (nodeData.selectable) ? CPOnState : CPOffState;

    return objectValue;
}

// Optional method: needed to allow editing.
- (void)outlineView:(CPOutlineView)theOutlineView setObjectValue:(id)object forTableColumn:(CPTableColumn)tableColumn byItem:(id)item
{
    var nodeData = [item representedObject];

    // Here, we manipulate the data stored in the node.
    if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString:COLUMNID_NAME])
        nodeData.name = object;
    else if ([[tableColumn identifier] isEqualToString:COLUMNID_IS_EXPANDABLE])
    {
        nodeData.expandable = [object boolValue];
        if (!nodeData.expandable && [theOutlineView isItemExpanded:item])
            [theOutlineView collapseItem:item];
    }
    else if ([[tableColumn identifier] isEqualToString:COLUMID_IS_SELECTABLE])
        nodeData.selectable = [object boolValue];
}

// We can return a different cell for each row, if we want
- (CPView)outlineView:(CPOutlineView)theOutlineView dataViewForTableColumn:(CPTableColumn)tableColumn item:(id)item
{
    // If we return a cell for the 'nil' tableColumn, it will be used as a "full width" cell and span all the columns
    if ([useGroupRowLook state] && (tableColumn == nil))
    {
        var nodeData = [item representedObject];
        if (nodeData.container)
        {
            // We want to use the cell for the name column, but we could construct a new cell if we wanted to, or return a different cell for each row.
            return [[theOutlineView tableColumnWithIdentifier:COLUMNID_NAME] dataView];
        }
    }

    return [tableColumn dataView];
}

// To get the "group row" look, we implement this method.
- (BOOL)outlineView:(CPOutlineView)theOutlineView isGroupItem:(id)item
{
    var nodeData = [item representedObject];
    return (nodeData.container) && ([useGroupRowLook state]);
}

- (BOOL)outlineView:(CPOutlineView)theOutlineView shouldExpandItem:(id)item
{
    // Query our model for the answer to this question
    var nodeData = [item representedObject];
    return nodeData.expandable;
}

- (void)outlineView:(CPOutlineView)theOutlineView willDisplayView:(CPView)aView forTableColumn:(CPTableColumn)tableColumn item:(id)item
{
    var nodeData = [item representedObject];
    if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString:COLUMNID_NAME])
    {
        // Make sure the image and text cell has an image.  If not, lazily fill in a random image
        if (nodeData.image == nil)
            nodeData.image = [self randomIconImage];

        // We know that the cell at this column is our image and text cell, so grab it
        var imageAndTextView = aView;
        // Set the image here since the value returned from outlineView:objectValueForTableColumn:... didn't specify the image part...
        [imageAndTextView setImage:nodeData.image];
    }
    else if ([[tableColumn identifier] isEqualToString:COLUMNID_IS_EXPANDABLE])
    {
        [aView setEnabled:nodeData.container];
        // On Mac OS 10.5 and later, in willDisplayCell: we can dynamically set the contextual menu (right click menu) for a particular cell. If nothing is set, then the contextual menu for the CPOutlineView itself will be used. We will set a different menu for the "Expandable?" column, and leave the default one for everything else.
        //[aView setMenu:expandableColumnMenu];
    }
    // For all the other columns, we don't do anything.
}

- (BOOL)outlineView:(CPOutlineView)theOutlineView shouldSelectItem:(id)item
{
    // Control selection of a particular item.
    var nodeData = [item representedObject],
        result = nodeData.selectable;

    if (result)
    {
        //We can access the clicked row and column to potentially disable row selection based on what item was clicked on. We don't want to change the selection when clicking on a column with a button cell, if that option is checked.
        if (![allowButtonCellsToChangeSelection state])
        {
            var clickedCol = [theOutlineView clickedColumn],
                clickedRow = [theOutlineView clickedRow];

            if (clickedRow >= 0 && clickedCol >= 0)
            {
                var view = [theOutlineView preparedViewAtColumn:clickedCol row:clickedRow];
                if ([view isKindOfClass:[CPButton class]] && [view isEnabled])
                    result = NO;
            }
        }
    }

    return result;
}
/*
- (BOOL)outlineView:(CPOutlineView)ov shouldTrackCell:(CPView)cell forTableColumn:(CPTableColumn)tableColumn item:(id)item
{
    // We want to allow tracking for all the button cells, even if we don't allow selecting that particular row.
    if ([cell isKindOfClass:[CPButton class]]) {
        // We can also take a peek and make sure that the part of the cell clicked is an area that is normally tracked. Otherwise, clicking outside of the checkbox may make it check the checkbox
        var cellFrame = [outlineView frameOfCellAtColumn:[[outlineView tableColumns] indexOfObject:tableColumn] row:[outlineView rowForItem:item]];
        var hitTestResult = [cell hitTestForEvent:[CPApp currentEvent] inRect:cellFrame ofView:outlineView];
        if ((hitTestResult & CPCellHitTrackableArea) != 0) {
            return YES;
        } else {
            return NO;
        }
    } else {
        // Only allow tracking on selected rows. This is what CPTableView does by default.
        return [outlineView isRowSelected:[outlineView rowForItem:item]];
    }
}
*/

- (BOOL)outlineView:(CPOutlineView)theOutlineView writeItems:(CPArray)items toPasteboard:(CPPasteboard)pboard
{

    draggedNodes = items; // Don't retain since this is just holding temporaral drag information, and it is only used during a drag!  We could put this in the pboard actually.

    // Provide data for our custom type, and simple CPStrings.
    [pboard declareTypes:[CPArray arrayWithObjects:SIMPLE_PBOARD_TYPE, CPStringPboardType, nil] owner:self];

    // the actual data doesn't matter since SIMPLE_PBOARD_TYPE drags aren't recognized by anyone but us!.
    [pboard setData:[CPData data] forType:SIMPLE_PBOARD_TYPE];

    // Put string data on the pboard... notice you can drag into TextEdit!
    [pboard setString:[draggedNodes description] forType:CPStringPboardType];

    return YES;
}

- (BOOL)treeNode:(CPTreeNode)treeNode isDescendantOfNode:(CPTreeNode)parentNode
{
    while (treeNode != nil)
    {
        if (treeNode == parentNode)
            return YES;

        treeNode = [treeNode parentNode];
    }

    return NO;
}

- (CPDragOperation)outlineView:(CPOutlineView)theOutlineView validateDrop:(id)info proposedItem:(id)item proposedChildIndex:(CPInteger)childIndex
{
    // To make it easier to see exactly what is called, uncomment the following line:
    // CPLogConsole(@"outlineView:validateDrop:proposedItem:" + item + " proposedChildIndex:" + childIndex);

    // This method validates whether or not the proposal is a valid one.
    // We start out by assuming that we will do a "generic" drag operation, which means we are accepting the drop. If we return CPDragOperationNone, then we are not accepting the drop.
    var result = CPDragOperationEvery;

    if ([self onlyAcceptDropOnRoot])
    {
        // We are going to accept the drop, but we want to retarget the drop item to be "on" the entire outlineView
        [theOutlineView setDropItem:nil dropChildIndex:CPOutlineViewDropOnItemIndex];
    }
    else
    {
        // Check to see what we are proposed to be dropping on
        var targetNode = item;
        // A target of "nil" means we are on the main root tree
        if (targetNode == nil)
            targetNode = rootTreeNode;

        var nodeData = [targetNode representedObject];
        if (nodeData.container)
        {
            // See if we allow dropping "on" or "between"
            if (childIndex == CPOutlineViewDropOnItemIndex)
            {
                if (![self allowOnDropOnContainer])
                    // Refuse to drop on a container if we are not allowing that
                    result = CPDragOperationNone;
            }
            else
            {
                if (![self allowBetweenDrop])
                    // Refuse to drop between an item if we are not allowing that
                    result = CPDragOperationNone;
            }
        }
        else
        {
            // The target node is not a container, but a leaf. See if we allow dropping on a leaf. If we don't, refuse the drop (we may get called again with a between)
            if (childIndex == CPOutlineViewDropOnItemIndex && ![self allowOnDropOnLeaf])
                result = CPDragOperationNone;
        }

        // If we are allowing the drop, we see if we are draggng from ourselves and dropping into a descendent, which wouldn't be allowed...
        if (result != CPDragOperationNone)
        {
            if ([info draggingSource] == outlineView)
            {
                // Yup, the drag is originating from ourselves. See if the appropriate drag information is available on the pasteboard
                if (targetNode != rootTreeNode && [[info draggingPasteboard] availableTypeFromArray:[CPArray arrayWithObject:SIMPLE_PBOARD_TYPE]] != nil)
                {
                    var count = [draggedNodes count];
                    for (var i = 0; i < count; i++)
                    {
                        var draggedNode = [draggedNodes objectAtIndex:i];
                        if ([self treeNode:targetNode isDescendantOfNode:draggedNode])
                        {
                            // Yup, it is, refuse it.
                            result = CPDragOperationNone;
                            break;
                        }
                    }
                }
            }
        }

        [theOutlineView setDropItem:item dropChildIndex:childIndex];
    }
    // To see what we decide to return, uncomment this line
    CPLog(@"%@", result == CPDragOperationNone ? @" - Refusing drop" : @" + Accepting drop");

    return result;
}

- (BOOL)outlineView:(CPOutlineView)theOutlineView acceptDrop:(id)info item:(id)item childIndex:(CPInteger)childIndex
{
    var oldSelectedNodes = [self selectedNodes];

    var targetNode = item;
    // A target of "nil" means we are on the main root tree
    if (targetNode == nil)
        targetNode = rootTreeNode;

    var nodeData = [targetNode representedObject];

    // Determine the parent to insert into and the child index to insert at.
    if (!nodeData.container)
    {
        // If our target is a leaf, and we are dropping on it
        if (childIndex == CPOutlineViewDropOnItemIndex)
        {
            // If we are dropping on a leaf, we will have to turn it into a container node
            nodeData.container = YES;
            nodeData.expandable = YES;
            childIndex = 0;
        }
        else
        {
            // We will be dropping on the item's parent at the target index of this child, plus one
            var oldTargetNode = targetNode;
            targetNode = [targetNode parentNode];
            childIndex = [[targetNode childNodes] indexOfObject:oldTargetNode] + 1;
        }
    }
    else
    {
        if (childIndex == CPOutlineViewDropOnItemIndex)
            // ICPert it at the start, if we were dropping on it
            childIndex = 0;
    }

    var currentDraggedNodes = nil;
    // If the source was ourselves, we use our dragged nodes.
    if ([info draggingSource] == theOutlineView && [[info draggingPasteboard] availableTypeFromArray:[CPArray arrayWithObject:SIMPLE_PBOARD_TYPE]] != nil)
    {
        // Yup, the drag is originating from ourselves. See if the appropriate drag information is available on the pasteboard
        currentDraggedNodes = draggedNodes;
    }
    else
    {
        // We create a new model item for the dropped data, and wrap it in an CPTreeNode
        var string = [[info draggingPasteboard] stringForType:CPStringPboardType];
        if (string == nil)
        {
            // Try the filename -- it is an array of filenames, so we just grab one.
            var filename = [[[info draggingPasteboard] propertyListForType:CPFilenamesPboardType] lastObject];
            string = [filename lastPathComponent];
        }

        if (string == nil)
            string = @"Unknown data dragged";

	    var newNodeData = [SimpleNodeData nodeDataWithName:string];
        var treeNode = [CPTreeNode treeNodeWithRepresentedObject:newNodeData];
        newNodeData.container = NO;
        // Finally, add it to the array of dragged items to insert
        currentDraggedNodes = [CPArray arrayWithObject:treeNode];
    }

    var childNodeArray = [targetNode mutableChildNodes],
        count = [currentDraggedNodes count];

    // Go ahead and move things.
    for (var i = 0; i < count; i++)
    {
        var treeNode = [currentDraggedNodes objectAtIndex:i],
        // Remove the node from its old location
            oldIndex = [childNodeArray indexOfObject:treeNode],
            newIndex = childIndex;

        if (oldIndex != CPNotFound)
        {
            [childNodeArray removeObjectAtIndex:oldIndex];
            if (childIndex > oldIndex)
                newIndex--; // account for the remove
        }
        else
        {
            // Remove it from the old parent
            [[[treeNode parentNode] mutableChildNodes] removeObject:treeNode];
        }

        [childNodeArray insertObject:treeNode atIndex:newIndex];
        newIndex++;
    }

    [theOutlineView reloadData];
    // Make sure the target is expanded
    [theOutlineView expandItem:targetNode];
    // Reselect old items.
    [theOutlineView setSelectedItems:oldSelectedNodes];

    // Return YES to indicate we were successful with the drop. Otherwise, it would slide back the drag image.
    return YES;
}

// On Mac OS 10.5 and above, CPTableView and CPOutlineView have better contextual menu support. We now see a highlighted item for what was clicked on, and can access that item to do particular things (such as dynamically change the menu, as we do here!). Each of the contextual menus in the nib file have the delegate set to be the AppController instance. In menuNeedsUpdate, we dynamically update the menus based on the currently clicked upon row/column pair.
- (void)menuNeedsUpdate:(CPMenu)menu
{
    var clickedRow = [outlineView clickedRow],
        item = nil,
        nodeData = nil,
        clickedOnMultipleItems = NO;

    if (clickedRow != -1)
    {
        // If we clicked on a selected row, then we want to consider all rows in the selection. Otherwise, we only consider the clicked on row.
        item = [outlineView itemAtRow:clickedRow];
        nodeData = [item representedObject];
        clickedOnMultipleItems = [outlineView isRowSelected:clickedRow] && ([outlineView numberOfSelectedRows] > 1);
    }

    if (menu == outlineViewContextMenu)
    {
        var menuItem = [menu itemAtIndex:0];
        if (nodeData != nil)
        {
            if (clickedOnMultipleItems)
            {
                // We could walk through the selection and note what was clicked on at this point
                [menuItem setTitle:[CPString stringWithFormat:@"You clicked on %ld items!", [outlineView numberOfSelectedRows]]];
            }
            else
            {
                [menuItem setTitle:[CPString stringWithFormat:@"You clicked on: '%@'", nodeData.name]];
            }

            [menuItem setEnabled:YES];

        }
        else
        {
            [menuItem setTitle:@"You didn't click on any rows..."];
            [menuItem setEnabled:NO];
        }

    }
    else if (menu == expandableColumnMenu)
    {
        var menuItem = [menu itemAtIndex:0];
        if (!clickedOnMultipleItems && (nodeData != nil))
        {
            // The item will be enabled only if it is a group
            [menuItem setEnabled:nodeData.container];
            // Check it if it is expandable
            [menuItem setState:nodeData.expandable ? 1 : 0];
        }
        else
        {
            [menuItem setEnabled:NO];
        }
    }
}

- (IBAction)expandableMenuItemAction:(id)sender
{
    // The tag of the clicked row contains the item that was clicked on
    var clickedRow = [outlineView clickedRow],
        treeNode = [outlineView itemAtRow:clickedRow],
        nodeData = [treeNode representedObject];
    // Flip the expandable state,
    nodeData.expandable = !nodeData.expandable;
    // Refresh that row (since its state has changed)
    [outlineView setNeedsDisplayInRect:[outlineView rectOfRow:clickedRow]];
    // And collopse it if we can no longer expand it
    if (!nodeData.expandable && [outlineView isItemExpanded:treeNode])
        [outlineView collapseItem:treeNode];
}

- (IBAction)useGroupGrowLook:(id)sender
{
    // We simply need to redraw things.
    [outlineView setNeedsDisplay:YES];
}

- (IBAction)useBadges:(id)sender
{
    // FIXME: We simply need to redraw things.
    [outlineView setNeedsDisplay:YES];
}

@end

@implementation AppController(Private)

- (void)addNewDataToSelection:(SimpleNodeData)newChildData
{
    var selectedNodes = [self selectedNodes],
        selectedNode;
    // We are inserting as a child of the last selected node. If there are none selected, insert it as a child of the treeData itself
    if ([selectedNodes count] > 0)
        selectedNode = [selectedNodes lastObject];
    else
        selectedNode = rootTreeNode;

    // If the selected node is a container, use its parent. We access the underlying model object to find this out.
    // In addition, keep track of where we want the child.
    var childIndex,
        parentNode;

    var nodeData = [selectedNode representedObject];
    if (nodeData.container)
    {
        // Since it was already a container, we insert it as the first child
        childIndex = 0;
        parentNode = selectedNode;
    }
    else
    {
        // The selected node is not a container, so we use its parent, and insert after the selected node
        parentNode = [selectedNode parentNode];
        childIndex = [[parentNode childNodes] indexOfObject:selectedNode ] + 1; // + 1 means to insert after it.
    }

    // Now, create a tree node for the data and insert it as a child
    var childTreeNode = [CPTreeNode treeNodeWithRepresentedObject:newChildData];
    [[parentNode mutableChildNodes] insertObject:childTreeNode atIndex:childIndex];
    // Then, reload things and attempt to select the new child tree node and start editing the text.
    [outlineView reloadData];
    // Make sure it is expanded
    [outlineView expandItem:[childTreeNode parentNode]];
    var newRow = [outlineView rowForItem:childTreeNode];
    if (newRow >= 0)
    {
        [outlineView selectRowIndexes:[CPIndexSet indexSetWithIndex:newRow] byExtendingSelection:NO];
        var column = 0;
        // With "full width" cells, there is no column
        if (newChildData.container && [useGroupRowLook state])
        {
            column = -1;
        }

        [outlineView editColumn:column row:newRow withEvent:nil select:YES];
    }
}

- (CPImage)randomIconImage
{
    // The first time through, we create a random array of images to use for the items.
    if (iconImages == nil)
    {
        iconImages = [CPArray array];
        // There is a set of images with the format "Image<number>.tiff" in the Resources directory. We go through and add them to the array until we are out of images.
        for (var i = 1 ; i < 15; i++)
        {
            // The typcast to a long and the use of %ld allows this application to easily be compiled as 32-bit or 64-bit+
            var imagePath = [[CPBundle mainBundle] pathForResource:@"Images/Image" + i + ".png"];
            var image = [[CPImage alloc] initWithContentsOfFile:imagePath];
                // Add the image to our array and loop to the next one
            [iconImages addObject:image];
         }
    }

    // We systematically iterate through the image array and return a result. Keep track of where we are in the array with a static variable.
    if (this.imageNum == nil)
        this.imageNum = 0;

    var imageNum = this.imageNum;

    var result = [iconImages objectAtIndex:imageNum];
    imageNum++;
    // Once we are at the end of the array, start over
    if (imageNum == [iconImages count])
        imageNum = 0;

    this.imageNum = imageNum;

    return result;
}


- (CPTreeNode)treeNodeFromDictionary:(CPDictionary)dictionary
{
    // We will use the built-in CPTreeNode with a representedObject that is our model object - the SimpleNodeData object.
    // First, create our model object.
    var nodeName = [dictionary objectForKey:NAME_KEY];
    var nodeData = [SimpleNodeData nodeDataWithName:nodeName];
    // The image for the nodeData is lazily filled in, for performance.

    // Create a CPTreeNode to wrap our model object. It will hold a cache of things such as the children.
    var result = [CPTreeNode treeNodeWithRepresentedObject:nodeData];

    // Walk the dictionary and create CPTreeNodes for each child.
    var children = [dictionary objectForKey:CHILDREN_KEY];
    var count = [children count];

    for (var i = 0; i < count; i++)
    {
        // A particular item can be another dictionary (ie: a container for more children), or a simple string
        var item = [children objectAtIndex:i],
            childTreeNode;
        if ([item isKindOfClass:[CPDictionary class]])
        {
            // Recursively create the child tree node and add it as a child of this tree node
            childTreeNode = [self treeNodeFromDictionary:item];
        }
        else
        {
            // It is a regular leaf item with just the name
            var childNodeData = [[SimpleNodeData alloc] initWithName:item];
            childNodeData.container = NO;
            childTreeNode = [CPTreeNode treeNodeWithRepresentedObject:childNodeData];
            [childNodeData release];
        }
        // Now add the child to this parent tree node
        [[result mutableChildNodes] addObject:childTreeNode];
    }

    return result;
}

@end
