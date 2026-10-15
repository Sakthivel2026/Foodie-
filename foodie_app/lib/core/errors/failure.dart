import 'package:dio/dio.dart';

enum FailureType {
  noNetwork,
  badRequest, // 400
  unauthorized, // 401
  forbidden, // 403
  notFound, // 404
  conflict, // 409
  rateLimited, // 429
  serverError, // 500+
  unknown,
}

class Failure implements Exception {
  final String message;
  final int? statusCode;
  final FailureType type;

  const Failure({
    required this.message,
    required this.type,
    this.statusCode,
  });

  factory Failure.fromDioException(DioException exception) {
    if (exception.type == DioExceptionType.connectionTimeout ||
        exception.type == DioExceptionType.sendTimeout ||
        exception.type == DioExceptionType.receiveTimeout ||
        exception.type == DioExceptionType.connectionError) {
      return const Failure(
        message: 'No internet connection. Please check your network and try again.',
        type: FailureType.noNetwork,
      );
    }

    final response = exception.response;
    if (response != null) {
      final statusCode = response.statusCode;
      String extractedMessage = '';

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('error') && data['error'] != null) {
          extractedMessage = data['error'].toString();
        }
      }

      switch (statusCode) {
        case 400:
          return Failure(
            message: extractedMessage.isNotEmpty
                ? extractedMessage
                : 'Invalid request. Please check your details.',
            type: FailureType.badRequest,
            statusCode: 400,
          );
        case 401:
          return Failure(
            message: extractedMessage.isNotEmpty
                ? extractedMessage
                : 'Session expired. Please log in again.',
            type: FailureType.unauthorized,
            statusCode: 401,
          );
        case 403:
          return Failure(
            message: extractedMessage.isNotEmpty
                ? extractedMessage
                : 'You do not have permission to perform this action.',
            type: FailureType.forbidden,
            statusCode: 403,
          );
        case 404:
          return Failure(
            message: extractedMessage.isNotEmpty
                ? extractedMessage
                : 'Requested resource not found.',
            type: FailureType.notFound,
            statusCode: 404,
          );
        case 409:
          return Failure(
            message: extractedMessage.isNotEmpty
                ? extractedMessage
                : 'Conflict detected. Please try again.',
            type: FailureType.conflict,
            statusCode: 409,
          );
        case 429:
          return Failure(
            message: extractedMessage.isNotEmpty
                ? extractedMessage
                : 'Too many requests. Please wait a moment and try again.',
            type: FailureType.rateLimited,
            statusCode: 429,
          );
        default:
          if (statusCode != null && statusCode >= 500) {
            return Failure(
              message: 'Server error occurred ($statusCode). Please try again later.',
              type: FailureType.serverError,
              statusCode: statusCode,
            );
          }
      }
    }

    return Failure(
      message: exception.message ?? 'An unexpected network error occurred.',
      type: FailureType.unknown,
      statusCode: response?.statusCode,
    );
  }

  factory Failure.unknown([String? message]) {
    return Failure(
      message: message ?? 'An unexpected error occurred.',
      type: FailureType.unknown,
    );
  }

  @override
  String toString() => 'Failure(statusCode: $statusCode, type: $type, message: $message)';
}
