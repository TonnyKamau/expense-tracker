// Database constants
// Database table and column names
const String tableName = 'expenses';
const String columnId = 'id';
const String columnTitle = 'title';
const String columnAmount = 'amount';
const String columnDate = 'date';

// Column types
const String idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
const String textType = 'TEXT NOT NULL';
const String realType = 'REAL NOT NULL';
const String integerType = 'INTEGER NOT NULL';

/// Represents an expense entry with basic information including
/// title, amount, and date.
class Expense {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;

  /// Creates a new [Expense] instance.
  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
  })  : assert(title.trim().isNotEmpty, 'Title cannot be empty'),
        assert(amount > 0, 'Amount must be positive');

  factory Expense.fromJson(Map<String, dynamic> map) {
    return Expense(
      id: map[columnId] as int?,
      title: map[columnTitle] as String,
      amount: (map[columnAmount] as num).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map[columnDate] as int),
    );
  }

  // Convert Expense to a map for database storage
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      columnTitle: title,
      columnAmount: amount,
      columnDate: date.millisecondsSinceEpoch,
    };

    if (id != null) {
      map[columnId] = id;
    }

    return map;
  } // Creates an [Expense] instance from a database map.

  /// Creates a copy of this expense with optionally updated fields.
  Expense copyWith({
    int? id,
    String? title,
    double? amount,
    DateTime? date,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }

  /// Returns a formatted string representation of the amount.
  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';

  /// Returns a formatted string representation of the date.
  String get formattedDate =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  String toString() =>
      'Expense(id: $id, title: $title, amount: $formattedAmount, date: $formattedDate)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          amount == other.amount &&
          date == other.date;

  @override
  int get hashCode => Object.hash(id, title, amount, date);
}
