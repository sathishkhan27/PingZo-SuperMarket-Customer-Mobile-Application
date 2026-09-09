/// Custom exception classes for API error handling.
///
/// All API-related exceptions extend [ApiException] so callers
/// can catch the base class or specific subtypes.

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const ApiException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thrown when the device has no internet connection.
class NoInternetException extends ApiException {
  const NoInternetException()
      : super(message: 'No internet connection. Please check your network and try again.');
}

/// Thrown when the request exceeds the timeout duration.
class TimeoutException extends ApiException {
  const TimeoutException()
      : super(message: 'Request timed out. Please try again.');
}

/// Thrown for 5xx server errors.
class ServerException extends ApiException {
  const ServerException({int? statusCode})
      : super(
          message: 'Server error. Please try again later.',
          statusCode: statusCode,
        );
}

/// Thrown for 401 Unauthorized responses.
class UnauthorizedException extends ApiException {
  const UnauthorizedException()
      : super(message: 'Session expired. Please login again.', statusCode: 401);
}

/// Thrown for 404 Not Found responses.
class NotFoundException extends ApiException {
  const NotFoundException()
      : super(message: 'Requested resource not found.', statusCode: 404);
}

/// Thrown for 400 Bad Request responses.
class BadRequestException extends ApiException {
  const BadRequestException({String? detail})
      : super(
          message: detail ?? 'Invalid request. Please try again.',
          statusCode: 400,
        );
}
