import 'package:first_maps_project/services/api/api_error.dart';

/// Generic API response wrapper that can hold either a successful result or an error
class ApiResponse<T> {
  final T? data;
  final ApiError? error;
  final bool isSuccess;

  ApiResponse._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  /// Creates a successful response
  factory ApiResponse.success(T data) {
    return ApiResponse._(
      data: data,
      error: null,
      isSuccess: true,
    );
  }

  /// Creates an error response
  factory ApiResponse.failure(ApiError error) {
    return ApiResponse._(
      data: null,
      error: error,
      isSuccess: false,
    );
  }

  /// Maps the data if the response is successful
  ApiResponse<R> map<R>(R Function(T) transform) {
    if (isSuccess && data != null) {
      return ApiResponse.success(transform(data as T));
    } else {
      return ApiResponse.failure(error!);
    }
  }

  /// Execute different callbacks based on success or failure
  R fold<R>({
    required R Function(T) onSuccess,
    required R Function(ApiError) onFailure,
  }) {
    if (isSuccess && data != null) {
      return onSuccess(data as T);
    } else {
      return onFailure(error!);
    }
  }

  /// Returns the data or throws the error
  T getOrThrow() {
    if (isSuccess && data != null) {
      return data as T;
    } else {
      throw Exception(error?.message ?? 'Unknown error');
    }
  }

  /// Returns the data or a default value
  T getOrElse(T defaultValue) {
    if (isSuccess && data != null) {
      return data as T;
    } else {
      return defaultValue;
    }
  }
} 