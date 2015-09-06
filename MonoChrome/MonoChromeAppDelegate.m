//
//  MonoChromeAppDelegate.m
//  MonoChrome
//
//  Created by Alastair Tse on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MonoChromeAppDelegate.h"

@implementation MonoChromeAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  monitor_ = [[Monitor alloc] init];
  [[monitor_ paths] addObject:@"/Library/Preferences/com.sophos.sav.plist"];
  [[monitor_ paths] addObject:@"/Library/Preferences/com.sophos.sau.plist"];
  [monitor_ start];

	// Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)notification {
  [monitor_ stop];
  [monitor_ release];
  monitor_ = nil;
}

- (void)dealloc {
  [monitor_ stop];
  [monitor_ release];
  [super dealloc];
}

@end
