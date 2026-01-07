import '../models/user_model.dart';
import '../models/item_model.dart';
import '../models/request_model.dart';

class MockData {
  // Mock Users
  static final UserModel mockFounder = UserModel(
    uid: 'mock-founder-123',
    email: 'founder@demo.com',
    displayName: 'Demo Founder',
  );

  static final UserModel mockFinder = UserModel(
    uid: 'mock-finder-456',
    email: 'finder@demo.com',
    displayName: 'Demo Finder',
  );

  // Mock Items
  static final List<ItemModel> mockItems = [
    ItemModel(
      id: 'item-1',
      title: 'Blue iPhone 13',
      description: 'Blue iPhone 13 with black protective case. Found in Starbucks coffee shop on Main Street. Has a small scratch on the back.',
      founderId: mockFounder.uid,
      founderName: mockFounder.displayName!,
      founderEmail: mockFounder.email!,
      boxId: 'BOX_A1',
      location: 'Building A, Floor 1, Near Main Entrance',
      deviceId: 'DEVICE-001',
      status: 'waiting',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ItemModel(
      id: 'item-2',
      title: 'Brown Leather Wallet',
      description: 'Brown leather wallet containing several cards and some cash. Found on the second floor of the university library near the study area.',
      founderId: mockFounder.uid,
      founderName: mockFounder.displayName!,
      founderEmail: mockFounder.email!,
      boxId: 'BOX_B1',
      location: 'Building B, Ground Floor, Library Entrance',
      deviceId: 'DEVICE-002',
      status: 'waiting',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    ItemModel(
      id: 'item-3',
      title: 'Toyota Car Keys',
      description: 'Car keys with Toyota logo keychain and two other keys. Found on a bench in Central Park near the playground area.',
      founderId: mockFounder.uid,
      founderName: mockFounder.displayName!,
      founderEmail: mockFounder.email!,
      boxId: 'BOX_C1',
      location: 'Building C, Ground Floor, Gym Entrance',
      deviceId: 'DEVICE-003',
      status: 'waiting',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  // Mock Requests
  static final List<RequestModel> mockRequests = [
    RequestModel(
      id: 'request-1',
      itemId: 'item-1',
      finderId: mockFinder.uid,
      finderName: mockFinder.displayName!,
      finderEmail: mockFinder.email!,
      finderDescription: 'I lost my blue iPhone 13 in a coffee shop yesterday',
      status: 'pending',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
  ];

  // Helper to simulate network delay
  static Future<void> mockDelay() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
