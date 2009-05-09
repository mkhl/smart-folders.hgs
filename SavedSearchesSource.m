//
//  SavedSearchesSource.m
//
//  Copyright (c) 2009  Martin Kuehl <purl.org/net/mkhl>
//  Licensed under the MIT License.
//

#import <Vermilion/Vermilion.h>
#import <Vermilion/HGSTokenizer.h>
#import "HGSDirectoryScannerSearchSource.h"

#pragma mark Static Data

static NSString *const kSavedSearchesResultType
  = HGS_SUBTYPE(kHGSTypeFileSearch, @"savedSearch");

static NSString *const kSavedSearchesAttributeQueryKey
  = @"SavedSearchesAttributeQuery";

static NSString *const kSavedSearchesPathComponent = @"Saved Searches";
static NSString *const kSavedSearchesPathExtension = @"savedSearch";

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

#pragma mark NSMetadataItem

- (HGSResult *) resultForMetadataItem:(NSMetadataItem *)mdResult
                                query:(HGSQuery *)query
{
  NSString *path = [mdResult valueForAttribute:(NSString *)kMDItemPath];
  HGSMutableResult *result = [HGSMutableResult resultWithFilePath:path
                                                           source:self
                                                       attributes:nil];
  NSString *tokenizedName = [HGSTokenizer tokenizeString:[result displayName]];
  NSString *normalizedQuery = [query normalizedQueryString];
  [result setRank:HGSScoreForAbbreviation(tokenizedName, normalizedQuery, NULL)];
  return result;
}

#pragma mark HGSResult

// Override -indexResult: to add our data to the HGSResult.
// The added data consists of:
// - a more specific result type than "file"
// - an NSMetadataQuery instance executing the saved search
// Creates a new HGSResult instance and merges it with the given one, because
// HGSResult's -setValue:forKey: currently contains a failing assertion and
// cannot be called.
- (void)indexResult:(HGSResult *)hgsResult
{
  NSMetadataQuery *query = [[NSMetadataQuery new] autorelease];
  NSDictionary *attrs
    = [NSDictionary dictionaryWithObject:query
                                  forKey:kSavedSearchesAttributeQueryKey];
  NSURL *url = [hgsResult url];
  HGSResult *result = [HGSResult resultWithURL:url
                                          name:[hgsResult displayName]
                                          type:kSavedSearchesResultType
                                        source:self
                                    attributes:attrs];
  [super indexResult:[result mergeWith:hgsResult]];
  [self startQuery:query forPath:[url path]];
}

#pragma mark HGSSearchSource

- (void) performSearchOperation:(HGSSearchOperation*)operation
{
  HGSQuery *query = [operation query];
  HGSResult *pivot = [query pivotObject];
  if (pivot) {
    NSMetadataQuery *mdQuery
      = [pivot valueForKey:kSavedSearchesAttributeQueryKey];
    if (mdQuery) {
      NSMutableArray *results = [NSMutableArray array];
      [mdQuery disableUpdates];
      for (NSMetadataItem *mdResult in [mdQuery results]) {
        HGSResult *result = [self resultForMetadataItem:mdResult query:query];
        if ([result rank] > 0) {
          [results addObject:result];
        }
      }
      [mdQuery enableUpdates];
      [operation setResults:results];
    }
  }
  else {
    [super performSearchOperation:operation];
  }
}

@end
