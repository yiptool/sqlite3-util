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
#import "sqlite_statement.h"
#import "sqlite_database.h"
#import <yip-imports/cxx-util/macros.h>
#import <cstdlib>
#import <exception>

@implementation NZSQLiteStatement

-(id)initWithSQL:(NSString *)sql
{
	self = [super init];
	[self _initWithDatabase:[NZSQLiteDatabase sharedDatabase] sql:sql];
	return self;
}

-(id)initWithDatabase:(NZSQLiteDatabase *)database sql:(NSString *)sql
{
	self = [super init];
	[self _initWithDatabase:database sql:sql];
	return self;
}

-(void)_initWithDatabase:(NZSQLiteDatabase *)database sql:(NSString *)sql
{
	try
	{
		if (LIKELY(database.cxxObject.get()))
			statement.reset(new SQLiteStatement(*database.cxxObject, [sql UTF8String]));
	}
	catch (const std::exception & e)
	{
		NSLog(@"%s", e.what());
	}
}

-(void)dealloc
{
	statement.reset();
	[super dealloc];
}

+(NZSQLiteStatement *)statementWithSQL:(NSString *)sql
{
	return [[[NZSQLiteStatement alloc] initWithSQL:sql] autorelease];
}

+(NZSQLiteStatement *)statementWithDatabase:(NZSQLiteDatabase *)database sql:(NSString *)sql
{
	return [[[NZSQLiteStatement alloc] initWithDatabase:database sql:sql] autorelease];
}

-(void)bindNullAtIndex:(int)index
{
	try
	{
		if (statement.get())
			statement->bindNull(index);
	}
	catch (const std::exception & e)
	{
		NSLog(@"%s", e.what());
	}
}

-(void)bindInt:(int)value atIndex:(int)index
{
	try
	{
		if (statement.get())
			statement->bindInt(index, value);
	}
	catch (const std::exception & e)
	{
		NSLog(@"%s", e.what());
	}
}

-(void)bindInt64:(sqlite3_int64)value atIndex:(int)index
{
	try
	{
		if (statement.get())
			statement->bindInt64(index, value);
	}
	catch (const std::exception & e)
	{
		NSLog(@"%s", e.what());
	}
}

-(void)bindSizeT:(size_t)value atIndex:(int)index
{
	try
	{
		if (statement.get())
			statement->bindSizeT(index, value);
	}
	catch (const std::exception & e)
	{
		NSLog(@"%s", e.what());
	}
}

-(void)bindTimeT:(time_t)value atIndex:(int)index;
{
	try
	{
		if (statement.get())
			statement->bindTimeT(index, value);
	}
	catch (const std::exception & e)
	{
		NSLog(@"%s", e.what());
	}
}

-(void)bindFloat:(float)value atIndex:(int)index
{
	try
	{
		if (statement.get())
			statement->bindFloat(index, value);
	}
	catch (const std::exception & e)
	{
		NSLog(@"%s", e.what());
	}
}

-(void)bindDouble:(double)value atIndex:(int)index
{
	try
	{
		if (statement.get())
			statement->bindDouble(index, value);
	}
	catch (const std::exception & e)
	{
		NSLog(@"%s", e.what());
	}
}

-(void)bindText:(const char *)text atIndex:(int)index
{
	try
	{
		if (statement.get())
			statement->bindText(index, text);
	}
	catch (const std::exception & e)
	{
		NSLog(@"%s", e.what());
	}
}

-(void)bindText:(const char *)text length:(size_t)length atIndex:(int)index
{
	try
	{
		if (statement.get())
			statement->bindText(index, text, length);
	}
	catch (const std::exception & e)
	{
		NSLog(@"%s", e.what());
	}
}

-(void)bindText:(const char *)text atIndex:(int)index withDestructor:(void(*)(void *))destructor
{
	try
	{
		if (statement.get())
			statement->bindText(index, text, destructor);
	}
	catch (const std::exception & e)
	{
		NSLog(@"%s", e.what());
	}
}

-(void)bindText:(const char *)text length:(size_t)length atIndex:(int)index withDestructor:(void(*)(void *))d
{
	try
	{
		if (statement.get())
			statement->bindText(index, text, length, d);
	}
	catch (const std::exception & e)
	{
		NSLog(@"%s", e.what());
	}
}

-(void)bindString:(NSString *)value atIndex:(int)index
{
	[self bindText:[value UTF8String] atIndex:index];
}

-(void)bindBlob:(const void *)data size:(size_t)size atIndex:(int)index
{
	try
	{
		if (statement.get())
			statement->bindBlob(index, data, size);
	}
	catch (const std::exception & e)
	{
		NSLog(@"%s", e.what());
	}
}

-(void)bindBlob:(const void *)data size:(size_t)size atIndex:(int)index withDestructor:(void(*)(void *))destructor
{
	try
	{
		if (statement.get())
			statement->bindBlob(index, data, size, destructor);
	}
	catch (const std::exception & e)
	{
		NSLog(@"%s", e.what());
	}
}

-(BOOL)exec
{
	try
	{
		if (!statement.get())
			return NO;
		statement->exec();
		return YES;
	}
	catch (const std::exception & e)
	{
		NSLog(@"%s", e.what());
		return NO;
	}
}

-(BOOL)execWithBlock:(void(^)(NZSQLiteCursor *))block
{
	try
	{
		if (!statement.get())
			return NO;

		NZSQLiteCursor * cursorWrapper = [NZSQLiteCursor cursor];
		statement->exec([&cursorWrapper, &block](const SQLiteCursor & cursor) {
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

@end
