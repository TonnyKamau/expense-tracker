import 'package:expensetracker/bargraph/bar_graph.dart';
import 'package:expensetracker/helpers/database.dart';
import 'package:expensetracker/syncing/sync.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController titleController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  final FirebaseSyncService _syncService = FirebaseSyncService();

  Future<Map<String, double>>? _monthlyTotalFuture;
  Future<double>? _calculateMonthlyTotalExpensesFuture;

  @override
  void initState() {
    super.initState();
    Provider.of<AppDatabase>(context, listen: false).getAllExpenses();
    refreshData();
    _syncService.onSyncComplete = refreshData;
    _syncService.startSyncing();
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    _syncService.stopSyncing();
    super.dispose();
  }

  void refreshData() {
    _monthlyTotalFuture = Provider.of<AppDatabase>(context, listen: false)
        .getTotalExpensesForMonth();
    _calculateMonthlyTotalExpensesFuture =
        Provider.of<AppDatabase>(context, listen: false)
            .getCurrentMonthTotalExpenses();
  }

  void openNewExpenseBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text('Add Expense'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  hintText: 'Amount',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [_cancelButton(), _submitButton()],
      ),
    );
  }

  void openEditExpenseBox(Expense expense) {
    titleController.text = expense.title;
    amountController.text = expense.amount.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text('Edit Expense'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [_cancelButton(), _editButton(expense)],
      ),
    );
  }

  String getCurrentMonthName() {
    final now = DateTime.now();
    List<String> monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final monthName = monthNames[now.month - 1];
    return monthName;
  }

  void openDeleteExpenseBox(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text('Delete Expense'),
        content: const Text(
          'Are you sure you want to delete this expense?',
        ),
        actions: [
          _cancelButton(),
          _deleteButton(expense.id!),
        ],
      ),
    );
  }

  Widget _cancelButton() {
    return MaterialButton(
      onPressed: () {
        Navigator.pop(context);
        titleController.clear();
        amountController.clear();
      },
      child: const Text('Cancel'),
    );
  }

  Widget _deleteButton(int id) {
    return MaterialButton(
      onPressed: () async {
        Navigator.pop(context);
        await context.read<AppDatabase>().deleteExpense(id);
        refreshData();
      },
      child: const Text('Delete'),
    );
  }

  Widget _editButton(Expense expense) {
    return MaterialButton(
      onPressed: () async {
        if (titleController.text.isNotEmpty ||
            (amountController.text.isNotEmpty &&
                double.tryParse(amountController.text) != null)) {
          Navigator.pop(context);
          Expense editedExpense = Expense(
            id: expense.id,
            title: titleController.text.isNotEmpty
                ? titleController.text
                : expense.title,
            amount: amountController.text.isNotEmpty
                ? double.parse(amountController.text)
                : expense.amount,
            date: DateTime.now(),
          );
          await context.read<AppDatabase>().updateExpense(editedExpense);
          refreshData();
          titleController.clear();
          amountController.clear();
        }
      },
      child: const Text('Edit'),
    );
  }

  Widget _submitButton() {
    return MaterialButton(
      onPressed: () async {
        if (titleController.text.isNotEmpty &&
            amountController.text.isNotEmpty &&
            double.tryParse(amountController.text) != null) {
          Navigator.pop(context);
          Expense newExpense = Expense(
            title: titleController.text,
            amount: double.parse(amountController.text),
            date: DateTime.now(),
          );
          await context.read<AppDatabase>().createExpense(newExpense);
          refreshData();
          titleController.clear();
          amountController.clear();
        }
      },
      child: const Text('Add Expense'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppDatabase>(
      builder: (context, database, child) {
        Future<int> startMonthFuture = database.getStartMonth();
        Future<int> startYearFuture = database.getStartYear();

        int currentMonth = DateTime.now().month;
        int currentYear = DateTime.now().year;

        return Scaffold(
          appBar: AppBar(
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Text(
                  '${getCurrentMonthName()} $currentYear',
                  style: const TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),
            ],
            backgroundColor: Colors.transparent,
            centerTitle: true,
            title: FutureBuilder<double>(
                future: _calculateMonthlyTotalExpensesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  double totalExpenses = snapshot.data ?? 0.0;
                  return Text('ksh${totalExpenses.toStringAsFixed(2)}');
                }),
          ),
          drawer: Drawer(
            child: ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 20.0, bottom: 10.0, left: 20.0),
                  child: Text(
                    'Expense Tracker',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.settings,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Settings'),
                  onTap: () {
                    Get.toNamed('/settings');
                  },
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: openNewExpenseBox,
            child: const Icon(Icons.add),
          ),
          body: FutureBuilder<List<int>>(
            future: Future.wait([startMonthFuture, startYearFuture]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              int startMonth = snapshot.data![0];
              int startYear = snapshot.data![1];
              int monthCount = (currentYear - startYear) * 12 +
                  currentMonth -
                  startMonth +
                  1;

              return Column(
                children: [
                  SizedBox(
                    height: 250,
                    child: FutureBuilder(
                      future: _monthlyTotalFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          Map<String, double>? monthlyTotals =
                              snapshot.data ?? {};
                          List<double> monthlySummary =
                              List.generate(monthCount, (index) {
                            int year =
                                startYear + (startMonth + index - 1) ~/ 12;
                            int month = (startMonth + index - 1) % 12 + 1;
                            String yearMonthKey = '$year-$month';
                            return monthlyTotals[yearMonthKey] ?? 0.0;
                          });
                          return MyBarGraph(
                            monthlySummary: monthlySummary,
                            startMonth: startMonth,
                          );
                        } else {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 25),
                  Expanded(
                    child: FutureBuilder<List<Expense>>(
                      future: database.getAllExpenses(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(child: Text('No expenses found'));
                        } else {
                          final expenses = snapshot.data!;
                          return ListView.builder(
                            itemCount: expenses.length,
                            itemBuilder: (context, index) {
                              final expense = expenses[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                child: ExpenseListTile(
                                  title:
                                      '${expense.title[0].toUpperCase()}${expense.title.substring(1)}',
                                  // subtitle:
                                  //     'Amount: ${NumberFormat.currency(symbol: "ksh", locale: 'en_KE', decimalDigits: 2).format(expense.amount)}',
                                  // trailing: DateFormat('yyyy-MM-dd – hh:mm a')
                                  //     .format(expense.date),
                                  trailing: NumberFormat.currency(
                                          symbol: "ksh",
                                          locale: 'en_KE',
                                          decimalDigits: 2)
                                      .format(expense.amount),
                                  onDeletePressed: () =>
                                      openDeleteExpenseBox(expense),
                                  onEditPressed: () =>
                                      openEditExpenseBox(expense),
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
