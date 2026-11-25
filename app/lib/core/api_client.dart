import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pantry_app/core/constants.dart';
import 'package:pantry_app/core/storage.dart';

/// Structured API Exception representing client, server, or network errors.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic details;

  ApiException({
    required this.statusCode,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Central HTTP API Client.
/// - Reads base URL from compile-time constant (API_BASE_URL)
/// - Automatically injects Bearer token in the Authorization header
/// - Provides centralized JSON decoding and error handling
class ApiClient {
  static const Duration _timeout = Duration(seconds: 12);

  final http.Client _httpClient;
  final StorageService _storage;
  final String baseUrl;

  ApiClient({
    http.Client? httpClient,
    StorageService? storage,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _storage = storage ?? StorageService(),
        baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  /// Builds common HTTP headers, adding Authorization if token exists.
  Future<Map<String, String>> _buildHeaders([Map<String, String>? extra]) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await _storage.getAuthToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  /// Converts any network-layer error into a friendly [ApiException].
  /// In debug mode the full URL and underlying error are printed.
  Never _handleNetworkError(Uri uri, Object error) {
    if (kDebugMode) {
      debugPrint('[ApiClient] Request to ${uri.toString()} failed: $error');
    }
    throw ApiException(
      statusCode: 0,
      message: 'Cannot reach the server, please try again.',
    );
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParams]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$baseUrl$cleanPath';
    final uri = Uri.parse(fullUrl);

    if (queryParams != null && queryParams.isNotEmpty) {
      final stringParams = queryParams.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      );
      return uri.replace(queryParameters: stringParams);
    }
    return uri;
  }

  dynamic _processResponse(http.Response response) {
    dynamic decodedBody;
    if (response.body.isNotEmpty) {
      try {
        decodedBody = jsonDecode(response.body);
      } catch (_) {
        decodedBody = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decodedBody;
    }

    // Extract error message from FastAPI standard error response
    String errorMessage = 'Request failed with status: ${response.statusCode}';
    if (decodedBody is Map && decodedBody.containsKey('detail')) {
      final detail = decodedBody['detail'];
      if (detail is String) {
        errorMessage = detail;
      } else {
        errorMessage = jsonEncode(detail);
      }
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: errorMessage,
      details: decodedBody,
    );
  }

  /// Sends a GET request.
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    final uri = _buildUri(path, queryParams);
    try {
      final headers = await _buildHeaders();
      final response = await _httpClient
          .get(uri, headers: headers)
          .timeout(_timeout);
      return _processResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      _handleNetworkError(uri, e);
    }
  }

  /// Sends a POST request.
  Future<dynamic> post(String path, {dynamic body}) async {
    final uri = _buildUri(path);
    try {
      final headers = await _buildHeaders();
      final response = await _httpClient
          .post(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(_timeout);
      return _processResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      _handleNetworkError(uri, e);
    }
  }

  /// Sends a PATCH request.
  Future<dynamic> patch(String path, {dynamic body}) async {
    final uri = _buildUri(path);
    try {
      final headers = await _buildHeaders();
      final response = await _httpClient
          .patch(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(_timeout);
      return _processResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      _handleNetworkError(uri, e);
    }
  }

  /// Sends a DELETE request.
  Future<dynamic> delete(String path) async {
    final uri = _buildUri(path);
    try {
      final headers = await _buildHeaders();
      final response = await _httpClient
          .delete(uri, headers: headers)
          .timeout(_timeout);
      return _processResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      _handleNetworkError(uri, e);
    }
  }
}
