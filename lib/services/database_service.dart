import 'dart:async';
import 'package:uuid/uuid.dart';
import '../config/mock_data.dart';
import '../models/item_model.dart';
import '../models/request_model.dart';
import '../models/notification_model.dart';
import '../models/chat_model.dart';
import 'auth_service.dart';

class DatabaseService {
  final AuthService _authService;
  
  // Demo mode state
  final List<ItemModel> _demoItems = List.from(MockData.mockItems);
  final List<RequestModel> _demoRequests = List.from(MockData.mockRequests);
  final List<NotificationModel> _demoNotifications = [];
  final List<ChatRoomModel> _demoChatRooms = [];
  final List<ChatMessageModel> _demoChatMessages = [];
  final Map<String, StreamController> _demoControllers = {};

  DatabaseService(this._authService);

  // ============ ITEMS ============

  // Create item
  Future<Map<String, dynamic>> createItem({
    required String title,
    required String description,
    String? deviceId,
    String? location,
  }) async {
    await MockData.mockDelay();
    
    final user = _authService.currentUser!;
    final newItem = ItemModel(
      id: const Uuid().v4(),
      title: title,
      description: description,
      founderId: user.uid,
      founderName: user.displayName ?? 'Demo User',
      founderEmail: user.email ?? '',
      deviceId: deviceId,
      location: location,
      status: 'waiting',
      timestamp: DateTime.now(),
      createdAt: DateTime.now(),
    );
    
    _demoItems.add(newItem);
    return {'success': true, 'itemId': newItem.id};
  }

  // Search items
  Future<List<ItemModel>> searchItems(String searchText) async {
    await MockData.mockDelay();
    
    final lowerSearch = searchText.toLowerCase();
    return _demoItems.where((item) {
      return item.status == 'waiting' &&
          (item.title.toLowerCase().contains(lowerSearch) ||
           item.description.toLowerCase().contains(lowerSearch));
    }).toList();
  }

  // Get items submitted by a specific founder
  Future<List<ItemModel>> getFounderItems(String founderId) async {
    await MockData.mockDelay();
    
    return _demoItems.where((item) => item.founderId == founderId).toList();
  }

  // ============ REQUESTS ============

  // Create request
  Future<Map<String, dynamic>> createRequest({
    required String itemId,
    required String finderDescription,
  }) async {
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
    
    // Get item details for notification
    final item = _demoItems.firstWhere((i) => i.id == itemId);
    
    // Create notification for founder
    await _createNotification(
      userId: item.founderId,
      title: 'New retrieval request',
      message: '${user.displayName} requested your found item: ${item.title}',
      type: 'request_received',
      relatedId: newRequest.id,
    );
    
    // Notify item requests listeners
    final key = 'item_requests_$itemId';
    if (_demoControllers.containsKey(key)) {
      final requests = _demoRequests.where((r) => r.itemId == itemId).toList();
      _demoControllers[key]!.add(requests);
    }
    
    return {'success': true, 'requestId': newRequest.id};
  }

  // Get requests submitted by a specific finder
  Future<List<RequestModel>> getFinderRequests(String finderId) async {
    await MockData.mockDelay();
    
    return _demoRequests.where((req) => req.finderId == finderId).toList();
  }

  // Update request status
  Future<Map<String, dynamic>> updateRequestStatus(
    String requestId,
    String status,
  ) async {
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
      
      // Get item details for notification
      final item = _demoItems.firstWhere((i) => i.id == request.itemId);
      
      // Create notification for finder
      if (status == 'approved') {
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
      
      // Notify request listeners
      final key = 'request_$requestId';
      if (_demoControllers.containsKey(key)) {
        _demoControllers[key]!.add(_demoRequests[index]);
      }
    }
    
    return {'success': true};
  }

  // Stream item requests (for founder)
  Stream<List<RequestModel>> streamItemRequests(String itemId) {
    final key = 'item_requests_$itemId';
    _demoControllers[key] = StreamController<List<RequestModel>>.broadcast();
    
    // Send initial data
    Future.delayed(const Duration(milliseconds: 100), () {
      final requests = _demoRequests.where((r) => r.itemId == itemId).toList();
      if (_demoControllers[key] != null && !_demoControllers[key]!.isClosed) {
        _demoControllers[key]!.add(requests);
      }
    });
    
    return _demoControllers[key]!.stream as Stream<List<RequestModel>>;
  }

  // Stream single request (for finder)
  Stream<RequestModel> streamRequest(String requestId) {
    final key = 'request_$requestId';
    _demoControllers[key] = StreamController<RequestModel>.broadcast();
    
    // Send initial data
    Future.delayed(const Duration(milliseconds: 100), () {
      final request = _demoRequests.firstWhere((r) => r.id == requestId);
      if (_demoControllers[key] != null && !_demoControllers[key]!.isClosed) {
        _demoControllers[key]!.add(request);
      }
    });
    
    return _demoControllers[key]!.stream as Stream<RequestModel>;
  }

  // ============ NOTIFICATIONS ============

  // Create notification
  Future<void> _createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
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
    
    // Notify listeners
    final key = 'notifications_$userId';
    if (_demoControllers.containsKey(key)) {
      final userNotifications = _demoNotifications
          .where((n) => n.userId == userId)
          .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _demoControllers[key]!.add(userNotifications);
    }
  }

  // Get user notifications
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    await MockData.mockDelay();
    
    return _demoNotifications
        .where((n) => n.userId == userId)
        .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Stream user notifications
  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    final key = 'notifications_$userId';
    
    if (!_demoControllers.containsKey(key)) {
      _demoControllers[key] = StreamController<List<NotificationModel>>.broadcast();
    }
    
    // Send initial data
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

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await MockData.mockDelay();
    
    final index = _demoNotifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final notification = _demoNotifications[index];
      _demoNotifications[index] = notification.copyWith(isRead: true);
      
      // Notify listeners
      final key = 'notifications_${notification.userId}';
      if (_demoControllers.containsKey(key)) {
        final userNotifications = _demoNotifications
            .where((n) => n.userId == notification.userId)
            .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _demoControllers[key]!.add(userNotifications);
      }
    }
  }

  // Get unread notification count
  int getUnreadNotificationCount(String userId) {
    return _demoNotifications
        .where((n) => n.userId == userId && !n.isRead)
        .length;
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
    await MockData.mockDelay();
    
    // Check if chat room already exists
    final existing = _demoChatRooms.where((room) =>
        room.itemId == itemId &&
        room.founderId == founderId &&
        room.finderId == finderId).toList();
    
    if (existing.isNotEmpty) {
      return existing.first.id;
    }
    
    // Create new chat room
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

  // Get user's chat rooms
  Future<List<ChatRoomModel>> getUserChatRooms(String userId) async {
    await MockData.mockDelay();
    
    return _demoChatRooms
        .where((room) => room.founderId == userId || room.finderId == userId)
        .toList()
        ..sort((a, b) => (b.lastMessageAt ?? b.createdAt)
            .compareTo(a.lastMessageAt ?? a.createdAt));
  }

  // Stream chat rooms
  Stream<List<ChatRoomModel>> streamUserChatRooms(String userId) {
    final key = 'chat_rooms_$userId';
    
    if (!_demoControllers.containsKey(key)) {
      _demoControllers[key] = StreamController<List<ChatRoomModel>>.broadcast();
    }
    
    // Send initial data
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

  // Send message
  Future<Map<String, dynamic>> sendMessage({
    required String chatRoomId,
    required String message,
  }) async {
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
    
    // Update chat room's last message
    final roomIndex = _demoChatRooms.indexWhere((r) => r.id == chatRoomId);
    if (roomIndex != -1) {
      final room = _demoChatRooms[roomIndex];
      _demoChatRooms[roomIndex] = room.copyWith(
        lastMessage: message,
        lastMessageAt: DateTime.now(),
      );
      
      // Notify chat room listeners
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
      
      // Create notification for the other user
      final otherUserId = user.uid == room.founderId ? room.finderId : room.founderId;
      await _createNotification(
        userId: otherUserId,
        title: 'New message',
        message: '${user.displayName} sent you a message',
        type: 'new_message',
        relatedId: chatRoomId,
      );
    }
    
    // Notify message listeners
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

  // Stream chat messages
  Stream<List<ChatMessageModel>> streamChatMessages(String chatRoomId) {
    final key = 'chat_messages_$chatRoomId';
    
    if (!_demoControllers.containsKey(key)) {
      _demoControllers[key] = StreamController<List<ChatMessageModel>>.broadcast();
    }
    
    // Send initial data
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

  // Dispose demo controllers
  void dispose() {
    for (var controller in _demoControllers.values) {
      controller.close();
    }
    _demoControllers.clear();
  }
}
