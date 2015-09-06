//
//  Monitor.h
//  MonoChrome
//
//  Created by Alastair Tse on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>


@interface Monitor : NSObject <GrowlApplicationBridgeDelegate> {
  NSMutableArray *paths_;
  NSMutableArray *directories_;
  FSEventStreamRef stream_;
  NSTimeInterval latency_;
  FSEventStreamEventId lastEventId_;
  NSMutableDictionary *lastModifications_;
  __weak NSFileManager *fileManager_;
}

@property (nonatomic, readonly) NSMutableArray *paths;

- (void)start;
- (void)stop;

- (void)fileDidUpdate:(NSString *)path
           eventFlags:(const FSEventStreamEventFlags)flags
              eventId:(const FSEventStreamEventId)eventId;
- (void)fileUpdatesDidFinish;
@end
