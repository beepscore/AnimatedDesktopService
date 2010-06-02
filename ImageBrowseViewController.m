//
// IPHONE AND COCOA DEVELOPMENT AUSP10
//	
//  ImageBrowseViewController.m
//	HW9
//
//  Copyright 2010 Chris Parrish
//

#import "ImageBrowseViewController.h"

#import "ApplicationController.h"
#import "FilePathImageObject.h"
#import <Quartz/Quartz.h>

@interface ImageBrowseViewController ()

- (void) addImagesFromDirectory:(NSString*) path;
- (void) addImagesFromDirectory:(NSString *)path atIndex:(NSUInteger)index;
- (void) addImageWithPath:(NSString *)path atIndex:(NSUInteger)index;
- (void) addImageWithPath:(NSString *)path;
- (void) updateSendButtonState;

@end

@implementation ImageBrowseViewController

@synthesize imageBrowser = imageBrowser_;
@synthesize zoomSlider = zoomSlider_;
@synthesize sendButton = sendButton_;

- (void) dealloc
{
	[images_ release];
	[super dealloc];
}

- (NSString*) nibName
{
	return @"ImageBrowsingView";
}


-(void) awakeFromNib
{
	// Setup the browser with some default images that should be installed on the system
    images_ = [[NSMutableArray alloc] init];
    
    // add images from application bundle
    NSString* gifPath = [[NSBundle mainBundle] pathForResource:@"predict" ofType:@"gif"];    
    [self addImageWithPath:gifPath];
    NSString* jpgPath = [[NSBundle mainBundle] pathForResource:@"baileySit100514" ofType:@"jpg"];    
    [self addImageWithPath:jpgPath];
    NSString *pngPath = [[NSBundle mainBundle] pathForResource:@"russianRocket" ofType:@"png"];
    [self addImageWithPath:pngPath];
    	
	[self addImagesFromDirectory:@"/Library/Desktop Pictures/"];	
	
	// sync up the zoom slider and the image browser zoom level
	
	[imageBrowser_ setZoomValue:[zoomSlider_ floatValue]];
	
	// Make sure the image browser allows reordering
	[imageBrowser_ setAllowsReordering:YES];
    [imageBrowser_ setAnimates:YES];
	
	// Set up the style of image cells in the browser
	[imageBrowser_ setCellsStyleMask:IKCellsStyleTitled | IKCellsStyleShadowed];
	[imageBrowser_ setConstrainsToOriginalSize:YES];	
	
	//synchronize the send button state with the selection
	[self updateSendButtonState];
	
}

- (void) updateSendButtonState
{
	// Enable or disable the send button based on the selection. If there is no selection disale the button
	
	BOOL enabled = [[imageBrowser_ selectionIndexes] count] > 0;
	[sendButton_ setEnabled:enabled];
}


#pragma mark -
#pragma mark Adding Images

- (void) addImageWithPath:(NSString*)filePath selectInBrowser:(BOOL)select
{	
	NSUInteger index = [images_ count];
	
	FilePathImageObject* imageObject = [[FilePathImageObject alloc] init];	
	imageObject.filePath = filePath;
	[images_ insertObject:imageObject atIndex:index];
	[imageObject release];	
	
	[imageBrowser_ reloadData];

	if (select)
	{
		NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:index];
		[imageBrowser_ setSelectionIndexes:indexSet byExtendingSelection:NO];
		[imageBrowser_ scrollIndexToVisible:index];
	}
}

- (void) addImageWithPath:(NSString *)path
{
	[self addImageWithPath:path atIndex:[images_ count]];
}

- (void) addImageWithPath:(NSString *)path atIndex:(NSUInteger)index
{   
	
    FilePathImageObject* imageObject;
    
    NSString* filename = [path lastPathComponent];
	
	//skip hidden directories and files
	if([filename length] > 0)
	{		
		if ( [filename characterAtIndex:0] == L'.')
			return;	
	}
	
	BOOL isDirectory = NO;
	[[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
	
	if (isDirectory)
	{
		[self addImagesFromDirectory:path atIndex:index];
		return;
	}
	
	imageObject = [[FilePathImageObject alloc] init];	
	imageObject.filePath = path;
	[images_ insertObject:imageObject atIndex:index];
	[imageObject release];
}

- (void) addImagesFromDirectory:(NSString *) path
{
	[self addImagesFromDirectory:path atIndex:[images_ count]];
}


- (void) addImagesFromDirectory:(NSString *)path atIndex:(NSUInteger)index
{
    int i, n;
    BOOL dir;
	
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&dir];
    
    if(dir)
	{
        NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
		
        n = [content count];
        
        for(i=0; i<n; i++)
			[self addImageWithPath:[path stringByAppendingPathComponent:[content objectAtIndex:i]] atIndex:index];
    }
    else
        [self addImageWithPath:path];
	
	[imageBrowser_ reloadData];
}


#pragma mark -
#pragma mark Actions

- (NSImage*) selectedImage
{
	NSIndexSet* selected = [imageBrowser_ selectionIndexes];
	NSUInteger selectedImage = [selected firstIndex];
	// we only allow single selection by property setting in IB on the
	// IKImageBrowserView so we should only have a single selected index
	
	// we need an NSImage for the image selected
	FilePathImageObject* imageObject = [images_ objectAtIndex:selectedImage];
	
	NSImage* image = [[[NSImage alloc] initWithContentsOfFile:imageObject.filePath] autorelease];
	return image;
}

- (IBAction) sendImage:(id)sender
{
	
	[[ApplicationController sharedApplicationController] sendImage:[self selectedImage]];
}

- (IBAction) addImages:(id)sender
{
    NSOpenPanel* panel;
	
    panel = [NSOpenPanel openPanel];        
	
    [panel setFloatingPanel:YES];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:YES];
	
	NSInteger buttonPressed = [panel runModal];
	
	if( buttonPressed == NSOKButton )
	{
		NSArray* filePaths = [panel filenames];
		for (NSString* filePath in filePaths)
		{
			[self addImagesFromDirectory:filePath];
		}
    }
    
}

- (IBAction) zoomChanged:(id)sender
{
	[imageBrowser_ setZoomValue:[sender floatValue]];
}


#pragma mark -
#pragma mark IKImageBrowserDataSource

/* implement image-browser's datasource protocol 
 Our datasource representation is a simple mutable array
 */

- (NSUInteger) numberOfItemsInImageBrowser:(IKImageBrowserView *) view
{
    return [images_ count];
}

- (id) imageBrowser:(IKImageBrowserView *) aBrowser itemAtIndex:(NSUInteger)index;

{
    return [images_ objectAtIndex:index];
}

- (void) imageBrowser:(IKImageBrowserView *)view removeItemsAtIndexes:(NSIndexSet *)indexes
{
    [images_ removeObjectsAtIndexes:indexes];
}

- (BOOL) imageBrowser:(IKImageBrowserView *)view  moveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)destinationIndex
{
	NSUInteger index;
	NSMutableArray* temporaryArray;
	
	temporaryArray = [[[NSMutableArray alloc] init] autorelease];
	
	// remove items from the end working our way back to the first item
	// this keeps the indexs we haven't moved yet from shifting to a new position
	// before we get to them
	for( index = [indexes lastIndex];
		index != NSNotFound;
		index = [indexes indexLessThanIndex:index] )
	{
		if (index < destinationIndex)
			destinationIndex--;
		
		FilePathImageObject* image = [images_ objectAtIndex:index];
		[temporaryArray addObject:image];
		[images_ removeObjectAtIndex:index];
	}
	
	// Insert at the new destination
	int n = [temporaryArray count];
	for( index = 0; index < n; index++)
	{
		[images_ insertObject:[temporaryArray objectAtIndex:index]
					  atIndex:destinationIndex];
	}
	
	return YES;
}


#pragma mark -
#pragma mark IKImageBrowserDelegate

- (void) imageBrowser:(IKImageBrowserView *) aBrowser cellWasDoubleClickedAtIndex:(NSUInteger) index
{
	// double click is starts an edit on the image selected
	
	NSIndexSet* selected = [imageBrowser_ selectionIndexes];
	NSUInteger selectedImage = [selected firstIndex];
	FilePathImageObject* imageObject = [images_ objectAtIndex:selectedImage];
	
	[[ApplicationController sharedApplicationController] beginEditImageWithFilePath:imageObject.filePath];
}

- (void) imageBrowserSelectionDidChange:(IKImageBrowserView *) aBrowser
{
	[self updateSendButtonState];
}


#pragma mark -
#pragma mark  Drag and Drop

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	return [self draggingUpdated:sender];
}


- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	if ([sender draggingSource] == imageBrowser_) 
		return NSDragOperationMove;
	
    return NSDragOperationCopy;
}


- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender
{
    NSData*		data				= nil;
    NSString*	errorDescription	= nil;
    
	// if we are dragging from the browser itself, ignore it
	if ([sender draggingSource] == imageBrowser_) 
		return NO;
	
    NSPasteboard* pasteboard = [sender draggingPasteboard];
    
    if ([[pasteboard types] containsObject:NSFilenamesPboardType])
	{
        data = [pasteboard dataForType:NSFilenamesPboardType];
		
        NSArray* filePaths = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:kCFPropertyListImmutable format:nil errorDescription:&errorDescription];		
		
		
		for (NSString* filePath in filePaths)
		{
			[self addImageWithPath:filePath atIndex:[imageBrowser_ indexAtLocationOfDroppedItem]];
		}
		
		[imageBrowser_ reloadData];
    }
	
	return YES;
}



@end

