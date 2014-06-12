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
#import "../apple/sqlite_database.h"

@interface MyObject : NSObject
@property (nonatomic, copy) NSString * string;
@property (nonatomic, copy) NSNumber * number;
@property (nonatomic, assign) bool test0;
@property (nonatomic, assign) BOOL test1;
@property (nonatomic, assign) char test2;
@property (nonatomic, assign) signed char test3;
@property (nonatomic, assign) unsigned char test4;
@property (nonatomic, assign) short test5;
@property (nonatomic, assign) unsigned short test6;
@property (nonatomic, assign) int test7;
@property (nonatomic, assign) unsigned int test8;
@property (nonatomic, assign) long test9;
@property (nonatomic, assign) unsigned long test10;
@property (nonatomic, assign) long long test11;
@property (nonatomic, assign) unsigned long long test12;
@property (nonatomic, assign) float test13;
@property (nonatomic, assign) double test14;
-(void)dealloc;
@end

@implementation MyObject
@synthesize string;
@synthesize number;
-(void)dealloc
{
	[string release];
	[number release];
	[super dealloc];
}
@end

int main()
{
	@autoreleasepool
	{
		Class className = [MyObject class];

		// Drop table
		[NZSQLiteDatabase exec:[NSString stringWithFormat:@"DROP TABLE %@", NSStringFromClass(className)]];

		// Create table
		[NZSQLiteDatabase createTableForClass:className withKeys:@[ @"string", @"number" ] uniqueKeys:@[ @"string" ]];

		// Insert object #1 into the database
		MyObject * object = [[[MyObject alloc] init] autorelease];
		object.string = @"Hello, world!";
		object.number = @42;
		object.test0 = false;
		object.test13 = 9876.5432f;
		NZSQLiteStatement * insertStmt = [NZSQLiteStatement statementWithSQL:
			@"INSERT INTO MyObject (string, number, test0, test13) VALUES (:string, :number, :test0, :test13)"];
		[insertStmt bindFromObject:object];
		[insertStmt exec];

		// Insert object #2 into the database
		object = [[[MyObject alloc] init] autorelease];
		object.string = @"Second object";
		object.number = @1234;
		object.test0 = true;
		object.test13 = 0.987f;
		[insertStmt bindFromObject:object];
		[insertStmt exec];

		// Insert object #3 into the database
		object = [[[MyObject alloc] init] autorelease];
		object.string = @"Third object";
		object.number = @4321;
		object.test0 = false;
		object.test13 = 7.156f;
		sqlite3_int64 row = [NZSQLiteDatabase insertObject:object];
		NSLog(@"Row = %lld", (long long)row);

		// Fetch number of objects from the database
		sqlite3_int64 numObjects = [NZSQLiteDatabase objectCountForClass:className];
		NSLog(@"Num objects = %lld", (long long)numObjects);

		// Fetch single object from the database
		object = [NZSQLiteDatabase selectObjectOfClass:className index:0];
		NSLog(@"[[%@]] [[%@]]", object.string, object.number);

		// Fetch single object from the database
		object = [NZSQLiteDatabase selectObjectOfClass:className sql:@"SELECT * FROM MyObject"];
		NSLog(@"[[%@]] [[%@]]", object.string, object.number);

		// Fetch all objects from the database
		NSArray * objects = [NZSQLiteDatabase selectObjectsOfClass:className orderBy:@"string"];
		for (MyObject * obj in objects)
			NSLog(@"<<%@>> <<%@>> %@ %f", obj.string, obj.number, (obj.test0 ? @"true" : @"false"), obj.test13);
	}

	return 0;
}
