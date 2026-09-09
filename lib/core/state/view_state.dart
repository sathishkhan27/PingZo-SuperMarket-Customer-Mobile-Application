/// Represents the lifecycle state of an async operation in a provider.
enum ViewState {
  /// No operation in progress. Initial state.
  idle,

  /// An async operation is in progress (show spinner).
  loading,

  /// The last operation completed successfully.
  success,

  /// The last operation failed (check [BaseProvider.errorMessage]).
  error,
}
