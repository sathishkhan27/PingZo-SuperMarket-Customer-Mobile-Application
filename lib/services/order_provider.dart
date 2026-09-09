import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/state/base_provider.dart';
import '../models/order_model.dart';
import '../models/chat_model.dart';
import '../models/app_notification_model.dart';
import 'notification_service.dart';
import 'api_service.dart';

class OrderProvider extends BaseProvider {
  static const String _prefKeyChats = 'pingzo_customer_order_chats';

  final List<OrderModel> _orders = [];
  OrderModel? _activeOrder;
  final Map<String, List<ChatMessageModel>> _orderChats = {};
  bool _isDriverTyping = false;
  bool _isPlacingOrder = false;
  bool _isFetchingOrder = false;
  bool _isTracking = false;
  Timer? _liveTrackingTimer;
  int _trackingTickCount = 0;

  List<OrderModel> get orders => _orders;
  OrderModel? get activeOrder {
    if (_activeOrder != null && _activeOrder!.orderStatus != 'DELIVERED' && _activeOrder!.orderStatus != 'CANCELLED') {
      return _activeOrder;
    }
    final activeInList = _orders.where((o) => o.orderStatus != 'DELIVERED' && o.orderStatus != 'CANCELLED').toList();
    if (activeInList.isNotEmpty) {
      return activeInList.first;
    }
    return _activeOrder ?? (_orders.isNotEmpty ? _orders.first : null);
  }

  List<ChatMessageModel> get activeChatMessages {
    if (_activeOrder != null) {
      return getChatMessagesForOrder(_activeOrder!.id);
    }
    return [];
  }

  bool get isDriverTyping => _isDriverTyping;
  bool get isPlacingOrder => _isPlacingOrder;
  bool get isFetchingOrder => _isFetchingOrder;
  bool get isTracking => _isTracking;

  OrderProvider() {
    _loadSavedChats();
  }

  /// Sets the currently viewed / tracked active order.
  void setActiveOrder(OrderModel order) {
    _activeOrder = order;
    final existingIndex = _orders.indexWhere((o) => o.id == order.id);
    if (existingIndex >= 0) {
      _orders[existingIndex] = order;
    } else {
      _orders.insert(0, order);
    }
    ensureOrderChatInitialized(order);
    notifyListeners();
  }

  /// Place a new order with loading/error state management.
  Future<bool> placeOrder({
    required List<OrderItemModel> items,
    required double subtotal,
    required double deliveryFee,
    required double couponDiscount,
    required double grossTotal,
    required String deliveryAddress,
    required String paymentMethod,
  }) async {
    _isPlacingOrder = true;
    notifyListeners();

    final success = await runAsync(() async {
      final newOrder = await ApiService.createOrder(
        items: items,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        couponDiscount: couponDiscount,
        grossTotal: grossTotal,
        deliveryAddress: deliveryAddress,
        paymentMethod: paymentMethod,
      );
      _orders.insert(0, newOrder);
      _activeOrder = newOrder;
      ensureOrderChatInitialized(newOrder);
    });

    _isPlacingOrder = false;
    notifyListeners();
    return success;
  }

  void addOrder(OrderModel newOrder) {
    final existingIdx = _orders.indexWhere((o) => o.id == newOrder.id);
    if (existingIdx >= 0) {
      _orders[existingIdx] = newOrder;
    } else {
      _orders.insert(0, newOrder);
    }
    _activeOrder = newOrder;
    ensureOrderChatInitialized(newOrder);
    notifyListeners();
  }

  /// Fetches the latest order state by ID from backend.
  Future<OrderModel?> fetchOrderById(String orderId) async {
    _isFetchingOrder = true;
    notifyListeners();

    try {
      final serverOrder = await ApiService.getOrderById(orderId);
      if (serverOrder != null) {
        final index = _orders.indexWhere((o) => o.id == orderId);
        final previousOrder = index >= 0 ? _orders[index] : _activeOrder;

        // Check for state transitions and trigger in-app notification & chat closure
        if (previousOrder != null) {
          final hadDriver = previousOrder.assignedDriverName != null && previousOrder.assignedDriverName!.trim().isNotEmpty;
          final hasDriver = serverOrder.assignedDriverName != null && serverOrder.assignedDriverName!.trim().isNotEmpty;

          if (!hadDriver && hasDriver) {
            NotificationService.showInAppNotification(
              title: 'Partner Assigned 🛵',
              body: '${serverOrder.assignedDriverName} has been assigned to Order #${serverOrder.id}.',
              type: AppNotificationType.driverAssigned,
              orderId: serverOrder.id,
            );
          } else if (previousOrder.orderStatus != 'OUT_FOR_DELIVERY' && serverOrder.orderStatus == 'OUT_FOR_DELIVERY') {
            NotificationService.showInAppNotification(
              title: 'Out For Delivery! ⚡',
              body: 'Your order #${serverOrder.id} is on the way! ETA: ${serverOrder.estimatedDeliveryEta}.',
              type: AppNotificationType.outForDelivery,
              orderId: serverOrder.id,
            );
          } else if (previousOrder.orderStatus != 'DELIVERED' && serverOrder.orderStatus == 'DELIVERED') {
            NotificationService.showInAppNotification(
              title: 'Order Delivered! 🎉',
              body: 'Order #${serverOrder.id} has reached your doorstep. Enjoy your fresh groceries!',
              type: AppNotificationType.orderDelivered,
              orderId: serverOrder.id,
            );
            // Immediately close chat channel upon delivery
            closeOrderChat(
              serverOrder.id,
              closureText: '🎉 Order #${serverOrder.id} delivered successfully! Chat conversation completed and closed for customer privacy.',
            );
          }
        }

        if (index >= 0) {
          _orders[index] = serverOrder;
        } else {
          _orders.insert(0, serverOrder);
        }
        if (_activeOrder?.id == orderId || _activeOrder == null) {
          _activeOrder = serverOrder;
        }
        _isFetchingOrder = false;
        notifyListeners();
        return serverOrder;
      }
    } catch (_) {}

    _isFetchingOrder = false;
    notifyListeners();
    return null;
  }

  /// Starts real-time polling and live updates for the given order from backend API.
  void startLiveTracking(String orderId, {Duration interval = const Duration(seconds: 4)}) {
    _liveTrackingTimer?.cancel();
    _isTracking = true;
    _trackingTickCount = 0;
    notifyListeners();

    // Immediate fetch from backend
    fetchOrderById(orderId);

    _liveTrackingTimer = Timer.periodic(interval, (_) async {
      _trackingTickCount++;
      await fetchOrderById(orderId);
      syncOrderChat(orderId);
    });
  }

  /// Stops real-time tracking polling.
  void stopLiveTracking() {
    _liveTrackingTimer?.cancel();
    _liveTrackingTimer = null;
    _isTracking = false;
    _trackingTickCount = 0;
    notifyListeners();
  }

  /// Fetches all customer orders from backend.
  Future<void> fetchOrders({String? customerId}) async {
    try {
      final serverOrders = await ApiService.getOrders(customerId: customerId);
      if (serverOrders.isNotEmpty) {
        for (final so in serverOrders) {
          final idx = _orders.indexWhere((o) => o.id == so.id);
          if (idx >= 0) {
            _orders[idx] = so;
          } else {
            _orders.add(so);
          }
        }
        if (_activeOrder != null) {
          final updatedActive = _orders.firstWhere((o) => o.id == _activeOrder!.id, orElse: () => _activeOrder!);
          _activeOrder = updatedActive;
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  void updateOrderStatus(String orderId, String newStatus) {
    int index = _orders.indexWhere((o) => o.id == orderId || o.id.contains(orderId) || orderId.contains(o.id));
    if (index >= 0) {
      _orders[index] = _orders[index].copyWith(orderStatus: newStatus);
      _activeOrder = _orders[index];
    } else if (_activeOrder != null) {
      _activeOrder = _activeOrder!.copyWith(orderStatus: newStatus);
    }
    if (newStatus == 'DELIVERED' || newStatus == 'CANCELLED') {
      closeOrderChat(
        orderId,
        closureText: newStatus == 'DELIVERED'
            ? '🎉 Order #$orderId delivered successfully! Chat conversation completed and closed for customer privacy.'
            : '🛑 Order #$orderId cancelled. Chat conversation closed.',
      );
    }
    notifyListeners();
  }

  void updateOrderEta(String orderId, String eta) {
    int index = _orders.indexWhere((o) => o.id == orderId || o.id.contains(orderId) || orderId.contains(o.id));
    if (index >= 0) {
      _orders[index] = _orders[index].copyWith(estimatedDeliveryEta: eta);
      _activeOrder = _orders[index];
    } else if (_activeOrder != null) {
      _activeOrder = _activeOrder!.copyWith(estimatedDeliveryEta: eta);
    }
    notifyListeners();
  }

  void assignDriverToOrder({
    required String orderId,
    required String driverName,
    required String driverPhone,
    String? driverId,
    String? status,
    String? eta,
    double? lat,
    double? lng,
  }) {
    int index = _orders.indexWhere((o) => o.id == orderId || o.id.contains(orderId) || orderId.contains(o.id));
    if (index >= 0) {
      _orders[index] = _orders[index].copyWith(
        assignedDriverName: driverName,
        assignedDriverPhone: driverPhone,
        assignedDriverId: driverId ?? _orders[index].assignedDriverId,
        orderStatus: status ?? _orders[index].orderStatus,
        estimatedDeliveryEta: eta ?? _orders[index].estimatedDeliveryEta,
        driverLatitude: lat ?? _orders[index].driverLatitude,
        driverLongitude: lng ?? _orders[index].driverLongitude,
      );
      _activeOrder = _orders[index];
    } else if (_activeOrder != null) {
      _activeOrder = _activeOrder!.copyWith(
        assignedDriverName: driverName,
        assignedDriverPhone: driverPhone,
        assignedDriverId: driverId ?? _activeOrder!.assignedDriverId,
        orderStatus: status ?? _activeOrder!.orderStatus,
        estimatedDeliveryEta: eta ?? _activeOrder!.estimatedDeliveryEta,
        driverLatitude: lat ?? _activeOrder!.driverLatitude,
        driverLongitude: lng ?? _activeOrder!.driverLongitude,
      );
      _orders.insert(0, _activeOrder!);
    }
    notifyListeners();
  }

  void updateDriverLocation(double lat, double lng) {
    if (_activeOrder != null) {
      _activeOrder = _activeOrder!.copyWith(
        driverLatitude: lat,
        driverLongitude: lng,
      );
      int index = _orders.indexWhere((o) => o.id == _activeOrder!.id);
      if (index >= 0) {
        _orders[index] = _activeOrder!;
      }
      notifyListeners();
    }
  }

  bool cancelOrder(String orderId, String reason) {
    int index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0 && _orders[index].isCancellable) {
      _orders[index] = _orders[index].copyWith(
        orderStatus: "CANCELLED",
        isCancellable: false,
        refundStatus: "INITIATED",
        refundAmount: _orders[index].grossTotal,
      );
      if (_activeOrder?.id == orderId) {
        _activeOrder = _orders[index];
      }
      closeOrderChat(
        orderId,
        closureText: '🛑 Order #$orderId cancelled. Chat conversation closed.',
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  void addRating(String orderId, double rating, String feedback) {
    int index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      _orders[index] = _orders[index].copyWith(
        rating: rating,
        feedback: feedback,
      );
      if (_activeOrder?.id == orderId) {
        _activeOrder = _orders[index];
      }
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ─── Real-Time Customer ↔ Driver Chat Management ──────────────
  // ─────────────────────────────────────────────────────────────

  List<ChatMessageModel> getChatMessagesForOrder(String orderId) {
    if (_orderChats.containsKey(orderId) && _orderChats[orderId]!.isNotEmpty) {
      return _orderChats[orderId]!;
    }
    if (_activeOrder != null && _activeOrder!.id == orderId) {
      return _orderChats[_activeOrder!.id] ?? [];
    }
    return _orderChats[orderId] ?? [];
  }

  bool isOrderChatCompleted(String orderId) {
    final order = _orders.firstWhere(
      (o) => o.id == orderId,
      orElse: () => _activeOrder != null && _activeOrder!.id == orderId ? _activeOrder! : OrderModel.empty(),
    );
    if (order.id.isNotEmpty && (order.orderStatus == 'DELIVERED' || order.orderStatus == 'CANCELLED')) {
      return true;
    }
    final messages = getChatMessagesForOrder(orderId);
    return messages.any((m) => m.isSystem && (m.message.contains('delivered') || m.message.contains('cancelled') || m.message.contains('closed')));
  }

  void ensureOrderChatInitialized(OrderModel order) {
    if (order.id.isEmpty) return;
    final list = _orderChats.putIfAbsent(order.id, () => []);
    if (list.isEmpty) {
      final driverName = (order.assignedDriverName != null && order.assignedDriverName!.isNotEmpty)
          ? order.assignedDriverName!
          : 'Delivery Partner';

      list.add(
        ChatMessageModel(
          id: 'sys-init-${order.id}',
          orderId: order.id,
          senderId: 'SYSTEM',
          senderName: 'PingZo System',
          message: 'Order #${order.id} assigned to $driverName. End-to-end encrypted order channel is active.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
          isCustomer: false,
          isRead: true,
          isSystem: true,
        ),
      );

      list.add(
        ChatMessageModel(
          id: 'drv-init-${order.id}',
          orderId: order.id,
          senderId: order.assignedDriverId ?? 'drv_88',
          senderName: '$driverName (Partner)',
          message: 'Hello! I am on my way to ${order.supermarketName.isNotEmpty ? order.supermarketName : "store"} to pick up your order.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
          isCustomer: false,
          isRead: true,
        ),
      );

      _saveChatsToPrefs();
      notifyListeners();
    }
  }

  /// Sync chat messages with backend for the specified order
  Future<void> syncOrderChat(String orderId) async {
    final cleanId = orderId.trim();
    if (cleanId.isEmpty) return;
    final strippedId = cleanId.startsWith('#') ? cleanId.substring(1) : cleanId;

    try {
      final remoteList = await ApiService.fetchOrderChat(strippedId);
      if (remoteList.isEmpty) return;

      final localList = _orderChats.putIfAbsent(strippedId, () => []);
      bool newIncomingFound = false;

      for (final remote in remoteList) {
        final exists = localList.any((m) =>
            m.id == remote.id ||
            (m.message == remote.message && m.isCustomer == remote.isCustomer));
        if (!exists) {
          localList.add(remote);
          if (!remote.isCustomer && !remote.isSystem) {
            newIncomingFound = true;
          }
        }
      }

      if (_activeOrder != null && _activeOrder!.id != strippedId && _activeOrder!.id.contains(strippedId)) {
        _orderChats[_activeOrder!.id] = localList;
      }

      _saveChatsToPrefs();
      notifyListeners();
    } catch (_) {}
  }

  void sendChatMessage(
    String messageText, {
    required bool isCustomer,
    String? orderId,
    String? senderName,
  }) {
    final targetOrderId = orderId ?? _activeOrder?.id;
    if (targetOrderId == null || targetOrderId.isEmpty || messageText.trim().isEmpty) return;

    if (isOrderChatCompleted(targetOrderId)) return;

    final targetOrder = _orders.firstWhere(
      (o) => o.id == targetOrderId,
      orElse: () => _activeOrder != null && _activeOrder!.id == targetOrderId ? _activeOrder! : OrderModel.empty(),
    );

    final sName = senderName ?? (isCustomer
        ? (targetOrder.customerName.isNotEmpty ? targetOrder.customerName : 'Customer')
        : (targetOrder.assignedDriverName ?? 'Delivery Partner'));

    final msg = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      orderId: targetOrderId,
      senderId: isCustomer ? 'cust_101' : (targetOrder.assignedDriverId ?? 'drv_88'),
      senderName: sName,
      message: messageText.trim(),
      timestamp: DateTime.now(),
      isCustomer: isCustomer,
      isRead: true,
      isSystem: false,
    );

    _orderChats.putIfAbsent(targetOrderId, () => []).add(msg);
    _saveChatsToPrefs();
    notifyListeners();

    // Transmit to Spring Boot microservice backend in real time
    ApiService.sendOrderChatMessage(targetOrderId, msg).then((_) {
      syncOrderChat(targetOrderId);
    }).catchError((_) {});

    // Sync backend responses after brief delay
    Future.delayed(const Duration(seconds: 2), () {
      syncOrderChat(targetOrderId);
    });
  }

  void closeOrderChat(String orderId, {String? closureText}) {
    if (orderId.isEmpty) return;
    final cleanId = orderId.trim();
    final strippedId = cleanId.startsWith('#') ? cleanId.substring(1) : cleanId;

    // Notify backend
    ApiService.closeOrderChat(strippedId, reason: closureText);

    final list = _orderChats.putIfAbsent(strippedId, () => []);
    if (list.any((m) => m.isSystem && m.id.startsWith('sys-closed-'))) {
      return;
    }

    final closureMsg = ChatMessageModel(
      id: 'sys-closed-${DateTime.now().millisecondsSinceEpoch}',
      orderId: strippedId,
      senderId: 'SYSTEM',
      senderName: 'PingZo System',
      message: closureText ?? '🎉 Order #$strippedId delivered successfully! Chat conversation completed and closed for customer privacy.',
      timestamp: DateTime.now(),
      isCustomer: false,
      isRead: true,
      isSystem: true,
    );

    list.add(closureMsg);
    _saveChatsToPrefs();
    notifyListeners();
  }

  void _simulatePartnerReply(String orderId, String customerText, OrderModel order) {
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (isOrderChatCompleted(orderId)) return;
      _isDriverTyping = true;
      notifyListeners();

      Future.delayed(const Duration(milliseconds: 1800), () {
        _isDriverTyping = false;
        if (isOrderChatCompleted(orderId)) {
          notifyListeners();
          return;
        }

        final lower = customerText.toLowerCase();
        String reply = "Got it! Thanks for letting me know.";

        if (lower.contains('where') || lower.contains('location') || lower.contains('reach')) {
          reply = "I am nearby on the main road, arriving in approx ${order.estimatedDeliveryEta}!";
        } else if (lower.contains('gate') || lower.contains('door') || lower.contains('building')) {
          reply = "Understood! I will head straight to your door/lobby.";
        } else if (lower.contains('call') || lower.contains('phone')) {
          reply = "Sure! I will ring your phone once I reach your building.";
        } else if (lower.contains('otp') || lower.contains('pin') || lower.contains('code')) {
          reply = "Perfect, received your OTP (${order.deliveryOtp}). I will enter it upon handover!";
        } else if (lower.contains('bag') || lower.contains('milk') || lower.contains('pack')) {
          reply = "Handled! Verified item packing with store manager.";
        }

        final driverMsg = ChatMessageModel(
          id: 'drv_${DateTime.now().millisecondsSinceEpoch}',
          orderId: orderId,
          senderId: order.assignedDriverId ?? 'drv_88',
          senderName: '${order.assignedDriverName ?? "Ramesh Kumar"} (Partner)',
          message: reply,
          timestamp: DateTime.now(),
          isCustomer: false,
          isRead: true,
          isSystem: false,
        );

        _orderChats.putIfAbsent(orderId, () => []).add(driverMsg);
        _saveChatsToPrefs();
        notifyListeners();
      });
    });
  }

  Future<void> _saveChatsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> rawMap = {};
      _orderChats.forEach((key, list) {
        rawMap[key] = list.map((m) => m.toJson()).toList();
      });
      await prefs.setString(_prefKeyChats, jsonEncode(rawMap));
    } catch (_) {}
  }

  Future<void> _loadSavedChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKeyChats);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        decoded.forEach((key, value) {
          if (value is List) {
            _orderChats[key] = value.map((m) => ChatMessageModel.fromJson(Map<String, dynamic>.from(m))).toList();
          }
        });
        notifyListeners();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _liveTrackingTimer?.cancel();
    super.dispose();
  }
}
