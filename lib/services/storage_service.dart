import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Local Storage Service
/// Replaces Firebase local persistence
class StorageService {
  // ============================================
  // Storage Keys
  // ============================================
  
  static const String KEY_AUTH_TOKEN = 'auth_token';
  static const String KEY_USER_DATA = 'user_data';
  static const String KEY_USER_ID = 'user_id';
  static const String KEY_USER_EMAIL = 'user_email';
  static const String KEY_USER_NAME = 'user_name';
  static const String KEY_USER_ROLE = 'user_role';
  static const String KEY_FCM_TOKEN = 'fcm_token';
  static const String KEY_LAST_SYNC = 'last_sync';
  
  // ============================================
  // Singleton Instance
  // ============================================
  
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  
  late SharedPreferences _prefs;
  late FlutterSecureStorage _secureStorage;
  bool _initialized = false;
  
  StorageService._internal() {
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    );
  }
  
  // ============================================
  // Initialization
  // ============================================
  
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }
  
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }
  
  // ============================================
  // Auth Token (Secure)
  // ============================================
  
  /// Save authentication token (JWT)
  Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: KEY_AUTH_TOKEN, value: token);
  }
  
  /// Get authentication token
  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: KEY_AUTH_TOKEN);
  }
  
  /// Clear authentication token
  Future<void> clearAuthToken() async {
    await _secureStorage.delete(key: KEY_AUTH_TOKEN);
  }
  
  // ============================================
  // User Data
  // ============================================
  
  /// Save user data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _ensureInitialized();
    
    // Save as JSON string
    await _prefs.setString(KEY_USER_DATA, jsonEncode(userData));
    
    // Save individual fields for quick access
    await _prefs.setString(KEY_USER_ID, userData['user_id'] ?? '');
    await _prefs.setString(KEY_USER_EMAIL, userData['email'] ?? '');
    await _prefs.setString(KEY_USER_NAME, userData['name'] ?? '');
    await _prefs.setString(KEY_USER_ROLE, userData['role'] ?? 'both');
  }
  
  /// Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    await _ensureInitialized();
    
    String? jsonStr = _prefs.getString(KEY_USER_DATA);
    if (jsonStr != null) {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    }
    return null;
  }
  
  /// Clear user data
  Future<void> clearUserData() async {
    await _ensureInitialized();
    
    await _prefs.remove(KEY_USER_DATA);
    await _prefs.remove(KEY_USER_ID);
    await _prefs.remove(KEY_USER_EMAIL);
    await _prefs.remove(KEY_USER_NAME);
    await _prefs.remove(KEY_USER_ROLE);
  }
  
  /// Get user ID
  Future<String?> getUserId() async {
    await _ensureInitialized();
    return _prefs.getString(KEY_USER_ID);
  }
  
  /// Get user email
  Future<String?> getUserEmail() async {
    await _ensureInitialized();
    return _prefs.getString(KEY_USER_EMAIL);
  }
  
  /// Get user name
  Future<String?> getUserName() async {
    await _ensureInitialized();
    return _prefs.getString(KEY_USER_NAME);
  }
  
  /// Get user role
  Future<String?> getUserRole() async {
    await _ensureInitialized();
    return _prefs.getString(KEY_USER_ROLE);
  }
  
  // ============================================
  // FCM Token (Firebase Cloud Messaging)
  // ============================================
  
  /// Save FCM token for push notifications
  Future<void> saveFCMToken(String token) async {
    await _ensureInitialized();
    await _prefs.setString(KEY_FCM_TOKEN, token);
  }
  
  /// Get FCM token
  Future<String?> getFCMToken() async {
    await _ensureInitialized();
    return _prefs.getString(KEY_FCM_TOKEN);
  }
  
  // ============================================
  // App Settings
  // ============================================
  
  /// Save last sync timestamp
  Future<void> saveLastSync(DateTime timestamp) async {
    await _ensureInitialized();
    await _prefs.setInt(KEY_LAST_SYNC, timestamp.millisecondsSinceEpoch);
  }
  
  /// Get last sync timestamp
  Future<DateTime?> getLastSync() async {
    await _ensureInitialized();
    int? millis = _prefs.getInt(KEY_LAST_SYNC);
    if (millis != null) {
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    return null;
  }
  
  // ============================================
  // Generic Methods
  // ============================================
  
  /// Save string value
  Future<void> setString(String key, String value) async {
    await _ensureInitialized();
    await _prefs.setString(key, value);
  }
  
  /// Get string value
  Future<String?> getString(String key) async {
    await _ensureInitialized();
    return _prefs.getString(key);
  }
  
  /// Save int value
  Future<void> setInt(String key, int value) async {
    await _ensureInitialized();
    await _prefs.setInt(key, value);
  }
  
  /// Get int value
  Future<int?> getInt(String key) async {
    await _ensureInitialized();
    return _prefs.getInt(key);
  }
  
  /// Save bool value
  Future<void> setBool(String key, bool value) async {
    await _ensureInitialized();
    await _prefs.setBool(key, value);
  }
  
  /// Get bool value
  Future<bool?> getBool(String key) async {
    await _ensureInitialized();
    return _prefs.getBool(key);
  }
  
  /// Remove value
  Future<void> remove(String key) async {
    await _ensureInitialized();
    await _prefs.remove(key);
  }
  
  /// Clear all data (logout)
  Future<void> clearAll() async {
    await _ensureInitialized();
    await _prefs.clear();
    await _secureStorage.deleteAll();
  }
  
  // ============================================
  // Cache Management
  // ============================================
  
  /// Save cached data (JSON)
  Future<void> cacheData(String key, Map<String, dynamic> data) async {
    await _ensureInitialized();
    await _prefs.setString('cache_$key', jsonEncode(data));
  }
  
  /// Get cached data
  Future<Map<String, dynamic>?> getCachedData(String key) async {
    await _ensureInitialized();
    String? jsonStr = _prefs.getString('cache_$key');
    if (jsonStr != null) {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    }
    return null;
  }
  
  /// Clear cached data
  Future<void> clearCache(String key) async {
    await _ensureInitialized();
    await _prefs.remove('cache_$key');
  }
  
  /// Clear all cached data
  Future<void> clearAllCache() async {
    await _ensureInitialized();
    Set<String> keys = _prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith('cache_')) {
        await _prefs.remove(key);
      }
    }
  }
  
  // ============================================
  // Utility Methods
  // ============================================
  
  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    String? token = await getAuthToken();
    String? userId = await getUserId();
    return token != null && userId != null;
  }
  
  /// Get all stored keys (debug)
  Future<Set<String>> getAllKeys() async {
    await _ensureInitialized();
    return _prefs.getKeys();
  }
}
