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
#import "sqlite_statement.h"
#import "sqlite_cursor.h"
#import "../sqlite_database.h"
#import <memory>

@interface NZSQLiteDatabase : NSObject
{
	std::shared_ptr<SQLiteDatabase> database;
}
@property (nonatomic, readonly, assign) const std::shared_ptr<SQLiteDatabase> & cxxObject;
-(id)initWithFile:(NSString *)file;
-(void)dealloc;
+(NZSQLiteDatabase *)sharedDatabase;
-(const std::shared_ptr<SQLiteDatabase> &)cxxObject;
-(BOOL)transaction:(void(^)())protectedBlock;
+(BOOL)transaction:(void(^)())protectedBlock;
-(BOOL)exec:(NSString *)sql;
+(BOOL)exec:(NSString *)sql;
-(BOOL)exec:(NSString *)sql withBlock:(void(^)(NZSQLiteCursor *))block;
+(BOOL)exec:(NSString *)sql withBlock:(void(^)(NZSQLiteCursor *))block;
-(BOOL)exec:(NSString *)sql withBlock:(void(^)(NZSQLiteCursor *))block limit:(size_t)limit;
+(BOOL)exec:(NSString *)sql withBlock:(void(^)(NZSQLiteCursor *))block limit:(size_t)limit;
-(BOOL)createTableForClass:(Class)className;
+(BOOL)createTableForClass:(Class)className;
-(BOOL)createTableForClass:(Class)className withKeys:(NSArray *)keyList;
+(BOOL)createTableForClass:(Class)className withKeys:(NSArray *)keyList;
-(BOOL)createTableForClass:(Class)className withUniqueKeys:(NSArray *)keyList;
+(BOOL)createTableForClass:(Class)className withUniqueKeys:(NSArray *)keyList;
-(BOOL)createTableForClass:(Class)className withKeys:(NSArray *)keyList uniqueKeys:(NSArray *)uniqueKeyList;
+(BOOL)createTableForClass:(Class)className withKeys:(NSArray *)keyList uniqueKeys:(NSArray *)uniqueKeyList;
-(sqlite3_int64)insertObject:(id)object;
+(sqlite3_int64)insertObject:(id)object;
-(sqlite3_int64)replaceObject:(id)object;
+(sqlite3_int64)replaceObject:(id)object;
-(sqlite3_int64)objectCountForClass:(Class)className;
+(sqlite3_int64)objectCountForClass:(Class)className;
-(id)selectObjectOfClass:(Class)className index:(size_t)index;
+(id)selectObjectOfClass:(Class)className index:(size_t)index;
-(id)selectObjectOfClass:(Class)className index:(size_t)index where:(NSString *)where;
+(id)selectObjectOfClass:(Class)className index:(size_t)index where:(NSString *)where;
-(id)selectObjectOfClass:(Class)className index:(size_t)index orderBy:(NSString *)orderBy;
+(id)selectObjectOfClass:(Class)className index:(size_t)index orderBy:(NSString *)orderBy;
-(id)selectObjectOfClass:(Class)className index:(size_t)index where:(NSString *)where orderBy:(NSString *)orderBy;
+(id)selectObjectOfClass:(Class)className index:(size_t)index where:(NSString *)where orderBy:(NSString *)orderBy;
-(id)selectObjectOfClass:(Class)className where:(NSString *)where;
+(id)selectObjectOfClass:(Class)className where:(NSString *)where;
-(id)selectObjectOfClass:(Class)className where:(NSString *)where orderBy:(NSString *)orderBy;
+(id)selectObjectOfClass:(Class)className where:(NSString *)where orderBy:(NSString *)orderBy;
-(id)selectObjectOfClass:(Class)className sql:(NSString *)sql;
+(id)selectObjectOfClass:(Class)className sql:(NSString *)sql;
-(NSMutableArray *)selectObjectsOfClass:(Class)className;
+(NSMutableArray *)selectObjectsOfClass:(Class)className;
-(NSMutableArray *)selectObjectsOfClass:(Class)className orderBy:(NSString *)orderBy;
+(NSMutableArray *)selectObjectsOfClass:(Class)className orderBy:(NSString *)orderBy;
-(NSMutableArray *)selectObjectsOfClass:(Class)className where:(NSString *)where;
+(NSMutableArray *)selectObjectsOfClass:(Class)className where:(NSString *)where;
-(NSMutableArray *)selectObjectsOfClass:(Class)className where:(NSString *)where orderBy:(NSString *)orderBy;
+(NSMutableArray *)selectObjectsOfClass:(Class)className where:(NSString *)where orderBy:(NSString *)orderBy;
-(NSMutableArray *)selectObjectsOfClass:(Class)className sql:(NSString *)sql;
+(NSMutableArray *)selectObjectsOfClass:(Class)className sql:(NSString *)sql;
@end
