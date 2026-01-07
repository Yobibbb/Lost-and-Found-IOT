import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/demo_config.dart';
import '../config/mock_data.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _currentUser;

  // Get current user
  UserModel? get currentUser => _currentUser;

  // Sign in with email and password
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    if (DemoConfig.demoMode) {
      // Demo mode
      await MockData.mockDelay();
      final isFounder = email.contains('founder');
      _currentUser = isFounder ? MockData.mockFounder : MockData.mockFinder;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', _currentUser!.uid);
      await prefs.setBool('demoMode', true);
      
      notifyListeners();
      return {'success': true, 'user': _currentUser};
    }
    
    // Firebase mode
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      _currentUser = UserModel.fromMap(userDoc.data()!, userDoc.id);
      
      notifyListeners();
      return {'success': true, 'user': _currentUser};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Sign up with email and password
  Future<Map<String, dynamic>> signUp(
    String email,
    String password,
    String displayName,
  ) async {
    if (DemoConfig.demoMode) {
      // Demo mode
      await MockData.mockDelay();
      _currentUser = UserModel(
        uid: 'demo-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: displayName,
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', _currentUser!.uid);
      await prefs.setBool('demoMode', true);
      
      notifyListeners();
      return {'success': true, 'user': _currentUser};
    }
    
    // Firebase mode
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _currentUser = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        displayName: displayName,
      );
      
      // Save user to Firestore
      await _firestore.collection('users').doc(_currentUser!.uid).set({
        'email': email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      notifyListeners();
      return {'success': true, 'user': _currentUser};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Sign out
  Future<void> signOut() async {
    if (!DemoConfig.demoMode) {
      await _firebaseAuth.signOut();
    }
    
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    notifyListeners();
  }

  // Check if user is signed in
  bool isSignedIn() {
    return _currentUser != null;
  }
}
