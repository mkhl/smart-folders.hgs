//
//  SmartFoldersSystemSource.m
//
//  Copyright (c) 2009  Martin Kuehl <purl.org/net/mkhl>
//  Licensed under the MIT License.
//

#import <Vermilion/Vermilion.h>
#import "SmartFoldersAbstractSource.h"

#pragma mark HGSResult Type
static NSString *const kSmartFoldersSystemResultType
  = HGS_SUBTYPE(kHGSTypeFileSearch, @"cannedSearch");

#pragma mark Canned Search Path data
static NSString *const kSmartFoldersSystemBundleIdentifier = @"com.apple.Finder";
static NSString *const kSmartFoldersSystemPathComponent = @"CannedSearches";
static NSString *const kSmartFoldersSystemPathExtension = @"cannedSearch";
static NSString *const kSmartFoldersSystemPathSearchFile = @"search.savedSearch";

#pragma mark Canned Search Content keys
static NSString *const kSmartFoldersSystemFileQueryKey = @"RawQuery";
static NSString *const kSmartFoldersSystemFileScopesKey
  = @"RawQueryDict.SearchScopes";

#pragma mark -
#pragma mark Helper Functions

static NSString *_SmartFoldersSystemPath(void)
{
  NSWorkspace *ws = [NSWorkspace sharedWorkspace];
  NSString *path
    = [ws absolutePathForAppBundleWithIdentifier:kSmartFoldersSystemBundleIdentifier];
  path = [[NSBundle bundleWithPath:path] resourcePath];
  return [path stringByAppendingPathComponent:kSmartFoldersSystemPathComponent];
}

static NSArray *_SmartFoldersSystemQueryScopes(NSDictionary *attrs)
{
  return [attrs valueForKeyPath:kSmartFoldersSystemFileScopesKey];
}

static NSPredicate *_SmartFoldersSystemQueryPredicate(NSDictionary *attrs)
{
  NSString *format = [attrs valueForKeyPath:kSmartFoldersSystemFileQueryKey];
  format = [format stringByReplacingOccurrencesOfString:@" && (true)"
                                             withString:@""];
  return [NSPredicate predicateWithFormat:format];
}

#pragma mark -
@interface SmartFoldersSystemSource : SmartFoldersAbstractSource
@end

#pragma mark -
@implementation SmartFoldersSystemSource

#pragma mark Memory Management
- (id) initWithConfiguration:(NSDictionary *)configuration
{
  self = [super initWithConfiguration:configuration
                             rootPath:_SmartFoldersSystemPath()
                           resultType:kSmartFoldersSystemResultType];
  return self;
}

#pragma mark NSMetadataQuery

- (void) startQuery:(NSMetadataQuery *)query forPath:(NSString *)path
{
  path = [path stringByAppendingPathComponent:kSmartFoldersSystemPathSearchFile];
  NSDictionary *attrs = [NSDictionary dictionaryWithContentsOfFile:path];
  if (attrs == nil) {
    HGSLogDebug(@"%@: Failed to read dictionary from file: %@", self, path);
  } else {
    [query setSearchScopes:_SmartFoldersSystemQueryScopes(attrs)];
    [query setPredicate:_SmartFoldersSystemQueryPredicate(attrs)];
    [query startQuery];
  }
}

@end
