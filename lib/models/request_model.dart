import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String id;
  final String itemId;
  final String finderId;
  final String finderName;
  final String finderEmail;
  final String finderDescription;
  final String status; // pending, approved, rejected
  final DateTime timestamp;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;

  RequestModel({
    required this.id,
    required this.itemId,
    required this.finderId,
    required this.finderName,
    required this.finderEmail,
    required this.finderDescription,
    required this.status,
    required this.timestamp,
    required this.createdAt,
    this.approvedAt,
    this.rejectedAt,
  });

  factory RequestModel.fromMap(Map<String, dynamic> map, String id) {
    return RequestModel(
      id: id,
      itemId: map['itemId'] ?? '',
      finderId: map['finderId'] ?? '',
      finderName: map['finderName'] ?? '',
      finderEmail: map['finderEmail'] ?? '',
      finderDescription: map['finderDescription'] ?? '',
      status: map['status'] ?? 'pending',
      timestamp: _parseDateTime(map['timestamp']),
      createdAt: _parseDateTime(map['createdAt']),
      approvedAt: map['approvedAt'] != null ? _parseDateTime(map['approvedAt']) : null,
      rejectedAt: map['rejectedAt'] != null ? _parseDateTime(map['rejectedAt']) : null,
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
      'itemId': itemId,
      'finderId': finderId,
      'finderName': finderName,
      'finderEmail': finderEmail,
      'finderDescription': finderDescription,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectedAt': rejectedAt?.toIso8601String(),
    };
  }

  RequestModel copyWith({
    String? id,
    String? itemId,
    String? finderId,
    String? finderName,
    String? finderEmail,
    String? finderDescription,
    String? status,
    DateTime? timestamp,
    DateTime? createdAt,
    DateTime? approvedAt,
    DateTime? rejectedAt,
  }) {
    return RequestModel(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      finderId: finderId ?? this.finderId,
      finderName: finderName ?? this.finderName,
      finderEmail: finderEmail ?? this.finderEmail,
      finderDescription: finderDescription ?? this.finderDescription,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
    );
  }
}
