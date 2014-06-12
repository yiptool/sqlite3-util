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
#import "sqlite_cursor.h"

@implementation NZSQLiteCursor

-(id)copy
{
	NZSQLiteCursor * copy = [super copy];
	copy.ref = nil;
	return copy;
}

+(NZSQLiteCursor *)cursor
{
	return [[[NZSQLiteCursor alloc] init] autorelease];
}

-(void)setRef:(const SQLiteCursor *)r
{
	ref = r;
}

-(BOOL)isNullAtIndex:(int)index
{
	return (!ref ? YES : ref->isNull(index));
}

-(int)intValueAtIndex:(int)index
{
	return (!ref ? 0 : ref->toInt(index));
}

-(sqlite3_int64)int64ValueAtIndex:(int)index
{
	return (!ref ? sqlite3_int64(0) : ref->toInt64(index));
}

-(size_t)sizeValueAtIndex:(int)index
{
	return (!ref ? size_t(0) : ref->toSizeT(index));
}

-(time_t)timeValueAtIndex:(int)index
{
	return (!ref ? time_t(0) : ref->toTimeT(index));
}

-(float)floatValueAtIndex:(int)index
{
	return (!ref ? 0.0f : ref->toFloat(index));
}

-(double)doubleValueAtIndex:(int)index
{
	return (!ref ? 0.0 : ref->toDouble(index));
}

-(const char *)textValueAtIndex:(int)index
{
	if (!ref)
		return "";

	const char * ptr = ref->toText(index);
	if (!ptr)
		return "";

	return ptr;
}

-(NSString *)stringValueAtIndex:(int)index
{
	return [NSString stringWithUTF8String:[self textValueAtIndex:index]];
}

@end
