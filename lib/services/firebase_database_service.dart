import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../config/demo_config.dart';
import '../config/mock_data.dart';
import '../models/item_model.dart';
import '../models/request_model.dart';
import '../models/notification_model.dart';
import '../models/chat_model.dart';
import 'auth_service.dart';
import 'box_service.dart';

class FirebaseDatabaseService {
  final AuthService _authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BoxService _boxService = BoxService();
  
  // Demo mode state (for backward compatibility)
  final List<ItemModel> _demoItems = List.from(MockData.mockItems);
  final List<RequestModel> _demoRequests = List.from(MockData.mockRequests);
  final List<NotificationModel> _demoNotifications = [];
  final List<ChatRoomModel> _demoChatRooms = [];
  final List<ChatMessageModel> _demoChatMessages = [];
  final Map<String, StreamController> _demoControllers = {};

  FirebaseDatabaseService(this._authService);

  // ============ ITEMS ============

  // Create item
  Future<Map<String, dynamic>> createItem({
    required String title,
    required String description,
    required String boxId,
    required String location,
    String? deviceId,
  }) async {
    if (DemoConfig.demoMode) {
      // Demo mode logic
      await MockData.mockDelay();
      final user = _authService.currentUser!;
      final itemId = const Uuid().v4();
      final newItem = ItemModel(
        id: itemId,
        title: title,
        description: description,
        founderId: user.uid,
        founderName: user.displayName ?? 'Demo User',
        founderEmail: user.email ?? '',
        boxId: boxId,
        location: location,
        deviceId: deviceId,
        status: 'pending_storage',
        timestamp: DateTime.now(),
        createdAt: DateTime.now(),
      );
      
      _demoItems.add(newItem);
      
      // Mark box as reserved/occupied immediately
      await _boxService.occupyBox(boxId, itemId);
      
      return {'success': true, 'itemId': newItem.id};
    }
    
    // Firebase mode
    try {
      final user = _authService.currentUser!;
      final itemRef = _firestore.collection('items').doc();
      
      await itemRef.set({
        'title': title,
        'description': description,
        'founderId': user.uid,
        'founderName': user.displayName ?? 'User',
        'founderEmail': user.email ?? '',
        'boxId': boxId,
        'location': location,
        'deviceId': deviceId,
        'status': 'pending_storage',
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Mark box as reserved/occupied immediately
      await _boxService.occupyBox(boxId, itemRef.id);
      
      return {'success': true, 'itemId': itemRef.id};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Update item status (and manage box availability)
  Future<Map<String, dynamic>> updateItemStatus(String itemId, String newStatus) async {
    if (DemoConfig.demoMode) {
      await MockData.mockDelay();
      final index = _demoItems.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        final item = _demoItems[index];
        
        // Update box availability based on status
        if (newStatus == 'waiting') {
          // Item stored in box - mark box as occupied
          await _boxService.occupyBox(item.boxId, itemId);
        } else if (newStatus == 'claimed') {
          // Item claimed/retrieved - release the box
          await _boxService.releaseBox(item.boxId);
        }
        
        return {'success': true};
      }
      return {'success': false, 'error': 'Item not found'};
    }

    try {
      // Get the item to know which box it's in
      final itemDoc = await _firestore.collection('items').doc(itemId).get();
      if (!itemDoc.exists) {
        return {'success': false, 'error': 'Item not found'};
      }
      
      final item = ItemModel.fromMap(itemDoc.data()!, itemId);
      
      // Update item status
      await _firestore.collection('items').doc(itemId).update({
        'status': newStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Update box availability based on status
      if (newStatus == 'waiting') {
        // Item stored in box - mark box as occupied
        await _boxService.occupyBox(item.boxId, itemId);
      } else if (newStatus == 'claimed') {
        // Item claimed/retrieved - release the box
        await _boxService.releaseBox(item.boxId);
      }
      
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Search items
  Future<List<ItemModel>> searchItems(String searchText) async {
    if (DemoConfig.demoMode) {
      await MockData.mockDelay();
      final currentUserId = _authService.currentUser?.uid;
      final lowerSearch = searchText.toLowerCase();
      return _demoItems.where((item) {
        // Exclude items posted by current user
        return item.founderId != currentUserId &&
            (item.status == 'waiting' || item.status == 'pending_storage') &&
            (item.title.toLowerCase().contains(lowerSearch) ||
             item.description.toLowerCase().contains(lowerSearch));
      }).toList();
    }
    
    // Firebase mode - search for items that are waiting OR pending_storage (for testing)
    try {
      final currentUserId = _authService.currentUser?.uid;
      final snapshot = await _firestore
          .collection('items')
          .where('status', whereIn: ['waiting', 'pending_storage'])
          .get();
      
      final lowerSearch = searchText.toLowerCase();
      final items = snapshot.docs
          .map((doc) => ItemModel.fromMap(doc.data(), doc.id))
          .where((item) =>
              // Exclude items posted by current user
              item.founderId != currentUserId &&
              (item.title.toLowerCase().contains(lowerSearch) ||
               item.description.toLowerCase().contains(lowerSearch)))
          .toList();
      
      return items;
    } catch (e) {
      print('❌ Error searching items: $e');
      return [];
    }
  }

  // Get a single item by ID
  Future<ItemModel?> getItemById(String itemId) async {
    if (DemoConfig.demoMode) {
      await MockData.mockDelay();
      try {
        return _demoItems.firstWhere((item) => item.id == itemId);
      } catch (e) {
        return null;
      }
    }
    
    // Firebase mode
    try {
      final doc = await _firestore.collection('items').doc(itemId).get();
      if (!doc.exists) return null;
      return ItemModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('❌ Error fetching item: $e');
      return null;
    }
  }

  // Get items submitted by a specific founder
  Future<List<ItemModel>> getFounderItems(String founderId) async {
    if (DemoConfig.demoMode) {
      await MockData.mockDelay();
      return _demoItems.where((item) => item.founderId == founderId).toList();
    }
    
    // Firebase mode
    try {
      print('🔍 Fetching items for founder: $founderId');
      
      final snapshot = await _firestore
          .collection('items')
          .where('founderId', isEqualTo: founderId)
          .get();
      
      print('📦 Found ${snapshot.docs.length} items');
      
      final items = snapshot.docs
          .map((doc) {
            print('📄 Item doc: ${doc.id} - ${doc.data()}');
            return ItemModel.fromMap(doc.data(), doc.id);
          })
          .toList();
      
      // Sort by createdAt manually (to avoid index requirement)
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return items;
    } catch (e) {
      print('❌ Error fetching founder items: $e');
      return [];
    }
  }

  // ============ REQUESTS ============

  // Create request
  Future<Map<String, dynamic>> createRequest({
    required String itemId,
    required String finderDescription,
  }) async {
    if (DemoConfig.demoMode) {
      // Demo mode logic
      await MockData.mockDelay();
      final user = _authService.currentUser!;
      final newRequest = RequestModel(
        id: const Uuid().v4(),
        itemId: itemId,
        finderId: user.uid,
        finderName: user.displayName ?? 'Demo User',
        finderEmail: user.email ?? '',
        finderDescription: finderDescription,
        status: 'pending',
        timestamp: DateTime.now(),
        createdAt: DateTime.now(),
      );
      
      _demoRequests.add(newRequest);
      
      final item = _demoItems.firstWhere((i) => i.id == itemId);
      await _createNotification(
        userId: item.founderId,
        title: 'New retrieval request',
        message: '${user.displayName} requested your found item: ${item.title}',
        type: 'request_received',
        relatedId: newRequest.id,
      );
      
      final key = 'item_requests_$itemId';
      if (_demoControllers.containsKey(key)) {
        final requests = _demoRequests.where((r) => r.itemId == itemId).toList();
        _demoControllers[key]!.add(requests);
      }
      
      // Create or get chat room (without sending initial message)
      await createOrGetChatRoom(
        itemId: itemId,
        founderId: item.founderId,
        founderName: item.founderName,
        finderId: user.uid,
        finderName: user.displayName ?? 'Demo User',
        itemTitle: item.title,
      );
      
      return {'success': true, 'requestId': newRequest.id};
    }
    
    // Firebase mode
    try {
      final user = _authService.currentUser!;
      final requestRef = _firestore.collection('requests').doc();
      
      print('📝 Creating request for item: $itemId');
      print('👤 Finder: ${user.uid} (${user.displayName})');
      
      await requestRef.set({
        'itemId': itemId,
        'finderId': user.uid,
        'finderName': user.displayName ?? 'User',
        'finderEmail': user.email ?? '',
        'finderDescription': finderDescription,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Request created with ID: ${requestRef.id}');
      
      // Get item for notification
      final itemDoc = await _firestore.collection('items').doc(itemId).get();
      final item = ItemModel.fromMap(itemDoc.data()!, itemDoc.id);
      
      // Create notification
      await _firestore.collection('notifications').add({
        'userId': item.founderId,
        'title': 'New retrieval request',
        'message': '${user.displayName} requested your found item: ${item.title}',
        'type': 'request_received',
        'relatedId': requestRef.id,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('🔔 Notification sent to founder');
      
      // Create or get chat room (without sending initial message)
      print('💬 Creating chat room...');
      await createOrGetChatRoom(
        itemId: itemId,
        founderId: item.founderId,
        founderName: item.founderName,
        finderId: user.uid,
        finderName: user.displayName ?? 'User',
        itemTitle: item.title,
      );
      
      print('✅ Chat room created/retrieved');
      
      return {'success': true, 'requestId': requestRef.id};
    } catch (e) {
      print('❌ Error creating request: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get requests submitted by a specific finder
  Future<List<RequestModel>> getFinderRequests(String finderId) async {
    print('🔍 Fetching requests for finder: $finderId');
    
    if (DemoConfig.demoMode) {
      await MockData.mockDelay();
      return _demoRequests.where((req) => req.finderId == finderId).toList();
    }
    
    // Firebase mode
    try {
      print('📡 Querying Firestore for finder requests...');
      final snapshot = await _firestore
          .collection('requests')
          .where('finderId', isEqualTo: finderId)
          .get(); // Temporarily removed orderBy to avoid index requirement
      
      print('📦 Found ${snapshot.docs.length} requests');
      
      final requests = snapshot.docs
          .map((doc) {
            print('📄 Request doc: ${doc.id}');
            return RequestModel.fromMap(doc.data(), doc.id);
          })
          .toList();
      
      // Manual sorting by createdAt
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return requests;
    } catch (e) {
      print('❌ Error fetching finder requests: $e');
      return [];
    }
  }

  // Update request status
  Future<Map<String, dynamic>> updateRequestStatus(
    String requestId,
    String status,
  ) async {
    if (DemoConfig.demoMode) {
      // Demo mode logic
      await MockData.mockDelay();
      final index = _demoRequests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        final request = _demoRequests[index];
        final updatedRequest = request.copyWith(
          status: status,
          approvedAt: status == 'approved' ? DateTime.now() : null,
          rejectedAt: status == 'rejected' ? DateTime.now() : null,
        );
        _demoRequests[index] = updatedRequest;
        
        final item = _demoItems.firstWhere((i) => i.id == request.itemId);
        
        if (status == 'approved') {
          // Update item status to 'to_collect'
          await updateItemStatus(item.id, 'to_collect');
          
          await _createNotification(
            userId: request.finderId,
            title: 'Request Approved! ✅',
            message: 'Your request for "${item.title}" has been approved! You can now retrieve it.',
            type: 'request_approved',
            relatedId: requestId,
          );
        } else if (status == 'rejected') {
          await _createNotification(
            userId: request.finderId,
            title: 'Request Rejected',
            message: 'Your request for "${item.title}" was not approved.',
            type: 'request_rejected',
            relatedId: requestId,
          );
        }
        
        final key = 'request_$requestId';
        if (_demoControllers.containsKey(key)) {
          _demoControllers[key]!.add(_demoRequests[index]);
        }
      }
      
      return {'success': true};
    }
    
    // Firebase mode
    try {
      final requestDoc = await _firestore.collection('requests').doc(requestId).get();
      final request = RequestModel.fromMap(requestDoc.data()!, requestDoc.id);
      
      await _firestore.collection('requests').doc(requestId).update({
        'status': status,
        if (status == 'approved') 'approvedAt': FieldValue.serverTimestamp(),
        if (status == 'rejected') 'rejectedAt': FieldValue.serverTimestamp(),
      });
      
      // Get item for notification
      final itemDoc = await _firestore.collection('items').doc(request.itemId).get();
      final item = ItemModel.fromMap(itemDoc.data()!, itemDoc.id);
      
      // Update item status to 'to_collect' when request is approved
      if (status == 'approved') {
        await updateItemStatus(item.id, 'to_collect');
      }
      
      // Create notification
      if (status == 'approved') {
        await _firestore.collection('notifications').add({
          'userId': request.finderId,
          'title': 'Request Approved! ✅',
          'message': 'Your request for "${item.title}" has been approved! You can now retrieve it.',
          'type': 'request_approved',
          'relatedId': requestId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else if (status == 'rejected') {
        await _firestore.collection('notifications').add({
          'userId': request.finderId,
          'title': 'Request Rejected',
          'message': 'Your request for "${item.title}" was not approved.',
          'type': 'request_rejected',
          'relatedId': requestId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Stream item requests (for founder)
  Stream<List<RequestModel>> streamItemRequests(String itemId) {
    if (DemoConfig.demoMode) {
      final key = 'item_requests_$itemId';
      _demoControllers[key] = StreamController<List<RequestModel>>.broadcast();
      
      Future.delayed(const Duration(milliseconds: 100), () {
        final requests = _demoRequests.where((r) => r.itemId == itemId).toList();
        if (_demoControllers[key] != null && !_demoControllers[key]!.isClosed) {
          _demoControllers[key]!.add(requests);
        }
      });
      
      return _demoControllers[key]!.stream as Stream<List<RequestModel>>;
    }
    
    // Firebase mode
    return _firestore
        .collection('requests')
        .where('itemId', isEqualTo: itemId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get single request
  Future<RequestModel?> getRequest(String requestId) async {
    if (DemoConfig.demoMode) {
      await MockData.mockDelay();
      try {
        return _demoRequests.firstWhere((r) => r.id == requestId);
      } catch (e) {
        return null;
      }
    }
    
    // Firebase mode
    try {
      final doc = await _firestore.collection('requests').doc(requestId).get();
      if (!doc.exists) return null;
      return RequestModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  // Stream request status (for finder)
  Stream<RequestModel> streamRequest(String requestId) {
    if (DemoConfig.demoMode) {
      final key = 'request_$requestId';
      _demoControllers[key] = StreamController<RequestModel>.broadcast();
      
      Future.delayed(const Duration(milliseconds: 100), () {
        final request = _demoRequests.firstWhere((r) => r.id == requestId);
        if (_demoControllers[key] != null && !_demoControllers[key]!.isClosed) {
          _demoControllers[key]!.add(request);
        }
      });
      
      return _demoControllers[key]!.stream as Stream<RequestModel>;
    }
    
    // Firebase mode
    return _firestore
        .collection('requests')
        .doc(requestId)
        .snapshots()
        .map((doc) => RequestModel.fromMap(doc.data()!, doc.id));
  }

  // Cancel/Delete request (for finder to cancel their pending request)
  Future<Map<String, dynamic>> cancelRequest(String requestId) async {
    if (DemoConfig.demoMode) {
      await MockData.mockDelay();
      final index = _demoRequests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        final request = _demoRequests[index];
        
        // Only allow canceling pending requests
        if (request.status != 'pending') {
          return {'success': false, 'error': 'Only pending requests can be canceled'};
        }
        
        _demoRequests.removeAt(index);
        
        // Refresh streams
        final finderKey = 'finder_requests_${request.finderId}';
        if (_demoControllers.containsKey(finderKey)) {
          final finderRequests = _demoRequests
              .where((r) => r.finderId == request.finderId)
              .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _demoControllers[finderKey]!.add(finderRequests);
        }
        
        final itemKey = 'item_requests_${request.itemId}';
        if (_demoControllers.containsKey(itemKey)) {
          final itemRequests = _demoRequests.where((r) => r.itemId == request.itemId).toList();
          _demoControllers[itemKey]!.add(itemRequests);
        }
      }
      
      return {'success': true};
    }
    
    // Firebase mode
    try {
      final requestDoc = await _firestore.collection('requests').doc(requestId).get();
      if (!requestDoc.exists) {
        return {'success': false, 'error': 'Request not found'};
      }
      
      final request = RequestModel.fromMap(requestDoc.data()!, requestDoc.id);
      
      // Only allow canceling pending requests
      if (request.status != 'pending') {
        return {'success': false, 'error': 'Only pending requests can be canceled'};
      }
      
      await _firestore.collection('requests').doc(requestId).delete();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Delete item (for founder to delete items with "pending_storage" status)
  Future<Map<String, dynamic>> deleteItem(String itemId) async {
    if (DemoConfig.demoMode) {
      await MockData.mockDelay();
      final index = _demoItems.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        final item = _demoItems[index];
        
        // Only allow deleting items with "pending_storage" status
        if (item.status != 'pending_storage') {
          return {'success': false, 'error': 'Only items with "pending_storage" status can be deleted'};
        }
        
        // Check if there are any requests for this item
        final hasRequests = _demoRequests.any((r) => r.itemId == itemId);
        if (hasRequests) {
          return {'success': false, 'error': 'Cannot delete item with active requests'};
        }
        
        // Release the box if occupied
        await _boxService.releaseBox(item.boxId);
        
        _demoItems.removeAt(index);
        
        // Refresh streams
        final founderKey = 'founder_items_${item.founderId}';
        if (_demoControllers.containsKey(founderKey)) {
          final founderItems = _demoItems
              .where((i) => i.founderId == item.founderId)
              .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _demoControllers[founderKey]!.add(founderItems);
        }
        
        const allItemsKey = 'all_items';
        if (_demoControllers.containsKey(allItemsKey)) {
          final sortedItems = List<ItemModel>.from(_demoItems)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _demoControllers[allItemsKey]!.add(sortedItems);
        }
      }
      
      return {'success': true};
    }
    
    // Firebase mode
    try {
      final itemDoc = await _firestore.collection('items').doc(itemId).get();
      if (!itemDoc.exists) {
        return {'success': false, 'error': 'Item not found'};
      }
      
      final item = ItemModel.fromMap(itemDoc.data()!, itemDoc.id);
      
      // Only allow deleting items with "pending_storage" status
      if (item.status != 'pending_storage') {
        return {'success': false, 'error': 'Only items with "pending_storage" status can be deleted'};
      }
      
      // Check if there are any requests for this item
      final requestsSnapshot = await _firestore
          .collection('requests')
          .where('itemId', isEqualTo: itemId)
          .get();
      
      if (requestsSnapshot.docs.isNotEmpty) {
        return {'success': false, 'error': 'Cannot delete item with active requests'};
      }
      
      // Release the box if occupied
      await _boxService.releaseBox(item.boxId);
      
      await _firestore.collection('items').doc(itemId).delete();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============ NOTIFICATIONS ============

  // Create notification (internal method)
  Future<void> _createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    if (DemoConfig.demoMode) {
      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: userId,
        title: title,
        message: message,
        type: type,
        relatedId: relatedId,
        isRead: false,
        createdAt: DateTime.now(),
      );
      
      _demoNotifications.add(notification);
      
      final key = 'notifications_$userId';
      if (_demoControllers.containsKey(key)) {
        final userNotifications = _demoNotifications
            .where((n) => n.userId == userId)
            .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _demoControllers[key]!.add(userNotifications);
      }
    } else {
      // Firebase mode - already handled in calling methods
    }
  }

  // Get user notifications
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    if (DemoConfig.demoMode) {
      await MockData.mockDelay();
      return _demoNotifications
          .where((n) => n.userId == userId)
          .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    
    // Firebase mode
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();
      
      final notifications = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
          .toList();
      
      // Manual sorting to avoid composite index requirement
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return notifications;
    } catch (e) {
      return [];
    }
  }

  // Stream user notifications
  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    if (DemoConfig.demoMode) {
      final key = 'notifications_$userId';
      
      if (!_demoControllers.containsKey(key)) {
        _demoControllers[key] = StreamController<List<NotificationModel>>.broadcast();
      }
      
      Future.delayed(const Duration(milliseconds: 100), () {
        final notifications = _demoNotifications
            .where((n) => n.userId == userId)
            .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (_demoControllers[key] != null && !_demoControllers[key]!.isClosed) {
          _demoControllers[key]!.add(notifications);
        }
      });
      
      return _demoControllers[key]!.stream as Stream<List<NotificationModel>>;
    }
    
    // Firebase mode
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .toList();
          // Manual sorting to avoid composite index requirement
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notifications;
        });
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    if (DemoConfig.demoMode) {
      await MockData.mockDelay();
      final index = _demoNotifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final notification = _demoNotifications[index];
        _demoNotifications[index] = notification.copyWith(isRead: true);
        
        final key = 'notifications_${notification.userId}';
        if (_demoControllers.containsKey(key)) {
          final userNotifications = _demoNotifications
              .where((n) => n.userId == notification.userId)
              .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _demoControllers[key]!.add(userNotifications);
        }
      }
    } else {
      // Firebase mode
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    }
  }

  // Mark chat messages as read
  Future<void> markChatMessagesAsRead(String chatRoomId, String currentUserId) async {
    if (DemoConfig.demoMode) {
      // Mark all messages in this chat room that were sent by others as read
      for (int i = 0; i < _demoChatMessages.length; i++) {
        final msg = _demoChatMessages[i];
        if (msg.chatRoomId == chatRoomId && msg.senderId != currentUserId && !msg.isRead) {
          _demoChatMessages[i] = msg.copyWith(isRead: true);
        }
      }
      
      // Update the stream
      final key = 'chat_messages_$chatRoomId';
      if (_demoControllers.containsKey(key)) {
        final messages = _demoChatMessages
            .where((m) => m.chatRoomId == chatRoomId)
            .toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _demoControllers[key]!.add(messages);
      }
      
      // Update all user messages stream
      final allMsgKey = 'all_user_messages_$currentUserId';
      if (_demoControllers.containsKey(allMsgKey)) {
        final userRooms = _demoChatRooms.where((room) => 
          room.founderId == currentUserId || room.finderId == currentUserId
        ).map((room) => room.id).toList();
        
        final messages = _demoChatMessages
            .where((m) => userRooms.contains(m.chatRoomId))
            .toList();
        _demoControllers[allMsgKey]!.add(messages);
      }
    } else {
      // Firebase mode
      final snapshot = await _firestore
          .collection('messages')
          .where('chatRoomId', isEqualTo: chatRoomId)
          .where('senderId', isNotEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();
      
      for (var doc in snapshot.docs) {
        await doc.reference.update({'isRead': true});
      }
    }
  }

  // Get unread notification count
  int getUnreadNotificationCount(String userId) {
    if (DemoConfig.demoMode) {
      return _demoNotifications
          .where((n) => n.userId == userId && !n.isRead)
          .length;
    }
    
    // For Firebase, this would need to be async, but for UI purposes we return 0
    // The actual count will be updated via the stream
    return 0;
  }

  // Get unread chat count
  int getUnreadChatCount(String userId) {
    if (DemoConfig.demoMode) {
      // Count chat rooms where the user has unread messages
      int count = 0;
      for (var room in _demoChatRooms) {
        if (room.founderId == userId || room.finderId == userId) {
          // Check if there are unread messages in this room
          final hasUnread = _demoChatMessages.any((msg) =>
              msg.chatRoomId == room.id &&
              msg.senderId != userId &&
              !msg.isRead);
          if (hasUnread) count++;
        }
      }
      return count;
    }
    
    // For Firebase, this would need to be async, but for UI purposes we return 0
    return 0;
  }

  // ============ CHAT ============

  // Create or get chat room
  Future<String> createOrGetChatRoom({
    required String itemId,
    required String founderId,
    required String founderName,
    required String finderId,
    required String finderName,
    required String itemTitle,
  }) async {
    if (DemoConfig.demoMode) {
      await MockData.mockDelay();
      
      final existing = _demoChatRooms.where((room) =>
          room.itemId == itemId &&
          room.founderId == founderId &&
          room.finderId == finderId).toList();
      
      if (existing.isNotEmpty) {
        return existing.first.id;
      }
      
      final chatRoom = ChatRoomModel(
        id: const Uuid().v4(),
        itemId: itemId,
        founderId: founderId,
        founderName: founderName,
        finderId: finderId,
        finderName: finderName,
        itemTitle: itemTitle,
        createdAt: DateTime.now(),
      );
      
      _demoChatRooms.add(chatRoom);
      return chatRoom.id;
    }
    
    // Firebase mode
    try {
      final snapshot = await _firestore
          .collection('chatRooms')
          .where('itemId', isEqualTo: itemId)
          .where('founderId', isEqualTo: founderId)
          .where('finderId', isEqualTo: finderId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
      
      final chatRoomRef = _firestore.collection('chatRooms').doc();
      await chatRoomRef.set({
        'itemId': itemId,
        'founderId': founderId,
        'founderName': founderName,
        'finderId': finderId,
        'finderName': finderName,
        'itemTitle': itemTitle,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return chatRoomRef.id;
    } catch (e) {
      throw Exception('Failed to create chat room: $e');
    }
  }

  // Get user's chat rooms
  Future<List<ChatRoomModel>> getUserChatRooms(String userId) async {
    if (DemoConfig.demoMode) {
      await MockData.mockDelay();
      return _demoChatRooms
          .where((room) => room.founderId == userId || room.finderId == userId)
          .toList()
          ..sort((a, b) => (b.lastMessageAt ?? b.createdAt)
              .compareTo(a.lastMessageAt ?? a.createdAt));
    }
    
    // Firebase mode
    try {
      // Query rooms where user is either founder or finder
      final founderSnapshot = await _firestore
          .collection('chatRooms')
          .where('founderId', isEqualTo: userId)
          .get();
      
      final finderSnapshot = await _firestore
          .collection('chatRooms')
          .where('finderId', isEqualTo: userId)
          .get();
      
      final rooms = <ChatRoomModel>[];
      for (var doc in founderSnapshot.docs) {
        rooms.add(ChatRoomModel.fromMap(doc.data(), doc.id));
      }
      for (var doc in finderSnapshot.docs) {
        rooms.add(ChatRoomModel.fromMap(doc.data(), doc.id));
      }
      
      rooms.sort((a, b) => (b.lastMessageAt ?? b.createdAt)
          .compareTo(a.lastMessageAt ?? a.createdAt));
      
      return rooms;
    } catch (e) {
      return [];
    }
  }

  // Stream chat rooms
  Stream<List<ChatRoomModel>> streamUserChatRooms(String userId) {
    if (DemoConfig.demoMode) {
      final key = 'chat_rooms_$userId';
      
      if (!_demoControllers.containsKey(key)) {
        _demoControllers[key] = StreamController<List<ChatRoomModel>>.broadcast();
      }
      
      Future.delayed(const Duration(milliseconds: 100), () {
        final chatRooms = _demoChatRooms
            .where((room) => room.founderId == userId || room.finderId == userId)
            .toList()
            ..sort((a, b) => (b.lastMessageAt ?? b.createdAt)
                .compareTo(a.lastMessageAt ?? a.createdAt));
        if (_demoControllers[key] != null && !_demoControllers[key]!.isClosed) {
          _demoControllers[key]!.add(chatRooms);
        }
      });
      
      return _demoControllers[key]!.stream as Stream<List<ChatRoomModel>>;
    }
    
    // Firebase mode - combine streams (simplified version)
    return _firestore
        .collection('chatRooms')
        .where('founderId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          final rooms = snapshot.docs
              .map((doc) => ChatRoomModel.fromMap(doc.data(), doc.id))
              .toList();
          
          final finderSnapshot = await _firestore
              .collection('chatRooms')
              .where('finderId', isEqualTo: userId)
              .get();
          
          rooms.addAll(finderSnapshot.docs
              .map((doc) => ChatRoomModel.fromMap(doc.data(), doc.id)));
          
          rooms.sort((a, b) => (b.lastMessageAt ?? b.createdAt)
              .compareTo(a.lastMessageAt ?? a.createdAt));
          
          return rooms;
        });
  }

  // Send message
  Future<Map<String, dynamic>> sendMessage({
    required String chatRoomId,
    required String message,
  }) async {
    if (DemoConfig.demoMode) {
      await MockData.mockDelay();
      
      final user = _authService.currentUser!;
      final chatMessage = ChatMessageModel(
        id: const Uuid().v4(),
        chatRoomId: chatRoomId,
        senderId: user.uid,
        senderName: user.displayName ?? 'User',
        message: message,
        timestamp: DateTime.now(),
        isRead: false,
      );
      
      _demoChatMessages.add(chatMessage);
      
      final roomIndex = _demoChatRooms.indexWhere((r) => r.id == chatRoomId);
      if (roomIndex != -1) {
        final room = _demoChatRooms[roomIndex];
        _demoChatRooms[roomIndex] = room.copyWith(
          lastMessage: message,
          lastMessageAt: DateTime.now(),
        );
        
        final founderKey = 'chat_rooms_${room.founderId}';
        final finderKey = 'chat_rooms_${room.finderId}';
        
        for (final key in [founderKey, finderKey]) {
          if (_demoControllers.containsKey(key)) {
            final userId = key.split('_').last;
            final chatRooms = _demoChatRooms
                .where((r) => r.founderId == userId || r.finderId == userId)
                .toList()
                ..sort((a, b) => (b.lastMessageAt ?? b.createdAt)
                    .compareTo(a.lastMessageAt ?? a.createdAt));
            _demoControllers[key]!.add(chatRooms);
          }
        }
        
        final otherUserId = user.uid == room.founderId ? room.finderId : room.founderId;
        await _createNotification(
          userId: otherUserId,
          title: 'New message',
          message: '${user.displayName} sent you a message',
          type: 'new_message',
          relatedId: chatRoomId,
        );
      }
      
      final key = 'chat_messages_$chatRoomId';
      if (_demoControllers.containsKey(key)) {
        final messages = _demoChatMessages
            .where((m) => m.chatRoomId == chatRoomId)
            .toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _demoControllers[key]!.add(messages);
      }
      
      return {'success': true, 'messageId': chatMessage.id};
    }
    
    // Firebase mode
    try {
      final user = _authService.currentUser!;
      final messageRef = _firestore.collection('messages').doc();
      
      await messageRef.set({
        'chatRoomId': chatRoomId,
        'senderId': user.uid,
        'senderName': user.displayName ?? 'User',
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      
      // Update chat room's last message
      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'lastMessage': message,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
      
      // Get chat room for notification
      final roomDoc = await _firestore.collection('chatRooms').doc(chatRoomId).get();
      final room = ChatRoomModel.fromMap(roomDoc.data()!, roomDoc.id);
      
      // Create notification for the other user
      final otherUserId = user.uid == room.founderId ? room.finderId : room.founderId;
      await _firestore.collection('notifications').add({
        'userId': otherUserId,
        'title': 'New message',
        'message': '${user.displayName} sent you a message',
        'type': 'new_message',
        'relatedId': chatRoomId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return {'success': true, 'messageId': messageRef.id};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Stream all chat messages for a user (across all their chat rooms)
  Stream<List<ChatMessageModel>> streamAllUserChatMessages(String userId) {
    if (DemoConfig.demoMode) {
      final key = 'all_user_messages_$userId';
      
      if (!_demoControllers.containsKey(key)) {
        _demoControllers[key] = StreamController<List<ChatMessageModel>>.broadcast();
      }
      
      // Get all chat rooms for this user
      final userRooms = _demoChatRooms.where((room) => 
        room.founderId == userId || room.finderId == userId
      ).map((room) => room.id).toList();
      
      Future.delayed(const Duration(milliseconds: 100), () {
        final messages = _demoChatMessages
            .where((m) => userRooms.contains(m.chatRoomId))
            .toList();
        if (_demoControllers[key] != null && !_demoControllers[key]!.isClosed) {
          _demoControllers[key]!.add(messages);
        }
      });
      
      return _demoControllers[key]!.stream as Stream<List<ChatMessageModel>>;
    }
    
    // Firebase mode - get all chat rooms for user first, then get messages
    return streamUserChatRooms(userId).asyncMap((chatRooms) async {
      if (chatRooms.isEmpty) return <ChatMessageModel>[];
      
      final roomIds = chatRooms.map((room) => room.id).toList();
      final snapshot = await _firestore
          .collection('messages')
          .where('chatRoomId', whereIn: roomIds)
          .get();
          
      return snapshot.docs
          .map((doc) => ChatMessageModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Stream chat messages
  Stream<List<ChatMessageModel>> streamChatMessages(String chatRoomId) {
    if (DemoConfig.demoMode) {
      final key = 'chat_messages_$chatRoomId';
      
      if (!_demoControllers.containsKey(key)) {
        _demoControllers[key] = StreamController<List<ChatMessageModel>>.broadcast();
      }
      
      Future.delayed(const Duration(milliseconds: 100), () {
        final messages = _demoChatMessages
            .where((m) => m.chatRoomId == chatRoomId)
            .toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        if (_demoControllers[key] != null && !_demoControllers[key]!.isClosed) {
          _demoControllers[key]!.add(messages);
        }
      });
      
      return _demoControllers[key]!.stream as Stream<List<ChatMessageModel>>;
    }
    
    // Firebase mode
    return _firestore
        .collection('messages')
        .where('chatRoomId', isEqualTo: chatRoomId)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => ChatMessageModel.fromMap(doc.data(), doc.id))
              .toList();
          // Manual sorting to avoid composite index requirement
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return messages;
        });
  }

  // Dispose demo controllers
  void dispose() {
    for (var controller in _demoControllers.values) {
      controller.close();
    }
    _demoControllers.clear();
  }
}
