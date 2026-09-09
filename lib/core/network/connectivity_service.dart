import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to check internet connectivity before making API calls.
class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();

  /// Returns true if the device has an active network connection
  /// (WiFi, mobile data, ethernet, or VPN).
  static Future<bool> hasInternet() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }
}
