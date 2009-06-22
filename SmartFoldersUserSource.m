//
//  SmartFoldersUserSource.m
//
//  Copyright (c) 2009  Martin Kuehl <purl.org/net/mkhl>
//  Licensed under the MIT License.
//

#import <Vermilion/Vermilion.h>
#import "SmartFoldersAbstractSource.h"

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
  NSString *path = [paths lastObject];
  return [path stringByAppendingPathComponent:kSmartFoldersUserPathComponent];
}

static NSArray *_SmartFoldersUserQueryScopes(NSDictionary *attrs)
{
  return [attrs valueForKeyPath:kSmartFoldersUserFileScopesKey];
}

static NSString *_SmartFoldersUserQueryString(NSDictionary *attrs)
{
  return [attrs valueForKeyPath:kSmartFoldersUserFileQueryKey];
}

#pragma mark -
@interface SmartFoldersUserSource : SmartFoldersAbstractSource
@end

#pragma mark -
@implementation SmartFoldersUserSource

#pragma mark Memory Management
- (id)initWithConfiguration:(NSDictionary *)configuration
{
  self = [super initWithConfiguration:configuration
                             rootPath:_SmartFoldersUserPath()
                        pathExtension:kSmartFoldersUserPathExtension];
  return self;
}

#pragma mark SmartFoldersAbstractSource
- (NSString *)queryStringForPath:(NSString *)path
{
  NSDictionary *attrs = [NSDictionary dictionaryWithContentsOfFile:path];
  if (attrs == nil) {
    HGSLogDebug(@"%@: Failed to read dictionary from file: %@", self, path);
    return nil;
  }
  return _SmartFoldersUserQueryString(attrs);
}

- (NSArray *)queryScopesForPath:(NSString *)path
{
  NSDictionary *attrs = [NSDictionary dictionaryWithContentsOfFile:path];
  if (attrs == nil) {
    HGSLogDebug(@"%@: Failed to read dictionary from file: %@", self, path);
    return nil;
  }
  return _SmartFoldersUserQueryScopes(attrs);
}

@end
