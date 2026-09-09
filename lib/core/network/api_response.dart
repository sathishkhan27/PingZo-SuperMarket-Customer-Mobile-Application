/// Generic typed response wrapper for API calls.
///
/// Usage:
///   final response = ApiResponse.success(data: products);
///   final response = ApiResponse.error(message: 'Not found');

class ApiResponse<T> {
  final T? data;
  final String? errorMessage;
  final bool isSuccess;

  const ApiResponse._({
    this.data,
    this.errorMessage,
    required this.isSuccess,
  });

  factory ApiResponse.success({required T data}) {
    return ApiResponse._(data: data, isSuccess: true);
  }

  factory ApiResponse.error({required String message}) {
    return ApiResponse._(errorMessage: message, isSuccess: false);
  }
}
