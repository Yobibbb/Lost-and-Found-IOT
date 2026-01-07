import 'package:cloud_firestore/cloud_firestore.dart';

class BoxModel {
  final String id; // e.g., "BOX_A1", "BOX_B2"
  final String name; // Display name e.g., "Box A1"
  final String location; // Physical location e.g., "Building A, Floor 1, Near Entrance"
  final bool isAvailable; // Whether box is available for new items
  final bool isLocked; // Current lock status
  final String? currentItemId; // ID of item currently in the box
  final DateTime lastUpdated;
  final DateTime createdAt;

  BoxModel({
    required this.id,
    required this.name,
    required this.location,
    required this.isAvailable,
    required this.isLocked,
    this.currentItemId,
    required this.lastUpdated,
    required this.createdAt,
  });

  factory BoxModel.fromMap(Map<String, dynamic> map, String id) {
    return BoxModel(
      id: id,
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      isLocked: map['isLocked'] ?? true,
      currentItemId: map['currentItemId'],
      lastUpdated: _parseDateTime(map['lastUpdated']),
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
      'name': name,
      'location': location,
      'isAvailable': isAvailable,
      'isLocked': isLocked,
      'currentItemId': currentItemId,
      'lastUpdated': lastUpdated.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  BoxModel copyWith({
    String? id,
    String? name,
    String? location,
    bool? isAvailable,
    bool? isLocked,
    String? currentItemId,
    DateTime? lastUpdated,
    DateTime? createdAt,
  }) {
    return BoxModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      isAvailable: isAvailable ?? this.isAvailable,
      isLocked: isLocked ?? this.isLocked,
      currentItemId: currentItemId ?? this.currentItemId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
