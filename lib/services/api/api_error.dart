/// Represents an error from the API
class ApiError {
  final int? statusCode;
  final String message;
  final String? details;
  final Map<String, dynamic>? data;

  ApiError({
    this.statusCode,
    required this.message,
    this.details,
    this.data,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      statusCode: json['status_code'] as int?,
      message: json['message'] as String? ?? 'Unknown error',
      details: json['details'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  factory ApiError.fromException(Exception e, {int? statusCode}) {
    return ApiError(
      statusCode: statusCode,
      message: e.toString(),
    );
  }

  factory ApiError.fromError(Object error, {int? statusCode}) {
    return ApiError(
      statusCode: statusCode,
      message: error.toString(),
    );
  }

  factory ApiError.networkError() {
    return ApiError(
      message: 'Network error. Please check your connection.',
    );
  }

  factory ApiError.timeoutError() {
    return ApiError(
      message: 'Request timed out. Please try again.',
    );
  }

  factory ApiError.unknownError() {
    return ApiError(
      message: 'An unknown error occurred.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (statusCode != null) 'status_code': statusCode,
      'message': message,
      if (details != null) 'details': details,
      if (data != null) 'data': data,
    };
  }

  @override
  String toString() {
    return 'ApiError(statusCode: $statusCode, message: $message, details: $details)';
  }
} 