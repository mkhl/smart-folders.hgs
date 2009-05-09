//
//  SavedSearchesSource.m
//
//  Copyright (c) 2009  Martin Kuehl <purl.org/net/mkhl>
//  Licensed under the MIT License.
//

#import <Vermilion/Vermilion.h>
#import "SavedSearchesAbstractSource.h"

#pragma mark HGSResult Type
static NSString *const kSavedSearchesResultType
  = HGS_SUBTYPE(kHGSTypeFileSearch, @"savedSearch");

#pragma mark Saved Search Path data
static NSString *const kSavedSearchesPathComponent = @"Saved Searches";
static NSString *const kSavedSearchesPathExtension = @"savedSearch";

#pragma mark Saved Search Content keys
static NSString *const kSavedSearchesFileQueryKey = @"RawQuery";
static NSString *const kSavedSearchesFileScopesKey
  = @"RawQueryDict.SearchScopes";

#pragma mark -
#pragma mark Helper Functions

static NSString *_SavedSearchesPath(void)
{
  NSArray *paths
    = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
                                          NSUserDomainMask, YES);
  return [[paths lastObject]
          stringByAppendingPathComponent:kSavedSearchesPathComponent];
}

static NSArray *_SavedSearchesQueryScopes(NSDictionary *attrs)
{
  return [attrs valueForKeyPath:kSavedSearchesFileScopesKey];
}

static NSPredicate *_SavedSearchesQueryPredicate(NSDictionary *attrs)
{
  NSString *format = [attrs valueForKeyPath:kSavedSearchesFileQueryKey];
  format = [format stringByReplacingOccurrencesOfString:@" && (true)"
                                             withString:@""];
  return [NSPredicate predicateWithFormat:format];
}

#pragma mark -
@interface SavedSearchesSource : SavedSearchesAbstractSource
@end

#pragma mark -
@implementation SavedSearchesSource

#pragma mark Memory Management

- (id) initWithConfiguration:(NSDictionary *)configuration
{
  self = [super initWithConfiguration:configuration
                             rootPath:_SavedSearchesPath()
                           resultType:kSavedSearchesResultType];
  return self;
}

#pragma mark NSMetadataQuery

- (void) startQuery:(NSMetadataQuery *)query forPath:(NSString *)path
{
  NSDictionary *attrs = [NSDictionary dictionaryWithContentsOfFile:path];
  if (attrs == nil) {
    HGSLogDebug(@"%@: Failed to read dictionary from file: %@", self, path);
  } else {
    [query setSearchScopes:_SavedSearchesQueryScopes(attrs)];
    [query setPredicate:_SavedSearchesQueryPredicate(attrs)];
    [query startQuery];
  }
}

@end
