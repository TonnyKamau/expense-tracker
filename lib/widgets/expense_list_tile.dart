import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ExpenseListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback? onDeletePressed;
  final VoidCallback? onEditPressed; // Changed type to VoidCallback

  const ExpenseListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onDeletePressed,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          SlidableAction(
            onPressed: (context) =>
                onEditPressed?.call(), // Modified to handle context
            icon: Icons.edit,
          ),
          SlidableAction(
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
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 12,
          ),
        ),
        trailing: Text(
          trailing,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
