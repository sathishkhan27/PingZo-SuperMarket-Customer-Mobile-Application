import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../core/state/base_provider.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthProvider extends BaseProvider {
  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isDriverMode = false;
  bool _hasSkippedAuth = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isDriverMode => _isDriverMode;
  bool get hasSkippedAuth => _hasSkippedAuth;

  AuthProvider() {
    loadSession();
  }

  Future<void> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSkippedAuth = prefs.getBool('hasSkippedAuth') ?? false;
      _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
      final phone = prefs.getString('userPhone');
      final name = prefs.getString('userName');
      final role = prefs.getString('userRole') ?? 'customer';
      final id = prefs.getString('userId') ?? (role == 'driver' ? 'drv_88' : 'cust_101');
      final token = prefs.getString('authToken');
      if (token != null && token.isNotEmpty) {
        ApiClient.setAuthToken(token);
      }
      if (_isAuthenticated && phone != null) {
        _currentUser = UserModel(
          id: id,
          name: name ?? "Customer",
          phone: phone,
          email: "$role@pingzo.com",
          role: role,
        );
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> skipAuth() async {
    _hasSkippedAuth = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSkippedAuth', true);
    } catch (_) {}
  }

  void toggleMode(bool isDriver) {
    _isDriverMode = isDriver;
    if (isDriver) {
      _currentUser = UserModel(
        id: "drv_88",
        name: "Ramesh Kumar",
        phone: "+91 98765 43210",
        email: "ramesh.driver@pingzo.com",
        role: "driver",
        vehicleType: "EV Scooter",
        vehicleNumber: "KA-05-PZ-9988",
        rating: 4.9,
      );
    } else {
      _currentUser = UserModel(
        id: "cust_101",
        name: "Sathish Kumar",
        phone: "+91 98765 12345",
        email: "sathish@pingzo.com",
        role: "customer",
      );
    }
    _isAuthenticated = true;
    notifyListeners();
  }

  /// Request OTP from backend authentication microservice.
  Future<bool> sendOtp(String phone, {String? name}) async {
    final success = await runAsync(() async {
      await ApiService.sendOtp(
        phone: phone,
        name: name,
        // role: _isDriverMode ? 'DRIVER' : 'CUSTOMER',
      );
    });
    return success;
  }

  /// Login with OTP and synchronize user profile & JWT token.
  Future<bool> loginWithOtp(String phone, String otp, {String? name}) async {
    final success = await runAsync(() async {
      final res = await ApiService.verifyOtp(
        phone: phone,
        otp: otp,
        name: name,
        // role: _isDriverMode ? 'DRIVER' : 'CUSTOMER',
      );

      final user = res['user'] as UserModel?;
      final token = res['token']?.toString();

      _currentUser = user;
      _isAuthenticated = true;
      _hasSkippedAuth = true;

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAuthenticated', true);
        await prefs.setBool('hasSkippedAuth', true);
        if (user != null) {
          await prefs.setString('userPhone', user.phone);
          await prefs.setString('userName', user.name);
          await prefs.setString('userRole', user.role);
          await prefs.setString('userId', user.id);
        }
        if (token != null) {
          await prefs.setString('authToken', token);
        }
      } catch (_) {}
    });
    return success;
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _currentUser = null;
    await ApiService.logoutCustomer();
    ApiClient.setAuthToken(null);
    setIdle();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isAuthenticated');
      await prefs.remove('userPhone');
      await prefs.remove('userName');
      await prefs.remove('userRole');
      await prefs.remove('userId');
      await prefs.remove('authToken');
    } catch (_) {}
    notifyListeners();
  }
}
