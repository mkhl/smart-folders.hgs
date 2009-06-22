//
//  SmartFoldersSystemSource.m
//
//  Copyright (c) 2009  Martin Kuehl <purl.org/net/mkhl>
//  Licensed under the MIT License.
//

#import <Vermilion/Vermilion.h>
#import "SmartFoldersAbstractSource.h"

#pragma mark Canned Search Path data
static NSString *const kSmartFoldersSystemBundleIdentifier
  = @"com.apple.Finder";
static NSString *const kSmartFoldersSystemPathComponent = @"CannedSearches";
static NSString *const kSmartFoldersSystemPathExtension = @"cannedSearch";
static NSString *const kSmartFoldersSystemPathSearchFile
  = @"search.savedSearch";

#pragma mark Canned Search Content keys
static NSString *const kSmartFoldersSystemFileQueryKey = @"RawQuery";
static NSString *const kSmartFoldersSystemFileScopesKey
  = @"RawQueryDict.SearchScopes";

#pragma mark -
#pragma mark Helper Functions
static NSString *_SmartFoldersSystemPath(void)
{
  NSWorkspace *ws = [NSWorkspace sharedWorkspace];
  NSString *path = [ws absolutePathForAppBundleWithIdentifier:
                    kSmartFoldersSystemBundleIdentifier];
  path = [[NSBundle bundleWithPath:path] resourcePath];
  return [path stringByAppendingPathComponent:
          kSmartFoldersSystemPathComponent];
}

static NSArray *_SmartFoldersSystemQueryScopes(NSDictionary *attrs)
{
  return [attrs valueForKeyPath:kSmartFoldersSystemFileScopesKey];
}

static NSString *_SmartFoldersSystemQueryString(NSDictionary *attrs)
{
  return [attrs valueForKeyPath:kSmartFoldersSystemFileQueryKey];
}

#pragma mark -
@interface SmartFoldersSystemSource : SmartFoldersAbstractSource
@end

#pragma mark -
@implementation SmartFoldersSystemSource

#pragma mark Memory Management
- (id)initWithConfiguration:(NSDictionary *)configuration
{
  self = [super initWithConfiguration:configuration
                             rootPath:_SmartFoldersSystemPath()
                        pathExtension:kSmartFoldersSystemPathExtension];
  return self;
}

#pragma mark SmartFoldersAbstractSource
- (NSString *)queryStringForPath:(NSString *)path
{
  path = [path stringByAppendingPathComponent:
          kSmartFoldersSystemPathSearchFile];
  NSDictionary *attrs = [NSDictionary dictionaryWithContentsOfFile:path];
  if (attrs == nil) {
    HGSLogDebug(@"%@: Failed to read dictionary from file: %@", self, path);
    return nil;
  }
  return _SmartFoldersSystemQueryString(attrs);
}

- (NSArray *)queryScopesForPath:(NSString *)path
{
  path = [path stringByAppendingPathComponent:
          kSmartFoldersSystemPathSearchFile];
  NSDictionary *attrs = [NSDictionary dictionaryWithContentsOfFile:path];
  if (attrs == nil) {
    HGSLogDebug(@"%@: Failed to read dictionary from file: %@", self, path);
    return nil;
  }
  return _SmartFoldersSystemQueryScopes(attrs);
}

@end
