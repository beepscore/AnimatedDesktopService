//
// IPHONE AND COCOA DEVELOPMENT AUSP10
//	
//  ImageBrowseViewController.h
//	HW9
//
//  Copyright 2010 Chris Parrish
//
//  This class conforms to two IKImageBrowserView informal protocols: 
//  IKImageBrowserDataSource and IKImageBrowserDelegate.
#import <Cocoa/Cocoa.h>

@class IKImageBrowserView;

@interface ImageBrowseViewController : NSViewController
{
	IKImageBrowserView*		imageBrowser_;
	NSSlider*				zoomSlider_;
	NSButton*				sendButton_;
	
	NSMutableArray*			images_;
}

@property (nonatomic, assign) IBOutlet IKImageBrowserView*	imageBrowser;
@property (nonatomic, assign) IBOutlet NSSlider*			zoomSlider;
@property (nonatomic, assign) IBOutlet NSButton*			sendButton;

- (IBAction)	sendImage:(id)sender;
- (IBAction)	addImages:(id)sender;
- (IBAction)	zoomChanged:(id)sender;

- (void) addImageWithPath:(NSString*)filePath selectInBrowser:(BOOL)select;
- (NSImage*) selectedImage;

@end
