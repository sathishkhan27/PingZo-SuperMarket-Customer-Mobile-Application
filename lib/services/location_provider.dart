import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/address_model.dart';
import 'api_service.dart';

class LocationProvider with ChangeNotifier {
  AddressModel? _activeAddress;
  List<AddressModel> _addresses = [];
  bool _isLoading = false;

  AddressModel? get activeAddress => _activeAddress;
  List<AddressModel> get addresses => _addresses;
  bool get isLoading => _isLoading;

  String get activeAddressTitle {
    if (_activeAddress != null) {
      return "${_activeAddress!.type} - ${_activeAddress!.addressDetails}";
    }
    if (_addresses.isNotEmpty) {
      final first = _addresses.first;
      return "${first.type} - ${first.addressDetails}";
    }
    return "Select Location";
  }

  LocationProvider() {
    loadLocationData();
  }

  Future<void> loadLocationData({String customerId = '1'}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Load cached active address from Local Storage (user's previously selected address)
      final activeStr = prefs.getString('active_address');
      if (activeStr != null && activeStr.isNotEmpty) {
        try {
          _activeAddress = AddressModel.fromJson(jsonDecode(activeStr));
          notifyListeners();
        } catch (_) {}
      }

      // 2. Load cached address list from Local Storage
      final cachedListStr = prefs.getString('saved_addresses');
      if (cachedListStr != null && cachedListStr.isNotEmpty) {
        try {
          final List raw = jsonDecode(cachedListStr);
          _addresses = raw.map((x) => AddressModel.fromJson(x)).toList();
          if (_activeAddress == null && _addresses.isNotEmpty) {
            _activeAddress = _addresses.first;
          }
          notifyListeners();
        } catch (_) {}
      }

      // 3. Fetch fresh addresses from backend API
      try {
        final apiAddresses = await ApiService.getCustomerAddresses(customerId: customerId);
        if (apiAddresses.isNotEmpty) {
          _addresses = apiAddresses;
          _saveAddressesToCache(prefs, apiAddresses);

          // If no active address set in local storage, select the first saved address
          if (_activeAddress == null) {
            final defaultAddr = apiAddresses.firstWhere(
              (a) => a.isDefault,
              orElse: () => apiAddresses.first,
            );
            _activeAddress = defaultAddr;
            prefs.setString('active_address', jsonEncode(defaultAddr.toJson()));
          }
        }
      } catch (e) {
        if (kDebugMode) print("Network fetch address error (using local storage cache): $e");
      }
    } catch (e) {
      if (kDebugMode) print("Error loading location data from local storage: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setActiveAddress(AddressModel address) async {
    _activeAddress = address;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_address', jsonEncode(address.toJson()));
    } catch (e) {
      if (kDebugMode) print("Error saving active address to local storage: $e");
    }
  }

  /// Instantly saves a new address into Local Storage (SharedPreferences) and syncs with API.
  Future<void> saveAddress(AddressModel address, {String customerId = '1'}) async {
    final localAddr = AddressModel(
      id: address.id.isNotEmpty ? address.id : DateTime.now().millisecondsSinceEpoch.toString(),
      customerId: customerId,
      type: address.type,
      distance: address.distance,
      addressDetails: address.addressDetails,
      isDefault: address.isDefault,
    );

    // 1. Instantly save to local memory & Local Storage SharedPreferences
    _addresses.insert(0, localAddr);
    await setActiveAddress(localAddr);
    await _syncCache();
    notifyListeners();

    // 2. Sync with backend API
    try {
      final savedFromApi = await ApiService.saveCustomerAddress(localAddr, customerId: customerId);
      final idx = _addresses.indexWhere((a) => a.id == localAddr.id);
      if (idx != -1) {
        _addresses[idx] = savedFromApi;
        if (_activeAddress?.id == localAddr.id) {
          await setActiveAddress(savedFromApi);
        }
        await _syncCache();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print("Network save address error (persisted in Local Storage): $e");
    }
  }

  /// Instantly saves detected Current GPS Location into Local Storage (SharedPreferences) and syncs with API.
  Future<AddressModel> saveCurrentGpsLocation({
    required String addressDetails,
    String customerId = '1',
  }) async {
    final currentAddr = AddressModel(
      id: "current_gps_${DateTime.now().millisecondsSinceEpoch}",
      customerId: customerId,
      type: "Current Location",
      distance: "0 m",
      addressDetails: addressDetails,
      isDefault: true,
    );

    // 1. Remove previous current location entry if exists and insert new one
    _addresses.removeWhere((a) => a.type == "Current Location");
    _addresses.insert(0, currentAddr);

    // 2. Set as active address in Local Storage (SharedPreferences)
    await setActiveAddress(currentAddr);
    await _syncCache();
    notifyListeners();

    // 3. Sync with backend API in background
    try {
      final apiSaved = await ApiService.saveCustomerAddress(currentAddr, customerId: customerId);
      final idx = _addresses.indexWhere((a) => a.id == currentAddr.id);
      if (idx != -1) {
        _addresses[idx] = apiSaved;
        await setActiveAddress(apiSaved);
        await _syncCache();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print("Network current location save error (persisted in Local Storage): $e");
    }

    return currentAddr;
  }

  Future<void> editAddress(AddressModel address, {String customerId = '1'}) async {
    try {
      final updated = await ApiService.updateCustomerAddress(address, customerId: customerId);
      final target = updated ?? address;
      final idx = _addresses.indexWhere((a) => a.id == address.id);
      if (idx != -1) {
        _addresses[idx] = target;
      }
      if (_activeAddress?.id == address.id) {
        await setActiveAddress(target);
      }
    } catch (_) {
      final idx = _addresses.indexWhere((a) => a.id == address.id);
      if (idx != -1) {
        _addresses[idx] = address;
      }
      if (_activeAddress?.id == address.id) {
        await setActiveAddress(address);
      }
    }

    notifyListeners();
    _syncCache();
  }

  Future<void> deleteAddress(String addressId, {String customerId = '1'}) async {
    try {
      await ApiService.deleteCustomerAddress(addressId, customerId: customerId);
    } catch (_) {}

    _addresses.removeWhere((a) => a.id == addressId);

    if (_activeAddress?.id == addressId) {
      _activeAddress = _addresses.isNotEmpty ? _addresses.first : null;
      if (_activeAddress != null) {
        await setActiveAddress(_activeAddress!);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('active_address');
      }
    }

    notifyListeners();
    _syncCache();
  }

  Future<void> _syncCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _saveAddressesToCache(prefs, _addresses);
    } catch (e) {
      if (kDebugMode) print("Error syncing addresses to cache: $e");
    }
  }

  void _saveAddressesToCache(SharedPreferences prefs, List<AddressModel> list) {
    final raw = list.map((a) => a.toJson()).toList();
    prefs.setString('saved_addresses', jsonEncode(raw));
  }
}
