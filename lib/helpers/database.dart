import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';

class AppDatabase extends ChangeNotifier {
  AppDatabase._init();

  static final AppDatabase instance = AppDatabase._init();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('expenses.db');
    return _database!;
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        $columnId $idType PRIMARY KEY,
        $columnTitle $textType,
        $columnAmount $realType,
        $columnDate $integerType
      )
    ''');
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<Expense> createExpense(Expense expense) async {
    final db = await instance.database;
    final id = await db.insert(tableName, expense.toJson());
    notifyListeners(); // Notify listeners of the change
    return expense.copyWith(id: id);
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await instance.database;
    final result = await db.query(
      tableName,
      orderBy: '$columnDate DESC',
    );
    return result.map((json) => Expense.fromJson(json)).toList();
  }

  Future<Expense?> getExpense(int id) async {
    final db = await instance.database;
    final result = await db.query(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return Expense.fromJson(result.first);
    }
    return null;
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await instance.database;
    final result = await db.update(
      tableName,
      expense.toJson(),
      where: '$columnId = ?',
      whereArgs: [expense.id],
    );
    notifyListeners(); // Notify listeners of the change
    return result;
  }

  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    final result = await db.delete(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );
    notifyListeners(); // Notify listeners of the change
    return result;
  }

// Calculate total expenses grouped by year and then by month
  Future<Map<int, double>> getTotalExpensesForMonth() async {
    final expenses = await getAllExpenses();
    Map<int, double> monthlyTotalExpenses = {};

    for (var expense in expenses) {
      int month = expense.date.month;

      // Initialize the month if it doesn't exist
      if (!monthlyTotalExpenses.containsKey(month)) {
        monthlyTotalExpenses[month] = 0.0;
      }

      // Add the expense amount to the appropriate month, ignoring the year
      monthlyTotalExpenses[month] =
          monthlyTotalExpenses[month]! + expense.amount;
    }

    return monthlyTotalExpenses;
  }

  Future<int> getStartMonth() async {
    final expenses = await getAllExpenses();
    if (expenses.isEmpty) {
      return DateTime.now().month;
    }
    expenses.sort((a, b) => a.date.compareTo(b.date));
    return expenses.first.date.month;
  }

  Future<int> getStartYear() async {
    final expenses = await getAllExpenses();
    if (expenses.isEmpty) {
      return DateTime.now().year;
    }
    expenses.sort((a, b) => a.date.compareTo(b.date));
    return expenses.first.date.year;
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
