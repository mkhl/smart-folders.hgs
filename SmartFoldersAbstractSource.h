//
//  SmartFoldersAbstractSource.h
//
//  Copyright (c) 2009  Martin Kuehl <purl.org/net/mkhl>
//  Licensed under the MIT License.
//

#import <Vermilion/Vermilion.h>
#import "HGSDirectoryScannerSearchSource.h"

#define kHGSTypeFileSearch HGS_SUBTYPE(kHGSTypeFile, kHGSTypeSearch)

@interface SmartFoldersAbstractSource : HGSDirectoryScannerSearchSource {
 @private
  NSString *resultType_;
}

- (id) initWithConfiguration:(NSDictionary *)configuration
                    rootPath:(NSString *)path
                  resultType:(NSString *)type;
@end

@interface SmartFoldersAbstractSource (ProtectedMethods)
- (void) startQuery:(NSMetadataQuery *)query forPath:(NSString *)path;
@end
