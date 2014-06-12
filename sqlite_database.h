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
#ifndef __c1cb3bca9328a35c1ed67c27131f36bd__
#define __c1cb3bca9328a35c1ed67c27131f36bd__

#include <yip-imports/sqlite3.h>
#include <string>
#include <functional>

class SQLiteCursor;
class SQLiteStatement;

class SQLiteDatabase
{
public:
	class Locker
	{
	public:
		Locker(SQLiteDatabase & db) noexcept;
		Locker(sqlite3_stmt * stmt) noexcept;
		inline Locker(sqlite3_mutex * mutex) noexcept : m_Mutex(mutex), m_Locked(false) { relock(); }
		inline ~Locker() noexcept { unlock(); }

		void unlock() noexcept;
		void relock() noexcept;

	private:
		sqlite3_mutex * m_Mutex;
		bool m_Locked;

		Locker(const Locker &) = delete;
		Locker & operator=(const Locker &) = delete;
	};

	SQLiteDatabase(const char * file);
	SQLiteDatabase(const std::string & file);
	~SQLiteDatabase();

	inline const std::string & fileName() const { return m_File; }
	inline sqlite3 * handle() const { return m_Handle; }

	void transaction(const std::function<void()> & protectedCode);

private:
	std::string m_File;
	sqlite3 * m_Handle;
	sqlite3_stmt * m_StmtBegin;
	sqlite3_stmt * m_StmtRollback;
	sqlite3_stmt * m_StmtCommit;
	int m_InTransaction;
	bool m_TransactionFailed;

	void begin(Locker & locker);
	void rollback(Locker & locker);
	void commit(Locker & locker);

	void prepare(Locker & locker, sqlite3_stmt *& stmt, const char * sql);

	static void exec(Locker & locker, sqlite3_stmt * stmt);
	static void exec(Locker & locker, sqlite3_stmt * stmt, const std::function<void()> & onRow);

	SQLiteDatabase(const SQLiteDatabase &) = delete;
	SQLiteDatabase & operator=(const SQLiteDatabase &) = delete;

	friend class SQLiteCursor;
	friend class SQLiteStatement;
	friend class SQLiteDatabase::Locker;
};

#endif
