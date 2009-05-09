//
//  CannedSearchesSource.m
//
//  Copyright (c) 2009  Martin Kuehl <purl.org/net/mkhl>
//  Licensed under the MIT License.
//

#import <Vermilion/Vermilion.h>
#import "HGSDirectoryScannerSearchSource.h"

#pragma mark Static Data

static NSString *const kCannedSearchesBundleIdentifier = @"com.apple.Finder";
static NSString *const kCannedSearchesPathComponent = @"CannedSearches";
static NSString *const kCannedSearchesPathExtension = @"cannedSearch";

#pragma mark -
#pragma mark Helper Functions

static NSString *_CannedSearchesPath(void)
{
  return [[[NSBundle bundleWithPath:[[NSWorkspace sharedWorkspace]
                                     absolutePathForAppBundleWithIdentifier:kCannedSearchesBundleIdentifier]]
           resourcePath] stringByAppendingPathComponent:kCannedSearchesPathComponent];
}

#pragma mark -
@interface CannedSearchesSource : HGSDirectoryScannerSearchSource
@end

#pragma mark -
@implementation CannedSearchesSource

- (id) initWithConfiguration:(NSDictionary *)configuration
{
  NSString *path = _CannedSearchesPath();
  self = [super initWithConfiguration:configuration rootPath:path];
  return self;
}

@end
