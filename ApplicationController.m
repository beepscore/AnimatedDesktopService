//
// IPHONE AND COCOA DEVELOPMENT AUSP10
//	
//  ApplicationController.m
//	HW9
//
//  Copyright 2010 Chris Parrish
//

#import "ApplicationController.h"
#import "ImageShareService.h"
#import "ImageBrowseViewController.h"
#import "ImageEditViewController.h"


#pragma mark Static
static ApplicationController*		sharedApplicationController = nil;

@interface ApplicationController ()

- (void) presentContentViewController:(NSViewController*)controller;
- (void) presentEditingViewWithImageURL:(NSURL*)imagePathURL;
- (void) presentBrowsingView;

- (void) presentLogView;
- (void) presentSendingView;

@end

@implementation ApplicationController

@synthesize contentHolder = contentHolder_;
@synthesize statusView = statusView_;
@synthesize logView = logView_;
@synthesize sendingView = sendingView_;

@synthesize logTextField = logTextField_;
@synthesize sendingPreviewImage = sendingPreviewImage_;
@synthesize sendingProgress = sendingProgress_;


#pragma mark Singleton

// Note : This is how Apple recommends implementing a singleton class :

+ (ApplicationController*)sharedApplicationController
{
    if (sharedApplicationController == nil)
	{
        sharedApplicationController = [[super allocWithZone:NULL] init];
    }
    return sharedApplicationController;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [[self sharedApplicationController] retain];
}


- (id) init
{
	self = [super init];
	if (self != nil)
	{
		transitionFilter_ = nil;
		imageBrowseController_ = nil;
		imageEditController_ = nil;
	}
	return self;
}

- (void) dealloc
{
	[imageBrowseController_ release];
	imageBrowseController_ = nil;
	
	[imageEditController_ release];
	imageEditController_ = nil;
	
	[transitionFilter_ release];
	transitionFilter_ = nil;
	
	[super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;  //denotes an object that cannot be released
}

- (void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}

#pragma mark -
#pragma mark Nib Loading

- (void) awakeFromNib
{
	// Go ahead and create both of our view controllers
	// In some situations you might do this on demand to control memory use for instance
	imageBrowseController_ = [[ImageBrowseViewController alloc] initWithNibName:@"ImageBrowsingView" bundle:nil];
    
	imageEditController_ = [[ImageEditViewController alloc] initWithNibName:@"ImageEditingView" bundle:nil];
	
	
	// TODO: HW_TODO : 
	// Set up a Core Image filter to use for transitions between log and status view
	// Do this here so we only create the filter once and reuse it
	// You can create it on demand right before you use it as well
	
	// REMEMBER : CATransition ANIMATIONS REQUIRE A CORE IMAGE FILTER WITH THE FOLLOWING PARAMETERS:
	// input keys :
	//	  'inputImage', 'inputTargetImage' and 'inputTime' input
	// output key :
	//	  'outputImage'
	// optional input:
	//    'inputExtent'
	
	// ALL OF THE FILTERS IN THE CATEGORY CICategoryTransition FIT THE REQUIREMENTS
	
	
	// CREATE THE CIFilter INSTANCE
	
	// SET THE FILTER TO ITS DEFAULT PARAMETERS WITH setDefaults
	
	// SET ANY PARAMETERS FOR WHICH THE DEFAULTS ARE NOT SUFFICIENT
	
	// start on the image browsing view
	[self presentBrowsingView];
	
	// start on with log view shown
	[self presentLogView];
	
	[sendingProgress_ setHidden:YES];
}

#pragma mark -
#pragma mark Service

- (void) appendStringToLog:(NSString*)logString
{
	NSString* newString = [NSString stringWithFormat:@"%@\n", logString];
	[[[logTextField_ textStorage] mutableString] appendString: newString];
}

- (void) startService
{
	imageShareService_ = [[ImageShareService alloc] init];
	[imageShareService_ startService];
	[imageShareService_ publishService];
}

- (void) sendImage:(NSImage*)image
{
	// First, swap over to the sending view
	// startup the progress indicator 
	// and then start the send
	
	[sendingPreviewImage_ setImage:[imageBrowseController_ selectedImage]];
	
	[self presentSendingView];
}

- (void) beginSendingImage:(NSImage*)image
{
	// First we will show and start the progress indicator
	// NOTE : I found that the bar style progress inidcator
	//        would not animate when it used a layer backed view required for 
	//        core animation. Only the spinning indicator seems to work here
	
	[sendingProgress_ setHidden:NO];
	[sendingProgress_ startAnimation:self];
	
	// Because the send is not asynchronous, we block here until the send is finished
	// but the progress indicator should continue to animate
	// NOTE: I DO NOT RECOMMEND YOU SHIP A PRODUCT WITH THIS SYNCHRONOUS 
	//       SENDING. THE BEACH BALL IS BAD!
	[imageShareService_ sendImageToClients:image];	
	
	// once we return from the synchronous sending, 
	// stop the progress indicator and hide it
	[sendingProgress_ stopAnimation:self];
	[sendingProgress_ setHidden:YES];
	
	
	// finally go back to the log view
	[self presentLogView];
}


#pragma mark -
#pragma mark Status View

- (void) presentLogView
{
	// Size the log view to match the status area
	// the size of the status area may have changed since the last
	// time this view was in the status area	
	NSRect statusBounds = [statusView_ bounds];
	[logView_ setFrame:statusBounds];
    
	
	// TODO: HW_TODO :
	
	// CREATE THE CATransition ANIMATION
	
	// SET ANY PARAMETERS ON IT ( TIMING FUNCTION, DURATION
	
	// SET THE FILTER FOR THE CATransition TO THE CIFilter YOU WANT TO USE
    
	// CREATE A DICTIONARY WITH KEY PAIRS. 
	// KEY == ANIMATION ACITON  ("subviews")
	// VALUE == THE CATransition ANIMATION YOU WANT TO USE
	// THIS WILL CAUSE THE ANIMATION TO FIRE WHENEVER THE SUBVIEWS OF THE STATUS
	// VIEW ARE CHANGED
	
	// ADD THE ANIMATION DICTONARY TO THE VIEW THAT WILL HAVE ITS SUBVIEWS EXCHANGED
	// THIS VIEW IS statusView_ AND THE METHOD IS setAnimations:
	
	
	// finally, swap the subviews.
	// WITHOUT SETTING OUR OWN ANIMATION, THIS WILL USE THE IMPLICIT ANIMATION
	// ASSOCIATED WITH THIS VIEW BECAUSE WE HAVE MADE IT A LAYER BACKED VIEW
	[[statusView_ animator] replaceSubview:sendingView_ with:logView_];
	
}


- (void) presentSendingView
{
	// Size the sending view to match the status area
	// the size of the status area may have changed since the last
	// time this view was in the status area	
	NSRect statusBounds = [statusView_ bounds];
	[sendingView_ setFrame:statusBounds];
    
    
	// TODO: HW_TODO :
	
	// CREATE THE CATransition ANIMATION
    
	// SET ANY PARAMETERS ON IT ( TIMING FUNCTION, DURATION
	
	// SET THE FILTER FOR THE CATransition TO THE CIFilter YOU WANT TO USE
	
	// SPECIAL WORK FOR THIS CASE :
	// WE WANT TO START SENDING AFTER THE ANIMATION FINISHES
	// TO DO THAT, WE SET OURSELVES AS THE DELEGATE FOR THIS ANIMATION
	// AND WE START THE ACTUAL IMAGE SENDING IN THE DELEGATE METHOD
	// THAT IS CALLED FOR ANIMATION ENDING
	
	// CREATE A DICTIONARY WITH KEY PAIRS. 
	// KEY == ANIMATION ACITON  ("subviews")
	// VALUE == THE CATransition ANIMATION YOU WANT TO USE
	// THIS WILL CAUSE THE ANIMATION TO FIRE WHENEVER THE SUBVIEWS OF THE STATUS
	// VIEW ARE CHANGED
	
	// ADD THE ANIMATION DICTONARY TO THE VIEW THAT WILL HAVE ITS SUBVIEWS EXCHANGED
	// THIS VIEW IS statusView_ AND THE METHOD IS setAnimations:	
    
	// finally, swap the subviews. This will animate as long as the 
	// "subviews" key has an associated animation
	
	
	// NOTE : WE WANT TO FIRE OFF SENDING AT THE COMPLETION OF THE IMPLICIT ANIMATION
	//        UNTIL WE HAVE THE REAL ANIMATION IN PLACE
	//        TO DO THIS WE WILL HAVE A BLOCK THAT FIRES OFF AS A RESULT 
	//        OF COMPLETING A CATransaction. THIS IS JUST A PLACE HOLDER
	//        UNTIL YOU PROVIDE YOUR OWN ANIMATION ABOVE. WHEN YOU SET THE DELEGATE OF THAT
	//        ANIMATION animationDidStop:finished: WILL BE CALLED WHICH DOES THE SAME
	//        THING AS THE BLOCK HERE
	
    
     // REMOVE THIS LINE WHEN YOU HAVE YOUR ANIMATION ADDED WITH self AS THE DELEGATE
	[CATransaction begin];
    // REMOVE THIS LINE TOO
	[CATransaction setCompletionBlock:^(void){[self beginSendingImage:[imageBrowseController_ selectedImage]];}];     
    
	// ????: SB- keep this line?
    [[statusView_ animator] replaceSubview:logView_ with:sendingView_];		

    // AND REMOVE THIS LINE
    [CATransaction commit];
    
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
	// this is called when our animation has finished. In this case we know 
	// that this is the end of presentation of the sending view image, 
	// so we will no fire off the actual send. 
	
	// In this particular case the delegate is called twice, once with finsihed 
	// false and once later with it true. We only want to react when flag
	// is true indicating that the anination has truly finished 
	
	// ( I honestly do not know for sure why its called twice. I suspect
	//   its related to how the implicit animation we are replacing works )
	if ( flag )
    {
		[self beginSendingImage:[imageBrowseController_ selectedImage]];        
    }
}



#pragma mark -
#pragma mark Image Editing
- (void) beginEditImageWithFilePath:(NSString*)filePath
{
	NSURL* imagePathURL = [NSURL fileURLWithPath:filePath];
	[self presentEditingViewWithImageURL:imagePathURL];
}

- (void) finishEditImageWithNewFilePath:(NSString*)filePath
{
	if ( filePath )
	{
		// if we have a new file as a result of saving the edits,
		// add it to our images in the browsers data source
		[imageBrowseController_ addImageWithPath:filePath selectInBrowser:YES];
	}
	
	// return to browing view
	
	[self presentBrowsingView];
}


#pragma mark -
#pragma mark View Controllers

- (void) presentEditingViewWithImageURL:(NSURL*)imagePathURL
{
	[self presentContentViewController:imageEditController_];
	[imageEditController_.imageView setImageWithURL:imagePathURL];
	[imageEditController_.imageView zoomImageToFit: self];
    
}

- (void) presentBrowsingView
{
	[self presentContentViewController:imageBrowseController_];
}


- (void) presentContentViewController:(NSViewController*)controller
{
	if ( contentView_ == [controller view] )
		return;
	
	NSRect contentBounds = [contentHolder_ bounds];
	NSView* newView = [controller view];
	[newView setFrame:contentBounds];
	
	if ( contentView_ == nil )
	{
		// if the content view is being set for the first time, no need to swap
		contentView_ = [controller view];
		[contentHolder_ addSubview:contentView_];
	}
	else
	{
		[contentHolder_ replaceSubview:contentView_ with:newView];
		contentView_ = newView;
	}
}


@end





