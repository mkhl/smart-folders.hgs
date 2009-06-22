//
//  HGSDirectoryScannerSearchSource.m
//
//  Copyright (c) 2008 Google Inc. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are
//  met:
//
//    * Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
//  copyright notice, this list of conditions and the following disclaimer
//  in the documentation and/or other materials provided with the
//  distribution.
//    * Neither the name of Google Inc. nor the names of its
//  contributors may be used to endorse or promote products derived from
//  this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
//  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
//  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
//  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import <Vermilion/Vermilion.h>
#import <GTM/GTMFileSystemKQueue.h>
#import "HGSDirectoryScannerSearchSource.h"


#pragma mark -
@interface HGSDirectoryScannerSearchSource ()

@property (retain) NSString *path;
@property (retain) GTMFileSystemKQueue *kQueue;

- (void)recacheContents;

@end


#pragma mark -
@implementation HGSDirectoryScannerSearchSource

#pragma mark Accessors
@synthesize path = path_;
@synthesize kQueue = kQueue_;

#pragma mark Memory Management
- (id)initWithConfiguration:(NSDictionary *)configuration
{
  return [self initWithConfiguration:configuration
                            rootPath:[configuration objectForKey:@"rootPath"]];
}

- (id)initWithConfiguration:(NSDictionary *)configuration
                   rootPath:(NSString *)rootPath
{
  self = [super initWithConfiguration:configuration];
  if (!self)
    return nil;
  path_ = [rootPath copy];
  return self;
}

- (void)dealloc
{
  [kQueue_ release];
  kQueue_ = nil;
  [path_ release];
  path_ = nil;
  [super dealloc];
}

#pragma mark FileSystem KQueue
- (void)directoryChanged:(GTMFileSystemKQueue *)queue
              eventFlags:(GTMFileSystemKQueueEvents)flags
{
  [self recacheContents];
}

#pragma mark Result Index
- (void)recacheContents
{
  [self clearResultIndex];
  
  NSFileManager *fm = [NSFileManager defaultManager];
  
  for (NSString *subpath in [fm directoryContentsAtPath:self.path]) {
    LSItemInfoRecord infoRec;
    subpath = [self.path stringByAppendingPathComponent:subpath];
    NSURL *subURL = [NSURL fileURLWithPath:subpath];
    OSStatus status = paramErr;
    if (subURL) {
      status = LSCopyItemInfoForURL((CFURLRef)subURL,
                                    kLSRequestBasicFlagsOnly,
                                    &infoRec);
    }
    if (status) {
      // For some odd reason /dev always returns nsvErr.
      // Radar 6759537 - Getting URL info on /dev return -35 nsvErr
      if (![subpath isEqualToString:@"/dev"]) {
        HGSLogDebug(@"Unable to LSCopyItemInfoForURL (%d) for %@", 
                    status, subURL);
      }
      continue;
    }
    if (infoRec.flags & kLSItemInfoIsInvisible) continue;
    if ([[subpath lastPathComponent] hasPrefix:@"."]) continue;
    
    [self indexResult:[self resultForFilePath:subpath]];
  }
  [self saveResultsCache];
}

@end

#pragma mark -
@implementation HGSDirectoryScannerSearchSource (ProtectedMethods)

- (void)startIndexing
{
  if (![self loadResultsCache]) {
    [self recacheContents];
  } else {
    [self performSelector:@selector(recacheContents)
               withObject:nil
               afterDelay:10.0];
  }
  GTMFileSystemKQueueEvents events = kGTMFileSystemKQueueWriteEvent;
  SEL action = @selector(directoryChanged:eventFlags:);
  self.kQueue = [[[GTMFileSystemKQueue alloc] initWithPath:self.path
                                                 forEvents:events
                                             acrossReplace:NO
                                                    target:self
                                                    action:action]
                 autorelease];
}

- (HGSResult *)resultForFilePath:(NSString *)path
{
  return [HGSResult resultWithFilePath:path
                                source:self
                            attributes:nil];
}

@end
