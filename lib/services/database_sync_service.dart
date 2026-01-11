import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import '../models/box_model.dart';
import '../models/item_model.dart';
import '../config/demo_config.dart';

/// Service to sync Firebase data with MySQL backend
/// This ensures both databases stay in sync
class DatabaseSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Dio _dio = Dio();
  
  // Your XAMPP backend URL
  final String _baseUrl = 'http://localhost/Lost-and-Found-IOT/backend/api';

  /// Sync box status from Firebase to MySQL
  Future<bool> syncBoxToMySQL(BoxModel box) async {
    if (DemoConfig.demoMode) {
      print('📦 Demo mode: Skipping MySQL sync');
      return true;
    }

    try {
      final response = await _dio.post(
        '$_baseUrl/boxes/sync',
        data: {
          'box_id': box.id,
          'box_name': box.name,
          'location': box.location,
          'status': box.isAvailable ? 'available' : 'occupied',
          'current_item_id': box.currentItemId,
        },
      );

      if (response.statusCode == 200) {
        print('✅ Box ${box.id} synced to MySQL');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error syncing box to MySQL: $e');
      return false;
    }
  }

  /// Sync all boxes from Firebase to MySQL
  Future<void> syncAllBoxesToMySQL() async {
    if (DemoConfig.demoMode) {
      print('📦 Demo mode: Skipping MySQL sync');
      return;
    }

    try {
      final snapshot = await _firestore.collection('boxes').get();
      
      for (var doc in snapshot.docs) {
        final box = BoxModel.fromMap(doc.data(), doc.id);
        await syncBoxToMySQL(box);
      }
      
      print('✅ All boxes synced to MySQL');
    } catch (e) {
      print('❌ Error syncing boxes: $e');
    }
  }

  /// Sync item from Firebase to MySQL
  Future<bool> syncItemToMySQL(ItemModel item) async {
    if (DemoConfig.demoMode) {
      print('📦 Demo mode: Skipping MySQL sync');
      return true;
    }

    try {
      final response = await _dio.post(
        '$_baseUrl/items/sync',
        data: {
          'item_id': item.id,
          'title': item.title,
          'description': item.description,
          'founder_id': item.founderId,
          'founder_name': item.founderName,
          'box_id': item.boxId,
          'location': item.location,
          'status': item.status,
          'device_id': item.deviceId,
        },
      );

      if (response.statusCode == 200) {
        print('✅ Item ${item.id} synced to MySQL');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error syncing item to MySQL: $e');
      return false;
    }
  }

  /// Listen to Firebase changes and auto-sync to MySQL
  void startAutoSync() {
    if (DemoConfig.demoMode) {
      print('📦 Demo mode: Auto-sync disabled');
      return;
    }

    // Listen to box changes
    _firestore.collection('boxes').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified ||
            change.type == DocumentChangeType.added) {
          final box = BoxModel.fromMap(
            change.doc.data()!,
            change.doc.id,
          );
          syncBoxToMySQL(box);
        }
      }
    });

    // Listen to item changes
    _firestore.collection('items').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified ||
            change.type == DocumentChangeType.added) {
          final item = ItemModel.fromMap(
            change.doc.data()!,
            change.doc.id,
          );
          syncItemToMySQL(item);
        }
      }
    });

    print('🔄 Database auto-sync started (Firebase → MySQL)');
  }

  /// Verify sync status between Firebase and MySQL
  Future<Map<String, dynamic>> verifySyncStatus() async {
    if (DemoConfig.demoMode) {
      return {
        'status': 'demo_mode',
        'firebase_boxes': 2,
        'mysql_boxes': 2,
        'in_sync': true,
      };
    }

    try {
      // Get Firebase box count
      final firebaseSnapshot = await _firestore.collection('boxes').get();
      final firebaseCount = firebaseSnapshot.docs.length;

      // Get MySQL box count
      final response = await _dio.get('$_baseUrl/boxes/count');
      final mysqlCount = response.data['count'] ?? 0;

      final inSync = firebaseCount == mysqlCount;

      return {
        'status': inSync ? 'synced' : 'out_of_sync',
        'firebase_boxes': firebaseCount,
        'mysql_boxes': mysqlCount,
        'in_sync': inSync,
      };
    } catch (e) {
      print('❌ Error verifying sync: $e');
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }
}
