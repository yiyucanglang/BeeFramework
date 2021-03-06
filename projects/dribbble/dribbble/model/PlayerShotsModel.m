//
//	 ______    ______    ______
//	/\  __ \  /\  ___\  /\  ___\
//	\ \  __<  \ \  __\_ \ \  __\_
//	 \ \_____\ \ \_____\ \ \_____\
//	  \/_____/  \/_____/  \/_____/
//
//
//	Copyright (c) 2014-2015, Geek Zoo Studio
//	http://www.bee-framework.com
//
//
//	Permission is hereby granted, free of charge, to any person obtaining a
//	copy of this software and associated documentation files (the "Software"),
//	to deal in the Software without restriction, including without limitation
//	the rights to use, copy, modify, merge, publish, distribute, sublicense,
//	and/or sell copies of the Software, and to permit persons to whom the
//	Software is furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//	IN THE SOFTWARE.
//

#import "PlayerShotsModel.h"

#pragma mark -

#undef	PER_PAGE
#define PER_PAGE	(30)

#pragma mark -

@implementation PlayerShotsModel

@synthesize player_id = _player_id;
@synthesize shots = _shots;

- (void)load
{
	self.autoSave = YES;
	self.autoLoad = YES;

	self.shots = [NSMutableArray array];
}

- (void)unload
{
	self.shots = nil;
	self.player_id = nil;
}

#pragma mark -

- (void)loadCache
{
	[self.shots removeAllObjects];
}

- (void)saveCache
{
}

- (void)clearCache
{
	[self.shots removeAllObjects];
}

#pragma mark -

- (void)firstPage
{
	[self gotoPage:1];
}

- (void)nextPage
{
	if ( self.shots.count )
	{
		[self gotoPage:(self.shots.count / PER_PAGE + 1)];
	}
}

- (void)gotoPage:(NSUInteger)page
{
	[API_PLAYERS_ID_SHOTS cancel];

	API_PLAYERS_ID_SHOTS * api = [API_PLAYERS_ID_SHOTS api];
	
	@weakify(api);
	@weakify(self);

	api.id = self.player_id;
	api.req.page = @(page);
	api.req.per_page = @(PER_PAGE);
	
	api.whenUpdate = ^
	{
		@normalize(api);
		@normalize(self);

		if ( api.sending )
		{
			[self sendUISignal:self.RELOADING];
		}
		else
		{
			if ( api.succeed )
			{
				if ( nil == api.resp.shots )
				{
					api.failed = YES;
				}
				else
				{
					if ( page <= 1 )
					{
						[self.shots removeAllObjects];
						[self.shots addObjectsFromArray:api.resp.shots];
					}
					else
					{
						[self.shots addObjectsFromArray:api.resp.shots];
						[self.shots unique:^NSComparisonResult(id left, id right) {
							return [((SHOT *)left).id compare:((SHOT *)right).id];
						}];	
					}
										
					self.more = (self.shots.count >= api.resp.total.intValue) ? NO : YES;
					self.loaded = YES;
					
					[self saveCache];
				}
			}
			
			[self sendUISignal:self.RELOADED];
		}
	};
	
	[api send];
}

@end
