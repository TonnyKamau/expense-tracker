const String tableName = 'expenses';
const String columnId = 'id';
const String columnTitle = 'title';
const String columnAmount = 'amount';
const String columnDate = 'date';

const String idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
const String textType = 'TEXT NOT NULL';
const String realType = 'REAL NOT NULL';
const String integerType = 'INTEGER NOT NULL';

class Expense {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;
  final DateTime lastModified;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    DateTime? lastModified,
  })  : lastModified = lastModified ?? DateTime.now(),
        assert(title.trim().isNotEmpty, 'Title cannot be empty'),
        assert(amount > 0, 'Amount must be positive');

  factory Expense.fromJson(Map<String, dynamic> map) {
    return Expense(
      id: map[columnId] as int?,
      title: map[columnTitle] as String,
      amount: (map[columnAmount] as num).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map[columnDate] as int),
      lastModified:
          DateTime.fromMillisecondsSinceEpoch(map['lastModified'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      columnTitle: title,
      columnAmount: amount,
      columnDate: date.millisecondsSinceEpoch,
      'lastModified': lastModified.millisecondsSinceEpoch,
    };

    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  Expense copyWith({
    int? id,
    String? title,
    double? amount,
    DateTime? date,
    DateTime? lastModified,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';
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
