//
//  SmartFoldersAbstractSource.m
//
//  Copyright (c) 2009  Martin Kuehl <purl.org/net/mkhl>
//  Licensed under the MIT License.
//

#import <Vermilion/Vermilion.h>
#import <Vermilion/HGSTokenizer.h>
#import "SmartFoldersAbstractSource.h"
#import "Macros.h"


#pragma mark -
@interface SmartFoldersAbstractSource ()

@property (copy) NSString *pathExtension;
@property (retain) NSMutableDictionary *queryMap;

- (HGSResult *)resultForMetadataItem:(MDItemRef)mdItem query:(HGSQuery *)query;

@end


#pragma mark -
@implementation SmartFoldersAbstractSource

#pragma mark Accessors
@synthesize pathExtension = pathExtension_;
@synthesize queryMap = queryMap_;

#pragma mark Memory Management
- (id)initWithConfiguration:(NSDictionary *)configuration
                   rootPath:(NSString *)path
              pathExtension:(NSString *)extension
{
  self = [super initWithConfiguration:configuration rootPath:path];
  if (!self)
    return nil;
  pathExtension_ = [extension copy];
  queryMap_ = [NSMutableDictionary new];
  [self startIndexing];
  return self;
}

- (void)dealloc
{
  DESTROY(pathExtension_);
  DESTROY(queryMap_);
  [super dealloc];
}

#pragma mark Metadata Query Creation
- (MDQueryRef)queryWithString:(NSString *)string
                     inScopes:(NSArray *)scopes
{
  MDQueryRef mdQuery = MDQueryCreate(NULL, (CFStringRef)string, NULL, NULL);
  if (!mdQuery) {
    HGSLogDebug(@"%@: Failed to create Query from String: %@ in Scopes: %@", 
                self, string, scopes);
    return NULL;
  }
  if (scopes) {
    MDQuerySetSearchScope(mdQuery, (CFArrayRef)scopes, 0);
  }
  return mdQuery;
}

#pragma mark Metadata Query Execution
- (void)startQueryWithPath:(NSString *)path
{
  MDQueryRef mdQuery = [self queryWithString:[self queryStringForPath:path]
                                    inScopes:[self queryScopesForPath:path]];
  MDQueryExecute(mdQuery, kMDQueryWantsUpdates);
  [self.queryMap setObject:(id)mdQuery forKey:path];
  CFRelease(mdQuery);
}

#pragma mark Sublevel Results
- (HGSResult *)resultForMetadataItem:(MDItemRef)mdItem
                               query:(HGSQuery *)query
{
  NSString *path = (NSString *)MDItemCopyAttribute(mdItem, kMDItemPath);
  HGSMutableResult *result
    = [HGSMutableResult resultWithFilePath:path source:self attributes:nil];
  [path release];
  NSString *name = [HGSTokenizer tokenizeString:[result displayName]];
  NSString *abbr = [query normalizedQueryString];
  [result setRank:HGSScoreForAbbreviation(name, abbr, NULL)];
  return result;
}

#pragma mark Toplevel Results
- (HGSResult *)resultForFilePath:(NSString *)path
{
  [self startQueryWithPath:path];
  return [HGSResult resultWithFilePath:path source:self attributes:nil];
}

#pragma mark HGSSearchSource
- (BOOL)isValidSourceForQuery:(HGSQuery *)query
{
  BOOL valid = [super isValidSourceForQuery:query];
  if (valid) {
    HGSResult *pivot = [query pivotObject];
    if (pivot) {
      NSString *path = [[[pivot url] path] lastPathComponent];
      valid = [self.pathExtension isEqualToString:[path pathExtension]];
    }
  }
  return valid;
}

// Override -performSearchOperation: to support descending into smart folders.
- (void)performSearchOperation:(HGSSearchOperation*)operation
{
  HGSQuery *query = [operation query];
  HGSResult *pivot = [query pivotObject];
  if (!pivot) {
    [super performSearchOperation:operation];
  } else {
    NSString *path = [[pivot url] path];
    MDQueryRef mdQuery = (MDQueryRef)[self.queryMap objectForKey:path];
    if (!mdQuery) {
      HGSLogDebug(@"%@: Failed to extract Query for Path: %@", self, path);
      return;
    }
    NSMutableArray *results = [NSMutableArray array];
    MDQueryDisableUpdates(mdQuery);
    CFIndex i, count = MDQueryGetResultCount(mdQuery);
    for (i = 0; i < count; i++) {
      MDItemRef mdItem = (MDItemRef)MDQueryGetResultAtIndex(mdQuery, i);
      HGSResult *result = [self resultForMetadataItem:mdItem query:query];
      if ([result rank] > 0) {
        [results addObject:result];
      }
    }
    MDQueryEnableUpdates(mdQuery);
    [operation setResults:results];
  }
}

@end


#pragma mark -
@implementation SmartFoldersAbstractSource (ProtectedMethods)

- (NSString *)queryStringForPath:(NSString *)path
{
  return nil;
}
- (NSArray *)queryScopesForPath:(NSString *)path
{
  return nil;
}

@end
