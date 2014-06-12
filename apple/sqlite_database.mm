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
#import "sqlite_database.h"
#import "sqlite_statement.h"
#import "objc_properties.h"
#import <yip-imports/cxx-util/macros.h>
#import <cstdlib>
#import <exception>

static NZSQLiteDatabase * g_SharedDatabase;

static void cleanup()
{
	[g_SharedDatabase release];
	g_SharedDatabase = nil;
}

@implementation NZSQLiteDatabase

-(id)initWithFile:(NSString *)file
{
	self = [super init];
	if (self)
	{
		try
		{
			database.reset(new SQLiteDatabase([file UTF8String]));
		}
		catch (const std::exception & e)
		{
			NSLog(@"%s", e.what());
		}
	}
	return self;
}

-(void)dealloc
{
	database.reset();
	[super dealloc];
}

+(NZSQLiteDatabase *)sharedDatabase
{
	if (UNLIKELY(!g_SharedDatabase))
	{
		NSError * error = nil;
		BOOL isDir = NO;

		NSArray * paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
		NSString * cachePath = [paths objectAtIndex:0];
		if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:&isDir] && isDir == NO)
		{
			if (UNLIKELY(![[NSFileManager defaultManager] createDirectoryAtPath:cachePath
					withIntermediateDirectories:NO attributes:nil error:&error] || error))
				NSLog(@"Unable to create directory \"%@\": %@", cachePath, error);
		}

		NSString * databaseFile = [cachePath stringByAppendingPathComponent:@"sqlite.db"];
		g_SharedDatabase = [[NZSQLiteDatabase alloc] initWithFile:databaseFile];

		atexit(cleanup);
	}

	return g_SharedDatabase;
}

-(const std::shared_ptr<SQLiteDatabase> &)cxxObject
{
	return database;
}

-(BOOL)transaction:(void(^)())protectedBlock
{
	if (!database)
		return NO;

	try
	{
		database->transaction([&protectedBlock](){ if (LIKELY(protectedBlock)) protectedBlock(); });
		return YES;
	}
	catch (const std::exception & e)
	{
		NSLog(@"Database transaction failed: %s", e.what());
		return NO;
	}
}

+(BOOL)transaction:(void(^)())protectedBlock
{
	return [[NZSQLiteDatabase sharedDatabase] transaction:protectedBlock];
}

-(BOOL)exec:(NSString *)sql
{
	if (!database)
		return NO;

	try
	{
		database->exec([sql UTF8String]);
		return YES;
	}
	catch (const std::exception & e)
	{
		NSLog(@"%s", e.what());
		return NO;
	}
}

+(BOOL)exec:(NSString *)sql
{
	return [[NZSQLiteDatabase sharedDatabase] exec:sql];
}

-(BOOL)exec:(NSString *)sql withBlock:(void(^)(NZSQLiteCursor *))block
{
	if (!database)
		return NO;

	try
	{
		NZSQLiteCursor * cursorWrapper = [NZSQLiteCursor cursor];
		database->exec([sql UTF8String], [&cursorWrapper, &block](const SQLiteCursor & cursor) {
			cursorWrapper.ref = &cursor;
			if (block)
				block(cursorWrapper);
			cursorWrapper.ref = nil;
		});
		return YES;
	}
	catch (const std::exception & e)
	{
		NSLog(@"%s", e.what());
		return NO;
	}
}

+(BOOL)exec:(NSString *)sql withBlock:(void(^)(NZSQLiteCursor *))block
{
	return [[NZSQLiteDatabase sharedDatabase] exec:sql withBlock:block];
}

-(BOOL)exec:(NSString *)sql withBlock:(void(^)(NZSQLiteCursor *))block limit:(size_t)limit
{
	if (!database)
		return NO;

	try
	{
		NZSQLiteCursor * cursorWrapper = [NZSQLiteCursor cursor];
		database->exec([sql UTF8String], [&cursorWrapper, &block](const SQLiteCursor & cursor) {
			cursorWrapper.ref = &cursor;
			if (block)
				block(cursorWrapper);
			cursorWrapper.ref = nil;
		}, limit);
		return YES;
	}
	catch (const std::exception & e)
	{
		NSLog(@"%s", e.what());
		return NO;
	}
}

+(BOOL)exec:(NSString *)sql withBlock:(void(^)(NZSQLiteCursor *))block limit:(size_t)limit
{
	return [[NZSQLiteDatabase sharedDatabase] exec:sql withBlock:block limit:limit];
}

-(BOOL)createTableForClass:(Class)className
{
	return [self createTableForClass:className withKeys:nil uniqueKeys:nil];
}

+(BOOL)createTableForClass:(Class)className
{
	return [[NZSQLiteDatabase sharedDatabase] createTableForClass:className withKeys:nil uniqueKeys:nil];
}

-(BOOL)createTableForClass:(Class)className withKeys:(NSArray *)keyList
{
	return [self createTableForClass:className withKeys:keyList uniqueKeys:nil];
}

+(BOOL)createTableForClass:(Class)className withKeys:(NSArray *)keyList
{
	return [[NZSQLiteDatabase sharedDatabase] createTableForClass:className withKeys:keyList uniqueKeys:nil];
}

-(BOOL)createTableForClass:(Class)className withUniqueKeys:(NSArray *)keyList
{
	return [self createTableForClass:className withKeys:nil uniqueKeys:keyList];
}

+(BOOL)createTableForClass:(Class)className withUniqueKeys:(NSArray *)keyList
{
	return [[NZSQLiteDatabase sharedDatabase] createTableForClass:className withKeys:nil uniqueKeys:keyList];
}

-(BOOL)createTableForClass:(Class)className withKeys:(NSArray *)keyList uniqueKeys:(NSArray *)uniqueKeyList
{
	if (!database)
		return NO;

	NSString * tableName = NSStringFromClass(className);
	NSDictionary * properties = propertiesForClass(className);

	NSSet * keys = [NSSet setWithArray:keyList];
	NSSet * uniqueKeys = [NSSet setWithArray:uniqueKeyList];

	SQLiteDatabase::Locker locker(*database);

	__block BOOL hasTable = NO;
	NZSQLiteStatement * stmt = [NZSQLiteStatement statementWithDatabase:self
		sql:@"SELECT name FROM sqlite_master WHERE type='table' AND name=?"];
	[stmt bindString:tableName atIndex:1];
	[stmt execWithBlock:^(NZSQLiteCursor * cursor){ hasTable = YES; } limit:1];

	if (!hasTable)
	{
		NSLog(@"DB: Creating table %@", tableName);

		NSString * sql = [NSString stringWithFormat:
			@"CREATE TABLE %@ (_rowid_ INTEGER PRIMARY KEY AUTOINCREMENT", tableName];
		for (NSString * propertyName in properties)
			sql = [sql stringByAppendingFormat:@", %@", propertyName];
		sql = [sql stringByAppendingString:@")"];

		NZSQLiteStatement * stmt = [NZSQLiteStatement statementWithDatabase:self sql:sql];
		[stmt exec];
	}
	else
	{
		NSLog(@"DB: Validating table %@", tableName);
		for (NSString * propName in properties)
		{
			int err = sqlite3_table_column_metadata(database->handle(), nullptr, [tableName UTF8String],
				[propName UTF8String], nullptr, nullptr, nullptr, nullptr, nullptr);
			if (UNLIKELY(err != SQLITE_OK))
			{
				NSLog(@"DB: Adding column %@ to table %@", propName, tableName);
				NSString * sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@", tableName, propName];
				NZSQLiteStatement * stmt = [NZSQLiteStatement statementWithDatabase:self sql:sql];
				[stmt exec];
			}
		}
	}

	for (NSString * keyName in keys)
	{
		if (![properties objectForKey:keyName])
		{
			NSLog(@"DB: Attempted to create key on non-existent property %@ of class %@.",
				keyName, tableName);
			continue;
		}

		NSString * unique = @"";
		if ([uniqueKeys containsObject:keyName])
			unique = @"UNIQUE ";

		NSString * sql = [NSString stringWithFormat:@"CREATE %@INDEX IF NOT EXISTS %@ ON %@ (%@)",
			unique, keyName, tableName, keyName];
		NZSQLiteStatement * stmt = [NZSQLiteStatement statementWithDatabase:self sql:sql];
		[stmt exec];
	}

	for (NSString * keyName in uniqueKeys)
	{
		if ([keys containsObject:keyName])
			continue;

		if (![properties objectForKey:keyName])
		{
			NSLog(@"DB: Attempted to create key on non-existent property %@ of class %@.",
				keyName, tableName);
			continue;
		}

		NSString * sql = [NSString stringWithFormat:@"CREATE UNIQUE INDEX IF NOT EXISTS %@ ON %@ (%@)",
			keyName, tableName, keyName];
		NZSQLiteStatement * stmt = [NZSQLiteStatement statementWithDatabase:self sql:sql];
		[stmt exec];
	}

	return YES;
}

+(BOOL)createTableForClass:(Class)className withKeys:(NSArray *)keyList uniqueKeys:(NSArray *)uniqueKeyList
{
	return [[NZSQLiteDatabase sharedDatabase]
		createTableForClass:className withKeys:keyList uniqueKeys:uniqueKeyList];
}

-(sqlite3_int64)insertObject:(id)object
{
	if (!database || !object)
		return -1;

	Class className = [object class];
	NSString * tableName = NSStringFromClass(className);
	NSDictionary * properties = propertiesForClass(className);

	NSArray * allProperties = properties.allKeys;
	NSString * fields = [allProperties componentsJoinedByString:@", "];

	NSMutableArray * allValues = [NSMutableArray arrayWithCapacity:allProperties.count];
	for (NSString * field : allProperties)
		[allValues addObject:[@":" stringByAppendingString:field]];
	NSString * values = [allValues componentsJoinedByString:@", "];

	SQLiteDatabase::Locker locker(*database);

	NSString * sql = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", tableName, fields, values];
	NZSQLiteStatement * statement = [NZSQLiteStatement statementWithDatabase:self sql:sql];
	[statement bindFromObject:object];
	if (![statement exec])
		return -1;

	return sqlite3_last_insert_rowid(database->handle());
}

+(sqlite3_int64)insertObject:(id)object
{
	return [[NZSQLiteDatabase sharedDatabase] insertObject:object];
}

-(sqlite3_int64)replaceObject:(id)object
{
	if (!database || !object)
		return -1;

	Class className = [object class];
	NSString * tableName = NSStringFromClass(className);
	NSDictionary * properties = propertiesForClass(className);

	NSArray * allProperties = properties.allKeys;
	NSString * fields = [allProperties componentsJoinedByString:@", "];

	NSMutableArray * allValues = [NSMutableArray arrayWithCapacity:allProperties.count];
	for (NSString * field : allProperties)
		[allValues addObject:[@":" stringByAppendingString:field]];
	NSString * values = [allValues componentsJoinedByString:@", "];

	SQLiteDatabase::Locker locker(*database);

	NSString * sql = [NSString stringWithFormat:@"REPLACE INTO %@ (%@) VALUES (%@)", tableName, fields, values];
	NZSQLiteStatement * statement = [NZSQLiteStatement statementWithDatabase:self sql:sql];
	[statement bindFromObject:object];
	if (![statement exec])
		return -1;

	return sqlite3_last_insert_rowid(database->handle());
}

+(sqlite3_int64)replaceObject:(id)object
{
	return [[NZSQLiteDatabase sharedDatabase] replaceObject:object];
}

-(sqlite3_int64)objectCountForClass:(Class)className
{
	if (!database)
		return 0;

	NSString * sql = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@", NSStringFromClass(className)];

	__block sqlite3_int64 count = 0;
	[self exec:sql withBlock:^(NZSQLiteCursor * cursor){ count = [cursor int64ValueAtIndex:0]; } limit:1];

	return count;
}

+(sqlite3_int64)objectCountForClass:(Class)className
{
	return [[NZSQLiteDatabase sharedDatabase] objectCountForClass:className];
}

-(id)selectObjectOfClass:(Class)className index:(size_t)index
{
	NSString * sql = [NSString stringWithFormat:@"SELECT * FROM %@ LIMIT 1 OFFSET %lu",
		NSStringFromClass(className), (unsigned long)index];
	return [self selectObjectOfClass:className sql:sql];
}

+(id)selectObjectOfClass:(Class)className index:(size_t)index
{
	return [[NZSQLiteDatabase sharedDatabase] selectObjectOfClass:className index:index];
}

-(id)selectObjectOfClass:(Class)className index:(size_t)index orderBy:(NSString *)orderBy
{
	NSString * sql = [NSString stringWithFormat:@"SELECT * FROM %@ ORDER BY %@ LIMIT 1 OFFSET %lu",
		NSStringFromClass(className), orderBy, (unsigned long)index];
	return [self selectObjectOfClass:className sql:sql];
}

+(id)selectObjectOfClass:(Class)className index:(size_t)index orderBy:(NSString *)orderBy
{
	return [[NZSQLiteDatabase sharedDatabase] selectObjectOfClass:className index:index orderBy:orderBy];
}

-(id)selectObjectOfClass:(Class)className where:(NSString *)where
{
	NSString * sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ LIMIT 1",
		NSStringFromClass(className), where];
	return [self selectObjectOfClass:className sql:sql];
}

+(id)selectObjectOfClass:(Class)className where:(NSString *)where
{
	return [[NZSQLiteDatabase sharedDatabase] selectObjectOfClass:className where:where];
}

-(id)selectObjectOfClass:(Class)className where:(NSString *)where orderBy:(NSString *)orderBy
{
	NSString * sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ ORDER BY %@ LIMIT 1",
		NSStringFromClass(className), where, orderBy];
	return [self selectObjectOfClass:className sql:sql];
}

+(id)selectObjectOfClass:(Class)className where:(NSString *)where orderBy:(NSString *)orderBy
{
	return [[NZSQLiteDatabase sharedDatabase] selectObjectOfClass:className where:where orderBy:orderBy];
}

-(id)selectObjectOfClass:(Class)className sql:(NSString *)sql
{
	NZSQLiteStatement * statement = [NZSQLiteStatement statementWithDatabase:self sql:sql];

	__block id result = nil;
	[statement execWithBlock:^(NZSQLiteCursor * cursor) {
		result = [[cursor newObjectWithClass:className] autorelease];
	} limit:1];

	return result;
}

+(id)selectObjectOfClass:(Class)className sql:(NSString *)sql
{
	return [[NZSQLiteDatabase sharedDatabase] selectObjectOfClass:className sql:sql];
}

-(NSMutableArray *)selectObjectsOfClass:(Class)className
{
	NSString * sql = [NSString stringWithFormat:@"SELECT * FROM %@", NSStringFromClass(className)];
	return [self selectObjectsOfClass:className sql:sql];
}

+(NSMutableArray *)selectObjectsOfClass:(Class)className
{
	return [[NZSQLiteDatabase sharedDatabase] selectObjectsOfClass:className];
}

-(NSMutableArray *)selectObjectsOfClass:(Class)className orderBy:(NSString *)orderBy
{
	NSString * sql = [NSString stringWithFormat:@"SELECT * FROM %@ ORDER BY %@",
		NSStringFromClass(className), orderBy];
	return [self selectObjectsOfClass:className sql:sql];
}

+(NSMutableArray *)selectObjectsOfClass:(Class)className orderBy:(NSString *)orderBy
{
	return [[NZSQLiteDatabase sharedDatabase] selectObjectsOfClass:className orderBy:orderBy];
}

-(NSMutableArray *)selectObjectsOfClass:(Class)className where:(NSString *)where
{
	NSString * sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@",
		NSStringFromClass(className), where];
	return [self selectObjectsOfClass:className sql:sql];
}

+(NSMutableArray *)selectObjectsOfClass:(Class)className where:(NSString *)where
{
	return [[NZSQLiteDatabase sharedDatabase] selectObjectsOfClass:className where:where];
}

-(NSMutableArray *)selectObjectsOfClass:(Class)className where:(NSString *)where orderBy:(NSString *)orderBy
{
	NSString * sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ ORDER BY %@",
		NSStringFromClass(className), where, orderBy];
	return [self selectObjectsOfClass:className sql:sql];
}

+(NSMutableArray *)selectObjectsOfClass:(Class)className where:(NSString *)where orderBy:(NSString *)orderBy
{
	return [[NZSQLiteDatabase sharedDatabase] selectObjectsOfClass:className where:where orderBy:orderBy];
}

-(NSMutableArray *)selectObjectsOfClass:(Class)className sql:(NSString *)sql
{
	NZSQLiteStatement * statement = [NZSQLiteStatement statementWithDatabase:self sql:sql];
	NSMutableArray * result = [[[NSMutableArray alloc] init] autorelease];

	[statement execWithBlock:^(NZSQLiteCursor * cursor) {
		id object = [[cursor newObjectWithClass:className] autorelease];
		[result addObject:object];
	}];

	return result;
}

+(NSMutableArray *)selectObjectsOfClass:(Class)className sql:(NSString *)sql
{
	return [[NZSQLiteDatabase sharedDatabase] selectObjectsOfClass:className sql:sql];
}

@end
