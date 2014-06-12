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
#include "sqlite_statement.h"
#include "sqlite_database.h"
#include <yip-imports/cxx-util/macros.h>
#include <yip-imports/cxx-util/fmt.h>
#include <stdexcept>

SQLiteStatement::SQLiteStatement(SQLiteDatabase & database, const char * sql)
	: m_Handle(nullptr)
{
	SQLiteDatabase::Locker locker(database);
	database.prepare(locker, m_Handle, sql);
}

SQLiteStatement::SQLiteStatement(SQLiteDatabase & database, const std::string & sql)
	: m_Handle(nullptr)
{
	SQLiteDatabase::Locker locker(database);
	database.prepare(locker, m_Handle, sql.c_str());
}

SQLiteStatement::~SQLiteStatement() noexcept
{
	sqlite3_finalize(m_Handle);
}

void SQLiteStatement::bindNull(int index)
{
	checkError(sqlite3_bind_null(m_Handle, index), index);
}

void SQLiteStatement::bindInt(int index, int value)
{
	checkError(sqlite3_bind_int(m_Handle, index, value), index);
}

void SQLiteStatement::bindInt64(int index, sqlite3_int64 value)
{
	checkError(sqlite3_bind_int64(m_Handle, index, value), index);
}

void SQLiteStatement::bindSizeT(int index, size_t value)
{
	checkError(sqlite3_bind_int64(m_Handle, index, static_cast<sqlite3_int64>(value)), index);
}

void SQLiteStatement::bindTimeT(int index, time_t value)
{
	checkError(sqlite3_bind_int64(m_Handle, index, static_cast<sqlite3_int64>(value)), index);
}

void SQLiteStatement::bindFloat(int index, float value)
{
	checkError(sqlite3_bind_double(m_Handle, index, static_cast<double>(value)), index);
}

void SQLiteStatement::bindDouble(int index, double value)
{
	checkError(sqlite3_bind_double(m_Handle, index, value), index);
}

void SQLiteStatement::bindText(int index, const char * text, void (* destructor)(void *))
{
	checkError(sqlite3_bind_text(m_Handle, index, text, -1, destructor), index);
}

void SQLiteStatement::bindText(int index, const char * text, size_t length, void (* destructor)(void *))
{
	checkError(sqlite3_bind_text(m_Handle, index, text, static_cast<int>(length), destructor), index);
}

void SQLiteStatement::bindString(int index, const std::string & string)
{
	bindText(index, string.data(), string.length());
}

void SQLiteStatement::bindBlob(int index, const void * data, size_t size, void (* destructor)(void *))
{
	checkError(sqlite3_bind_blob(m_Handle, index, data, static_cast<int>(size), destructor), index);
}

int SQLiteStatement::parameterIndex(const char * name) const
{
	int index = sqlite3_bind_parameter_index(m_Handle, name);
	if (!index)
	{
		throw std::runtime_error(fmt()
			<< "there is no parameter '" << name << "' in query '" << sqlite3_sql(m_Handle) << "'.");
	}
	return index;
}

int SQLiteStatement::parameterIndex(const std::string & name) const
{
	return parameterIndex(name.c_str());
}

int SQLiteStatement::parameterIndex(const char * name, const std::nothrow_t &) const noexcept
{
	return sqlite3_bind_parameter_index(m_Handle, name);
}

int SQLiteStatement::parameterIndex(const std::string & name, const std::nothrow_t &) const noexcept
{
	return parameterIndex(name.c_str(), std::nothrow);
}

void SQLiteStatement::exec()
{
	SQLiteDatabase::Locker locker(m_Handle);
	SQLiteDatabase::exec(locker, m_Handle);
}

void SQLiteStatement::exec(const std::function<void(const SQLiteCursor &)> & onRow)
{
	SQLiteDatabase::Locker locker(m_Handle);
	SQLiteDatabase::exec(locker, m_Handle, [&onRow, this](){ onRow(SQLiteCursor(m_Handle)); });
}

void SQLiteStatement::exec(const std::function<void(const SQLiteCursor &)> & onRow, size_t limit)
{
	SQLiteDatabase::Locker locker(m_Handle);
	SQLiteDatabase::exec(locker, m_Handle, [&onRow, this](){ onRow(SQLiteCursor(m_Handle)); }, limit);
}

void SQLiteStatement::checkError(int err, int index)
{
	if (UNLIKELY(err != SQLITE_OK))
	{
		throw std::runtime_error(fmt() << "unable to bind value for parameter #" << index << " of query '"
			<< sqlite3_sql(m_Handle) << "': " << sqlite3_errstr(err));
	}
}
