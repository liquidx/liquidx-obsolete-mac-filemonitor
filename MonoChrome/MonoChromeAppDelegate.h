//
//  MonoChromeAppDelegate.h
//  MonoChrome
//
//  Created by Alastair Tse on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Monitor.h"

@interface MonoChromeAppDelegate : NSObject <NSApplicationDelegate> {
  NSWindow *window;
  Monitor *monitor_;
}

@property (assign) IBOutlet NSWindow *window;

@end
