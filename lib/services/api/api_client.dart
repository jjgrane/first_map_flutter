import 'dart:convert';
import 'dart:io';
import 'dart:async'; // For TimeoutException
import 'package:http/http.dart' as http;
import 'package:first_maps_project/services/api/api_error.dart';
import 'package:first_maps_project/services/api/api_response.dart';
import 'package:first_maps_project/services/api/api_endpoints.dart';

/// Centralized HTTP client for API calls with retry logic and error handling
class ApiClient {
  final http.Client _httpClient;
  final Duration _timeout;
  final int _maxRetries;
  
  ApiClient({
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = 3,
  })  : _httpClient = httpClient ?? http.Client(),
        _timeout = timeout,
        _maxRetries = maxRetries;

  /// Common headers for all requests
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Performs a GET request
  Future<ApiResponse<T>> get<T>({
    required String endpoint,
    Map<String, String>? queryParams,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    return _executeRequest(
      () => _httpClient.get(uri, headers: _headers),
      fromJson: fromJson,
    );
  }

  /// Performs a GET request that returns a list
  Future<ApiResponse<List<T>>> getList<T>({
    required String endpoint,
    Map<String, String>? queryParams,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    return _executeListRequest(
      () => _httpClient.get(uri, headers: _headers),
      fromJson: fromJson,
    );
  }

  /// Performs a POST request
  Future<ApiResponse<T>> post<T>({
    required String endpoint,
    required Map<String, dynamic> body,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final uri = _buildUri(endpoint);
    return _executeRequest(
      () => _httpClient.post(
        uri,
        headers: _headers,
        body: jsonEncode(body),
      ),
      fromJson: fromJson,
    );
  }

  /// Performs a PUT request
  Future<ApiResponse<T>> put<T>({
    required String endpoint,
    required Map<String, dynamic> body,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final uri = _buildUri(endpoint);
    return _executeRequest(
      () => _httpClient.put(
        uri,
        headers: _headers,
        body: jsonEncode(body),
      ),
      fromJson: fromJson,
    );
  }

  /// Performs a DELETE request
  Future<ApiResponse<void>> delete({
    required String endpoint,
  }) async {
    final uri = _buildUri(endpoint);
    return _executeRequest(
      () => _httpClient.delete(uri, headers: _headers),
      fromJson: (_) {},
    );
  }

  /// Builds the full URI with base URL and query parameters
  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    final url = '${ApiEndpoints.baseUrl}$endpoint';
    return Uri.parse(url).replace(queryParameters: queryParams);
  }

  /// Executes an HTTP request with retry logic and error handling
  Future<ApiResponse<T>> _executeRequest<T>(
    Future<http.Response> Function() request, {
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    int attempts = 0;
    
    while (attempts < _maxRetries) {
      try {
        attempts++;
        
        final response = await request().timeout(_timeout);
        
        if (response.statusCode >= 200 && response.statusCode < 300) {
          if (response.body.isEmpty || response.statusCode == 204) {
            // Handle empty responses (like successful DELETE)
            return ApiResponse.success({} as T);
          }
          
          final data = jsonDecode(response.body);
          return ApiResponse.success(fromJson(data));
        } else {
          // Handle error responses
          final error = _parseErrorResponse(response);
          
          // Don't retry client errors (4xx)
          if (response.statusCode >= 400 && response.statusCode < 500) {
            return ApiResponse.failure(error);
          }
          
          // Retry server errors if not last attempt
          if (attempts >= _maxRetries) {
            return ApiResponse.failure(error);
          }
          
          // Wait before retrying (exponential backoff)
          await Future.delayed(Duration(seconds: attempts));
        }
      } on SocketException {
        if (attempts >= _maxRetries) {
          return ApiResponse.failure(ApiError.networkError());
        }
        await Future.delayed(Duration(seconds: attempts));
      } on TimeoutException {
        if (attempts >= _maxRetries) {
          return ApiResponse.failure(ApiError.timeoutError());
        }
        await Future.delayed(Duration(seconds: attempts));
      } on FormatException catch (e) {
        return ApiResponse.failure(ApiError(
          message: 'Invalid response format',
          details: e.toString(),
        ));
      } catch (e) {
        if (attempts >= _maxRetries) {
          return ApiResponse.failure(ApiError(
            message: 'Request failed: ${e.toString()}',
          ));
        }
        await Future.delayed(Duration(seconds: attempts));
      }
    }
    
    return ApiResponse.failure(ApiError.unknownError());
  }

  /// Executes an HTTP request that returns a list
  Future<ApiResponse<List<T>>> _executeListRequest<T>(
    Future<http.Response> Function() request, {
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    int attempts = 0;
    
    while (attempts < _maxRetries) {
      try {
        attempts++;
        
        final response = await request().timeout(_timeout);
        
        if (response.statusCode >= 200 && response.statusCode < 300) {
          if (response.body.isEmpty) {
            return ApiResponse.success(<T>[]);
          }
          
          final data = jsonDecode(response.body);
          if (data is! List) {
            return ApiResponse.failure(ApiError(
              message: 'Expected a list response but got ${data.runtimeType}',
            ));
          }
          
          final items = data.map((item) {
            if (item is! Map<String, dynamic>) {
              throw FormatException('Invalid item format in list');
            }
            return fromJson(item);
          }).toList();
          
          return ApiResponse.success(items);
        } else {
          // Handle error responses
          final error = _parseErrorResponse(response);
          
          // Don't retry client errors (4xx)
          if (response.statusCode >= 400 && response.statusCode < 500) {
            return ApiResponse.failure(error);
          }
          
          // Retry server errors if not last attempt
          if (attempts >= _maxRetries) {
            return ApiResponse.failure(error);
          }
          
          // Wait before retrying (exponential backoff)
          await Future.delayed(Duration(seconds: attempts));
        }
      } on SocketException {
        if (attempts >= _maxRetries) {
          return ApiResponse.failure(ApiError.networkError());
        }
        await Future.delayed(Duration(seconds: attempts));
      } on TimeoutException {
        if (attempts >= _maxRetries) {
          return ApiResponse.failure(ApiError.timeoutError());
        }
        await Future.delayed(Duration(seconds: attempts));
      } on FormatException catch (e) {
        return ApiResponse.failure(ApiError(
          message: 'Invalid response format',
          details: e.toString(),
        ));
      } catch (e) {
        if (attempts >= _maxRetries) {
          return ApiResponse.failure(ApiError(
            message: 'Request failed: ${e.toString()}',
          ));
        }
        await Future.delayed(Duration(seconds: attempts));
      }
    }
    
    return ApiResponse.failure(ApiError.unknownError());
  }

  /// Parses error response from HTTP response
  ApiError _parseErrorResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        // Always include the HTTP status code
        return ApiError(
          statusCode: response.statusCode,
          message: data['message'] as String? ?? 'Request failed with status ${response.statusCode}',
          details: data['details'] as String?,
          data: data,
        );
      }
    } catch (_) {
      // If parsing fails, use basic error
    }
    
    return ApiError(
      statusCode: response.statusCode,
      message: 'Request failed with status ${response.statusCode}',
      details: response.body,
    );
  }

  /// Closes the HTTP client
  void dispose() {
    _httpClient.close();
  }
} 