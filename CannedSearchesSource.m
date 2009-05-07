//
//  CannedSearchesSource.m
//
//  Copyright (c) 2009  Martin Kuehl <purl.org/net/mkhl>
//  Licensed under the MIT License.
//

#import <Vermilion/Vermilion.h>

#pragma mark Static Data

static NSString *const kCannedSearchesBundleIdentifier = @"com.apple.Finder";
static NSString *const kCannedSearchesDirectoryName = @"CannedSearches";
static NSString *const kCannedSearchesFileExtension = @"cannedSearch";

#pragma mark -
#pragma mark Helper Functions

static NSBundle *_CannedSearchesBundle(void)
{
  return [NSBundle bundleWithPath:[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:kCannedSearchesBundleIdentifier]];
}

#pragma mark -
@interface CannedSearchesSource : HGSMemorySearchSource
- (void) loadCannedSearches;
- (HGSResult *) resultForPath:(NSString *)path;
@end

#pragma mark -
@implementation CannedSearchesSource

- (id) initWithConfiguration:(NSDictionary *)configuration
{
  self = [super initWithConfiguration:configuration];
  if (self == nil)
    return nil;
  [self loadResultsCache];
  [self loadCannedSearches];
  return self;
}

- (void) loadCannedSearches
{
  NSBundle *bundle = _CannedSearchesBundle();
  NSArray *paths = [bundle pathsForResourcesOfType:kCannedSearchesFileExtension
                                       inDirectory:kCannedSearchesDirectoryName];
  [self clearResultIndex];
  for (NSString *path in paths) {
    [self indexResult:[self resultForPath:path]];
  }
  [self saveResultsCache];
}

- (HGSResult *) resultForPath:(NSString *)path
{
  return [HGSResult resultWithFilePath:path
                                source:self
                            attributes:nil];
}

@end
