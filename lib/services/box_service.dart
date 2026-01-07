import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/box_model.dart';
import '../config/demo_config.dart';

class BoxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Demo mode data
  static final List<BoxModel> _demoBoxes = [
    BoxModel(
      id: 'BOX_A1',
      name: 'Box A1',
      location: 'Building A, Floor 1, Near Main Entrance',
      isAvailable: true,
      isLocked: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastUpdated: DateTime.now(),
    ),
    BoxModel(
      id: 'BOX_A2',
      name: 'Box A2',
      location: 'Building A, Floor 2, Near Cafeteria',
      isAvailable: true,
      isLocked: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastUpdated: DateTime.now(),
    ),
  ];

  // Get all boxes
  Future<List<BoxModel>> getAllBoxes() async {
    if (DemoConfig.demoMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return List.from(_demoBoxes);
    }

    try {
      final snapshot = await _firestore.collection('boxes').get();
      return snapshot.docs
          .map((doc) => BoxModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error fetching boxes: $e');
      return [];
    }
  }

  // Get available boxes only
  Future<List<BoxModel>> getAvailableBoxes() async {
    if (DemoConfig.demoMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _demoBoxes.where((box) => box.isAvailable).toList();
    }

    try {
      final snapshot = await _firestore
          .collection('boxes')
          .where('isAvailable', isEqualTo: true)
          .get();
      
      return snapshot.docs
          .map((doc) => BoxModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error fetching available boxes: $e');
      return [];
    }
  }

  // Get box by ID
  Future<BoxModel?> getBoxById(String boxId) async {
    if (DemoConfig.demoMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      try {
        return _demoBoxes.firstWhere((box) => box.id == boxId);
      } catch (e) {
        return null;
      }
    }

    try {
      final doc = await _firestore.collection('boxes').doc(boxId).get();
      if (!doc.exists) return null;
      return BoxModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('❌ Error fetching box: $e');
      return null;
    }
  }

  // Mark box as occupied (when item is stored)
  Future<bool> occupyBox(String boxId, String itemId) async {
    if (DemoConfig.demoMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      final index = _demoBoxes.indexWhere((box) => box.id == boxId);
      if (index != -1) {
        _demoBoxes[index] = _demoBoxes[index].copyWith(
          isAvailable: false,
          currentItemId: itemId,
          lastUpdated: DateTime.now(),
        );
        return true;
      }
      return false;
    }

    try {
      await _firestore.collection('boxes').doc(boxId).update({
        'isAvailable': false,
        'currentItemId': itemId,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('❌ Error occupying box: $e');
      return false;
    }
  }

  // Mark box as available (when item is retrieved)
  Future<bool> releaseBox(String boxId) async {
    if (DemoConfig.demoMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      final index = _demoBoxes.indexWhere((box) => box.id == boxId);
      if (index != -1) {
        _demoBoxes[index] = _demoBoxes[index].copyWith(
          isAvailable: true,
          currentItemId: null,
          lastUpdated: DateTime.now(),
        );
        return true;
      }
      return false;
    }

    try {
      await _firestore.collection('boxes').doc(boxId).update({
        'isAvailable': true,
        'currentItemId': null,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('❌ Error releasing box: $e');
      return false;
    }
  }

  // Update box lock status
  Future<bool> updateBoxLockStatus(String boxId, bool isLocked) async {
    if (DemoConfig.demoMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      final index = _demoBoxes.indexWhere((box) => box.id == boxId);
      if (index != -1) {
        _demoBoxes[index] = _demoBoxes[index].copyWith(
          isLocked: isLocked,
          lastUpdated: DateTime.now(),
        );
        return true;
      }
      return false;
    }

    try {
      await _firestore.collection('boxes').doc(boxId).update({
        'isLocked': isLocked,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('❌ Error updating box lock status: $e');
      return false;
    }
  }

  // Stream box status (for real-time updates)
  Stream<BoxModel?> streamBoxStatus(String boxId) {
    if (DemoConfig.demoMode) {
      // In demo mode, return a stream that emits the current state
      return Stream.periodic(const Duration(seconds: 1), (_) {
        try {
          return _demoBoxes.firstWhere((box) => box.id == boxId);
        } catch (e) {
          return null;
        }
      });
    }

    return _firestore.collection('boxes').doc(boxId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return BoxModel.fromMap(doc.data()!, doc.id);
    });
  }

  // Initialize boxes in Firebase (for first-time setup)
  Future<void> initializeBoxes() async {
    if (DemoConfig.demoMode) {
      print('📦 Demo mode: Boxes already initialized');
      return;
    }

    try {
      final boxes = [
        {'id': 'BOX_A1', 'name': 'Box A1', 'location': 'Building A, Floor 1, Near Main Entrance'},
        {'id': 'BOX_A2', 'name': 'Box A2', 'location': 'Building A, Floor 2, Near Cafeteria'},
      ];

      for (var box in boxes) {
        final docRef = _firestore.collection('boxes').doc(box['id']);
        final docSnapshot = await docRef.get();
        
        if (!docSnapshot.exists) {
          await docRef.set({
            'name': box['name'],
            'location': box['location'],
            'isAvailable': true,
            'isLocked': true,
            'currentItemId': null,
            'createdAt': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
          print('✅ Created box: ${box['id']}');
        }
      }
      
      print('✅ Boxes initialization complete');
    } catch (e) {
      print('❌ Error initializing boxes: $e');
    }
  }
}
