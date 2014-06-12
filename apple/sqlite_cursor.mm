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
#import "objc_properties.h"
#import <yip-imports/cxx-util/macros.h>

@implementation NZSQLiteCursor

+(NZSQLiteCursor *)cursor
{
	return [[[NZSQLiteCursor alloc] init] autorelease];
}

-(id)copy
{
	NZSQLiteCursor * copy = [super copy];
	copy.ref = nil;
	return copy;
}

-(void)dealloc
{
	[columns release];
	columns = nil;
	[super dealloc];
}

-(void)setRef:(const SQLiteCursor *)r
{
	ref = r;
}

-(int)numColumns
{
	return (!ref ? 0 : ref->numColumns());
}

-(NSString *)columnNameAtIndex:(int)index
{
	return (!ref ? nil : [NSString stringWithUTF8String:ref->columnName(index)]);
}

-(NSDictionary *)columns
{
	if (!columns)
	{
		int numColumns = self.numColumns;
		NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithCapacity:numColumns];
		for (int i = 0; i < numColumns; i++)
		{
			NSString * columnName = [self columnNameAtIndex:i];
			[dict setObject:[NSNumber numberWithInt:i] forKey:columnName];
		}
		columns = [[NSDictionary dictionaryWithDictionary:dict] retain];
	}
	return columns;
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

-(NSNumber *)numericValueAtIndex:(int)index
{
	if (!ref)
		return nil;

	switch (ref->columnType(index))
	{
	case SQLiteCursor::ColumnNull:
		return nil;

	case SQLiteCursor::ColumnInt:
		return [NSNumber numberWithLongLong:ref->toInt64(index)];

	case SQLiteCursor::ColumnFloat:
	case SQLiteCursor::ColumnText:
	case SQLiteCursor::ColumnBlob:
	default:
		return [NSNumber numberWithDouble:ref->toDouble(index)];
	}
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
	if (ref->isNull(index))
		return nil;
	return [NSString stringWithUTF8String:[self textValueAtIndex:index]];
}

-(id)newObjectWithClass:(Class)className
{
	id object = [[className alloc] init];
	[self fillObject:object];
	return object;
}

-(void)fillObject:(id)object
{
	if (!ref)
		return;

	NSDictionary * properties = propertiesForClass([object class]);
	NSDictionary * columnIndexes = [self columns];

	for (NSString * propertyName in properties)
	{
		NSNumber * columnIndex = [columnIndexes objectForKey:propertyName];
		if (UNLIKELY(!columnIndex))
		{
			NSLog(@"DB: no column for property '%@' of class '%@'.", propertyName, [object className]);
			continue;
		}
		int column = [columnIndex intValue];

		NSString * propertyType = [properties objectForKey:propertyName];
		@try
		{
			if ([propertyType isEqualToString:@"NSString"])
				[object setValue:[self stringValueAtIndex:column] forKey:propertyName];
			else if ([propertyType isEqualToString:@"NSNumber"])
				[object setValue:[self numericValueAtIndex:column] forKey:propertyName];
			else if([propertyType isEqualToString:@"B"] ||				// bool
					[propertyType isEqualToString:@"c"] ||				// char
					[propertyType isEqualToString:@"C"] ||				// unsigned char
					[propertyType isEqualToString:@"s"] ||				// short
					[propertyType isEqualToString:@"S"] ||				// unsigned short
					[propertyType isEqualToString:@"i"] ||				// int
					[propertyType isEqualToString:@"I"] ||				// unsigned int
					[propertyType isEqualToString:@"q"] ||				// long
					[propertyType isEqualToString:@"Q"] ||				// unsigned long
					[propertyType isEqualToString:@"f"] ||				// float
					[propertyType isEqualToString:@"d"])
			{
				NSNumber * number = [self numericValueAtIndex:column];
				if (!number)
					number = @0;
				[object setValue:number forKey:propertyName];
			}
			else
			{
				NSLog(@"DB: property '%@' of class '%@' has unsupported type '%@'.",
					propertyName, [object className], propertyType);
			}
		}
		@catch (id e)
		{
			NSLog(@"DB: unable to set value for property '%@' of class '%@': %@",
				propertyName, [object className], e);
		}
	}
}

@end
