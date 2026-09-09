import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification_model.dart';
import '../models/order_model.dart';
import 'notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final List<AppNotificationModel> _notifications = [];
  static const String _storageKey = 'pingzo_notifications_cache';

  List<AppNotificationModel> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final List list = jsonDecode(raw);
        _notifications.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _notifications.add(AppNotificationModel.fromJson(item));
          }
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_notifications.map((n) => n.toJson()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (_) {}
  }

  /// Dispatch and record a custom notification
  void addNotification(
    AppNotificationModel notification, {
    bool showOverlay = true,
  }) {
    _notifications.insert(0, notification);
    _saveToStorage();
    notifyListeners();

    if (showOverlay) {
      NotificationService.showInAppNotification(
        title: notification.title,
        body: notification.body,
        type: notification.type,
        orderId: notification.orderId,
      );
    }
  }

  /// Helper: Order Placed
  void notifyOrderPlaced(OrderModel order) {
    addNotification(
      AppNotificationModel(
        id: 'placed_${order.id}_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Order Confirmed! 🛒',
        body: 'Order #${order.id} has been placed. Supermarket is packing your items.',
        type: AppNotificationType.orderPlaced,
        orderId: order.id,
      ),
    );
  }

  /// Helper: Driver Assigned
  void notifyDriverAssigned(OrderModel order) {
    final driverName = order.assignedDriverName ?? 'Delivery Partner';
    addNotification(
      AppNotificationModel(
        id: 'driver_${order.id}_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Partner Assigned 🛵',
        body: '$driverName is assigned to deliver Order #${order.id}.',
        type: AppNotificationType.driverAssigned,
        orderId: order.id,
      ),
    );
  }

  /// Helper: Out For Delivery
  void notifyOutForDelivery(OrderModel order) {
    addNotification(
      AppNotificationModel(
        id: 'ofd_${order.id}_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Out For Delivery! ⚡',
        body: 'Your order #${order.id} is on the way! ETA: ${order.estimatedDeliveryEta}.',
        type: AppNotificationType.outForDelivery,
        orderId: order.id,
      ),
    );
  }

  /// Helper: Order Delivered
  void notifyOrderDelivered(OrderModel order) {
    addNotification(
      AppNotificationModel(
        id: 'del_${order.id}_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Order Delivered! 🎉',
        body: 'Order #${order.id} has reached your doorstep. Enjoy your fresh groceries!',
        type: AppNotificationType.orderDelivered,
        orderId: order.id,
      ),
    );
  }

  /// Helper: Order Cancelled
  void notifyOrderCancelled(OrderModel order) {
    addNotification(
      AppNotificationModel(
        id: 'cnc_${order.id}_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Order Cancelled ⚠️',
        body: 'Order #${order.id} was cancelled. Refund has been initiated.',
        type: AppNotificationType.orderCancelled,
        orderId: order.id,
      ),
    );
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index >= 0) {
      _notifications[index].isRead = true;
      _saveToStorage();
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    _saveToStorage();
    notifyListeners();
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    _saveToStorage();
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    _saveToStorage();
    notifyListeners();
  }
}
