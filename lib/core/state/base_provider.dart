import 'package:flutter/material.dart';
import 'view_state.dart';
import '../network/api_exception.dart';

/// Base class for all providers. Provides consistent state management
/// with [ViewState] lifecycle, error messages, and a [runAsync] helper
/// that auto-manages state transitions and catches typed API exceptions.
///
/// Usage:
/// ```dart
/// class MyProvider extends BaseProvider {
///   Future<void> loadData() => runAsync(() async {
///     final data = await ApiService.getData();
///     _items = data;
///   });
/// }
/// ```
abstract class BaseProvider extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;

  // ─── Getters ───────────────────────────────────────

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  String? get error => _errorMessage;

  bool get isLoading => _state == ViewState.loading;
  bool get isSuccess => _state == ViewState.success;
  bool get hasError => _state == ViewState.error;
  bool get isIdle => _state == ViewState.idle;

  // ─── State setters ─────────────────────────────────

  /// Sets the provider to loading state and clears any previous error.
  @protected
  void setLoading() {
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();
  }

  /// Sets the provider to success state.
  @protected
  void setSuccess() {
    _state = ViewState.success;
    _errorMessage = null;
    notifyListeners();
  }

  /// Sets the provider to error state with a user-friendly message.
  @protected
  void setError(String message) {
    _state = ViewState.error;
    _errorMessage = message;
    notifyListeners();
  }

  /// Resets the provider to idle state.
  @protected
  void setIdle() {
    _state = ViewState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Async helper ──────────────────────────────────

  /// Runs an async action with automatic state management.
  ///
  /// 1. Sets state to [ViewState.loading]
  /// 2. Executes [action]
  /// 3. On success → [ViewState.success]
  /// 4. On failure → [ViewState.error] with a user-friendly message
  ///    derived from the exception type
  ///
  /// Returns `true` if the action succeeded, `false` otherwise.
  @protected
  Future<bool> runAsync(Future<void> Function() action) async {
    setLoading();
    try {
      await action();
      setSuccess();
      return true;
    } on NoInternetException {
      setError('No internet connection. Please check your network and try again.');
      return false;
    } on TimeoutException {
      setError('Request timed out. Please try again.');
      return false;
    } on ServerException {
      setError('Server is temporarily unavailable. Please try again later.');
      return false;
    } on UnauthorizedException {
      setError('Session expired. Please login again.');
      return false;
    } on ApiException catch (e) {
      setError(e.message);
      return false;
    } catch (e) {
      setError('Something went wrong. Please try again.');
      return false;
    }
  }
}
