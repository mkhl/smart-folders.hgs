//
//  SavedSearchesSource.m
//
//  Copyright (c) 2009  Martin Kuehl <purl.org/net/mkhl>
//  Licensed under the MIT License.
//

#import <Vermilion/Vermilion.h>

@class SavedSearchesSource;

#pragma mark Static Data

static NSString *const kSavedSearchesPathComponent = @"Saved Searches";
static NSString *const kSavedSearchesPredicateFormat
	= @"(kMDItemKind == 'Saved Search Query')";

#pragma mark Helper Functions

static NSArray *_SavedSearchesQueryScopes(void)
{
	NSMutableArray *scopes = [NSMutableArray array];
	NSArray *paths
	= NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
																				NSUserDomainMask, YES);
	for (NSString *path in paths) {
		[scopes addObject:
		 [path stringByAppendingPathComponent:kSavedSearchesPathComponent]];
	}
	return scopes;
}

static NSPredicate *_SavedSearchesQueryPredicate(void)
{
	return [NSPredicate predicateWithFormat:kSavedSearchesPredicateFormat];
}

static NSArray *_SavedSearchesQuerySortDescriptors(void)
{
	NSSortDescriptor *lastUsed
		= [[[NSSortDescriptor alloc] initWithKey:(NSString *)kMDItemLastUsedDate 
																	 ascending:NO]
			 autorelease];
	return [NSArray arrayWithObject:lastUsed];
}

static NSArray *_SavedSearchesQueryAttributes(void)
{
  return [NSArray arrayWithObjects:
					(NSString *)kMDItemDisplayName,
					(NSString *)kMDItemPath,
					(NSString *)kMDItemLastUsedDate,
					nil];
}

#pragma mark -
@interface SavedSearchesSource : HGSMemorySearchSource {
 @private
	BOOL indexing_;
	NSCondition *condition_;
	NSMetadataQuery *query_;
}

@property (assign) BOOL indexing;
@property (retain) NSCondition *condition;
@property (retain) NSMetadataQuery *query;

- (void) queryNotification:(NSNotification *)notification;
- (NSOperation *) parseResultsOperation;
- (void) parseResults:(NSMetadataQuery *)query;
- (HGSResult *) resultForMetadataItem:(NSMetadataItem *)mdResult;

@end

#pragma mark -
@implementation SavedSearchesSource

#pragma mark Accessors

@synthesize indexing = indexing_;
@synthesize condition = condition_;
@synthesize query = query_;

#pragma mark Memory Management

- (id) initWithConfiguration:(NSDictionary *)configuration
{
	self = [super initWithConfiguration:configuration];
	if (self == nil)
		return nil;
	[self loadResultsCache];
	self.indexing = NO;
	self.condition = [NSCondition new];
	self.query = [NSMetadataQuery new];
	[self.query setSearchScopes:_SavedSearchesQueryScopes()];
	[self.query setPredicate:_SavedSearchesQueryPredicate()];
	[self.query setSortDescriptors:_SavedSearchesQuerySortDescriptors()];
	[self.query setNotificationBatchingInterval:10];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self
				 selector:@selector(queryNotification:)
						 name:NSMetadataQueryDidFinishGatheringNotification
					 object:self.query];
	[nc addObserver:self
				 selector:@selector(queryNotification:)
						 name:NSMetadataQueryDidUpdateNotification
					 object:self.query];
	[self.query startQuery];
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.condition = nil;
	self.query = nil;
	[super dealloc];
}

#pragma mark NSMetadataQuery

- (void) queryNotification:(NSNotification *)notification
{
	[self.query disableUpdates];
	[[HGSOperationQueue sharedOperationQueue]
	 addOperation:[self parseResultsOperation]];
}

- (NSOperation *) parseResultsOperation
{
	return [[NSInvocationOperation alloc] initWithTarget:self
																							selector:@selector(parseResults:)
																								object:self.query];
}

- (void) parseResults:(NSMetadataQuery *)query
{
	[self.condition lock];
	self.indexing = YES;
	[self clearResultIndex];
	for (NSMetadataItem *mdResult in [query results]) {
		[self indexResult:[self resultForMetadataItem:mdResult]];
	}
	self.indexing = NO;
	[self.condition signal];
	[self.condition unlock];
	[self saveResultsCache];
	[query enableUpdates];
}

- (HGSResult *) resultForMetadataItem:(NSMetadataItem *)mdResult
{
	NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
	NSDictionary *mdAttrs
	= [mdResult valuesForAttributes:_SavedSearchesQueryAttributes()];
	NSString *path = [mdAttrs objectForKey:(NSString *)kMDItemPath];
	NSString *name = [mdAttrs objectForKey:(NSString *)kMDItemDisplayName];
	if (name == nil) {
		name = [[path lastPathComponent] stringByDeletingPathExtension];
	}
	[attrs setObject:name forKey:kHGSObjectAttributeNameKey];
	NSDate *date = [mdAttrs objectForKey:(NSString *)kMDItemLastUsedDate];
	if (date == nil) {
		date = [NSDate distantPast];
	}
	[attrs setObject:date forKey:kHGSObjectAttributeLastUsedDateKey];
	return [HGSResult resultWithFilePath:path
																source:self
														attributes:attrs];
}

#pragma mark HGSSearchSource

- (void) performSearchOperation:(HGSSearchOperation *)operation
{
	[self.condition lock];
	while (self.indexing) {
		[self.condition wait];
	}
	[self.condition signal];
	[self.condition unlock];
	[super performSearchOperation:operation];
}

@end
