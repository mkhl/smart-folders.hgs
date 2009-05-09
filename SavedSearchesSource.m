//
//  SavedSearchesSource.m
//
//  Copyright (c) 2009  Martin Kuehl <purl.org/net/mkhl>
//  Licensed under the MIT License.
//

#import <Vermilion/Vermilion.h>
#import "HGSDirectoryScannerSearchSource.h"

#pragma mark Static Data

static NSString *const kSavedSearchesPathComponent = @"Saved Searches";
static NSString *const kSavedSearchesPathExtension = @"savedSearch";

#pragma mark -
#pragma mark Helper Functions

static NSString *_SavedSearchesPath(void)
{
  return [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)
           lastObject] stringByAppendingPathComponent:kSavedSearchesPathComponent];
}

#pragma mark -
@interface SavedSearchesSource : HGSDirectoryScannerSearchSource
@end

#pragma mark -
@implementation SavedSearchesSource

#pragma mark Memory Management

- (id) initWithConfiguration:(NSDictionary *)configuration
{
  NSString *path = _SavedSearchesPath();
  self = [super initWithConfiguration:configuration rootPath:path];
  return self;
}

@end
