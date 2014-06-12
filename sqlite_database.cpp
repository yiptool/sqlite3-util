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
#include "sqlite_database.h"
#include "sqlite_cursor.h"
#include <yip-imports/cxx-util/macros.h>
#include <yip-imports/cxx-util/fmt.h>
#include <iostream>
#include <stdexcept>
#include <cassert>

/* SQLiteDatabase::Locker */

SQLiteDatabase::Locker::Locker(SQLiteDatabase & db) noexcept
	: m_Mutex(sqlite3_db_mutex(db.m_Handle)),
	  m_Locked(false)
{
	relock();
}

SQLiteDatabase::Locker::Locker(sqlite3_stmt * stmt) noexcept
	: m_Mutex(sqlite3_db_mutex(sqlite3_db_handle(stmt))),
	  m_Locked(false)
{
}

void SQLiteDatabase::Locker::unlock() noexcept
{
	if (m_Locked)
	{
		m_Locked = false;
		sqlite3_mutex_leave(m_Mutex);
	}
}

void SQLiteDatabase::Locker::relock() noexcept
{
	if (!m_Locked)
	{
		sqlite3_mutex_enter(m_Mutex);
		m_Locked = true;
	}
}


/* SQLiteDatabase */

SQLiteDatabase::SQLiteDatabase(const char * file)
	: m_File(file),
	  m_StmtBegin(nullptr),
	  m_StmtRollback(nullptr),
	  m_StmtCommit(nullptr)
{
	int err = sqlite3_open_v2(file, &m_Handle, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nullptr);
	if (UNLIKELY(err != SQLITE_OK))
	{
		throw std::runtime_error(fmt()
			<< "unable to open sqlite database '" << file << "': " << sqlite3_errstr(err));
	}
}

SQLiteDatabase::SQLiteDatabase(const std::string & file)
	: m_File(file),
	  m_StmtBegin(nullptr),
	  m_StmtRollback(nullptr),
	  m_StmtCommit(nullptr)
{
	int err = sqlite3_open_v2(file.c_str(), &m_Handle, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nullptr);
	if (UNLIKELY(err != SQLITE_OK))
	{
		throw std::runtime_error(fmt()
			<< "unable to open sqlite database '" << file << "': " << sqlite3_errstr(err));
	}
}

SQLiteDatabase::~SQLiteDatabase()
{
	sqlite3_mutex_enter(sqlite3_db_mutex(m_Handle));

	if (m_StmtBegin)
		sqlite3_finalize(m_StmtBegin);
	if (m_StmtRollback)
		sqlite3_finalize(m_StmtRollback);
	if (m_StmtCommit)
		sqlite3_finalize(m_StmtCommit);

	int err = sqlite3_close(m_Handle);
	if (err != SQLITE_OK)
	{
		std::cerr << "warning: unable to close sqlite database '" << m_File << "': "
			<< sqlite3_errstr(err) << std::endl;
		sqlite3_close_v2(m_Handle);
	}
}

void SQLiteDatabase::transaction(const std::function<void()> & protectedCode)
{
	Locker locker(*this);

	begin(locker);
	try
	{
		if (LIKELY(protectedCode))
			protectedCode();
	}
	catch (...)
	{
		rollback(locker);
		throw;
	}
	commit(locker);
}

void SQLiteDatabase::exec(const char * sql)
{
	Locker locker(*this);

	sqlite3_stmt * stmt = nullptr;
	try
	{
		prepare(locker, stmt, sql);
		exec(locker, stmt);
	}
	catch (...)
	{
		sqlite3_finalize(stmt);
		throw;
	}

	sqlite3_finalize(stmt);
}

void SQLiteDatabase::exec(const std::string & sql)
{
	exec(sql.c_str());
}

void SQLiteDatabase::exec(const char * sql, const std::function<void(const SQLiteCursor & cursor)> & onRow)
{
	Locker locker(*this);

	sqlite3_stmt * stmt = nullptr;
	try
	{
		prepare(locker, stmt, sql);
		exec(locker, stmt, [stmt, &onRow](){ onRow(SQLiteCursor(stmt)); });
	}
	catch (...)
	{
		sqlite3_finalize(stmt);
		throw;
	}

	sqlite3_finalize(stmt);
}

void SQLiteDatabase::exec(const std::string & sql, const std::function<void(const SQLiteCursor & cursor)> & onRow)
{
	exec(sql.c_str(), onRow);
}

void SQLiteDatabase::exec(const char * sql, const std::function<void(const SQLiteCursor & cursor)> & onRow,
	size_t limit)
{
	Locker locker(*this);

	sqlite3_stmt * stmt = nullptr;
	try
	{
		prepare(locker, stmt, sql);
		exec(locker, stmt, [stmt, &onRow](){ onRow(SQLiteCursor(stmt)); }, limit);
	}
	catch (...)
	{
		sqlite3_finalize(stmt);
		throw;
	}

	sqlite3_finalize(stmt);
}

void SQLiteDatabase::exec(const std::string & sql, const std::function<void(const SQLiteCursor & cursor)> & onRow,
	size_t limit)
{
	exec(sql.c_str(), onRow, limit);
}

void SQLiteDatabase::begin(Locker & locker)
{
	if (m_InTransaction)
	{
		assert(m_InTransaction > 0);
		++m_InTransaction;
		return;
	}

	m_TransactionFailed = false;
	prepare(locker, m_StmtBegin, "BEGIN IMMEDIATE");
	prepare(locker, m_StmtRollback, "ROLLBACK");
	exec(locker, m_StmtBegin);
	++m_InTransaction;
}

void SQLiteDatabase::rollback(Locker & locker)
{
	if (UNLIKELY(!m_InTransaction))
		throw std::runtime_error("attempted to invoke 'rollback' outside of transaction.");

	m_TransactionFailed = true;
	if (--m_InTransaction == 0)
		exec(locker, m_StmtRollback);
}

void SQLiteDatabase::commit(Locker & locker)
{
	if (UNLIKELY(!m_InTransaction))
		throw std::runtime_error("attempted to invoke 'commit' outside of transaction.");

	if (--m_InTransaction > 0)
		return;

	if (UNLIKELY(m_TransactionFailed))
	{
		exec(locker, m_StmtRollback);
		return;
	}

	try
	{
		prepare(locker, m_StmtCommit, "COMMIT");
		exec(locker, m_StmtCommit);
	}
	catch (const std::exception & e)
	{
		std::cerr << "error: database commit failed: " << e.what() << std::endl;
		exec(locker, m_StmtRollback);
		throw;
	}
}

void SQLiteDatabase::prepare(Locker &, sqlite3_stmt *& stmt, const char * sql)
{
	if (stmt)
		return;

	int err = sqlite3_prepare_v2(m_Handle, sql, -1, &stmt, nullptr);
	if (UNLIKELY(err != SQLITE_OK || !stmt))
	{
		throw std::runtime_error(fmt()
			<< "unable to prepare statement '" << sql << "': " << sqlite3_errmsg(m_Handle));
	}
}

void SQLiteDatabase::exec(Locker &, sqlite3_stmt * stmt)
{
	try
	{
		for (;;)
		{
			int err = sqlite3_step(stmt);
			if (err == SQLITE_DONE)
				break;
			else if (UNLIKELY(err != SQLITE_ROW))
			{
				sqlite3 * db = sqlite3_db_handle(stmt);
				throw std::runtime_error(fmt()
					<< "unable to execute statement '" << sqlite3_sql(stmt) << "': " << sqlite3_errmsg(db));
			}
		}
	}
	catch (...)
	{
		sqlite3_reset(stmt);
		throw;
	}

	sqlite3_reset(stmt);
}

void SQLiteDatabase::exec(Locker & locker, sqlite3_stmt * stmt, const std::function<void()> & onRow)
{
	try
	{
		for (;;)
		{
			int err = sqlite3_step(stmt);
			if (err == SQLITE_DONE)
				break;
			else if (UNLIKELY(err != SQLITE_ROW))
			{
				sqlite3 * db = sqlite3_db_handle(stmt);
				throw std::runtime_error(fmt()
					<< "unable to execute statement '" << sqlite3_sql(stmt) << "': " << sqlite3_errmsg(db));
			}

			locker.unlock();
			onRow();
			locker.relock();
		}
	}
	catch (...)
	{
		sqlite3_reset(stmt);
		throw;
	}

	sqlite3_reset(stmt);
}

void SQLiteDatabase::exec(Locker & locker, sqlite3_stmt * stmt, const std::function<void()> & onRow, size_t limit)
{
	try
	{
		do
		{
			int err = sqlite3_step(stmt);
			if (err == SQLITE_DONE)
				break;
			else if (UNLIKELY(err != SQLITE_ROW))
			{
				sqlite3 * db = sqlite3_db_handle(stmt);
				throw std::runtime_error(fmt()
					<< "unable to execute statement '" << sqlite3_sql(stmt) << "': " << sqlite3_errmsg(db));
			}

			if (limit == 0)
				break;
			--limit;

			locker.unlock();
			onRow();
			locker.relock();
		}
		while (limit != 0);
	}
	catch (...)
	{
		sqlite3_reset(stmt);
		throw;
	}

	sqlite3_reset(stmt);
}
