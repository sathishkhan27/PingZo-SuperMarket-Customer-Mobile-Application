enum AppNotificationType {
  orderPlaced,
  orderPacking,
  driverAssigned,
  outForDelivery,
  orderDelivered,
  orderCancelled,
  promo,
  systemAlert,
}

class AppNotificationModel {
  final String id;
  final String title;
  final String body;
  final AppNotificationType type;
  final String? orderId;
  final DateTime timestamp;
  bool isRead;
  final Map<String, dynamic>? payload;

  AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.orderId,
    DateTime? timestamp,
    this.isRead = false,
    this.payload,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    AppNotificationType parseType(String? t) {
      switch (t?.toLowerCase()) {
        case 'driver_assigned':
        case 'driverassigned':
          return AppNotificationType.driverAssigned;
        case 'out_for_delivery':
        case 'outfordelivery':
          return AppNotificationType.outForDelivery;
        case 'delivered':
        case 'order_delivered':
          return AppNotificationType.orderDelivered;
        case 'packing':
        case 'order_packing':
          return AppNotificationType.orderPacking;
        case 'cancelled':
        case 'order_cancelled':
          return AppNotificationType.orderCancelled;
        case 'promo':
          return AppNotificationType.promo;
        case 'order_placed':
        case 'placed':
          return AppNotificationType.orderPlaced;
        default:
          return AppNotificationType.systemAlert;
      }
    }

    return AppNotificationModel(
      id: json['id']?.toString() ?? 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] ?? 'PingZo Update',
      body: json['body'] ?? '',
      type: parseType(json['type']),
      orderId: json['orderId']?.toString() ?? json['order_id']?.toString(),
      timestamp: json['timestamp'] != null
          ? (DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now())
          : DateTime.now(),
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      payload: json['payload'] is Map<String, dynamic> ? json['payload'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'orderId': orderId,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'payload': payload,
    };
  }
}
