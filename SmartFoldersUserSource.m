//
//  SmartFoldersUserSource.m
//
//  Copyright (c) 2009  Martin Kuehl <purl.org/net/mkhl>
//  Licensed under the MIT License.
//

#import <Vermilion/Vermilion.h>
#import "SmartFoldersAbstractSource.h"

#pragma mark HGSResult Type
static NSString *const kSmartFoldersUserResultType
  = HGS_SUBTYPE(kHGSTypeFileSearch, @"savedSearch");

#pragma mark Saved Search Path data
static NSString *const kSmartFoldersUserPathComponent = @"Saved Searches";
static NSString *const kSmartFoldersUserPathExtension = @"savedSearch";

#pragma mark Saved Search Content keys
static NSString *const kSmartFoldersUserFileQueryKey = @"RawQuery";
static NSString *const kSmartFoldersUserFileScopesKey
  = @"RawQueryDict.SearchScopes";

#pragma mark -
#pragma mark Helper Functions

static NSString *_SmartFoldersUserPath(void)
{
  NSArray *paths
    = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
                                          NSUserDomainMask, YES);
  return [[paths lastObject]
          stringByAppendingPathComponent:kSmartFoldersUserPathComponent];
}

static NSArray *_SmartFoldersUserQueryScopes(NSDictionary *attrs)
{
  return [attrs valueForKeyPath:kSmartFoldersUserFileScopesKey];
}

static NSPredicate *_SmartFoldersUserQueryPredicate(NSDictionary *attrs)
{
  NSString *format = [attrs valueForKeyPath:kSmartFoldersUserFileQueryKey];
  format = [format stringByReplacingOccurrencesOfString:@" && (true)"
                                             withString:@""];
  return [NSPredicate predicateWithFormat:format];
}

#pragma mark -
@interface SmartFoldersUserSource : SmartFoldersAbstractSource
@end

#pragma mark -
@implementation SmartFoldersUserSource

#pragma mark Memory Management

- (id) initWithConfiguration:(NSDictionary *)configuration
{
  self = [super initWithConfiguration:configuration
                             rootPath:_SmartFoldersUserPath()
                           resultType:kSmartFoldersUserResultType];
  return self;
}

#pragma mark NSMetadataQuery

- (void) startQuery:(NSMetadataQuery *)query forPath:(NSString *)path
{
  NSDictionary *attrs = [NSDictionary dictionaryWithContentsOfFile:path];
  if (attrs == nil) {
    HGSLogDebug(@"%@: Failed to read dictionary from file: %@", self, path);
  } else {
    [query setSearchScopes:_SmartFoldersUserQueryScopes(attrs)];
    [query setPredicate:_SmartFoldersUserQueryPredicate(attrs)];
    [query startQuery];
  }
}

@end
