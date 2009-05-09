//
//  SmartFoldersAbstractSource.m
//
//  Copyright (c) 2009  Martin Kuehl <purl.org/net/mkhl>
//  Licensed under the MIT License.
//

#import <Vermilion/Vermilion.h>
#import <Vermilion/HGSTokenizer.h>
#import "SmartFoldersAbstractSource.h"

#pragma mark Static Data

static NSString *const kSmartFoldersAttributeQueryKey
  = @"SmartFoldersAttributeQuery";

#pragma mark -
@interface SmartFoldersAbstractSource ()
@property (copy) NSString *resultType;
@end

#pragma mark -
@implementation SmartFoldersAbstractSource

#pragma mark Accessors

@synthesize resultType = resultType_;

#pragma mark Memory Management

- (id) initWithConfiguration:(NSDictionary *)configuration
                    rootPath:(NSString *)path
                  resultType:(NSString *)type
{
  // We need to set this _first_. We need it in a method called super's init.
  self.resultType = type;
  self = [super initWithConfiguration:configuration rootPath:path];
  if (self == nil)
    return nil;
  return self;
}

- (void) dealloc
{
  self.resultType = nil;
  [super dealloc];
}

#pragma mark NSMetadataItems

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

#pragma mark HGSMemorySearchSource

// Override -indexResult: to add our data to the HGSResult.
// The added data consists of:
// - a more specific result type than "file"
// - an NSMetadataQuery instance executing the smart folder's search
// Creates a new HGSResult instance and merges it with the given one, because
// HGSResult's -setValue:forKey: currently contains a failing assertion and
// cannot be called.
- (void) indexResult:(HGSResult *)hgsResult
{
  NSMetadataQuery *query = [[NSMetadataQuery new] autorelease];
  NSDictionary *attrs
    = [NSDictionary dictionaryWithObject:query
                                  forKey:kSmartFoldersAttributeQueryKey];
  NSURL *url = [hgsResult url];
  HGSResult *result = [HGSResult resultWithURL:url
                                          name:[hgsResult displayName]
                                          type:self.resultType
                                        source:self
                                    attributes:attrs];
  [super indexResult:[result mergeWith:hgsResult]];
  @try {
    [self startQuery:query forPath:[url path]];
  }
  @catch (NSException *e) {
    HGSLogDebug(@"%@: failed to start NSMetadataQuery for HGSResult %@: %@",
                self, result, e);
  }
}

#pragma mark HGSSearchSource

// Override -performSearchOperation: to support descending into smart folders.
- (void) performSearchOperation:(HGSSearchOperation*)operation
{
  HGSQuery *query = [operation query];
  HGSResult *pivot = [query pivotObject];
  if (pivot) {
    NSMetadataQuery *mdQuery
      = [pivot valueForKey:kSmartFoldersAttributeQueryKey];
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

#pragma mark -
@implementation SmartFoldersAbstractSource (ProtectedMethods)

#pragma mark Subclassing

- (void) startQuery:(NSMetadataQuery *)query forPath:(NSString *)path
{
  // To be overridden by subclasses.
}

@end
