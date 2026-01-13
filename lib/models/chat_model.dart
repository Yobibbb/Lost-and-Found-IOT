import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String message;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isRead;

  ChatMessageModel({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    required this.message,
    this.imageUrl,
    required this.timestamp,
    required this.isRead,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessageModel(
      id: id,
      chatRoomId: map['chatRoomId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      message: map['message'] ?? '',
      imageUrl: map['imageUrl'],
      timestamp: _parseDateTime(map['timestamp']),
      isRead: map['isRead'] ?? false,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'imageUrl': imageUrl,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? chatRoomId,
    String? senderId,
    String? senderName,
    String? message,
    String? imageUrl,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

class ChatRoomModel {
  final String id;
  final String itemId;
  final String founderId;
  final String founderName;
  final String finderId;
  final String finderName;
  final String itemTitle;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final String? lastMessage;

  ChatRoomModel({
    required this.id,
    required this.itemId,
    required this.founderId,
    required this.founderName,
    required this.finderId,
    required this.finderName,
    required this.itemTitle,
    required this.createdAt,
    this.lastMessageAt,
    this.lastMessage,
  });

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  static DateTime? _parseDateTimeNullable(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return null;
  }

  factory ChatRoomModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatRoomModel(
      id: id,
      itemId: map['itemId'] ?? '',
      founderId: map['founderId'] ?? '',
      founderName: map['founderName'] ?? '',
      finderId: map['finderId'] ?? '',
      finderName: map['finderName'] ?? '',
      itemTitle: map['itemTitle'] ?? '',
      createdAt: _parseDateTime(map['createdAt']),
      lastMessageAt: _parseDateTimeNullable(map['lastMessageAt']),
      lastMessage: map['lastMessage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'founderId': founderId,
      'founderName': founderName,
      'finderId': finderId,
      'finderName': finderName,
      'itemTitle': itemTitle,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'lastMessage': lastMessage,
    };
  }

  ChatRoomModel copyWith({
    String? id,
    String? itemId,
    String? founderId,
    String? founderName,
    String? finderId,
    String? finderName,
    String? itemTitle,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    String? lastMessage,
  }) {
    return ChatRoomModel(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      founderId: founderId ?? this.founderId,
      founderName: founderName ?? this.founderName,
      finderId: finderId ?? this.finderId,
      finderName: finderName ?? this.finderName,
      itemTitle: itemTitle ?? this.itemTitle,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}
