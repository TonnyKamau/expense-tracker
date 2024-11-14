import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:expensetracker/helpers/database.dart';
import 'package:expensetracker/models/expense.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseSyncService {
  final AppDatabase _localDb = AppDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Function()? onSyncComplete;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Timer? _syncTimer;
  bool _isSyncing = false;

  FirebaseSyncService() {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> requestNotificationPermission() async {
    await _firebaseMessaging.requestPermission();
    final token = await _firebaseMessaging.getToken();
    if (token != null) print('FCM Token: $token');
  }

  Future<void> syncFromFirebase() async {
    _isSyncing = true;
    final firebaseItems = await _firestore.collection('expenses').get();
    final localItems = await _localDb.getAllExpenses();
    final Map<int, Expense> localMap = {for (var e in localItems) e.id!: e};
    final totalItems = firebaseItems.docs.length;

    int progress = 0;
    for (var doc in firebaseItems.docs) {
      final firebaseExpense = _mapFirestoreDocToExpense(doc);
      final localExpense = localMap[firebaseExpense.id];

      if (localExpense == null) {
        await _localDb.createExpense(firebaseExpense);
      } else if (firebaseExpense.lastModified
          .isAfter(localExpense.lastModified)) {
        await _localDb.updateExpense(firebaseExpense);
      }

      progress++;
      if (progress % 10 == 0) {
        await _showProgressNotification(progress, totalItems);
      }
    }

    _isSyncing = false;
    await _notificationsPlugin.cancel(0);
  }

  Future<void> syncToFirebase() async {
    _isSyncing = true;
    final localItems = await _localDb.getAllExpenses();
    final expensesCollection = _firestore.collection('expenses');
    final totalItems = localItems.length;

    int progress = 0;
    for (var expense in localItems) {
      await _syncExpenseWithFirebase(expense, expensesCollection);
      progress++;
      if (progress % 10 == 0) {
        await _showProgressNotification(progress, totalItems);
      }
    }

    _isSyncing = false;
    await _notificationsPlugin.cancel(0);
  }

  Expense _mapFirestoreDocToExpense(QueryDocumentSnapshot doc) {
    return Expense(
      id: int.parse(doc.id),
      title: doc['title'],
      amount: doc['amount'],
      date: DateTime.fromMillisecondsSinceEpoch(doc['date']),
      lastModified: DateTime.fromMillisecondsSinceEpoch(doc['lastModified']),
    );
  }

  Future<void> _syncExpenseWithFirebase(
      Expense expense, CollectionReference expensesCollection) async {
    try {
      final docRef = expensesCollection.doc(expense.id.toString());
      final firebaseDoc = await docRef.get();

      if (!firebaseDoc.exists) {
        await docRef.set({
          'title': expense.title,
          'amount': expense.amount,
          'date': expense.date.millisecondsSinceEpoch,
          'lastModified': expense.lastModified.millisecondsSinceEpoch,
        });
      } else {
        final firebaseModified =
            DateTime.fromMillisecondsSinceEpoch(firebaseDoc['lastModified']);
        if (expense.lastModified.isAfter(firebaseModified)) {
          await docRef.update({
            'title': expense.title,
            'amount': expense.amount,
            'date': expense.date.millisecondsSinceEpoch,
            'lastModified': expense.lastModified.millisecondsSinceEpoch,
          });
        }
      }
    } catch (e) {
      print('Error syncing expense ID: ${expense.id}, Error: $e');
    }
  }

  Future<void> _showProgressNotification(int progress, int total) async {
    if (!_isSyncing) return;

    final androidDetails = AndroidNotificationDetails(
      'sync_channel',
      'Syncing Data',
      channelDescription: 'Shows the sync progress with Firebase',
      importance: Importance.max,
      priority: Priority.high,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: total,
      progress: progress,
    );
    final notificationDetails = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(0, 'Syncing Expenses',
        'Syncing data with Firebase', notificationDetails);
  }

  Future<void> checkAndSync() async {
    if (await Connectivity().checkConnectivity() != ConnectivityResult.none) {
      await syncFromFirebase();
      await syncToFirebase();
      onSyncComplete?.call();
    }
  }

  void startSyncing() {
    _syncTimer = Timer.periodic(
        const Duration(minutes: 5), (_) async => await checkAndSync());
  }

  void stopSyncing() => _syncTimer?.cancel();
}
