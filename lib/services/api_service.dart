import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

/// API Service for REST API communication
/// Replaces Firebase SDK with HTTP requests
class ApiService {
  // ============================================
  // Configuration
  // ============================================
  
  // DEVELOPMENT (Local XAMPP)
  static const String BASE_URL = 'http://192.168.1.100/Lost-and-Found-IOT/backend/api';
  
  // PRODUCTION (Free hosting)
  // static const String BASE_URL = 'https://yourdomain.000webhostapp.com/api';
  
  static const Duration CONNECT_TIMEOUT = Duration(seconds: 10);
  static const Duration RECEIVE_TIMEOUT = Duration(seconds: 10);
  
  // ============================================
  // Singleton Instance
  // ============================================
  
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late Dio _dio;
  final StorageService _storage = StorageService();
  
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: BASE_URL,
      connectTimeout: CONNECT_TIMEOUT,
      receiveTimeout: RECEIVE_TIMEOUT,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token to all requests
          String? token = await _storage.getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          // Log request in debug mode
          if (kDebugMode) {
            print('→ REQUEST: ${options.method} ${options.path}');
            print('  Headers: ${options.headers}');
            print('  Data: ${options.data}');
          }
          
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Log response in debug mode
          if (kDebugMode) {
            print('← RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
            print('  Data: ${response.data}');
          }
          
          return handler.next(response);
        },
        onError: (error, handler) async {
          // Log error in debug mode
          if (kDebugMode) {
            print('✗ ERROR: ${error.message}');
            print('  Response: ${error.response?.data}');
          }
          
          // Handle 401 Unauthorized (token expired)
          if (error.response?.statusCode == 401) {
            // Clear stored token and user data
            await _storage.clearAuthToken();
            await _storage.clearUserData();
            
            // You might want to navigate to login screen here
            // NavigationService.navigateToLogin();
          }
          
          return handler.next(error);
        },
      ),
    );
  }
  
  // ============================================
  // Generic Request Methods
  // ============================================
  
  /// Generic GET request
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Generic POST request
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Generic PUT request
  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Generic DELETE request
  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // ============================================
  // Response Handling
  // ============================================
  
  Map<String, dynamic> _handleResponse(Response response) {
    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      // Success response
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ApiException('Invalid response format', 500);
      }
    } else {
      // Error response
      throw ApiException(
        response.data?['error'] ?? 'Unknown error',
        response.statusCode ?? 500,
      );
    }
  }
  
  ApiException _handleError(DioException error) {
    if (error.response != null) {
      // Server error response
      final message = error.response?.data?['error'] ?? error.message ?? 'Unknown error';
      return ApiException(message, error.response?.statusCode ?? 500);
    } else {
      // Network error
      if (error.type == DioExceptionType.connectionTimeout || 
          error.type == DioExceptionType.receiveTimeout) {
        return ApiException('Connection timeout. Please check your internet connection.', 408);
      } else if (error.type == DioExceptionType.connectionError) {
        return ApiException('Cannot connect to server. Please check your internet connection.', 503);
      } else {
        return ApiException('Network error: ${error.message}', 500);
      }
    }
  }
  
  // ============================================
  // File Upload
  // ============================================
  
  /// Upload image file
  Future<Map<String, dynamic>> uploadImage(String path, String filePath, String fieldName) async {
    try {
      FormData formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
      });
      
      final response = await _dio.post(path, data: formData);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // ============================================
  // Authentication Methods
  // ============================================
  
  /// Register new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String role = 'both',
  }) async {
    return await post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'role': role,
    });
  }
  
  /// Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    
    // Save auth token
    if (response['data'] != null && response['data']['token'] != null) {
      await _storage.saveAuthToken(response['data']['token']);
      await _storage.saveUserData(response['data']['user']);
    }
    
    return response;
  }
  
  /// Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    return await get('/auth/profile');
  }
  
  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? role,
  }) async {
    return await put('/auth/profile', data: {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (role != null) 'role': role,
    });
  }
  
  /// Update FCM token for push notifications
  Future<Map<String, dynamic>> updateFCMToken(String fcmToken) async {
    return await put('/auth/fcm-token', data: {
      'fcm_token': fcmToken,
    });
  }
  
  // ============================================
  // Box Methods
  // ============================================
  
  /// Get all boxes
  Future<List<dynamic>> getBoxes() async {
    final response = await get('/boxes');
    return response['data']['items'] ?? [];
  }
  
  /// Get available boxes only
  Future<List<dynamic>> getAvailableBoxes() async {
    final response = await get('/boxes/available');
    return response['data']['items'] ?? [];
  }
  
  /// Get box details
  Future<Map<String, dynamic>> getBoxDetails(String boxId) async {
    final response = await get('/boxes/$boxId');
    return response['data'];
  }
  
  /// Unlock box
  Future<Map<String, dynamic>> unlockBox(String boxId) async {
    return await post('/boxes/unlock', data: {
      'box_id': boxId,
    });
  }
  
  /// Lock box
  Future<Map<String, dynamic>> lockBox(String boxId) async {
    return await post('/boxes/lock', data: {
      'box_id': boxId,
    });
  }
  
  // ============================================
  // Item Methods
  // ============================================
  
  /// Create new item
  Future<Map<String, dynamic>> createItem({
    required String title,
    required String description,
    required String boxId,
    String? deviceId,
    String? imageUrl,
  }) async {
    return await post('/items', data: {
      'title': title,
      'description': description,
      'box_id': boxId,
      'device_id': deviceId,
      'image_url': imageUrl,
    });
  }
  
  /// Search items
  Future<List<dynamic>> searchItems(String query) async {
    final response = await get('/items/search', queryParameters: {
      'q': query,
    });
    return response['data']['items'] ?? [];
  }
  
  /// Get item details
  Future<Map<String, dynamic>> getItemDetails(String itemId) async {
    final response = await get('/items/$itemId');
    return response['data'];
  }
  
  /// Get founder's items
  Future<List<dynamic>> getFounderItems(String founderId) async {
    final response = await get('/items/founder/$founderId');
    return response['data']['items'] ?? [];
  }
  
  /// Update item status
  Future<Map<String, dynamic>> updateItemStatus(String itemId, String status) async {
    return await put('/items/$itemId', data: {
      'status': status,
    });
  }
  
  // ============================================
  // Request Methods
  // ============================================
  
  /// Create retrieval request
  Future<Map<String, dynamic>> createRequest({
    required String itemId,
    required String proofDescription,
  }) async {
    return await post('/requests', data: {
      'item_id': itemId,
      'proof_description': proofDescription,
    });
  }
  
  /// Get founder's requests
  Future<List<dynamic>> getFounderRequests(String founderId) async {
    final response = await get('/requests/founder/$founderId');
    return response['data']['items'] ?? [];
  }
  
  /// Get finder's requests
  Future<List<dynamic>> getFinderRequests(String finderId) async {
    final response = await get('/requests/finder/$finderId');
    return response['data']['items'] ?? [];
  }
  
  /// Get request details
  Future<Map<String, dynamic>> getRequestDetails(String requestId) async {
    final response = await get('/requests/$requestId');
    return response['data'];
  }
  
  /// Approve request
  Future<Map<String, dynamic>> approveRequest(String requestId) async {
    return await put('/requests/$requestId/approve');
  }
  
  /// Reject request
  Future<Map<String, dynamic>> rejectRequest(String requestId, {String? reason}) async {
    return await put('/requests/$requestId/reject', data: {
      if (reason != null) 'rejection_reason': reason,
    });
  }
  
  // ============================================
  // Message Methods
  // ============================================
  
  /// Send message
  Future<Map<String, dynamic>> sendMessage({
    required String requestId,
    required String messageText,
  }) async {
    return await post('/messages', data: {
      'request_id': requestId,
      'message_text': messageText,
    });
  }
  
  /// Get messages for a request
  Future<List<dynamic>> getMessages(String requestId) async {
    final response = await get('/messages/$requestId');
    return response['data']['items'] ?? [];
  }
  
  /// Mark message as read
  Future<Map<String, dynamic>> markMessageAsRead(String messageId) async {
    return await put('/messages/$messageId/read');
  }
  
  /// Get unread message count
  Future<int> getUnreadCount(String userId) async {
    final response = await get('/messages/unread/$userId');
    return response['data']['count'] ?? 0;
  }
  
  // ============================================
  // Utility Methods
  // ============================================
  
  /// Logout (clear local data)
  Future<void> logout() async {
    await _storage.clearAuthToken();
    await _storage.clearUserData();
  }
  
  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    String? token = await _storage.getAuthToken();
    return token != null;
  }
}

// ============================================
// Custom Exception
// ============================================

class ApiException implements Exception {
  final String message;
  final int statusCode;
  
  ApiException(this.message, this.statusCode);
  
  @override
  String toString() => message;
}
