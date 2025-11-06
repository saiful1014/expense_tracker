import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/expense.dart';
import '../models/borrow_lend.dart';
import 'connectivity_service.dart';

class CloudSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final ConnectivityService _connectivity = ConnectivityService.instance;

  String? get userId => _auth.currentUser?.uid;
  User? get currentUser => _auth.currentUser;

  Future<bool> _checkConnectivity() async {
    return await _connectivity.hasInternetConnection();
  }

  // Expense methods
  Future<void> syncExpenseToCloud(Expense expense) async {
    if (userId == null) return;
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection');
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .doc(expense.id?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString())
        .set({
      'description': expense.description,
      'amount': expense.amount,
      'date': expense.date.toIso8601String(),
      'category': expense.category,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteExpenseFromCloud(int expenseId) async {
    if (userId == null) return;
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection');
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .doc(expenseId.toString())
        .delete();
  }

  Future<List<Expense>> getExpensesFromCloud() async {
    if (userId == null) return [];
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection');
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Expense(
        id: int.tryParse(doc.id),
        description: data['description'] as String,
        amount: data['amount'] as double,
        date: DateTime.parse(data['date'] as String),
        category: data['category'] as String,
      );
    }).toList();
  }

  // Borrow/Lend methods
  Future<void> syncBorrowLendToCloud(BorrowLend borrowLend) async {
    if (userId == null) return;
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection');
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('borrow_lend')
        .doc(borrowLend.id?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString())
        .set({
      'person_name': borrowLend.personName,
      'amount': borrowLend.amount,
      'date': borrowLend.date.toIso8601String(),
      'type': borrowLend.type,
      'description': borrowLend.description,
      'completed': borrowLend.completed,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteBorrowLendFromCloud(int id) async {
    if (userId == null) return;
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection');
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('borrow_lend')
        .doc(id.toString())
        .delete();
  }

  Future<List<BorrowLend>> getBorrowLendFromCloud() async {
    if (userId == null) return [];
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection');
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('borrow_lend')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return BorrowLend(
        id: int.tryParse(doc.id),
        personName: data['person_name'] as String,
        amount: data['amount'] as double,
        date: DateTime.parse(data['date'] as String),
        type: data['type'] as String,
        description: data['description'] as String?,
        completed: data['completed'] as bool? ?? false,
      );
    }).toList();
  }

  // Auth methods
  Future<bool> signInWithGoogle() async {
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection');
    }
    
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        return false;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      await _auth.signInWithCredential(credential);
      return true;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return false;
    }
  }

  Future<bool> isSignedIn() async {
    return _auth.currentUser != null;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  String? getUserEmail() {
    return _auth.currentUser?.email;
  }

  String? getUserName() {
    return _auth.currentUser?.displayName;
  }

  String? getUserPhotoUrl() {
    return _auth.currentUser?.photoURL;
  }
}

