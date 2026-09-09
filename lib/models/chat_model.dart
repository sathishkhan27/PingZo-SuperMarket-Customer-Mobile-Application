class ChatMessageModel {
  final String id;
  final String orderId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isCustomer;
  final bool isRead;
  final bool isSystem;

  ChatMessageModel({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isCustomer,
    this.isRead = false,
    this.isSystem = false,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final sender = json['senderId']?.toString() ?? '';
    final isSys = json['isSystem'] == true || sender == 'SYSTEM' || sender == 'SYS' || (json['id']?.toString() ?? '').startsWith('sys-');
    final isDrv = json['isDriver'] == true || json['isFromDriver'] == true || sender.toLowerCase().contains('driver') || sender.toLowerCase().contains('drv');
    final isCust = json['isCustomer'] ?? (!isSys && !isDrv);

    return ChatMessageModel(
      id: json['id']?.toString() ?? 'msg-${DateTime.now().millisecondsSinceEpoch}',
      orderId: json['orderId']?.toString() ?? '',
      senderId: sender.isNotEmpty ? sender : (isCust ? 'CUSTOMER' : (isDrv ? 'DRIVER-1' : 'SYSTEM')),
      senderName: json['senderName']?.toString() ?? (isCust ? 'Customer' : (isDrv ? 'Delivery Partner' : 'PingZo System')),
      message: json['message']?.toString() ?? json['text']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? (DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now())
          : DateTime.now(),
      isCustomer: isCust,
      isRead: json['isRead'] ?? (json['status'] == 'read'),
      isSystem: isSys,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'text': message,
      'timestamp': timestamp.toIso8601String(),
      'isCustomer': isCustomer,
      'isDriver': !isCustomer && !isSystem,
      'isFromDriver': !isCustomer && !isSystem,
      'isSystem': isSystem,
      'isRead': isRead,
    };
  }
}
