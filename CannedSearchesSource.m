//
//  CannedSearchesSource.m
//
//  Copyright (c) 2009  Martin Kuehl <purl.org/net/mkhl>
//  Licensed under the MIT License.
//

#import <Vermilion/Vermilion.h>
#import "SavedSearchesAbstractSource.h"

#pragma mark HGSResult Type
static NSString *const kCannedSearchesResultType
  = HGS_SUBTYPE(kHGSTypeFileSearch, @"cannedSearch");

#pragma mark Saved Search Path data
static NSString *const kCannedSearchesBundleIdentifier = @"com.apple.Finder";
static NSString *const kCannedSearchesPathComponent = @"CannedSearches";
static NSString *const kCannedSearchesPathExtension = @"cannedSearch";
static NSString *const kCannedSearchesPathSearchFile = @"search.savedSearch";

#pragma mark Saved Search Content keys
static NSString *const kCannedSearchesFileQueryKey = @"RawQuery";
static NSString *const kCannedSearchesFileScopesKey
  = @"RawQueryDict.SearchScopes";

#pragma mark -
#pragma mark Helper Functions

static NSString *_CannedSearchesPath(void)
{
  NSWorkspace *ws = [NSWorkspace sharedWorkspace];
  NSString *path
    = [ws absolutePathForAppBundleWithIdentifier:kCannedSearchesBundleIdentifier];
  path = [[NSBundle bundleWithPath:path] resourcePath];
  return [path stringByAppendingPathComponent:kCannedSearchesPathComponent];
}

static NSArray *_CannedSearchesQueryScopes(NSDictionary *attrs)
{
  return [attrs valueForKeyPath:kCannedSearchesFileScopesKey];
}

static NSPredicate *_CannedSearchesQueryPredicate(NSDictionary *attrs)
{
  NSString *format = [attrs valueForKeyPath:kCannedSearchesFileQueryKey];
  format = [format stringByReplacingOccurrencesOfString:@" && (true)"
                                             withString:@""];
  return [NSPredicate predicateWithFormat:format];
}

#pragma mark -
@interface CannedSearchesSource : SavedSearchesAbstractSource
@end

#pragma mark -
@implementation CannedSearchesSource

#pragma mark Memory Management
- (id) initWithConfiguration:(NSDictionary *)configuration
{
  self = [super initWithConfiguration:configuration
                             rootPath:_CannedSearchesPath()
                           resultType:kCannedSearchesResultType];
  return self;
}

#pragma mark NSMetadataQuery

- (void) startQuery:(NSMetadataQuery *)query forPath:(NSString *)path
{
  path = [path stringByAppendingPathComponent:kCannedSearchesPathSearchFile];
  NSDictionary *attrs = [NSDictionary dictionaryWithContentsOfFile:path];
  if (attrs == nil) {
    HGSLogDebug(@"%@: Failed to read dictionary from file: %@", self, path);
  } else {
    [query setSearchScopes:_CannedSearchesQueryScopes(attrs)];
    [query setPredicate:_CannedSearchesQueryPredicate(attrs)];
    [query startQuery];
  }
}

@end
