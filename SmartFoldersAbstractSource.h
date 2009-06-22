//
//  SmartFoldersAbstractSource.h
//
//  Copyright (c) 2009  Martin Kuehl <purl.org/net/mkhl>
//  Licensed under the MIT License.
//

#import <Vermilion/Vermilion.h>
#import "HGSDirectoryScannerSearchSource.h"

@interface SmartFoldersAbstractSource : HGSDirectoryScannerSearchSource {
 @private
  NSString *pathExtension_;
  NSMutableDictionary *queryMap_;
}

- (id)initWithConfiguration:(NSDictionary *)configuration
                   rootPath:(NSString *)path
              pathExtension:(NSString *)extension;

@end

@interface SmartFoldersAbstractSource (ProtectedMethods)

- (NSString *)queryStringForPath:(NSString *)path;
- (NSArray *)queryScopesForPath:(NSString *)path;

@end
