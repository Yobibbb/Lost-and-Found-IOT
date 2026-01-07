import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String title;
  final String description;
  final String founderId;
  final String founderName;
  final String founderEmail;
  final String boxId; // Required: ID of the IoT box (e.g., "BOX_A1")
  final String location; // Required: Physical location of the box
  final String? deviceId;
  final String status; // pending_storage, waiting, to_collect, claimed
  // Status flow:
  // 1. pending_storage - Item submitted, waiting for founder to scan QR and store in box
  // 2. waiting - Item stored in box, waiting for finder requests
  // 3. to_collect - Request approved, waiting for finder to retrieve item
  // 4. claimed - Finder retrieved the item
  final DateTime timestamp;
  final DateTime createdAt;

  ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.founderId,
    required this.founderName,
    required this.founderEmail,
    required this.boxId,
    required this.location,
    this.deviceId,
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
      boxId: map['boxId'] ?? '',
      location: map['location'] ?? '',
      deviceId: map['deviceId'],
      status: map['status'] ?? 'pending_storage',
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
      'boxId': boxId,
      'location': location,
      'deviceId': deviceId,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
