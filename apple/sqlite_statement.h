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
#import <Foundation/Foundation.h>
#import "sqlite_cursor.h"
#import "../sqlite_statement.h"
#import <memory>

@class NZSQLiteDatabase;

@interface NZSQLiteStatement : NSObject
{
	std::shared_ptr<SQLiteStatement> statement;
}
-(id)initWithSQL:(NSString *)sql;
-(id)initWithDatabase:(NZSQLiteDatabase *)database sql:(NSString *)sql;
-(void)dealloc;
+(NZSQLiteStatement *)statementWithSQL:(NSString *)sql;
+(NZSQLiteStatement *)statementWithDatabase:(NZSQLiteDatabase *)database sql:(NSString *)sql;
-(int)parameterIndex:(NSString *)name;
-(void)bindNullAtIndex:(int)index;
-(void)bindInt:(int)value atIndex:(int)index;
-(void)bindInt64:(sqlite3_int64)value atIndex:(int)index;
-(void)bindSizeT:(size_t)value atIndex:(int)index;
-(void)bindTimeT:(time_t)value atIndex:(int)index;
-(void)bindFloat:(float)value atIndex:(int)index;
-(void)bindDouble:(double)value atIndex:(int)index;
-(void)bindText:(const char *)text atIndex:(int)index;
-(void)bindText:(const char *)text length:(size_t)length atIndex:(int)index;
-(void)bindText:(const char *)text atIndex:(int)index withDestructor:(void(*)(void *))destructor;
-(void)bindText:(const char *)text length:(size_t)length atIndex:(int)index withDestructor:(void(*)(void *))d;
-(void)bindString:(NSString *)value atIndex:(int)index;
-(void)bindBlob:(const void *)data size:(size_t)size atIndex:(int)index;
-(void)bindBlob:(const void *)data size:(size_t)size atIndex:(int)index withDestructor:(void(*)(void *))destructor;
-(BOOL)exec;
-(BOOL)execWithBlock:(void(^)(NZSQLiteCursor *))block;
-(BOOL)execWithBlock:(void(^)(NZSQLiteCursor *))block limit:(size_t)limit;
@end
