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
#ifndef __67d9d9fc4276e6645f36c8875a0eca32__
#define __67d9d9fc4276e6645f36c8875a0eca32__

#include <yip-imports/sqlite3.h>
#include <string>

class SQLiteStatement;

class SQLiteCursor
{
public:
	enum ColumnType
	{
		ColumnNull = SQLITE_NULL,
		ColumnInt = SQLITE_INTEGER,
		ColumnFloat = SQLITE_FLOAT,
		ColumnText = SQLITE_TEXT,
		ColumnBlob = SQLITE_BLOB,
	};

	inline bool isNull(int index) const noexcept { return sqlite3_column_type(m_Cursor, index) == SQLITE_NULL; }

	inline int toInt(int index) const noexcept { return sqlite3_column_int(m_Cursor, index); }
	inline sqlite3_int64 toInt64(int index) const noexcept { return sqlite3_column_int64(m_Cursor, index); }
	inline size_t toSizeT(int index) const noexcept { return static_cast<size_t>(toInt64(index)); }
	inline time_t toTimeT(int index) const noexcept { return static_cast<time_t>(toInt64(index)); }
	inline float toFloat(int index) const noexcept { return static_cast<float>(sqlite3_column_double(m_Cursor, index)); }
	inline double toDouble(int index) const noexcept { return sqlite3_column_double(m_Cursor, index); }

	inline const char * toText(int index) const noexcept
		{ return reinterpret_cast<const char *>(sqlite3_column_text(m_Cursor, index)); }

	inline std::string toString(int index) const
	{
		return std::string(
			reinterpret_cast<const char *>(sqlite3_column_blob(m_Cursor, index)),
			static_cast<size_t>(sqlite3_column_bytes(m_Cursor, index))
		);
	}

	inline int numColumns() const noexcept { return sqlite3_column_count(m_Cursor); }
	inline const char * columnName(int n) const noexcept { return sqlite3_column_name(m_Cursor, n); }
	inline ColumnType columnType(int n) const noexcept { return ColumnType(sqlite3_column_type(m_Cursor, n)); }

private:
	sqlite3_stmt * m_Cursor;

	inline SQLiteCursor(sqlite3_stmt * stmt) noexcept : m_Cursor(stmt) {}
	inline ~SQLiteCursor() noexcept {}

	SQLiteCursor(const SQLiteCursor &) = delete;
	SQLiteCursor & operator=(const SQLiteCursor &) = delete;

	friend class SQLiteDatabase;
	friend class SQLiteStatement;
};

#endif
