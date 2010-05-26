//
// IPHONE AND COCOA DEVELOPMENT AUSP10
//	
//  FilePathImageObject.h
//	HW9
//
//  Copyright 2010 Chris Parrish
//
// A simple data object that holds an image path
// used by Image Kit Browser data source

#import <Foundation/Foundation.h>


@interface FilePathImageObject : NSObject
{
	NSString*		filePath_;
}

@property (nonatomic, retain)	NSString*	filePath;


@end
