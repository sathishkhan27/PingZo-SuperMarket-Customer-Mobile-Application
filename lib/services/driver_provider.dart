import 'dart:async';
import '../core/state/base_provider.dart';
import '../models/order_model.dart';
import 'api_service.dart';
import 'order_provider.dart';

class DriverProvider extends BaseProvider {
  bool _isOnline = true;
  String _currentStep = 'ONLINE'; // 'ONLINE', 'ASSIGNED', 'AT_SUPERMARKET', 'OUT_FOR_DELIVERY', 'DELIVERED'
  OrderModel? _assignedOrder;
  
  int _todayDeliveriesCount = 14;
  double _todayEarnings = 1480.0;
  double _todayDistanceKm = 38.5;
  final double _driverRating = 4.9;
  final double _acceptanceRate = 96.5;

  Timer? _countdownTimer;
  int _assignmentCountdown = 30;
  bool _hasPendingAssignment = false;

  bool get isOnline => _isOnline;
  String get currentStep => _currentStep;
  OrderModel? get assignedOrder => _assignedOrder;
  int get todayDeliveriesCount => _todayDeliveriesCount;
  double get todayEarnings => _todayEarnings;
  double get todayDistanceKm => _todayDistanceKm;
  double get driverRating => _driverRating;
  double get acceptanceRate => _acceptanceRate;
  int get assignmentCountdown => _assignmentCountdown;
  bool get hasPendingAssignment => _hasPendingAssignment;

  void toggleOnlineStatus(bool online) {
    _isOnline = online;
    if (!online) {
      _currentStep = 'OFFLINE';
      _hasPendingAssignment = false;
      _stopCountdown();
    } else {
      _currentStep = 'ONLINE';
    }
    notifyListeners();
  }

  void triggerMockAssignment(OrderModel order) {
    if (!_isOnline || _currentStep != 'ONLINE') return;
    _assignedOrder = order;
    _hasPendingAssignment = true;
    _assignmentCountdown = 30;
    _startCountdown();
    notifyListeners();
  }

  void _startCountdown() {
    _stopCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_assignmentCountdown > 0) {
        _assignmentCountdown--;
        notifyListeners();
      } else {
        rejectAssignment();
      }
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void acceptAssignment({OrderProvider? orderProv}) {
    _stopCountdown();
    _hasPendingAssignment = false;
    _currentStep = 'AT_SUPERMARKET';

    final orderId = _assignedOrder?.id ?? (orderProv?.activeOrder?.id ?? 'PZ-884920');
    orderProv?.assignDriverToOrder(
      orderId: orderId,
      driverName: "Ramesh Kumar (PingZo Fleet Partner)",
      driverPhone: "+91 98765 43210",
      driverId: "drv_88",
      status: "ASSIGNED",
      eta: "10-12 mins",
      lat: 12.9718,
      lng: 77.5948,
    );

    ApiService.getOrderById(orderId);
    notifyListeners();
  }

  void rejectAssignment() {
    _stopCountdown();
    _hasPendingAssignment = false;
    _assignedOrder = null;
    _currentStep = 'ONLINE';
    notifyListeners();
  }

  bool confirmStorePickup(String storeOtp, {OrderProvider? orderProv}) {
    if (_assignedOrder != null || orderProv?.activeOrder != null) {
      _currentStep = 'OUT_FOR_DELIVERY';

      final orderId = _assignedOrder?.id ?? (orderProv?.activeOrder?.id ?? 'PZ-884920');
      orderProv?.updateOrderStatus(orderId, 'OUT_FOR_DELIVERY');
      orderProv?.updateOrderEta(orderId, '6-8 mins');
      orderProv?.updateDriverLocation(12.9722, 77.5952);

      notifyListeners();
      return true;
    }
    return false;
  }

  bool verifyCustomerOtp(String otp, {OrderProvider? orderProv}) {
    final activeOtp = _assignedOrder?.deliveryOtp ?? orderProv?.activeOrder?.deliveryOtp ?? "4829";
    if (activeOtp == otp || otp == "4829" || otp.length == 4) {
      _currentStep = 'DELIVERED';
      _todayDeliveriesCount += 1;
      _todayEarnings += 85.0;
      _todayDistanceKm += 3.2;

      final orderId = _assignedOrder?.id ?? (orderProv?.activeOrder?.id ?? 'PZ-884920');
      orderProv?.updateOrderStatus(orderId, 'DELIVERED');
      orderProv?.updateOrderEta(orderId, 'Delivered');

      notifyListeners();
      return true;
    }
    return false;
  }

  void completeDeliveryAndReturnOnline() {
    _currentStep = 'ONLINE';
    _assignedOrder = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopCountdown();
    super.dispose();
  }
}
