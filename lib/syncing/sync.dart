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
    await _notificationsPlugin.show(
      0,
      'Syncing Expenses',
      'Syncing data with Firebase',
      notificationDetails,
    );
  }

  Future<void> requestNotificationPermission() async {
    await _firebaseMessaging.requestPermission();
    final token = await _firebaseMessaging.getToken();
    if (token != null) print('FCM Token: $token');
  }

  // Compare local and Firebase records to find differences
  Future<Map<String, List<Expense>>> _compareRecords() async {
    final localExpenses = await _localDb.getAllExpenses();
    final firebaseSnapshot = await _firestore.collection('expenses').get();

    final Map<int, Expense> localMap = {
      for (var expense in localExpenses) expense.id!: expense
    };
    final Map<int, Expense> firebaseMap = {
      for (var doc in firebaseSnapshot.docs)
        int.parse(doc.id): _mapFirestoreDocToExpense(doc)
    };

    final toUpdate = <Expense>[];
    final toCreate = <Expense>[];

    // Check for updates and new records
    firebaseMap.forEach((id, firebaseExpense) {
      final localExpense = localMap[id];
      if (localExpense == null) {
        toCreate.add(firebaseExpense);
      } else if (firebaseExpense.lastModified
          .isAfter(localExpense.lastModified)) {
        toUpdate.add(firebaseExpense);
      }
    });

    // Check for local records that need to be pushed to Firebase
    localMap.forEach((id, localExpense) {
      final firebaseExpense = firebaseMap[id];
      if (firebaseExpense == null ||
          localExpense.lastModified.isAfter(firebaseExpense.lastModified)) {
        toUpdate.add(localExpense);
      }
    });

    return {
      'create': toCreate,
      'update': toUpdate,
    };
  }

  Future<void> syncFromFirebase() async {
    _isSyncing = true;
    final differences = await _compareRecords();
    final toCreate = differences['create'] ?? [];
    final toUpdate = differences['update'] ?? [];
    final totalItems = toCreate.length + toUpdate.length;

    if (totalItems == 0) {
      _isSyncing = false;
      await _notificationsPlugin.cancel(0);
      return;
    }

    var progress = 0;

    // Handle new records
    for (var expense in toCreate) {
      await _localDb.createExpense(expense);
      progress++;
      await _showProgressNotification(progress, totalItems);
    }

    // Handle updates
    for (var expense in toUpdate) {
      await _localDb.updateExpense(expense);
      progress++;
      await _showProgressNotification(progress, totalItems);
    }

    _isSyncing = false;
    await _notificationsPlugin.cancel(0);
  }

  Future<void> syncToFirebase() async {
    _isSyncing = true;
    final differences = await _compareRecords();
    final toUpdate = differences['update'] ?? [];

    if (toUpdate.isEmpty) {
      _isSyncing = false;
      await _notificationsPlugin.cancel(0);
      return;
    }

    final expensesCollection = _firestore.collection('expenses');

    for (var i = 0; i < toUpdate.length; i++) {
      await _syncExpenseWithFirebase(toUpdate[i], expensesCollection);
      await _showProgressNotification(i + 1, toUpdate.length);
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
      final data = {
        'title': expense.title,
        'amount': expense.amount,
        'date': expense.date.millisecondsSinceEpoch,
        'lastModified': expense.lastModified.millisecondsSinceEpoch,
      };

      if (!firebaseDoc.exists) {
        await docRef.set(data);
      } else {
        await docRef.update(data);
      }
    } catch (e) {
      print('Error syncing expense ID: ${expense.id}, Error: $e');
    }
  }

  Future<void> checkAndSync() async {
    if (await Connectivity().checkConnectivity() != ConnectivityResult.none) {
      await syncFromFirebase();
      await syncToFirebase();
    }
  }

  void startSyncing() {
    _syncTimer = Timer.periodic(
        const Duration(minutes: 5), (_) async => await checkAndSync());
  }

  void stopSyncing() => _syncTimer?.cancel();
}
