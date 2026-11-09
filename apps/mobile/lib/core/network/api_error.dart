import 'package:dio/dio.dart';

class ApiError implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  const ApiError({
    required this.code,
    required this.message,
    this.statusCode,
  });

  factory ApiError.fromDioException(DioException e) {
    final response = e.response;
    if (response != null) {
      final data = response.data;
      if (data is Map) {
        return ApiError(
          code: data['error'] as String? ?? 'unknown_error',
          message: data['message'] as String? ?? 'An error occurred',
          statusCode: response.statusCode,
        );
      }
    }
    return ApiError(
      code: 'network_error',
      message: 'Network error. Check your connection.',
      statusCode: e.response?.statusCode,
    );
  }

  @override
  String toString() => message;
}
