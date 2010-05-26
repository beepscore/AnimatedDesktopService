//
// IPHONE AND COCOA DEVELOPMENT AUSP10
//	
//  Animated DesktopServiceAppDelegate.m
//	HW9
//
//  portions Copyright 2010 Chris Parrish
//
// Desktop application that will
// advertise a network service available via bonjour

#import "AnimatedDesktopServiceAppDelegate.h"
#import "ImageShareService.h"

@implementation AnimatedDesktopServiceAppDelegate

@synthesize window;
@synthesize appController = appController_;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[appController_ startService];
}

@end
