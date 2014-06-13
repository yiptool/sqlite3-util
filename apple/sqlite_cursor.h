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
#import "../sqlite_cursor.h"

@interface NZSQLiteCursor : NSObject
{
	const SQLiteCursor * ref;
	NSDictionary * columns;
}
+(NZSQLiteCursor *)cursor;
-(void)dealloc;
-(void)setRef:(const SQLiteCursor *)r;
-(int)numColumns;
-(NSString *)columnNameAtIndex:(int)index;
-(NSDictionary *)columns;
-(BOOL)isNullAtIndex:(int)index;
-(int)intValueAtIndex:(int)index;
-(sqlite3_int64)int64ValueAtIndex:(int)index;
-(size_t)sizeValueAtIndex:(int)index;
-(time_t)timeValueAtIndex:(int)index;
-(float)floatValueAtIndex:(int)index;
-(double)doubleValueAtIndex:(int)index;
-(NSNumber *)numericValueAtIndex:(int)index;
-(const char *)textValueAtIndex:(int)index;
-(NSString *)stringValueAtIndex:(int)index;
-(NSDate *)dateValueAtIndex:(int)index;
-(id)newObjectWithClass:(Class)className;
-(void)fillObject:(id)object;
@end
