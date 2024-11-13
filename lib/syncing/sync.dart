import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:expensetracker/helpers/database.dart';
import 'package:expensetracker/models/expense.dart';

class FirebaseSyncService {
  final AppDatabase _localDb = AppDatabase.instance;

  Future<void> syncFromFirebase() async {
    final firebaseItems =
        await FirebaseFirestore.instance.collection('expenses').get();

    for (var doc in firebaseItems.docs) {
      final firebaseExpense = Expense(
        id: int.parse(doc.id),
        title: doc['title'],
        amount: doc['amount'],
        date: DateTime.fromMillisecondsSinceEpoch(doc['date']),
        lastModified: DateTime.fromMillisecondsSinceEpoch(doc['lastModified']),
      );

      final localExpense = await _localDb.getExpense(firebaseExpense.id!);

      if (localExpense == null) {
        await _localDb.createExpense(firebaseExpense);
      } else if (firebaseExpense.lastModified
          .isAfter(localExpense.lastModified)) {
        await _localDb.updateExpense(firebaseExpense);
      }
    }
  }

  Future<void> syncToFirebase() async {
    final localItems = await _localDb.getAllExpenses();
    final firebaseCollection =
        FirebaseFirestore.instance.collection('expenses');

    for (var item in localItems) {
      final firebaseDoc =
          await firebaseCollection.doc(item.id.toString()).get();

      if (!firebaseDoc.exists) {
        await firebaseCollection.doc(item.id.toString()).set({
          'title': item.title,
          'amount': item.amount,
          'date': item.date.millisecondsSinceEpoch,
          'lastModified': item.lastModified.millisecondsSinceEpoch,
        });
      } else {
        final firebaseModified =
            DateTime.fromMillisecondsSinceEpoch(firebaseDoc['lastModified']);
        if (item.lastModified.isAfter(firebaseModified)) {
          await firebaseCollection.doc(item.id.toString()).update({
            'title': item.title,
            'amount': item.amount,
            'date': item.date.millisecondsSinceEpoch,
            'lastModified': item.lastModified.millisecondsSinceEpoch,
          });
        }
      }
    }
  }

  Future<void> checkAndSync() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      await syncFromFirebase();
      await syncToFirebase();
    } else {
      // Handle offline mode (e.g., queue actions to sync later)
    }
  }

  Timer? syncTimer;

  void startSyncing() {
    syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await checkAndSync();
    });
  }

  void stopSyncing() {
    syncTimer?.cancel();
  }
}
