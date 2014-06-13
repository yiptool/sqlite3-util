/* vim: set ai noet ts=4 sw=4 tw=115: */
//
// Copyright (c) 2014 Nikolay Zapolnov (zapolnov@gmail.com).
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
#import "sqlite_data_source.h"
#import <cassert>

@implementation NZSQLiteDataSource

@synthesize database;
@synthesize section;
@synthesize sqlWhere;
@synthesize sqlOrderBy;

-(id)initWithTableView:(UITableView *)tableView dataClass:(Class)dataClass cellClass:(Class)cellClass
{
	NZSQLiteDatabase * db = [NZSQLiteDatabase sharedDatabase];
	return [self initWithDatabase:db tableView:tableView dataClass:dataClass cellClass:cellClass];
}

-(id)initWithDatabase:(NZSQLiteDatabase *)db tableView:(UITableView *)tableView dataClass:(Class)dataClass
	cellClass:(Class)cellClass
{
	self = [super init];
	if (self)
	{
		section = 0;
		database = [database retain];
		className = dataClass;

		assert([cellClass conformsToProtocol:@protocol(NZSQLiteCell)]);
		[tableView registerClass:cellClass forCellReuseIdentifier:NSStringFromClass(dataClass)];
	}
	return self;
}

-(void)dealloc
{
	[database release];
	database = nil;

	[sqlWhere release];
	sqlWhere = nil;

	[sqlOrderBy release];
	sqlOrderBy = nil;

	[super dealloc];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
	if (sectionIndex == section)
		return NSInteger([database objectCountForClass:className]);
	return 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section != section)
		return 0;

	UITableViewCell<NZSQLiteCell> * cell =
		[tableView dequeueReusableCellWithIdentifier:NSStringFromClass(className)];

	assert(cell != nil);
	assert([cell isMemberOfClass:[UITableViewCell class]]);
	assert([cell conformsToProtocol:@protocol(NZSQLiteCell)]);

	size_t index = size_t(indexPath.row);
	id object = nil;

	if (sqlWhere && sqlOrderBy)
		object = [database selectObjectOfClass:className index:index where:sqlWhere orderBy:sqlOrderBy];
	else if (sqlWhere)
		object = [database selectObjectOfClass:className index:index where:sqlWhere];
	else if (sqlOrderBy)
		object = [database selectObjectOfClass:className index:index where:sqlOrderBy];
	else
		object = [database selectObjectOfClass:className index:index];

	[cell initFromObject:object];

	return cell;
}

@end
