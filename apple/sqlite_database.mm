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
	try
	{
		if (!database)
			return NO;
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

@end
