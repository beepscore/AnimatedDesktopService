//
// IPHONE AND COCOA DEVELOPMENT AUSP10
//	
//  FilePathImageObject.m
//	HW9
//
//  Copyright 2010 Chris Parrish
//
// A simple data object that holds an image path
// used by Image Kit Browser data source


#import "FilePathImageObject.h"
#import <Quartz/Quartz.h>

@implementation FilePathImageObject

@synthesize filePath = filePath_;


- (void) dealloc
{
	[filePath_ release];
	self.filePath = nil;
	
	[super dealloc];
}

#pragma mark -
#pragma mark IKImageBrowserItem

// These methods implement the informal protocol
// required for objects returned by a IKImageBrowswerDataSource

- (NSString*)  imageRepresentationType
{
    return IKImageBrowserPathRepresentationType;
}

- (id)  imageRepresentation
{
    return filePath_;
}

- (id) imageTitle
{
	return [filePath_ lastPathComponent];
}

- (NSString *) imageUID
{
	// the filePath should serve as a unique identifier for the image
    return filePath_;
}


@end
