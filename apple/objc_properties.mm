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
#import "objc_properties.h"
#import <cstdlib>
#import <objc/runtime.h>

static NSString * getPropertyType(objc_property_t property)
{
	const char * attributes = property_getAttributes(property);

	char buffer[strlen(attributes) + 1];
	strcpy(buffer, attributes);

	char * state = buffer, * attribute;
	while ((attribute = strsep(&state, ",")) != NULL)
	{
		if (attribute[0] != 'T')
			continue;

		size_t len = strlen(attribute);
		if (attribute[1] != '@')
			return [[NSString alloc] initWithBytes:attribute + 1 length:len - 1 encoding:NSASCIIStringEncoding];
		else if (len >= 4)
			return [[NSString alloc] initWithBytes:attribute + 3 length:len - 4 encoding:NSASCIIStringEncoding];
		else if (len == 2)
			return @"id";
	}

	return nil;
}

NSDictionary * propertiesForClass(Class className)
{
	if (!className)
		return nil;

	NSMutableDictionary * properties = [[[NSMutableDictionary alloc] init] autorelease];

	unsigned numProperties = 0;
	objc_property_t * propertyList = class_copyPropertyList(className, &numProperties);
	for (size_t i = 0; i < numProperties; i++)
	{
		objc_property_t property = propertyList[i];

		const char * name = property_getName(property);
		if (!name)
			continue;

		NSString * propertyName = [NSString stringWithUTF8String:name];
		NSString * propertyType = getPropertyType(property);

		if (propertyType != nil)
			[properties setObject:propertyType forKey:propertyName];
	}
	free(propertyList);

	return properties;
}
