import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  const baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8085');
  return ApiClient(baseUrl: baseUrl, secureStorage: const FlutterSecureStorage());
});

class ApiClient {
  final String baseUrl;
  final FlutterSecureStorage _secureStorage;
  Function()? onUnauthorized;

  static const _sessionTokenKey = 'session_token';

  ApiClient({required this.baseUrl, required FlutterSecureStorage secureStorage}) : _secureStorage = secureStorage;

  Future<String?> getSessionToken() async {
    return await _secureStorage.read(key: _sessionTokenKey);
  }

  Future<void> setSessionToken(String token) async {
    await _secureStorage.write(key: _sessionTokenKey, value: token);
  }

  Future<void> clearSessionToken() async {
    await _secureStorage.delete(key: _sessionTokenKey);
  }

  Future<Map<String, String>> _getHeaders({bool requireAuth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json', 'Accept': 'application/json'};

    if (requireAuth) {
      final token = await getSessionToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    bool requireAuth = false,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http.get(Uri.parse('$baseUrl$path'), headers: headers);
      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    bool requireAuth = false,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<List<T>>> getList<T>(
    String path, {
    bool requireAuth = false,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http.get(Uri.parse('$baseUrl$path'), headers: headers);
      return _handleListResponse(response, fromJson);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<List<T>>> postList<T>(
    String path, {
    Map<String, dynamic>? body,
    bool requireAuth = false,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleListResponse(response, fromJson);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  ApiResponse<T> _handleResponse<T>(http.Response response, T Function(Map<String, dynamic>)? fromJson) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) as Map<String, dynamic> : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (fromJson != null) {
        return ApiResponse.success(fromJson(body));
      }
      return ApiResponse.success(body as T);
    } else {
      if (response.statusCode == 401) {
        onUnauthorized?.call();
      }
      final error = body['error'] as String? ?? 'Unknown error';
      return ApiResponse.error(error, statusCode: response.statusCode);
    }
  }

  ApiResponse<List<T>> _handleListResponse<T>(http.Response response, T Function(Map<String, dynamic>) fromJson) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : [];
      if (body is List) {
        final items = body.map((e) => fromJson(e as Map<String, dynamic>)).toList();
        return ApiResponse.success(items);
      }
      return ApiResponse.success([]);
    } else {
      if (response.statusCode == 401) {
        onUnauthorized?.call();
      }
      final body = response.body.isNotEmpty ? jsonDecode(response.body) as Map<String, dynamic> : <String, dynamic>{};
      final error = body['error'] as String? ?? 'Unknown error';
      return ApiResponse.error(error, statusCode: response.statusCode);
    }
  }
}

class ApiResponse<T> {
  final T? data;
  final String? error;
  final int? statusCode;
  final bool isSuccess;

  ApiResponse._({this.data, this.error, this.statusCode, required this.isSuccess});

  factory ApiResponse.success(T data) {
    return ApiResponse._(data: data, isSuccess: true);
  }

  factory ApiResponse.error(String error, {int? statusCode}) {
    return ApiResponse._(error: error, statusCode: statusCode, isSuccess: false);
  }
}
