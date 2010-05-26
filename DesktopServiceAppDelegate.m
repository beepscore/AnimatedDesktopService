//
// IPHONE AND COCOA DEVELOPMENT AUSP10
//	
//  DesktopServiceAppDelegate.m
//	HW9
//
//  Copyright 2010 Chris Parrish
//
// Desktop application that will
// advertise a network service available via bonjour

#import "DesktopServiceAppDelegate.h"
#import "ImageShareService.h"

@implementation DesktopServiceAppDelegate

@synthesize window;
@synthesize appController = appController_;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[appController_ startService];
}

@end
