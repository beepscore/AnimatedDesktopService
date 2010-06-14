//
// IPHONE AND COCOA DEVELOPMENT AUSP10
//	
//  ImageShareService.h
//	HW9
//
//  Copyright 2010 Chris Parrish
//
// Class that handles listening for incoming connections
// and advertises its service via Bonjour
// Sends an image to the connected clients


#import "ImageShareService.h"

#import	"ApplicationController.h"
#import <sys/socket.h>
#import <netinet/in.h>

NSString* const			kServiceTypeString		= @"_uwcelistener._tcp.";
NSString* const			kServiceNameString		= @"Images";
const	int				kListenPort				= 8082;

NSString* const kConnectionKey = @"connectionKey";
NSString* const kImageSizeKey = @"imageSize";
NSString* const kRepresentationToSendKey = @"representationToSend";

@interface ImageShareService ()

- (void) parseDataRecieved:(NSMutableData*)dataSoFar;
- (NSMutableData*) dataForFileHandle:(NSFileHandle*) fileHandle;
- (void) handleMessage:(NSString*)messageString;


@end

@implementation ImageShareService

#pragma mark properties
@synthesize delegate;

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		appController_			= [ApplicationController sharedApplicationController];
		socket_					= nil;
		connectionFileHandle_	= nil;
		
		dataForFileHandles_		= [[NSMutableDictionary dictionary] retain];
		connectedFileHandles_	= [[NSMutableArray array] retain];
	}
	return self;
}

- (void) dealloc
{
	[dataForFileHandles_ release];
	dataForFileHandles_ = nil;
	
	for (NSFileHandle* connection in connectedFileHandles_)
	{
		[connection closeFile];
	}
	
	[connectedFileHandles_ release];
	connectedFileHandles_ = nil;
    
    // a delegator doesn't retain it's delegate, and so it doesn't release it
    delegate = nil;
	
	[super dealloc];
}

- (BOOL) startService
{
	socket_ = CFSocketCreate
		(
			kCFAllocatorDefault,
			PF_INET,
			SOCK_STREAM,
			IPPROTO_TCP,
			0,
			NULL,
			NULL
		 );
	
	// Create a network socket for streaming TCP
	
	if (!socket_)
	{
		[appController_ appendStringToLog:@"Cound not create socket"];
		return NO;
	}
	
	int reuse = true;
	int fileDescriptor = CFSocketGetNative(socket_);
	
	// Make sure socket is set for reuse of the address
	// without this, you may find that the socket is already in use
	// when restartnig and debugging
	
	int result = setsockopt(
								fileDescriptor,
								SOL_SOCKET,
								SO_REUSEADDR,
								(void *)&reuse,
								sizeof(int)
							);
	
	
	
	if ( result != 0)
	{
		[appController_ appendStringToLog:@"Unable to set socket options"];
		return NO;
	}
	
	// Create the address for the scoket. 
	// In this case we don't care what address is incoming
	// but we listen on a specific port - kLisenPort
	
	struct sockaddr_in address;
	memset(&address, 0, sizeof(address));
	address.sin_len = sizeof(address);
	address.sin_family = AF_INET;
	address.sin_addr.s_addr = htonl(INADDR_ANY);
	address.sin_port = htons(kListenPort);
	
	CFDataRef addressData =
	CFDataCreate(NULL, (const UInt8 *)&address, sizeof(address));
	
	[(id)addressData autorelease];
	
	
	// bind socket to the address
	if (CFSocketSetAddress(socket_, addressData) != kCFSocketSuccess)
	{
		[appController_ appendStringToLog:@"Unable to bind socket to address"];
		return NO;
	}   
	
	// setup listening to incoming connections
	// we will use notifications to respond 
	// as we are not looking for high performance and want
	// to use the simpiler Cocoa NSFileHandle APIs
	
	connectionFileHandle_ = [[NSFileHandle alloc] initWithFileDescriptor:fileDescriptor closeOnDealloc:YES];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(handleIncomingConnection:) 
	        name:NSFileHandleConnectionAcceptedNotification
		  object:nil];
	
	[connectionFileHandle_ acceptConnectionInBackgroundAndNotify];
	
	NSString* logString = [NSString stringWithFormat:@"listening to socket on port %d", kListenPort];
	[appController_ appendStringToLog:logString];	
	
	return YES;
}


- (void) publishService
{
	// Create a name for the service that include's this computer's name
	CFStringRef computerName = CSCopyMachineName();
	NSString* serviceNameString = [NSString stringWithFormat:@"%@'s %@", (NSString*)computerName, kServiceNameString];
	CFRelease(computerName);
	
	NSNetService* netService = [[NSNetService alloc] initWithDomain:@"" 
												 type:kServiceTypeString
												 name:serviceNameString 
												 port:kListenPort];
	// publish on the default domains
	
    [netService setDelegate:self];
    [netService publish];
	
	// NOTE : We are not handling any failure to publish cases
	//        which is not a good idea. We should at least
	//        Be checking for name collisions
	
	NSString* logString = [NSString stringWithFormat:@"published service type:%@ with name %@ on port %d", kServiceTypeString, kServiceNameString, kListenPort];
	[appController_ appendStringToLog:logString];
}


#pragma mark -
#pragma mark Receiving 

-(void) handleIncomingConnection:(NSNotification*)notification
{
	NSDictionary*	userInfo			=	[notification userInfo];
	NSFileHandle*	connectedFileHandle	=	[userInfo objectForKey:NSFileHandleNotificationFileHandleItem];
	
    if(connectedFileHandle)
	{
		[[NSNotificationCenter defaultCenter]
		 addObserver:self
		 selector:@selector(readIncomingData:)
		 name:NSFileHandleDataAvailableNotification
		 object:connectedFileHandle];
		
		[connectedFileHandles_ addObject:connectedFileHandle];
		
		[appController_ appendStringToLog:@"Opened an incoming connection"];
		
        [connectedFileHandle waitForDataInBackgroundAndNotify];
    }
	
	[connectionFileHandle_ acceptConnectionInBackgroundAndNotify];
}

- (void) readIncomingData:(NSNotification*) notification
{
	NSFileHandle*	readFileHandle	= [notification object];
	NSData*			newData			= [readFileHandle availableData];
	
	NSMutableData*	dataSoFar		= [self dataForFileHandle:readFileHandle];
	
	if ([newData length] == 0)
	{
		[appController_ appendStringToLog:@"No more data in file handle, closing"];
		
		[self stopReceivingForFileHandle:readFileHandle closeFileHandle:YES];
		return;
	}	
	
	[appController_ appendStringToLog:@"Got a new message :"];
	[appController_ appendStringToLog:[NSString stringWithUTF8String:[newData bytes]]];
	
	// append the data to the data we have so far
	[dataSoFar appendData:newData];
	
	[self parseDataRecieved:dataSoFar];
	
	// wait for a read again
	[readFileHandle waitForDataInBackgroundAndNotify];	
}

- (void) parseDataRecieved:(NSMutableData*)dataSoFar
{
	// Look for a token that indicates a complete message
	// and act on the message. Remove the message from the data so far
	
	// Currently our token is the null terminator 0x00
	char token = 0x00;
	
	NSRange result = [dataSoFar rangeOfData:[NSData dataWithBytes:&token length:1] options:0 range:NSMakeRange(0, [dataSoFar length])];
	
	
	if ( result.location != NSNotFound )
	{
		NSData* messageData = [dataSoFar subdataWithRange:NSMakeRange(0, result.location+1)];
		NSString* messageString = [NSString stringWithUTF8String:[messageData bytes]];
		
		// act on the message
		
		NSLog(@"parsed message : %@", messageString);
		[self handleMessage:messageString];
		
		// trim the message we have handled off the data received 
		
		NSUInteger location = result.location + 1;
		NSUInteger length = [dataSoFar length] - [messageData length];
		
		[dataSoFar setData:[dataSoFar subdataWithRange:NSMakeRange(location, length)]];
	}
}

- (void) handleMessage:(NSString*)messageString
{
	// Not reacting to any sent messages for now
}

- (NSMutableData*) dataForFileHandle:(NSFileHandle*) fileHandle
{
	NSMutableData* data = [dataForFileHandles_ objectForKey:fileHandle];
	if ( data == nil )
	{
		data = [NSMutableData data];
		[dataForFileHandles_ setObject:data forKey:fileHandle];
	}
	
	return data;
}


- (void) stopReceivingForFileHandle:(NSFileHandle*)fileHandle closeFileHandle:(BOOL)close
{
	if (close)
	{
		[fileHandle closeFile];
		[connectedFileHandles_ removeObject:fileHandle];
	}
	
	NSMutableData* data = [dataForFileHandles_ objectForKey:fileHandle];
	if ( data != nil )
	{
		[dataForFileHandles_ removeObjectForKey:fileHandle];
	}
	
	[[NSNotificationCenter defaultCenter] 
		removeObserver:self
	              name:NSFileHandleDataAvailableNotification
	            object:fileHandle];
}


#pragma mark -
#pragma mark Sending
- (void)sendWithDictionary:(NSMutableDictionary*)sendArgumentsDictionary
{
    // Add autorelease pool.
    // Without autorelease pool, if iPhone client quits during send, console logs
    // "_NSCallStackArray autoreleased with no pool in place - just leaking"
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // sendWithDictionary: has one parameter, a dictionary.
    // This way, sendWithDictionary: can be called from performSelectorInBackground:withObject:    
    // The dictionary object contains multiple objects as "arguments" for use by the method
    NSFileHandle* connection = [sendArgumentsDictionary objectForKey:kConnectionKey];
    NSData* imageSize = [sendArgumentsDictionary objectForKey:kImageSizeKey];
    NSData* representationToSend = [sendArgumentsDictionary objectForKey:kRepresentationToSendKey];    
    
    // suggestion from Sean Quinlan
    // if we lose a connection and have a "bad socket", these catch blocks around writeData
    // allows the server to write to other valid connections.
    @try {
        [connection writeData:imageSize];
    }
    // @catch could return type NSException* instead of type id
    @catch (id e) {
        // log error
        NSLog(@"Error in sendWithDictionary: sending image size.");
    }    
    
    @try {
        [connection writeData:representationToSend];
    }
    @catch (id e) {
        // log error
        NSLog(@"Error in sendWithDictionary: sending image.");
    }    
    
    // Notify delegate the send is complete
    // The delegate controls the view.
    // View related methods are not thread safe and must be performed on the main thread.
    [self.delegate performSelectorOnMainThread:@selector(imageShareServiceDidSend:)
                                    withObject:self
                                 waitUntilDone:NO];
    
    // http://developer.apple.com/mac/library/documentation/Cocoa/Reference/Foundation/Classes/NSAutoreleasePool_Class/Reference/Reference.html#//apple_ref/occ/instm/NSAutoreleasePool/drain
    [pool drain];
}


- (void) sendImageToClients:(NSImage*)image
{
	NSUInteger clientCount = [connectedFileHandles_ count];
	
	if( clientCount <= 0 )
	{
		[appController_ appendStringToLog:@"No clients connected, not sending"];		
		return;
	}

	NSBitmapImageRep* imageRep = [[image representations] objectAtIndex:0];	
	NSData* representationToSend = [imageRep representationUsingType:NSPNGFileType properties:nil];
		
	// NOTE : this will only work when the image has a bitmap representation of some type
	// an EPS or PDF for instance do not and in that case imageRep will not be a NSBitmapImageRep
	// and then representationUsingType will fail
	// To do this better we could draw the image into an offscreen context
	// then save that context in a format like PNG
	// There are some downsides to this though, because for instance a jpeg will recompress
	// so you would want to use a rep when you have it and if not, create one. 
	

	// The first thing we send is 4 bytes that represent the length of
	// of the image so that the client will know when a full image has 
	// transfered
	
	
	NSUInteger imageDataSize = [representationToSend length];
    
    // the length method returns an NSUInteger, which happens to be 64 bits 
	// or 8 bytes in length on the desktop. On the phone NSUInteger is 32 bits
	// we are simply going to not send anything that is so big that it
	// length is > 2^32, which should be fine considering the iPhone client
	// could not handle images that large anyway    
	if ( imageDataSize > UINT32_MAX )
	{
		[appController_ appendStringToLog:[NSString stringWithFormat:@"Image is too large to send (%ld bytes", imageDataSize]];	
		return;
	}
	
    // We also have to be careful and make sure that the bytes are in the proper order
	// when sent over the network using htonl()
    uint32 dataLength = htonl( (uint32)imageDataSize );
	NSData*	imageSize = [NSData dataWithBytes:&dataLength length:sizeof(unsigned int)];

	for ( NSFileHandle* connection in connectedFileHandles_)
	{
        // make a dictionary for sendWithDictionary:
        NSMutableDictionary* sendArgumentsDictionary =
        [[NSMutableDictionary alloc] initWithObjectsAndKeys:connection, kConnectionKey,
         imageSize, kImageSizeKey,
         representationToSend, kRepresentationToSendKey, nil];
        
        // send asynchronously to avoid locking up UI
        // Thanks to suggestions from Greg Anderson and Pam DeBriere
        // including using performSelectorInBackground:withObject: to create a new thread
        [self performSelectorInBackground:@selector(sendWithDictionary:) 
                               withObject:sendArgumentsDictionary];
        [sendArgumentsDictionary release];        
	}
	
	
	[appController_ appendStringToLog:[NSString stringWithFormat:@"Sent image to %d clients", clientCount]];
	
}



@end
