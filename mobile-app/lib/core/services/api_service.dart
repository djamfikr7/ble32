import 'dart:convert';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// API Configuration
class ApiConfig {
  static const String baseUrl = 'http://localhost:8000';
  static const Duration timeout = Duration(seconds: 30);
}

/// Connectivity state
enum ConnectionState { connected, disconnected }

/// Offline queue item
class QueuedRequest {
  final String method;
  final String endpoint;
  final Map<String, dynamic>? body;
  final DateTime createdAt;

  QueuedRequest({
    required this.method,
    required this.endpoint,
    this.body,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'method': method,
        'endpoint': endpoint,
        'body': body,
        'created_at': createdAt.toIso8601String(),
      };

  factory QueuedRequest.fromJson(Map<String, dynamic> json) => QueuedRequest(
        method: json['method'],
        endpoint: json['endpoint'],
        body: json['body'],
        createdAt: DateTime.parse(json['created_at']),
      );
}

/// API Service with offline support
class ApiService {
  final http.Client _client;
  String? _authToken;
  static const _queueBoxName = 'offline_queue';

  ApiService() : _client = http.Client();

  /// Set auth token for authenticated requests
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Clear auth token on logout
  void clearAuthToken() {
    _authToken = null;
  }

  /// Check if device is online
  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result.isNotEmpty && !result.contains(ConnectivityResult.none);
  }

  /// Build headers with optional auth
  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  /// Queue request for offline execution
  Future<void> _queueRequest(
      String method, String endpoint, Map<String, dynamic>? body) async {
    final box = await Hive.openBox<Map>(_queueBoxName);
    final request = QueuedRequest(
      method: method,
      endpoint: endpoint,
      body: body,
      createdAt: DateTime.now(),
    );
    await box.add(request.toJson());
  }

  /// Process offline queue when back online
  Future<void> processQueue() async {
    if (!await isOnline()) return;

    final box = await Hive.openBox<Map>(_queueBoxName);
    final keys = box.keys.toList();

    for (var key in keys) {
      final data = box.get(key);
      if (data != null) {
        final request = QueuedRequest.fromJson(Map<String, dynamic>.from(data));
        try {
          switch (request.method) {
            case 'POST':
              await post(request.endpoint, request.body ?? {},
                  offlineQueue: false);
              break;
            case 'PUT':
              await put(request.endpoint, request.body ?? {},
                  offlineQueue: false);
              break;
            case 'DELETE':
              await delete(request.endpoint, offlineQueue: false);
              break;
          }
          await box.delete(key);
        } catch (_) {
          // Keep in queue if fails
        }
      }
    }
  }

  /// GET request
  Future<Map<String, dynamic>> get(String endpoint) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    try {
      final response = await _client
          .get(uri, headers: _headers())
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool offlineQueue = true,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    // Queue if offline
    if (offlineQueue && !await isOnline()) {
      await _queueRequest('POST', endpoint, body);
      return {'queued': true, 'message': 'Request queued for sync'};
    }

    try {
      final response = await _client
          .post(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      if (offlineQueue) {
        await _queueRequest('POST', endpoint, body);
        return {'queued': true, 'message': 'Request queued for sync'};
      }
      throw ApiException('Network error: $e');
    }
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool offlineQueue = true,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    if (offlineQueue && !await isOnline()) {
      await _queueRequest('PUT', endpoint, body);
      return {'queued': true, 'message': 'Request queued for sync'};
    }

    try {
      final response = await _client
          .put(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      if (offlineQueue) {
        await _queueRequest('PUT', endpoint, body);
        return {'queued': true, 'message': 'Request queued for sync'};
      }
      throw ApiException('Network error: $e');
    }
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool offlineQueue = true,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    if (offlineQueue && !await isOnline()) {
      await _queueRequest('DELETE', endpoint, null);
      return {'queued': true, 'message': 'Request queued for sync'};
    }

    try {
      final response = await _client
          .delete(uri, headers: _headers())
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  /// Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is List) {
        return {'data': body};
      }
      return body as Map<String, dynamic>;
    }

    final message = body['detail'] ?? 'Request failed';
    throw ApiException(message, statusCode: response.statusCode);
  }

  /// Get queue size
  Future<int> getQueueSize() async {
    final box = await Hive.openBox<Map>(_queueBoxName);
    return box.length;
  }
}

/// API Exception
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

/// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

/// Connectivity Provider
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Is Online Provider
final isOnlineProvider = FutureProvider<bool>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.isOnline();
});

/// Queue Size Provider
final queueSizeProvider = FutureProvider<int>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getQueueSize();
});
