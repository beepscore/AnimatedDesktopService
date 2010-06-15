//
// IPHONE AND COCOA DEVELOPMENT AUSP10
//	
//  ApplicationController.m
//	HW9
//
//  portions Copyright 2010 Chris Parrish
//  portions Copyright Beepscore LLC 2010. All rights reserved.
//
//  Reference: ViewTransitionsAppDelegate

#import "ApplicationController.h"
#import "ImageBrowseViewController.h"
#import "ImageEditViewController.h"

#pragma mark Static
static ApplicationController*		sharedApplicationController = nil;

// declare class extension (anonymous category) for "private" methods, avoid showing in .h file
// Note in Objective C no method is private, it can be called from elsewhere.
// Ref http://stackoverflow.com/questions/1052233/iphone-obj-c-anonymous-category-or-private-category
@interface ApplicationController ()

- (void) presentContentViewController:(NSViewController*)controller;
- (void) presentEditingViewWithImageURL:(NSURL*)imagePathURL;
- (void) presentBrowsingView;

- (void) presentLogView;
- (void) presentSendingView;

@end

@implementation ApplicationController

const CGFloat kTransitionDuration = 1.0;

@synthesize contentHolder = contentHolder_;
@synthesize statusView = statusView_;
@synthesize logView = logView_;
@synthesize sendingView = sendingView_;

@synthesize logTextField = logTextField_;
@synthesize sendingPreviewImage = sendingPreviewImage_;
@synthesize sendingProgress = sendingProgress_;

@synthesize filterName;

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
    
    [filterName release];
    filterName = nil;
    
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
	// Alternatively, you could create it on demand right before you use it (SB edited)
    
    // CREATE THE CIFilter INSTANCE
    // http://developer.apple.com/mac/library/documentation/GraphicsImaging/Reference/CoreImageFilterReference/Reference/reference.html#//apple_ref/doc/uid/TP40004346
    // http://www.devonferns.com/cocoablog/?p=3
    
	// SET THE FILTER TO ITS DEFAULT PARAMETERS WITH setDefaults
    
    // SET ANY PARAMETERS FOR WHICH THE DEFAULTS ARE NOT SUFFICIENT
    // REMEMBER : CATransition ANIMATIONS REQUIRE A CORE IMAGE FILTER WITH THE FOLLOWING PARAMETERS:
	// input keys :
	//	  'inputImage', 'inputTargetImage' and 'inputTime' input
	// output key :
	//	  'outputImage'
	// optional input:
	//    'inputExtent'	
	// ALL OF THE FILTERS IN THE CATEGORY CICategoryTransition FIT THE REQUIREMENTS
    
    // set up desired filter
    self.filterName = @"CIPageCurlTransition";
    if ([@"CIDissolveTransition" isEqualToString:self.filterName])
        [self setupDissolveTransition];
    if ([@"CIFlashTransition" isEqualToString:self.filterName])
        [self setupFlashTransition];
    if ([@"CIModTransition" isEqualToString:self.filterName])
        [self setupModTransition];
    if ([@"CIPageCurlTransition" isEqualToString:self.filterName])
        [self setupPageCurlTransition];
    if ([@"CIRippleTransition" isEqualToString:self.filterName])
        [self setupRippleTransition];
    
    NSLog(@"[transitionFilter_ attributes] = %@", [transitionFilter_ attributes]);
    NSLog(@"[transitionFilter_ inputKeys] = %@", [transitionFilter_ inputKeys]);
    NSLog(@"[transitionFilter_ outputKeys] = %@", [transitionFilter_ outputKeys]);
    
	// start on the image browsing view
	[self presentBrowsingView];
	
	// start on with log view shown
	[self presentLogView];
	
	[self.sendingProgress setHidden:YES];
}


- (void)setupDissolveTransition
{
    transitionFilter_ = [CIFilter filterWithName:@"CIDissolveTransition"];    
    [transitionFilter_ retain];
    [transitionFilter_ setDefaults];        
    // don't need to set name
    //[transitionFilter_ setName:@"transitionFilter_"];    
}


- (void)setupFlashTransition
{
    transitionFilter_ = [CIFilter filterWithName:@"CIFlashTransition"];    
    [transitionFilter_ retain];
    [transitionFilter_ setDefaults];        
}


- (void)setupModTransition
{
    transitionFilter_ = [CIFilter filterWithName:@"CIModTransition"];    
    [transitionFilter_ retain];
    [transitionFilter_ setDefaults];        
}


- (void)setupPageCurlTransition
{
    // reference http://flylib.com/books.php?ln=en&n=3&p=310&c=55&p1=1&c1=1&c2=100&layout=2&view=1
    transitionFilter_ = [CIFilter filterWithName:@"CIPageCurlTransition"];    
    [transitionFilter_ retain];
    [transitionFilter_ setDefaults];
    
    [transitionFilter_ setValue:[CIVector vectorWithX:statusView_.bounds.origin.x 
                                                    Y:statusView_.bounds.origin.y 
                                                    Z:statusView_.bounds.size.width 
                                                    W:statusView_.bounds.size.height] 
                         forKey:@"inputExtent"];
    [transitionFilter_ setValue:[NSNumber numberWithFloat: (0.25 * M_PI)] forKey:@"inputAngle"];
    [transitionFilter_ setValue:[self restrictedshineImage] forKey:@"inputShadingImage"];
    
    CIColor* tempBacksideImageCIColor = [CIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    CIImage* tempBacksideImage = [CIImage imageWithColor:tempBacksideImageCIColor];    
    [transitionFilter_ setValue:tempBacksideImage forKey:@"inputBacksideImage"];
}


- (void)setupRippleTransition
{
    transitionFilter_ = [CIFilter filterWithName:@"CIRippleTransition"];
    // this works too
    // transitionFilter_ = [CIFilter filterWithName:@"CIRippleTransition" keysAndValues:nil];    
    [transitionFilter_ retain];
    [transitionFilter_ setDefaults];    
    [transitionFilter_ setValue:[self restrictedshineImage] forKey:@"inputShadingImage"];
}


- (CIImage *)restrictedshineImage
{
    if(!restrictedshineImage)
    {
        NSURL  *url;
        url   = [NSURL fileURLWithPath: 
                 [[NSBundle mainBundle]
                  pathForResource: @"restrictedshine" 
                  ofType: @"tiff"]];
        
        restrictedshineImage = [[[CIImage alloc] 
                                 initWithContentsOfURL: url] autorelease];
    }    
    return restrictedshineImage;
}


- (CIImage *)ciImageFromNSImage:(NSImage*)nsImage
{
    // ref http://theocacao.com/document.page/350
    // ref http://gigliwood.com/weblog/Cocoa/Core_Image__Practic.html
    // convert NSImage to bitmap
    NSData  * tiffData = [nsImage TIFFRepresentation];
    NSBitmapImageRep * bitmap = [NSBitmapImageRep imageRepWithData:tiffData];
    
    // create CIImage from bitmap
    CIImage * ciImage = [[[CIImage alloc] initWithBitmapImageRep:bitmap] autorelease];    
    return ciImage;
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
    [imageShareService_ setDelegate:self];
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
	[self.sendingProgress setHidden:NO];
	[self.sendingProgress startAnimation:self];
	
    // This method sends asynchronously.
    // If the send were synchronous, we would block here until the send finished.   
	[imageShareService_ sendImageToClients:image];	
		
	// go back to the log view
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
    // this starts an implicit animation
    // Ref http://stackoverflow.com/questions/2233692/how-does-catransition-work
    CATransition *transition = [[CATransition alloc] init];
	
	// SET ANY PARAMETERS ON IT ( TIMING FUNCTION, DURATION )
    [transition setDuration:kTransitionDuration];
    
	// SET THE FILTER FOR THE CATransition TO THE CIFilter YOU WANT TO USE
    if ([@"CIPageCurlTransition" isEqualToString:self.filterName])
    {
        // show the image we are sending on the back side
        CIImage* inputBacksideImage = [self ciImageFromNSImage:[sendingPreviewImage_ image]];
        
        // scale backside image to match frontside image.
        // this scaling is close to correct, but still a little too big.
        // sendingPreviewImage is the status view's image view
        // maybe the numerator should use the image cell instead (see nib file)
        // CGFloat scaleX = (sendingPreviewImage_.bounds.size.width / inputBacksideImage.extent.size.width);
        // CGFloat scaleY = (sendingPreviewImage_.bounds.size.height / inputBacksideImage.extent.size.height);
        // CGFloat scaleX = (sendingView_.bounds.size.width / inputBacksideImage.extent.size.width);
        // CGFloat scaleY = (sendingView_.bounds.size.height / inputBacksideImage.extent.size.height);
        CGFloat scaleX = (statusBounds.size.width / inputBacksideImage.extent.size.width);
        CGFloat scaleY = (statusBounds.size.height / inputBacksideImage.extent.size.height);

        inputBacksideImage = [inputBacksideImage imageByApplyingTransform:CGAffineTransformMakeScale(scaleX, scaleY)];
        
        [transitionFilter_ setValue:inputBacksideImage forKey:@"inputBacksideImage"];
    }    
    [transition setFilter:transitionFilter_];
    
	// CREATE A DICTIONARY WITH KEY PAIRS. 
	// KEY == ANIMATION ACITON  ("subviews")
	// VALUE == THE CATransition ANIMATION YOU WANT TO USE
	// THIS WILL CAUSE THE ANIMATION TO FIRE WHENEVER THE SUBVIEWS OF THE STATUS
	// VIEW ARE CHANGED
    NSDictionary* animationDict = [[NSDictionary alloc] 
                                   initWithObjectsAndKeys: transition, @"subviews", nil];    
    
	// ADD THE ANIMATION DICTONARY TO THE VIEW THAT WILL HAVE ITS SUBVIEWS EXCHANGED
	// THIS VIEW IS statusView_ AND THE METHOD IS setAnimations:
    [statusView_ setAnimations:animationDict];
    
	// finally, swap the subviews.
	// WITHOUT SETTING OUR OWN ANIMATION, THIS WILL USE THE IMPLICIT ANIMATION
	// ASSOCIATED WITH THIS VIEW BECAUSE WE HAVE MADE IT A LAYER BACKED VIEW
	[[statusView_ animator] replaceSubview:sendingView_ with:logView_];
    
    [animationDict release];
    [transition release];
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
    CATransition *transition = [[CATransition alloc] init];
    
	// SET ANY PARAMETERS ON IT ( TIMING FUNCTION, DURATION )
    [transition setDuration:kTransitionDuration];
    
	// SET THE FILTER FOR THE CATransition TO THE CIFilter YOU WANT TO USE
    if ([@"CIPageCurlTransition" isEqualToString:self.filterName])
    {
        CIColor* tempBacksideImageCIColor = [CIColor colorWithRed:0.5 green:0.0 blue:0.0 alpha:1.0];
        CIImage* tempBacksideImage = [CIImage imageWithColor:tempBacksideImageCIColor];    
    
        [transitionFilter_ setValue:tempBacksideImage forKey:@"inputBacksideImage"];        
    }
    [transition setFilter:transitionFilter_];
    
	// SPECIAL WORK FOR THIS CASE :
	// WE WANT TO START SENDING AFTER THE ANIMATION FINISHES
	// TO DO THAT, WE SET OURSELVES AS THE DELEGATE FOR THIS ANIMATION
	// AND WE START THE ACTUAL IMAGE SENDING IN THE DELEGATE METHOD
	// THAT IS CALLED FOR ANIMATION ENDING
    // (SB- animationDidStop:finished:)
    transition.delegate = self;
    
	// CREATE A DICTIONARY WITH KEY PAIRS. 
	// KEY == ANIMATION ACITON  ("subviews")
	// VALUE == THE CATransition ANIMATION YOU WANT TO USE
	// THIS WILL CAUSE THE ANIMATION TO FIRE WHENEVER THE SUBVIEWS OF THE STATUS
	// VIEW ARE CHANGED
    NSDictionary* animationDict = [[NSDictionary alloc] 
                                   initWithObjectsAndKeys: transition, @"subviews", nil];    
    
	// ADD THE ANIMATION DICTONARY TO THE VIEW THAT WILL HAVE ITS SUBVIEWS EXCHANGED
	// THIS VIEW IS statusView_ AND THE METHOD IS setAnimations:	
    [statusView_ setAnimations:animationDict];
    
	// finally, swap the subviews. This will animate as long as the 
	// "subviews" key has an associated animation	
	
	// NOTE : WE WANT TO FIRE OFF SENDING AT THE COMPLETION OF THE IMPLICIT ANIMATION
	//        UNTIL WE HAVE THE REAL ANIMATION IN PLACE
	//        TO DO THIS WE WILL HAVE A BLOCK THAT FIRES OFF AS A RESULT 
	//        OF COMPLETING A CATransaction. THIS IS JUST A PLACE HOLDER
	//        UNTIL YOU PROVIDE YOUR OWN ANIMATION ABOVE. WHEN YOU SET THE DELEGATE OF THAT
	//        ANIMATION animationDidStop:finished: WILL BE CALLED WHICH DOES THE SAME
	//        THING AS THE BLOCK HERE
    
    // REMOVE THESE LINES WHEN YOU HAVE YOUR ANIMATION ADDED WITH self AS THE DELEGATE
	//[CATransaction begin];
	//[CATransaction setCompletionBlock:^(void){[self beginSendingImage:[imageBrowseController_ selectedImage]];}];     
    
	// SB- keep this line
    [[statusView_ animator] replaceSubview:logView_ with:sendingView_];		
    
    // AND REMOVE THIS LINE
    // [CATransaction commit];
    
    [animationDict release];
    [transition release];    
}


- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
	// this is called when our animation has finished. In this case we know 
	// that this is the end of presentation of the sending view image, 
	// so we will now fire off the actual send. 
	
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

#pragma mark -
#pragma mark ImageShareServiceDelegate
// Implement ImageShareService's formal protocol ImageShareServiceDelegate
// when the asynchronous send completes, imageShareService calls back to its delegate
- (void)imageShareServiceDidSend:(ImageShareService*)imageShareService
{
	// once we return from the synchronous sending, 
	// stop the progress indicator and hide it
	[self.sendingProgress stopAnimation:self];
	[self.sendingProgress setHidden:YES];	
}

@end





