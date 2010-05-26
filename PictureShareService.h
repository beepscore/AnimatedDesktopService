//
// IPHONE AND COCOA DEVELOPMENT AUSP10
//	
//  PictureShareService.h
//	HW4
//
//  Copyright 2010 Chris Parrish
//
// Class that handles listening for incoming connections
// and then sending an image to the connected client

#import <Foundation/Foundation.h>

@class ApplicationController;

@interface PictureShareService : NSObject <NSNetServiceDelegate>
{
	
	ApplicationController*	appController_;
	
	CFSocketRef				socket_;
	NSFileHandle*			connectionFileHandle_;
	
	NSMutableDictionary*	dataForFileHandles_;
	
	NSMutableArray*			connectedFileHandles_;
}

- (BOOL) startService;
- (void) publishService;

- (void) handleIncomingConnection:(NSNotification*)notification;
- (void) stopReceivingForFileHandle:(NSFileHandle*)fileHandle closeFileHandle:(BOOL)close;
- (void) readIncomingData:(NSNotification*) notification;



@end
