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
#ifndef __3e320ef32f5d788aaaff81904c4932cf__
#define __3e320ef32f5d788aaaff81904c4932cf__

#include "sqlite_cursor.h"
#include <yip-imports/sqlite3.h>
#include <string>
#include <functional>

class SQLiteDatabase;

class SQLiteStatement
{
public:
	SQLiteStatement(SQLiteDatabase & database, const char * sql);
	SQLiteStatement(SQLiteDatabase & database, const std::string & sql);
	~SQLiteStatement() noexcept;

	inline sqlite3_stmt * handle() const noexcept { return m_Handle; }

	void bindNull(int index) const;
	void bindInt(int index, int value) const;
	void bindInt64(int index, sqlite3_int64 value) const;
	void bindSizeT(int index, size_t value) const;
	void bindTimeT(int index, time_t value) const;
	void bindFloat(int index, float value) const;
	void bindDouble(int index, double value) const;
	void bindText(int index, const char * text, void (* destructor)(void *) = SQLITE_TRANSIENT) const;
	void bindText(int index, const char * text, size_t length, void (* destructor)(void *) = SQLITE_TRANSIENT) const;
	void bindString(int index, const std::string & string) const;
	void bindBlob(int index, const void * data, size_t size, void (* destructor)(void *) = SQLITE_TRANSIENT) const;

	int parameterIndex(const char * name) const;
	int parameterIndex(const std::string & name) const;

	int parameterIndex(const char * name, const std::nothrow_t &) const noexcept;
	int parameterIndex(const std::string & name, const std::nothrow_t &) const noexcept;

	void exec() const;
	void exec(const std::function<void(const SQLiteCursor & cursor)> & onRow) const;
	void exec(const std::function<void(const SQLiteCursor & cursor)> & onRow, size_t limit) const;

private:
	sqlite3_stmt * m_Handle;

	void checkError(int err, int index) const;

	SQLiteStatement(const SQLiteStatement &) = delete;
	SQLiteStatement & operator=(const SQLiteStatement &) = delete;
};

#endif
