//
// IPHONE AND COCOA DEVELOPMENT AUSP10
//	
//  ImageEditViewController.h
//	HW9
//
//  Copyright 2010 Chris Parrish
//
#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <QuartzCore/QuartzCore.h>


@interface ImageEditViewController : NSViewController
{
	IKImageView*		imageView_;
	IKSaveOptions*		saveOptions_;
}

@property (nonatomic, assign) IBOutlet IKImageView* imageView;
@property (nonatomic, assign) IBOutlet NSView*		filterContainerView;

-(IBAction)doZoom:(id)sender;
-(IBAction)switchToolMode:(id)sender;
-(IBAction)doCropAction:(id)sender;
-(IBAction)doFinsihedEditingAction:(id)sender;


@end
