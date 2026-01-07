import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String title;
  final String description;
  final String founderId;
  final String founderName;
  final String founderEmail;
  final String? deviceId;
  final String? location;
  final String status; // waiting, matched, retrieved
  final DateTime timestamp;
  final DateTime createdAt;

  ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.founderId,
    required this.founderName,
    required this.founderEmail,
    this.deviceId,
    this.location,
    required this.status,
    required this.timestamp,
    required this.createdAt,
  });

  factory ItemModel.fromMap(Map<String, dynamic> map, String id) {
    return ItemModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      founderId: map['founderId'] ?? '',
      founderName: map['founderName'] ?? '',
      founderEmail: map['founderEmail'] ?? '',
      deviceId: map['deviceId'],
      location: map['location'],
      status: map['status'] ?? 'waiting',
      timestamp: _parseDateTime(map['timestamp']),
      createdAt: _parseDateTime(map['createdAt']),
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
      'title': title,
      'description': description,
      'founderId': founderId,
      'founderName': founderName,
      'founderEmail': founderEmail,
      'deviceId': deviceId,
      'location': location,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
