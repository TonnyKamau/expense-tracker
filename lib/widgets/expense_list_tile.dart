import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ExpenseListTile extends StatelessWidget {
  final String title;
  // final String subtitle;
  final String trailing;
  final VoidCallback? onDeletePressed;
  final VoidCallback? onEditPressed; // Changed type to VoidCallback

  const ExpenseListTile({
    super.key,
    required this.title,
    // required this.subtitle,
    required this.trailing,
    required this.onDeletePressed,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 5.0),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: (context) =>
                  onEditPressed?.call(), // Modified to handle context
              icon: Icons.edit,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.surface,
            ),
            SlidableAction(
              backgroundColor: Colors.red,
              foregroundColor: Theme.of(context).colorScheme.surface,
              onPressed: (context) => onDeletePressed?.call(),
              icon: Icons.delete,
            ),
          ],
        ),
        child: ListTile(
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          // subtitle: Text(
          //   subtitle,
          //   style: TextStyle(
          //     color: Theme.of(context).colorScheme.primary,
          //     fontSize: 12,
          //   ),
          // ),
          trailing: Text(
            trailing,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
