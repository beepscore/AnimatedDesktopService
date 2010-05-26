//
// IPHONE AND COCOA DEVELOPMENT AUSP10
//	
//  ImageEditViewController.m
//	HW9
//
//  Copyright 2010 Chris Parrish
//
#import "ImageEditViewController.h"
#import "ApplicationController.h"


@interface ImageEditViewController ()

- (void)saveCurrentImageAndEndEditing;
- (void)finishEditingWithImagePath:(NSString*)imagePath;

@end


@implementation ImageEditViewController

@synthesize imageView = imageView_;
@synthesize filterContainerView = filterContainerView_;

- (void) dealloc
{	
	[super dealloc];
}


#pragma mark -
#pragma mark Nib Loading

- (void)awakeFromNib
{
	[imageView_ setAutoresizes:YES];
    [imageView_ setDoubleClickOpensImageEditPanel: YES];
    [imageView_ setCurrentToolMode: IKToolModeMove];
}


- (NSString*) nibName
{
	return @"ImageEditingView";
}


#pragma mark -
#pragma mark Actions

- (IBAction)doZoom:(id) sender
{
	
    NSInteger zoom;
	
    if ( [sender isKindOfClass: [NSSegmentedControl class]] )
	{
			zoom = [sender selectedSegment];
	}
	else
	{
		zoom = [sender tag];
	}	
	switch (zoom)
	{
		case 0:
			[imageView_ zoomOut:self];
			break;
		case 1:
			[imageView_ zoomIn:self];
			break;
		case 2:
			[imageView_ zoomImageToActualSize: self];
			break;
		case 3:
			[imageView_ zoomImageToFit: self];
			break;
	}
}

- (IBAction)switchToolMode: (id)sender
{	
    NSInteger newTool;
    if ([sender isKindOfClass: [NSSegmentedControl class]])
        newTool = [sender selectedSegment];
		else
			newTool = [sender tag];
			
			switch (newTool)
		{
			case 0:
				[imageView_ setCurrentToolMode: IKToolModeMove];
				break;
			case 1:
				[imageView_ setCurrentToolMode: IKToolModeRotate];
				break;
			case 2:
				[imageView_ setCurrentToolMode: IKToolModeCrop];
				break;
		}
}


-(IBAction)doCropAction:(id)sender
{
	[imageView_ crop:sender];
}

-(IBAction)doFinsihedEditingAction:(id)sender
{
	
	// right now, this code always assumes that the image needs to be saved
	// what would be nice is to note if there have been no edits
	// and then only bring this alert up if the image is 'dirty'
	
	NSAlert* alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:@"Save image"];
	[alert addButtonWithTitle:@"Continue without saving"];
	[alert setMessageText:@"Save Image?"];
	[alert setInformativeText:@"Save your image before leaving edit mode?"];
	[alert setAlertStyle:NSWarningAlertStyle];
	
	[alert beginSheetModalForWindow:[self.view window]
					  modalDelegate:self
					  didEndSelector:@selector(saveImageSheetDidEnd:returnCode:contextInfo:)
						contextInfo:nil];
	

}


- (void) finishEditingWithImagePath:(NSString*)imagePath
{
	IKImageEditPanel* editor = [IKImageEditPanel sharedImageEditPanel];
	[editor close];
	[[ApplicationController sharedApplicationController] finishEditImageWithNewFilePath:imagePath];
}

- (void) saveImageSheetDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSAlertFirstButtonReturn)
	{
		// Note : this litte trick of performing the selector 
		//        with a delay ensures that the previous sheet is allowed
		//        to finish dismissing before we bring up the next sheet. 
		[self performSelector:@selector(saveCurrentImageAndEndEditing) withObject:nil afterDelay:0];
	}
	else
	{
		[self finishEditingWithImagePath:nil];
	}

}

#pragma mark -
#pragma mark Saving

- (void)saveCurrentImageAndEndEditing
{
	
	// One nice improvement here would be to start of defaulting to the
	// same image format and name as the original image,
	// instead of picking a new name and the jpeg format
	
	// Bring up a save panel to save the edited image to a new location
    NSSavePanel * savePanel = [NSSavePanel savePanel];
    saveOptions_ = [[IKSaveOptions alloc]
					initWithImageProperties: [imageView_ imageProperties]
					imageUTType: (NSString*)kUTTypeJPEG];
    [saveOptions_ addSaveOptionsAccessoryViewToSavePanel: savePanel];
	
    NSString * fileName = @"My Great Image";
    [savePanel beginSheetForDirectory: NULL
								 file: fileName
					   modalForWindow: [self.view window]
						modalDelegate: self
					   didEndSelector: @selector(savePanelDidEnd:returnCode:contextInfo:)
						  contextInfo: NULL];	
}

- (void)savePanelDidEnd: (NSSavePanel *)sheet
             returnCode: (int)returnCode
            contextInfo: (void *)contextInfo
{
    if (returnCode == NSOKButton)
    {
        NSString* path		= [sheet filename];
        NSString* newUTType = [saveOptions_ imageUTType];
        CGImageRef image;
		
        image = [imageView_ image];
        if (image)
        {
            NSURL * url = [NSURL fileURLWithPath: path];
            CGImageDestinationRef dest = CGImageDestinationCreateWithURL((CFURLRef)url,
																		 (CFStringRef)newUTType, 1, NULL);
            if (dest)
            {
                CGImageDestinationAddImage(dest, image,
										   (CFDictionaryRef)[saveOptions_ imageProperties]);
                CGImageDestinationFinalize(dest);
                CFRelease(dest);
            }
        }
		else
        {
            NSLog(@"*** saveImageToPath - no image");
        }
		
		[self finishEditingWithImagePath:path];
    }
	else
	{
		// Don't do anything if they choose to cancel		
	}
}


@end