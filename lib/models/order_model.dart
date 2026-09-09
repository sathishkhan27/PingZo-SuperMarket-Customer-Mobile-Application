import 'dart:convert';

class OrderItemModel {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final double sgstAmount;
  final double cgstAmount;
  final bool isVegetableOrFruit;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.sgstAmount,
    required this.cgstAmount,
    required this.isVegetableOrFruit,
  });

  static double _parseDouble(dynamic val, [double defaultVal = 0.0]) {
    if (val == null) return defaultVal;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? defaultVal;
    return defaultVal;
  }

  static int _parseInt(dynamic val, [int defaultVal = 1]) {
    if (val == null) return defaultVal;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? defaultVal;
    return defaultVal;
  }

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['productId']?.toString() ?? json['product_id']?.toString() ?? json['id']?.toString() ?? '',
      productName: json['productName'] ?? json['product_name'] ?? json['name'] ?? '',
      quantity: _parseInt(json['quantity'] ?? json['qty']),
      unitPrice: _parseDouble(json['unitPrice'] ?? json['unit_price'] ?? json['price']),
      totalPrice: _parseDouble(json['totalPrice'] ?? json['total_price'] ?? json['total']),
      sgstAmount: _parseDouble(json['sgstAmount'] ?? json['sgst_amount'] ?? json['sgst']),
      cgstAmount: _parseDouble(json['cgstAmount'] ?? json['cgst_amount'] ?? json['cgst']),
      isVegetableOrFruit: json['isVegetableOrFruit'] ?? json['is_vegetable_or_fruit'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'sgstAmount': sgstAmount,
      'cgstAmount': cgstAmount,
      'isVegetableOrFruit': isVegetableOrFruit,
    };
  }
}

class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final String deliveryAddress;
  final String supermarketName;
  final String supermarketAddress;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final String? assignedDriverPhone;
  final double driverLatitude;
  final double driverLongitude;
  final List<OrderItemModel> items;
  final double subtotal;
  final double sgstTotal;
  final double cgstTotal;
  final double deliveryFee;
  final double couponDiscount;
  final double grossTotal;
  final String orderStatus; // PLACED, CONFIRMED, PROCESSING, PACKED, ASSIGNED, PICKED_UP, OUT_FOR_DELIVERY, DELIVERED, CANCELLED
  final String paymentStatus;
  final String paymentMethod; // UPI, CARD, COD
  final String estimatedDeliveryEta;
  final DateTime createdAt;
  final String deliveryOtp;
  final bool isCancellable;
  final double refundAmount;
  final String refundStatus; // NOT_APPLICABLE, INITIATED, COMPLETED
  final double? rating;
  final String? feedback;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.deliveryAddress,
    this.supermarketName = 'PingZo Supermarket',
    this.supermarketAddress = '',
    this.assignedDriverId,
    this.assignedDriverName,
    this.assignedDriverPhone,
    required this.driverLatitude,
    required this.driverLongitude,
    required this.items,
    required this.subtotal,
    required this.sgstTotal,
    required this.cgstTotal,
    required this.deliveryFee,
    required this.couponDiscount,
    required this.grossTotal,
    required this.orderStatus,
    required this.paymentStatus,
    this.paymentMethod = 'UPI',
    required this.estimatedDeliveryEta,
    DateTime? createdAt,
    this.deliveryOtp = '4829',
    this.isCancellable = true,
    this.refundAmount = 0.0,
    this.refundStatus = 'NOT_APPLICABLE',
    this.rating,
    this.feedback,
  }) : createdAt = createdAt ?? DateTime.now();

  factory OrderModel.empty() {
    return OrderModel(
      id: '',
      customerId: '',
      customerName: '',
      deliveryAddress: '',
      driverLatitude: 12.9279,
      driverLongitude: 77.6271,
      items: [],
      subtotal: 0.0,
      sgstTotal: 0.0,
      cgstTotal: 0.0,
      deliveryFee: 0.0,
      couponDiscount: 0.0,
      grossTotal: 0.0,
      orderStatus: 'PENDING',
      paymentStatus: 'PENDING',
      estimatedDeliveryEta: '15 mins',
    );
  }

  static double _parseDouble(dynamic val, [double defaultVal = 0.0]) {
    if (val == null) return defaultVal;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? defaultVal;
    return defaultVal;
  }

  static String? _cleanString(dynamic val) {
    if (val == null) return null;
    final str = val.toString().trim();
    if (str.isEmpty || str.toLowerCase() == 'null' || str.toLowerCase() == 'undefined') {
      return null;
    }
    return str;
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    List rawItems = [];
    if (json['items'] is List) {
      rawItems = json['items'] as List;
    } else if (json['items'] is String) {
      try {
        final decoded = jsonDecode(json['items'] as String);
        if (decoded is List) rawItems = decoded;
      } catch (_) {}
    } else if (json['orderItems'] is List) {
      rawItems = json['orderItems'] as List;
    } else if (json['order_items'] is List) {
      rawItems = json['order_items'] as List;
    }

    // Parse nested driver / delivery partner / assigned delivery user map or string if present
    Map<String, dynamic>? driverMap;
    String? rawDriverString;

    final potentialDriverKeys = [
      'driver',
      'deliveryPartner',
      'delivery_partner',
      'deliveryUser',
      'delivery_user',
      'deliveryPerson',
      'delivery_person',
      'deliveryAgent',
      'delivery_agent',
      'assignedUser',
      'assigned_user',
      'deliveryBoy',
      'delivery_boy',
      'assignedDriver',
      'assigned_driver',
      'assignedTo',
      'assigned_to',
      'rider',
      'agent',
      'partner',
      'delivery_partner_details',
      'driverDetails',
      'driver_details',
    ];

    for (final key in potentialDriverKeys) {
      if (json[key] is Map<String, dynamic>) {
        driverMap = json[key] as Map<String, dynamic>;
        break;
      } else if (json[key] is String && json[key].toString().trim().isNotEmpty) {
        final val = json[key].toString().trim();
        if (val.toLowerCase() != 'null' && val.toLowerCase() != 'undefined') {
          rawDriverString = val;
        }
      }
    }

    final parsedDriverId = _cleanString(
      json['assignedDriverId'] ??
      json['driverId'] ??
      json['assigned_driver_id'] ??
      json['deliveryPartnerId'] ??
      json['delivery_partner_id'] ??
      json['deliveryUserId'] ??
      json['delivery_user_id'] ??
      json['deliveryPersonId'] ??
      json['delivery_person_id'] ??
      json['deliveryAgentId'] ??
      json['delivery_agent_id'] ??
      json['assignedUserId'] ??
      json['assigned_user_id'] ??
      json['agentId'] ??
      json['agent_id'] ??
      json['riderId'] ??
      driverMap?['id'] ??
      driverMap?['driverId'] ??
      driverMap?['driver_id'] ??
      driverMap?['userId'] ??
      driverMap?['user_id'],
    );

    final parsedDriverName = _cleanString(
      json['assignedDriverName'] ??
      json['driverName'] ??
      json['driver_name'] ??
      json['deliveryPartnerName'] ??
      json['delivery_partner_name'] ??
      json['deliveryUserName'] ??
      json['delivery_user_name'] ??
      json['deliveryPersonName'] ??
      json['delivery_person_name'] ??
      json['deliveryAgentName'] ??
      json['delivery_agent_name'] ??
      json['assignedUserName'] ??
      json['assigned_user_name'] ??
      json['assignedToName'] ??
      json['assigned_to_name'] ??
      json['deliveryBoyName'] ??
      json['delivery_boy_name'] ??
      json['agentName'] ??
      json['agent_name'] ??
      json['riderName'] ??
      json['rider_name'] ??
      json['partnerName'] ??
      json['partner_name'] ??
      driverMap?['name'] ??
      driverMap?['driverName'] ??
      driverMap?['driver_name'] ??
      driverMap?['deliveryPartnerName'] ??
      driverMap?['deliveryPersonName'] ??
      driverMap?['userName'] ??
      driverMap?['fullName'] ??
      driverMap?['username'] ??
      rawDriverString,
    );

    final parsedDriverPhone = _cleanString(
      json['assignedDriverPhone'] ??
      json['driverPhone'] ??
      json['driver_phone'] ??
      json['deliveryPartnerPhone'] ??
      json['delivery_partner_phone'] ??
      json['deliveryUserPhone'] ??
      json['delivery_user_phone'] ??
      json['deliveryPersonPhone'] ??
      json['delivery_person_phone'] ??
      json['deliveryAgentPhone'] ??
      json['delivery_agent_phone'] ??
      json['assignedUserPhone'] ??
      json['assigned_user_phone'] ??
      json['deliveryBoyPhone'] ??
      json['delivery_boy_phone'] ??
      json['driverMobile'] ??
      json['agentPhone'] ??
      json['agent_phone'] ??
      json['riderPhone'] ??
      driverMap?['phone'] ??
      driverMap?['mobile'] ??
      driverMap?['driverPhone'] ??
      driverMap?['phoneNumber'] ??
      driverMap?['phone_number'] ??
      driverMap?['contact'] ??
      driverMap?['contactNumber'] ??
      driverMap?['contact_number'],
    );

    final parsedDriverLat = _parseDouble(
      json['driverLatitude'] ??
      json['driver_latitude'] ??
      json['driverLat'] ??
      json['driver_lat'] ??
      json['latitude'] ??
      json['lat'] ??
      driverMap?['latitude'] ??
      driverMap?['lat'],
      12.9716,
    );

    final parsedDriverLng = _parseDouble(
      json['driverLongitude'] ??
      json['driver_longitude'] ??
      json['driverLng'] ??
      json['driver_lng'] ??
      json['longitude'] ??
      json['lng'] ??
      driverMap?['longitude'] ??
      driverMap?['lng'],
      77.5946,
    );

    final rawEta = _cleanString(
      json['estimatedDeliveryEta'] ??
      json['estimated_delivery_eta'] ??
      json['deliveryTime'] ??
      json['delivery_time'] ??
      json['estimatedDeliveryTime'] ??
      json['estimated_delivery_time'] ??
      json['deliveryEta'] ??
      json['delivery_eta'] ??
      json['eta'] ??
      json['expectedDeliveryTime'] ??
      json['expected_delivery_time'],
    );

    String parsedEta = '10-15 mins';
    if (rawEta != null) {
      if (rawEta.toLowerCase().contains('min') ||
          rawEta.toLowerCase().contains('hour') ||
          rawEta.toLowerCase().contains('sec') ||
          rawEta.toLowerCase().contains('delivered')) {
        parsedEta = rawEta;
      } else {
        parsedEta = '$rawEta mins';
      }
    }

    final rawStatus = _cleanString(
      json['orderStatus'] ??
      json['order_status'] ??
      json['status'] ??
      json['currentStatus'] ??
      json['current_status'] ??
      json['deliveryStatus'] ??
      json['delivery_status'] ??
      json['orderState'] ??
      json['state'],
    ) ?? 'PLACED';

    final normalizedStatus = rawStatus.toUpperCase().replaceAll(' ', '_').replaceAll('-', '_');

    final bool hasAssignedDriver = (parsedDriverId != null && parsedDriverId.isNotEmpty && parsedDriverId.toLowerCase() != 'null') ||
        (parsedDriverName != null && parsedDriverName.isNotEmpty && parsedDriverName.toLowerCase() != 'null' && parsedDriverName.toLowerCase() != 'undefined');

    String effectiveStatus = normalizedStatus;
    if (hasAssignedDriver && (normalizedStatus == 'PLACED' || normalizedStatus == 'CONFIRMED' || normalizedStatus == 'ACCEPTED' || normalizedStatus == 'PENDING' || normalizedStatus == 'PACKING' || normalizedStatus == 'PREPARING' || normalizedStatus == 'PROCESSING' || normalizedStatus == 'PACKED')) {
      effectiveStatus = 'ASSIGNED';
    }

    final parsedDeliveryAddress = _cleanString(
      json['deliveryAddress'] ??
      json['delivery_address'] ??
      json['address'] ??
      json['shippingAddress'] ??
      json['shipping_address'] ??
      json['customerAddress'] ??
      json['customer_address'] ??
      json['dropAddress'] ??
      json['drop_address'] ??
      json['destinationAddress'] ??
      json['destination_address'],
    ) ?? '';

    final parsedSupermarketName = _cleanString(
      json['supermarketName'] ??
      json['supermarket_name'] ??
      json['storeName'] ??
      json['store_name'] ??
      json['shopName'] ??
      json['shop_name'] ??
      json['vendorName'] ??
      json['vendor_name'] ??
      json['hubName'] ??
      json['hub_name'],
    ) ?? 'PingZo Supermarket';

    final parsedSupermarketAddress = _cleanString(
      json['supermarketAddress'] ??
      json['supermarket_address'] ??
      json['storeAddress'] ??
      json['store_address'] ??
      json['shopAddress'] ??
      json['shop_address'] ??
      json['vendorAddress'] ??
      json['vendor_address'] ??
      json['hubAddress'] ??
      json['hub_address'] ??
      json['pickupAddress'] ??
      json['pickup_address'],
    ) ?? '';

    return OrderModel(
      id: json['id']?.toString() ?? json['orderId']?.toString() ?? json['order_id']?.toString() ?? json['orderNumber']?.toString() ?? json['order_number']?.toString() ?? 'PZ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      customerId: json['customerId']?.toString() ?? json['customer_id']?.toString() ?? '1',
      customerName: json['customerName']?.toString() ?? json['customer_name']?.toString() ?? 'Customer',
      deliveryAddress: parsedDeliveryAddress,
      supermarketName: parsedSupermarketName,
      supermarketAddress: parsedSupermarketAddress,
      assignedDriverId: parsedDriverId,
      assignedDriverName: parsedDriverName,
      assignedDriverPhone: parsedDriverPhone,
      driverLatitude: parsedDriverLat,
      driverLongitude: parsedDriverLng,
      items: rawItems.whereType<Map<String, dynamic>>().map((x) => OrderItemModel.fromJson(x)).toList(),
      subtotal: _parseDouble(json['subtotal'] ?? json['subTotal'] ?? json['sub_total']),
      sgstTotal: _parseDouble(json['sgstTotal'] ?? json['sgst_total'] ?? json['sgst']),
      cgstTotal: _parseDouble(json['cgstTotal'] ?? json['cgst_total'] ?? json['cgst']),
      deliveryFee: _parseDouble(json['deliveryFee'] ?? json['delivery_fee'] ?? json['deliveryCharge']),
      couponDiscount: _parseDouble(json['couponDiscount'] ?? json['coupon_discount'] ?? json['discount']),
      grossTotal: _parseDouble(json['grossTotal'] ?? json['gross_total'] ?? json['totalAmount'] ?? json['total_amount'] ?? json['total']),
      orderStatus: effectiveStatus,
      paymentStatus: json['paymentStatus']?.toString() ?? json['payment_status']?.toString() ?? 'SUCCESS',
      paymentMethod: json['paymentMethod']?.toString() ?? json['payment_method']?.toString() ?? 'UPI',
      estimatedDeliveryEta: parsedEta,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now()),
      deliveryOtp: json['deliveryOtp']?.toString() ?? json['delivery_otp']?.toString() ?? json['otp']?.toString() ?? '4829',
      isCancellable: json['isCancellable'] ?? json['is_cancellable'] ?? true,
      refundAmount: _parseDouble(json['refundAmount'] ?? json['refund_amount']),
      refundStatus: json['refundStatus']?.toString() ?? json['refund_status']?.toString() ?? 'NOT_APPLICABLE',
      rating: json['rating'] != null ? _parseDouble(json['rating']) : null,
      feedback: json['feedback']?.toString(),
    );
  }

  OrderModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? deliveryAddress,
    String? supermarketName,
    String? supermarketAddress,
    String? assignedDriverId,
    String? assignedDriverName,
    String? assignedDriverPhone,
    double? driverLatitude,
    double? driverLongitude,
    List<OrderItemModel>? items,
    double? subtotal,
    double? sgstTotal,
    double? cgstTotal,
    double? deliveryFee,
    double? couponDiscount,
    double? grossTotal,
    String? orderStatus,
    String? paymentStatus,
    String? paymentMethod,
    String? estimatedDeliveryEta,
    DateTime? createdAt,
    String? deliveryOtp,
    bool? isCancellable,
    double? refundAmount,
    String? refundStatus,
    double? rating,
    String? feedback,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      supermarketName: supermarketName ?? this.supermarketName,
      supermarketAddress: supermarketAddress ?? this.supermarketAddress,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      assignedDriverPhone: assignedDriverPhone ?? this.assignedDriverPhone,
      driverLatitude: driverLatitude ?? this.driverLatitude,
      driverLongitude: driverLongitude ?? this.driverLongitude,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      sgstTotal: sgstTotal ?? this.sgstTotal,
      cgstTotal: cgstTotal ?? this.cgstTotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      couponDiscount: couponDiscount ?? this.couponDiscount,
      grossTotal: grossTotal ?? this.grossTotal,
      orderStatus: orderStatus ?? this.orderStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      estimatedDeliveryEta: estimatedDeliveryEta ?? this.estimatedDeliveryEta,
      createdAt: createdAt ?? this.createdAt,
      deliveryOtp: deliveryOtp ?? this.deliveryOtp,
      isCancellable: isCancellable ?? this.isCancellable,
      refundAmount: refundAmount ?? this.refundAmount,
      refundStatus: refundStatus ?? this.refundStatus,
      rating: rating ?? this.rating,
      feedback: feedback ?? this.feedback,
    );
  }
}
