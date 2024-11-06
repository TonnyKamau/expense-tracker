import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController titleController = TextEditingController();
  TextEditingController amountController = TextEditingController();

// open new expense box
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
                decoration: const InputDecoration(hintText: 'Amount'),
              ),
            ],
          ),
        ),
        actions: [_cancleButton(), _submitButton()],
      ),
    );
  }

  Widget _cancleButton() {
    return MaterialButton(
      onPressed: () {
        Navigator.pop(context);
        titleController.clear();
        amountController.clear();
      },
      child: Text('Cancel'),
    );
  }

  Widget _submitButton() {
    return MaterialButton(
      onPressed: () {
        // TODO: Handle expense submission
        if (titleController.text.isNotEmpty &&
            amountController.text.isNotEmpty) {
          // Process the expense
          Navigator.pop(context);
        }
      },
      child: const Text('Add Expense'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const SizedBox(
              height: 20,
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
      body: const Center(
        child: Text('Home Page'),
      ),
    );
  }
}
