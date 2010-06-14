//
// IPHONE AND COCOA DEVELOPMENT AUSP10
//	
//  ApplicationController.m
//	HW9
//
//  Copyright 2010 Chris Parrish
//  portions Copyright Beepscore LLC 2010. All rights reserved.
//
//  sharedApplicationController is a singleton object

#import <Cocoa/Cocoa.h>

// import ImageShareService.h to see the ImageShareServiceProtocol declaration
#import "ImageShareService.h"

@class ImageBrowseViewController;
@class ImageEditViewController;

// declare ApplicationController implements ImageShareServiceProtocol
@interface ApplicationController : NSObject  <ImageShareServiceProtocol>
{
	ImageShareService*			imageShareService_;
	
	NSView*						statusView_;
	NSView*						logView_;
	NSView*						sendingView_;
	CIFilter*					transitionFilter_;

	NSTextView*					logTextField_;
	NSImageView*				sendingPreviewImage_;
	NSProgressIndicator*		sendingProgress_;

	NSView*						contentHolder_;
	NSView*						contentView_;
	
	ImageBrowseViewController*	imageBrowseController_;
	ImageEditViewController*	imageEditController_;
    
    CIImage * restrictedshineImage;
    NSString* filterName;
}
// Apple recommends on Mac assign IBOutlet, on iPhone retain IBOutlet
// applies only to nib top-level objects?

// Status view is a container view that will swap between
// showing either the log view or the sending view
@property (nonatomic, assign) IBOutlet NSView*			statusView;

// NOTE : retain these views, because we are going to
//        add and remove them from the hiearchy and we don't want
//        their retain count to go to zero when swapped
@property (nonatomic, retain) IBOutlet NSView*			logView;
@property (nonatomic, retain) IBOutlet NSView*			sendingView;

@property (nonatomic, assign) IBOutlet NSTextView*		logTextField;
@property (nonatomic, assign) IBOutlet NSImageView*		sendingPreviewImage;
@property (nonatomic, assign) IBOutlet NSProgressIndicator* sendingProgress;

// Content holder is a simple view that is the holder for the image editing
// and image browsing views that we swap in and out. This can make some
// management of the view easier by defining a frame that the content is allowed up.
@property (nonatomic, assign) IBOutlet NSView*			contentHolder;

@property (nonatomic, retain) NSString *filterName;

+ (ApplicationController*)sharedApplicationController;

- (void) startService;
- (void) appendStringToLog:(NSString*)logString;


- (void) beginEditImageWithFilePath:(NSString*)filePath;
- (void) finishEditImageWithNewFilePath:(NSString*)filePath;

- (void) sendImage:(NSImage*)image;

- (CIImage *)restrictedshineImage;

- (void)setupDissolveTransition;
- (void)setupFlashTransition;
- (void)setupModTransition;
- (void)setupPageCurlTransition;
- (void)setupRippleTransition;
- (CIImage *)ciImageFromNSImage:(NSImage*)nsImage;

@end
