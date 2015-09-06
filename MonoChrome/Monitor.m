//
//  Monitor.m
//  MonoChrome
//
//  Created by Alastair Tse on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Monitor.h"

static NSString * const kMonitorPrefLastEventId = @"kMonitorPrefLastEventId";
static NSString * const kMonitorPrefLastModifications = @"kMonitorPrefLastModifications";
static NSString * const kMonitorFileDidChange = @"kMonitorFileDidChange";
static NSString * const kMonitorFileDidChangeName = @"File Changed";

void fsEventsCallback(ConstFSEventStreamRef streamRef,
                             void *userData,
                             size_t numEvents,
                             void *eventPaths,
                             const FSEventStreamEventFlags eventFlags[],
                             const FSEventStreamEventId eventIds[]) {
  Monitor *monitor = (Monitor *)userData;
  NSArray *eventPathsArray = (NSArray *)eventPaths;
  size_t i = 0;
  for (i = 0; i < numEvents; i++) {
    [monitor fileDidUpdate:[eventPathsArray objectAtIndex:i]
                eventFlags:eventFlags[i]
                   eventId:eventIds[i]];
  }
  [monitor fileUpdatesDidFinish];
}


@implementation Monitor
@synthesize paths = paths_;

- (id) init {
  self = [super init];
  if (self) {
    paths_ = [[NSMutableArray alloc] init];
    directories_ = [[NSMutableArray alloc] init];
    lastModifications_ = [[NSMutableDictionary alloc] init];
    fileManager_ = [NSFileManager defaultManager];
    latency_ = 3.0;
    NSNumber *lastEventNumber =
        [[NSUserDefaults standardUserDefaults] objectForKey:kMonitorPrefLastEventId];
    if (lastEventNumber) {
      lastEventId_ = [lastEventNumber unsignedLongLongValue];
    }
    if (!lastEventId_) {
      lastEventId_ = kFSEventStreamEventIdSinceNow;
    }
    NSDictionary *modifications = [[NSUserDefaults standardUserDefaults] objectForKey:kMonitorPrefLastModifications];
    if (modifications) {
      [lastModifications_ release];
      lastModifications_ = [modifications mutableCopy];
    }

    NSLog(@"LastEvent: %qu", lastEventId_);
    [GrowlApplicationBridge setGrowlDelegate:self];
  }
  return self;
}

- (void)dealloc {
  [self stop];
  [lastModifications_ release];
  [directories_ release];
  [paths_ release];
  [super dealloc];
}

- (void)start {
  if (stream_) return;
  FSEventStreamContext context = {
    0,
    (void *)self,  // context
    NULL,
    NULL,
    NULL
  };

  [directories_ removeAllObjects];
  for (NSString *path in paths_) {
    NSString *directory = [[path stringByStandardizingPath] stringByDeletingLastPathComponent];
    if (![directories_ containsObject:directory]) {
      NSLog(@"registered: %@", directory);
      [directories_ addObject:directory];
    }
  }

  stream_ = FSEventStreamCreate(NULL,
                                &fsEventsCallback,
                                &context,
                                (CFArrayRef)directories_,
                                lastEventId_,
                                latency_,
                                kFSEventStreamCreateFlagUseCFTypes |
                                kFSEventStreamCreateFlagIgnoreSelf);
  FSEventStreamScheduleWithRunLoop(stream_,
                                   CFRunLoopGetCurrent(),
                                   kCFRunLoopDefaultMode);
  FSEventStreamStart(stream_);
}

- (void)stop {
  if (!stream_) return;
  FSEventStreamStop(stream_);
  FSEventStreamInvalidate(stream_);
  FSEventStreamRelease(stream_);
  stream_ = nil;
}

- (void)fileDidUpdate:(NSString *)path
           eventFlags:(const FSEventStreamEventFlags)flags
              eventId:(const FSEventStreamEventId)eventId {
  // For each path reported, we need to iterate through the directory
  // to find that's changed.
  NSLog(@"Changed: %qu %@", eventId, path);
  if (![directories_ containsObject:[path stringByStandardizingPath]]) return;

  for (NSString *fileName in [fileManager_ contentsOfDirectoryAtPath:path error:NULL]) {
    NSString *fullPath = [path stringByAppendingPathComponent:fileName];
    if (![paths_ containsObject:fullPath]) continue;
    NSLog(@"Changed: Full = %@", fullPath);
    NSDate *lastModified = [[fileManager_ attributesOfItemAtPath:fullPath error:NULL]
                                objectForKey:NSFileModificationDate];
    NSDate *previousLastModified = [lastModifications_ objectForKey:fullPath];
    if (!previousLastModified || [lastModified compare:previousLastModified]) {
        // File updated.
      [GrowlApplicationBridge notifyWithTitle:kMonitorFileDidChangeName
                                  description:fileName
                             notificationName:kMonitorFileDidChange
                                     iconData:nil
                                     priority:0
                                     isSticky:YES
                                 clickContext:nil];
      [lastModifications_ setObject:lastModified forKey:fullPath];
    }
  }
  lastEventId_ = eventId;
  NSNumber *lastEventNumber = [NSNumber numberWithUnsignedLongLong:lastEventId_];
  [[NSUserDefaults standardUserDefaults] setObject:lastEventNumber
                                            forKey:kMonitorPrefLastEventId];
}

- (void)fileUpdatesDidFinish {
  [[NSUserDefaults standardUserDefaults] setObject:lastModifications_ forKey:kMonitorPrefLastModifications];
  [[NSUserDefaults standardUserDefaults] synchronize];

}

#pragma mark Growl

- (NSString *)applicationNameForGrowl {
  return @"MonoChrome";
}

- (NSDictionary *)registrationDictionaryForGrowl {
  NSDictionary *notifications = [NSDictionary dictionaryWithObjectsAndKeys:
      kMonitorFileDidChangeName, kMonitorFileDidChange,
      nil];
  return [NSDictionary dictionaryWithObjectsAndKeys:
            [self applicationNameForGrowl], GROWL_APP_NAME,
            [notifications allKeys], GROWL_NOTIFICATIONS_ALL,
            [notifications allKeys], GROWL_NOTIFICATIONS_DEFAULT,
            notifications, GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES,
            nil];
}

- (void)growlNotificationWasClicked:(id)clickContext {
}

@end
