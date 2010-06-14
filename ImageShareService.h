//
// IPHONE AND COCOA DEVELOPMENT AUSP10
//	
//  ImageShareService.h
//	HW9
//
//  Copyright 2010 Chris Parrish
//
// Class that handles listening for incoming connections
// and then sending an image to the connected client

#import <Foundation/Foundation.h>

// declare ImageShareServiceProtocol.  We will list methods below, after interface block.
@protocol ImageShareServiceProtocol;

@class ApplicationController;

@interface ImageShareService : NSObject <NSNetServiceDelegate>
{
	
	ApplicationController*	appController_;
	
	CFSocketRef				socket_;
	NSFileHandle*			connectionFileHandle_;
	
	NSMutableDictionary*	dataForFileHandles_;
	
	NSMutableArray*			connectedFileHandles_;
    
    id delegate;
}
#pragma mark Properties
// a delegator should manage its delegate property with assign, not retain.
// Ref http://cocoawithlove.com/2009/07/rules-to-avoid-retain-cycles.html
// delegate type is id (any type)
@property(nonatomic,assign) id delegate;


- (BOOL) startService;
- (void) publishService;

- (void) handleIncomingConnection:(NSNotification*)notification;
- (void) stopReceivingForFileHandle:(NSFileHandle*)fileHandle closeFileHandle:(BOOL)close;
- (void) readIncomingData:(NSNotification*) notification;

- (void) sendImageToClients:(NSImage*)image;

@end

// list ImageShareServiceProtocol methods
@protocol ImageShareServiceProtocol
// notify delegate send is complete
- (void)imageShareServiceDidSend:(ImageShareService*)imageShareService;
@end

