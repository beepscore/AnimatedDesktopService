//
// IPHONE AND COCOA DEVELOPMENT AUSP10
//	
//  ListenService.h
//	HW4
//
//  Copyright 2010 Chris Parrish
//
// Class that handles listening for incoming connections
// and advertises its service via Bonjour

#import "PictureShareService.h"

#import	"ApplicationController.h"
#import <sys/socket.h>
#import <netinet/in.h>

NSString* const			kServiceTypeString		= @"_uwcelistener._tcp.";
NSString* const			kServiceNameString		= @"HW4 listen service";
const	int				kListenPort				= 8082;

@interface PictureShareService ()

- (void) parseDataRecieved:(NSMutableData*)dataSoFar;
- (NSMutableData*) dataForFileHandle:(NSFileHandle*) fileHandle;
- (void) handleMessage:(NSString*)messageString;


@end

@implementation PictureShareService

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		appController_			= [ApplicationController sharedApplicationController];
		socket_					= nil;
		connectionFileHandle_	= nil;
		
		dataForFileHandles_		= [[NSMutableDictionary dictionary] retain];
		connectedFileHandles_	= [NSMutableArray array];
	}
	return self;
}

- (void) dealloc
{
	[dataForFileHandles_ release];
	dataForFileHandles_ = nil;
	
	[connectedFileHandles_ release];
	connectedFileHandles_ = nil;
	
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
	NSNetService* netService = [[NSNetService alloc] initWithDomain:@"" 
												 type:kServiceTypeString
												 name:kServiceNameString 
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
#pragma mark NSFileHandle

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


@end
