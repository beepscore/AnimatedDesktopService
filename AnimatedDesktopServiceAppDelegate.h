//
// IPHONE AND COCOA DEVELOPMENT AUSP10
//	
//  AnimatedDesktopServiceAppDelegate.h
//	HW9
//
//  portions Copyright 2010 Chris Parrish
//
// Desktop application that will
// advertise a network service available via bonjour

#import <Cocoa/Cocoa.h>

@class ApplicationController;


@interface AnimatedDesktopServiceAppDelegate : NSObject <NSApplicationDelegate>
{
    NSWindow*				window;
	ApplicationController*  appController_;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet ApplicationController* appController;
@end
