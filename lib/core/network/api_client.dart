import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_exception.dart';
import 'connectivity_service.dart';

/// Central HTTP client that all API calls route through.
///
/// Handles:
/// - Internet connectivity checks
/// - Request timeouts (default 10s)
/// - HTTP status code → typed exception mapping
/// - JSON decoding
/// - Common headers
class ApiClient {
  static const String baseUrl = "http://10.100.102.173:8081/api";
  static const Duration _defaultTimeout = Duration(seconds: 10);
  static String? authToken;

  static void setAuthToken(String? token) {
    authToken = token;
  }

  static Map<String, String> _defaultHeaders({bool requiresAuth = false, String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final effectiveToken = token ?? authToken;
    if ((requiresAuth || effectiveToken != null) && effectiveToken != null && effectiveToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $effectiveToken';
    }
    return headers;
  }

  static String buildUrl(String endpoint) {
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      return endpoint;
    }
    final cleanEp = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    // If endpoint already starts with /api and baseUrl ends with /api, avoid /api/api
    if (baseUrl.endsWith('/api') && cleanEp.startsWith('/api/')) {
      final rootBase = baseUrl.substring(0, baseUrl.length - 4);
      return '$rootBase$cleanEp';
    }
    return '$baseUrl$cleanEp';
  }

  // ──────────────────────────────────────────────
  // Public HTTP methods
  // ──────────────────────────────────────────────

  /// Performs a GET request and returns the decoded JSON body.
  /// Set [requiresAuth] to false (default) for public endpoints like GET products.
  static Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    Duration? timeout,
    bool requiresAuth = false,
    String? authToken,
  }) async {
    final url = buildUrl(endpoint);
    return _executeRequest(
      () => http.get(
        Uri.parse(url),
        headers: {
          ..._defaultHeaders(requiresAuth: requiresAuth, token: authToken),
          ...?headers,
        },
      ),
      timeout: timeout,
    );
  }

  /// Performs a POST request with an optional JSON body.
  static Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final url = buildUrl(endpoint);
    return _executeRequest(
      () => http.post(
        Uri.parse(url),
        headers: {..._defaultHeaders(), ...?headers},
        body: body != null ? json.encode(body) : null,
      ),
      timeout: timeout,
    );
  }

  /// Performs a PUT request with an optional JSON body.
  static Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final url = buildUrl(endpoint);
    return _executeRequest(
      () => http.put(
        Uri.parse(url),
        headers: {..._defaultHeaders(), ...?headers},
        body: body != null ? json.encode(body) : null,
      ),
      timeout: timeout,
    );
  }

  /// Performs a DELETE request.
  static Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final url = buildUrl(endpoint);
    return _executeRequest(
      () => http.delete(
        Uri.parse(url),
        headers: {..._defaultHeaders(), ...?headers},
      ),
      timeout: timeout,
    );
  }

  // ──────────────────────────────────────────────
  // Core execution pipeline
  // ──────────────────────────────────────────────

  static Future<dynamic> _executeRequest(
    Future<http.Response> Function() requestFn, {
    Duration? timeout,
  }) async {
    // 1. Internet connectivity check
    final hasInternet = await ConnectivityService.hasInternet();
    if (!hasInternet) {
      throw const NoInternetException();
    }

    // 2. Execute request with timeout
    http.Response response;
    try {
      response = await requestFn().timeout(timeout ?? _defaultTimeout);
    } on TimeoutException {
      throw const TimeoutException();
    } on SocketException {
      throw const NoInternetException();
    } catch (e) {
      throw ApiException(
        message: 'Connection failed. Please try again.',
        originalError: e,
      );
    }

    // 3. Map HTTP status codes to typed exceptions
    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        // Success — decode JSON body
        if (response.body.isEmpty) return null;
        try {
          return json.decode(response.body);
        } catch (e) {
          throw ApiException(
            message: 'Invalid response format from server.',
            statusCode: response.statusCode,
            originalError: e,
          );
        }

      case 204:
        // No Content — success with no body
        return null;

      case 400:
        final detail = _extractErrorMessage(response);
        throw BadRequestException(detail: detail);

      case 401:
        throw const UnauthorizedException();

      case 404:
        throw const NotFoundException();

      case 500:
      case 502:
      case 503:
        throw ServerException(statusCode: response.statusCode);

      default:
        throw ApiException(
          message: _extractErrorMessage(response) ??
              'Something went wrong (${response.statusCode}).',
          statusCode: response.statusCode,
        );
    }
  }

  /// Tries to extract an error message from the response body JSON.
  static String? _extractErrorMessage(http.Response response) {
    try {
      final body = json.decode(response.body);
      return body['message'] ?? body['error'] ?? body['detail'];
    } catch (_) {
      return null;
    }
  }
}
