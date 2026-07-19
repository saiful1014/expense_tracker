import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:test_new_things/domain/models/expense.dart';
import 'package:test_new_things/domain/models/borrow_lend.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expenses.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7, // Updated version for due date & recurrence
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        is_recurring INTEGER DEFAULT 0,
        recurrence_interval TEXT,
        last_processed TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_expenses_date ON expenses(date)');
    await db.execute('CREATE INDEX idx_expenses_synced ON expenses(synced)');
    await db.execute('''
      CREATE TABLE borrow_lend (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        person_name TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT,
        completed INTEGER DEFAULT 0,
        synced INTEGER DEFAULT 0,
        repayments TEXT DEFAULT '[]',
        due_date TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_borrow_lend_type_completed ON borrow_lend(type, completed)');
    await db.execute('CREATE INDEX idx_borrow_lend_synced ON borrow_lend(synced)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS borrow_lend (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          person_name TEXT NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          type TEXT NOT NULL,
          description TEXT,
          completed INTEGER DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 3) {
      // Add completed column to existing borrow_lend table
      try {
        await db.execute('ALTER TABLE borrow_lend ADD COLUMN completed INTEGER DEFAULT 0');
      } catch (e) {
        // Column might already exist, ignore error
      }
    }
    if (oldVersion < 4) {
      // Add synced column to both tables
      try {
        await db.execute('ALTER TABLE expenses ADD COLUMN synced INTEGER DEFAULT 0');
      } catch (e) {
        // Column might already exist, ignore error
      }
      try {
        await db.execute('ALTER TABLE borrow_lend ADD COLUMN synced INTEGER DEFAULT 0');
      } catch (e) {
        // Column might already exist, ignore error
      }
    }
    if (oldVersion < 5) {
      // Add indexes for better query performance
      try {
        await db.execute('CREATE INDEX idx_expenses_date ON expenses(date)');
      } catch (e) {
        // Index might already exist, ignore error
      }
      try {
        await db.execute('CREATE INDEX idx_expenses_synced ON expenses(synced)');
      } catch (e) {
        // Index might already exist, ignore error
      }
      try {
        await db.execute('CREATE INDEX idx_borrow_lend_type_completed ON borrow_lend(type, completed)');
      } catch (e) {
        // Index might already exist, ignore error
      }
      try {
        await db.execute('CREATE INDEX idx_borrow_lend_synced ON borrow_lend(synced)');
      } catch (e) {
        // Index might already exist, ignore error
      }
    }
    if (oldVersion < 6) {
      // Add repayments column to store partial payments history as JSON
      try {
        await db.execute("ALTER TABLE borrow_lend ADD COLUMN repayments TEXT DEFAULT '[]'");
      } catch (e) {
        // Column might already exist, ignore error
      }
    }
    if (oldVersion < 7) {
      try {
        await db.execute("ALTER TABLE expenses ADD COLUMN is_recurring INTEGER DEFAULT 0");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE expenses ADD COLUMN recurrence_interval TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE expenses ADD COLUMN last_processed TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE borrow_lend ADD COLUMN due_date TEXT");
      } catch (_) {}
    }
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    if (expense.id == null) {
      throw ArgumentError('Expense ID must not be null for update');
    }
    return await db.update(
      'expenses',
      {
        'description': expense.description,
        'amount': expense.amount,
        'date': expense.date.toIso8601String(),
        'category': expense.category,
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final result = await db.query('expenses', orderBy: 'date DESC');
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  Future<List<Expense>> getExpensesByDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    final result = await db.query(
      'expenses',
      where: 'date LIKE ?',
      whereArgs: ['$dateStr%'],
      orderBy: 'date DESC',
    );
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  Future<List<Expense>> getExpensesByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    // Set endDate to end of day (23:59:59)
    final endDateTime = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    final startStr = startDate.toIso8601String();
    final endStr = endDateTime.toIso8601String();
    final result = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date DESC',
    );
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalExpenses() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(amount) as total FROM expenses');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalExpensesByDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE date LIKE ?',
      ['$dateStr%'],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalExpensesByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    // Set endDate to end of day (23:59:59)
    final endDateTime = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    final startStr = startDate.toIso8601String();
    final endStr = endDateTime.toIso8601String();
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE date >= ? AND date <= ?',
      [startStr, endStr],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Borrow/Lend methods
  Future<int> insertBorrowLend(BorrowLend borrowLend) async {
    final db = await database;
    return await db.insert('borrow_lend', borrowLend.toMap());
  }

  Future<int> updateBorrowLend(BorrowLend borrowLend) async {
    final db = await database;
    if (borrowLend.id == null) {
      throw ArgumentError('Borrow/Lend ID must not be null for update');
    }
    return await db.update(
      'borrow_lend',
      {
        'person_name': borrowLend.personName,
        'amount': borrowLend.amount,
        'date': borrowLend.date.toIso8601String(),
        'type': borrowLend.type,
        'description': borrowLend.description,
        'completed': borrowLend.completed ? 1 : 0,
        'synced': 0,
        'repayments': jsonEncode(borrowLend.repayments.map((r) => r.toMap()).toList()),
        'due_date': borrowLend.dueDate?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [borrowLend.id],
    );
  }

  Future<List<BorrowLend>> getAllBorrowLend() async {
    final db = await database;
    final result = await db.query('borrow_lend', orderBy: 'date DESC');
    return result.map((map) => BorrowLend.fromMap(map)).toList();
  }

  Future<List<BorrowLend>> getBorrowLendByType(String type) async {
    final db = await database;
    final result = await db.query(
      'borrow_lend',
      where: 'type = ? AND completed = 0',
      whereArgs: [type],
      orderBy: 'date DESC',
    );
    return result.map((map) => BorrowLend.fromMap(map)).toList();
  }

  Future<List<BorrowLend>> getCompletedBorrowLend() async {
    final db = await database;
    final result = await db.query(
      'borrow_lend',
      where: 'completed = 1',
      orderBy: 'date DESC',
    );
    return result.map((map) => BorrowLend.fromMap(map)).toList();
  }

  Future<int> markBorrowLendAsCompleted(int id) async {
    final db = await database;
    return await db.update(
      'borrow_lend',
      {
        'completed': 1,
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<BorrowLend?> getBorrowLendById(int id) async {
    final db = await database;
    final result = await db.query(
      'borrow_lend',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return BorrowLend.fromMap(result.first);
  }

  Future<BorrowLend?> markBorrowLendAsCompletedAndGet(int id) async {
    final db = await database;
    await db.update(
      'borrow_lend',
      {
        'completed': 1,
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return await getBorrowLendById(id);
  }

  Future<BorrowLend?> markBorrowLendAsPendingAndGet(int id) async {
    final db = await database;
    await db.update(
      'borrow_lend',
      {
        'completed': 0,
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return await getBorrowLendById(id);
  }

  Future<int> markBorrowLendAsPending(int id) async {
    final db = await database;
    return await db.update(
      'borrow_lend',
      {
        'completed': 0,
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteBorrowLend(int id) async {
    final db = await database;
    return await db.delete(
      'borrow_lend',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalBorrowed() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT SUM(amount) as total FROM borrow_lend WHERE type = 'borrow' AND completed = 0",
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalLent() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT SUM(amount) as total FROM borrow_lend WHERE type = 'lend' AND completed = 0",
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Methods for syncing
  Future<List<Expense>> getUnsyncedExpenses() async {
    final db = await database;
    final result = await db.query(
      'expenses',
      where: 'synced = 0',
      orderBy: 'date DESC',
    );
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  Future<List<BorrowLend>> getUnsyncedBorrowLend() async {
    final db = await database;
    final result = await db.query(
      'borrow_lend',
      where: 'synced = 0',
      orderBy: 'date DESC',
    );
    return result.map((map) => BorrowLend.fromMap(map)).toList();
  }

  Future<int> markExpenseAsSynced(int id) async {
    final db = await database;
    return await db.update(
      'expenses',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markBorrowLendAsSynced(int id) async {
    final db = await database;
    return await db.update(
      'borrow_lend',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markExpenseAsUnsynced(int id) async {
    final db = await database;
    return await db.update(
      'expenses',
      {'synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markBorrowLendAsUnsynced(int id) async {
    final db = await database;
    return await db.update(
      'borrow_lend',
      {'synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('expenses');
    await db.delete('borrow_lend');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}


