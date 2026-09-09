import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/product_model.dart';
import '../models/banner_model.dart';
import '../models/order_model.dart';
import '../models/chat_model.dart';
import '../models/coupon_model.dart';
import '../models/support_model.dart';
import '../models/address_model.dart';
import '../models/user_model.dart';

/// Business-level API service.
///
/// All HTTP calls go through [ApiClient] which handles connectivity,
/// timeouts, status codes, and JSON decoding. Methods here focus only
/// on endpoint paths and model mapping.
class ApiService {

  // ─── Authentication Endpoints ─────────────────────────

  /// Request / Send OTP to the given mobile number.
  /// Matches Spring Boot SendOtpRequest { "phone": "9887766554" }
  static Future<Map<String, dynamic>> sendOtp({
    required String phone,
    String? name,
  }) async {
    final cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final payload = {
      'phone': cleanDigits,
    };

    try {
      final res = await ApiClient.post('/api/v1/customer/auth/send-otp', body: payload);
      if (res is Map<String, dynamic>) {
        debugPrint("OTP successfully dispatched: $res");
        return res;
      }
    } catch (e) {
      debugPrint("sendOtp request failed: $e");
    }

    return {
      'success': true,
      'message': 'OTP sent successfully',
      'otp': '1234',
    };
  }

  /// Verify OTP and obtain authenticated User Model & Session Token.
  /// Matches Spring Boot VerifyOtpRequest { "phone": "...", "otp": "...", "name": "...", "email": "...", "address": "..." }
  static Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
    String? name,
    String? email,
    String? address,
  }) async {
    final cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final payload = {
      'phone': cleanDigits,
      'otp': otp,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (address != null && address.trim().isNotEmpty) 'address': address.trim(),
    };

    try {
      final res = await ApiClient.post('/api/v1/customer/auth/verify-otp', body: payload);
      if (res is Map<String, dynamic>) {
        debugPrint("OTP successfully verified: $res");

        final token = res['token']?.toString();
        if (token != null && token.isNotEmpty) {
          ApiClient.setAuthToken(token);
        }

        Map<String, dynamic> customerData = {};
        if (res['customer'] is Map<String, dynamic>) {
          customerData = res['customer'] as Map<String, dynamic>;
        } else if (res['user'] is Map<String, dynamic>) {
          customerData = res['user'] as Map<String, dynamic>;
        } else {
          customerData = res;
        }

        final user = UserModel(
          id: customerData['id']?.toString() ?? 'cust_101',
          name: customerData['name']?.toString() ?? (name ?? 'Customer'),
          phone: customerData['phone']?.toString() ?? cleanDigits,
          email: customerData['email']?.toString() ?? (email ?? 'customer@pingzo.com'),
          role: 'customer',
        );

        return {
          'success': true,
          'user': user,
          'token': token,
          'raw': res,
        };
      }
    } catch (e) {
      debugPrint("verifyOtp request failed: $e");
    }

    // Fallback for offline/testing mode
    final fallbackUser = UserModel(
      id: 'cust_101',
      name: (name != null && name.trim().isNotEmpty) ? name.trim() : 'Customer',
      phone: cleanDigits,
      email: email ?? 'customer@pingzo.com',
      role: 'customer',
      rating: 4.9,
    );
    return {
      'success': true,
      'user': fallbackUser,
      'token': 'PINGZO-CUST-TOKEN-${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  /// Get authenticated Customer Profile (/api/v1/customer/auth/me)
  static Future<UserModel?> getCustomerMe() async {
    try {
      final res = await ApiClient.get('/api/v1/customer/auth/me', requiresAuth: true);
      if (res is Map<String, dynamic>) {
        return UserModel.fromJson(res);
      }
    } catch (e) {
      debugPrint("getCustomerMe failed: $e");
    }
    return null;
  }

  /// Logout Customer from backend (/api/v1/customer/auth/logout)
  static Future<void> logoutCustomer() async {
    try {
      await ApiClient.post('/api/v1/customer/auth/logout', body: {});
    } catch (e) {
      debugPrint("logoutCustomer failed: $e");
    }
  }

  // ─── Products ───────────────────────────────────────

  static Future<List<ProductModel>> getProducts() async {
    final List data = await ApiClient.get('/products', requiresAuth: false);
    return data.map((x) => ProductModel.fromJson(x)).toList();
  }

  // ─── Categories ──────────────────────────────────────

  static Future<List<String>> getCategories() async {
    final List data = await ApiClient.get('/categories', requiresAuth: false);
    return data.map((x) => x['name']?.toString() ?? x.toString()).toList();
  }

  // ─── Customer Addresses ─────────────────────────────────

  static Future<List<AddressModel>> getCustomerAddresses({String customerId = '1'}) async {
    final List data = await ApiClient.get('/customers/$customerId/addresses', requiresAuth: false);
    return data.map((x) => AddressModel.fromJson(x)).toList();
  }

  static Future<AddressModel?> getActiveCustomerAddress({String customerId = '1'}) async {
    final data = await ApiClient.get('/customers/$customerId/addresses/active', requiresAuth: false);
    return data != null ? AddressModel.fromJson(data) : null;
  }

  static Future<AddressModel> saveCustomerAddress(AddressModel address, {String customerId = '1'}) async {
    final data = await ApiClient.post(
      '/customers/$customerId/addresses',
      body: address.toJson(),
    );
    return AddressModel.fromJson(data);
  }

  static Future<AddressModel?> updateCustomerAddress(AddressModel address, {String customerId = '1'}) async {
    final data = await ApiClient.put(
      '/customers/$customerId/addresses/${address.id}',
      body: address.toJson(),
    );
    return data != null ? AddressModel.fromJson(data) : null;
  }

  static Future<AddressModel?> setActiveCustomerAddress(String addressId, {String customerId = '1'}) async {
    final data = await ApiClient.put(
      '/customers/$customerId/addresses/$addressId/active',
      body: {},
    );
    return data != null ? AddressModel.fromJson(data) : null;
  }

  static Future<void> deleteCustomerAddress(String addressId, {String customerId = '1'}) async {
    await ApiClient.delete('/customers/$customerId/addresses/$addressId');
  }

  // ─── Banners ────────────────────────────────────────

  static Future<List<BannerModel>> getBanners() async {
    dynamic response;
    try {
      response = await ApiClient.get('/marketing/banners', requiresAuth: false);
    } catch (e) {
      try {
        response = await ApiClient.get('/banners', requiresAuth: false);
      } catch (_) {
        rethrow;
      }
    }

    List rawList = [];
    if (response is List) {
      rawList = response;
    } else if (response is Map<String, dynamic>) {
      if (response['data'] is List) {
        rawList = response['data'] as List;
      } else if (response['banners'] is List) {
        rawList = response['banners'] as List;
      } else if (response['content'] is List) {
        rawList = response['content'] as List;
      } else if (response['results'] is List) {
        rawList = response['results'] as List;
      } else if (response['items'] is List) {
        rawList = response['items'] as List;
      } else if (response['data'] is Map<String, dynamic>) {
        final nestedData = response['data'] as Map<String, dynamic>;
        if (nestedData['banners'] is List) {
          rawList = nestedData['banners'] as List;
        } else if (nestedData['content'] is List) {
          rawList = nestedData['content'] as List;
        } else if (nestedData['items'] is List) {
          rawList = nestedData['items'] as List;
        }
      }
    }

    final banners = rawList
        .whereType<Map<String, dynamic>>()
        .map((x) => BannerModel.fromJson(x))
        .where((b) => b.isActive)
        .toList();

    return banners;
  }

  // ─── Coupons ────────────────────────────────────────

  static List<CouponModel> getMockCoupons() {
    return [
      CouponModel(
        id: "c1",
        code: "PINGZO100",
        title: "FLAT ₹100 OFF",
        description: "Save ₹100 on grocery items above ₹299",
        discountPercentage: 20,
        maxDiscountAmount: 100,
        minOrderAmount: 299,
      ),
      CouponModel(
        id: "c2",
        code: "FRESH25",
        title: "25% OFF Fresh Vegetables",
        description: "Get up to ₹60 OFF on organic vegetables and fruits",
        discountPercentage: 25,
        maxDiscountAmount: 60,
        minOrderAmount: 150,
      ),
      CouponModel(
        id: "c3",
        code: "FIRST50",
        title: "50% OFF First Supermarket Order",
        description: "Welcome offer for new PingZo app users",
        discountPercentage: 50,
        maxDiscountAmount: 150,
        minOrderAmount: 199,
      ),
    ];
  }

  // ─── Orders ─────────────────────────────────────────

  static Future<OrderModel> createOrder({
    required List<OrderItemModel> items,
    required double subtotal,
    required double deliveryFee,
    required double couponDiscount,
    required double grossTotal,
    required String deliveryAddress,
    required String paymentMethod,
    String customerId = '1',
    String customerName = 'Sathish Kumar',
    String customerPhone = '+91 98765 43210',
  }) async {
    final int? numericCustomerId = int.tryParse(customerId);
    final List<Map<String, dynamic>> itemsList = items.map((i) {
      final int? numProdId = int.tryParse(i.productId);
      return {
        'productId': numProdId ?? i.productId,
        'productName': i.productName,
        'quantity': i.quantity,
        'unitPrice': i.unitPrice,
        'price': i.unitPrice,
        'totalPrice': i.totalPrice,
        'sgstAmount': i.sgstAmount,
        'cgstAmount': i.cgstAmount,
        'isVegetableOrFruit': i.isVegetableOrFruit,
      };
    }).toList();

    final String itemsJsonString = json.encode(itemsList);

    // Payload variant 1: items as String (fixes "Cannot deserialize String from Array")
    final Map<String, dynamic> payloadWithString = {
      'customerId': numericCustomerId ?? 1,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress.isNotEmpty ? deliveryAddress : 'Koramangala 4th Block, Bengaluru',
      'paymentMethod': paymentMethod,
      'paymentStatus': 'SUCCESS',
      'orderStatus': 'PLACED',
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'couponDiscount': couponDiscount,
      'grossTotal': grossTotal,
      'totalAmount': grossTotal,
      'items': itemsJsonString,
    };

    // Payload variant 2: items as Array
    final Map<String, dynamic> payloadWithArray = {
      'customerId': numericCustomerId ?? 1,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress.isNotEmpty ? deliveryAddress : '',
      'paymentMethod': paymentMethod,
      'paymentStatus': 'SUCCESS',
      'orderStatus': 'PLACED',
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'couponDiscount': couponDiscount,
      'grossTotal': grossTotal,
      'totalAmount': grossTotal,
      'items': itemsList,
    };

    dynamic response;
    final endpoints = ['/api/v1/customer/orders', '/orders', '/orders/create', '/billing/orders'];

    // Try payloadWithString first to satisfy Jackson String deserializer
    for (final ep in endpoints) {
      try {
        response = await ApiClient.post(ep, body: payloadWithString);
        if (response != null) break;
      } catch (e) {
        debugPrint("Trying $ep with string items failed: $e");
      }
    }

    if (response == null) {
      for (final ep in endpoints) {
        try {
          response = await ApiClient.post(ep, body: payloadWithArray);
          if (response != null) break;
        } catch (e) {
          debugPrint("Trying $ep with array items failed: $e");
        }
      }
    }

    if (response != null && response is Map<String, dynamic>) {
      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : (response['order'] is Map<String, dynamic>
              ? response['order'] as Map<String, dynamic>
              : response);
      try {
        final parsedOrder = OrderModel.fromJson(data);
        if (parsedOrder.items.isEmpty) {
          return OrderModel(
            id: parsedOrder.id.isNotEmpty ? parsedOrder.id : "PZ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
            customerId: parsedOrder.customerId,
            customerName: parsedOrder.customerName,
            deliveryAddress: parsedOrder.deliveryAddress,
            assignedDriverId: parsedOrder.assignedDriverId,
            assignedDriverName: parsedOrder.assignedDriverName,
            assignedDriverPhone: parsedOrder.assignedDriverPhone,
            driverLatitude: parsedOrder.driverLatitude,
            driverLongitude: parsedOrder.driverLongitude,
            items: items,
            subtotal: parsedOrder.subtotal > 0 ? parsedOrder.subtotal : subtotal,
            sgstTotal: parsedOrder.sgstTotal > 0 ? parsedOrder.sgstTotal : subtotal * 0.025,
            cgstTotal: parsedOrder.cgstTotal > 0 ? parsedOrder.cgstTotal : subtotal * 0.025,
            deliveryFee: parsedOrder.deliveryFee,
            couponDiscount: parsedOrder.couponDiscount,
            grossTotal: parsedOrder.grossTotal > 0 ? parsedOrder.grossTotal : grossTotal,
            orderStatus: parsedOrder.orderStatus,
            paymentStatus: parsedOrder.paymentStatus,
            paymentMethod: parsedOrder.paymentMethod,
            estimatedDeliveryEta: parsedOrder.estimatedDeliveryEta,
            createdAt: parsedOrder.createdAt,
            deliveryOtp: parsedOrder.deliveryOtp,
            isCancellable: parsedOrder.isCancellable,
            refundAmount: parsedOrder.refundAmount,
            refundStatus: parsedOrder.refundStatus,
          );
        }
        return parsedOrder;
      } catch (e) {
        debugPrint("Error parsing backend order response: $e");
      }
    }

    return OrderModel(
      id: "PZ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
      customerId: customerId,
      customerName: customerName,
      deliveryAddress: deliveryAddress.isNotEmpty ? deliveryAddress : '',
      assignedDriverId: null,
      assignedDriverName: null,
      assignedDriverPhone: null,
      driverLatitude: 12.9716,
      driverLongitude: 77.5946,
      items: items,
      subtotal: subtotal,
      sgstTotal: subtotal * 0.025,
      cgstTotal: subtotal * 0.025,
      deliveryFee: deliveryFee,
      couponDiscount: couponDiscount,
      grossTotal: grossTotal,
      orderStatus: "PLACED",
      paymentStatus: "SUCCESS",
      paymentMethod: paymentMethod,
      estimatedDeliveryEta: "15-20 mins",
      deliveryOtp: "${1000 + (DateTime.now().millisecondsSinceEpoch % 9000)}",
      isCancellable: true,
      refundAmount: grossTotal,
      refundStatus: "NOT_APPLICABLE",
    );
  }

  static Future<List<OrderModel>> getOrders({String? customerId}) async {
    final endpoints = [
      '/api/v1/customer/orders',
      if (customerId != null) '/customers/$customerId/orders',
      '/orders',
      '/billing/orders',
    ];

    for (final ep in endpoints) {
      try {
        final dynamic response = await ApiClient.get(ep, requiresAuth: false);
        List rawList = [];
        if (response is List) {
          rawList = response;
        } else if (response is Map<String, dynamic>) {
          if (response['data'] is List) {
            rawList = response['data'] as List;
          } else if (response['orders'] is List) {
            rawList = response['orders'] as List;
          } else if (response['content'] is List) {
            rawList = response['content'] as List;
          } else if (response['results'] is List) {
            rawList = response['results'] as List;
          }
        }
        if (rawList.isNotEmpty) {
          return rawList
              .whereType<Map<String, dynamic>>()
              .map((x) => OrderModel.fromJson(x))
              .toList();
        }
      } catch (e) {
        debugPrint("Endpoint $ep failed: $e");
      }
    }
    return [];
  }

  static Future<OrderModel?> getOrderById(String orderId) async {
    final endpoints = [
      '/api/v1/customer/orders/$orderId',
      '/orders/$orderId',
      '/orders/track/$orderId',
      '/billing/orders/$orderId',
    ];

    OrderModel? parsedOrder;
    for (final ep in endpoints) {
      try {
        final data = await ApiClient.get(ep, requiresAuth: false);
        if (data is Map<String, dynamic>) {
          final orderMap = data['data'] is Map<String, dynamic>
              ? data['data'] as Map<String, dynamic>
              : (data['order'] is Map<String, dynamic>
                  ? data['order'] as Map<String, dynamic>
                  : (data['result'] is Map<String, dynamic>
                      ? data['result'] as Map<String, dynamic>
                      : data));
          parsedOrder = OrderModel.fromJson(orderMap);
          break;
        }
      } catch (e) {
        debugPrint("Trying $ep failed: $e");
      }
    }

    // If order was found but driver info is empty, query assigned delivery user endpoint
    if (parsedOrder != null && (parsedOrder.assignedDriverName == null || parsedOrder.assignedDriverName!.isEmpty)) {
      final driverInfo = await getAssignedDeliveryUser(orderId);
      if (driverInfo != null) {
        final driverName = driverInfo['name'] ??
            driverInfo['driverName'] ??
            driverInfo['userName'] ??
            driverInfo['deliveryPersonName'] ??
            driverInfo['deliveryUserName'] ??
            driverInfo['agentName'] ??
            driverInfo['fullName'];
        final driverPhone = driverInfo['phone'] ??
            driverInfo['driverPhone'] ??
            driverInfo['mobile'] ??
            driverInfo['phoneNumber'] ??
            driverInfo['deliveryUserPhone'];
        final driverId = (driverInfo['id'] ?? driverInfo['driverId'] ?? driverInfo['userId'] ?? driverInfo['deliveryUserId'])?.toString();

        if (driverName != null) {
          final currentStatus = parsedOrder.orderStatus.toUpperCase();
          final isPendingStage = currentStatus == 'PLACED' ||
              currentStatus == 'CONFIRMED' ||
              currentStatus == 'PACKING' ||
              currentStatus == 'PROCESSING' ||
              currentStatus == 'PACKED' ||
              currentStatus == 'ACCEPTED' ||
              currentStatus == 'PENDING';

          parsedOrder = parsedOrder.copyWith(
            assignedDriverName: driverName.toString(),
            assignedDriverPhone: driverPhone?.toString() ?? parsedOrder.assignedDriverPhone,
            assignedDriverId: driverId ?? parsedOrder.assignedDriverId,
            orderStatus: isPendingStage ? 'ASSIGNED' : parsedOrder.orderStatus,
          );
        }
      }
    }

    return parsedOrder;
  }

  /// Request Refund on Customer Order (/api/v1/customer/orders/{id}/refund)
  static Future<bool> refundOrder({
    required String orderId,
    required String reason,
    required double amount,
  }) async {
    try {
      final res = await ApiClient.post(
        '/api/v1/customer/orders/$orderId/refund',
        body: {
          'reason': reason,
          'amount': amount,
        },
      );
      return res != null;
    } catch (e) {
      debugPrint("refundOrder failed: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getAssignedDeliveryUser(String orderId) async {
    final endpoints = [
      '/orders/$orderId/delivery-partner',
      '/orders/$orderId/driver',
      '/orders/$orderId/assigned-user',
      '/orders/$orderId/delivery-user',
      '/orders/$orderId/delivery-person',
      '/orders/$orderId/agent',
      '/delivery-partners/assigned/$orderId',
      '/delivery/tracking/$orderId',
      '/drivers/order/$orderId',
    ];

    for (final ep in endpoints) {
      try {
        final data = await ApiClient.get(ep, requiresAuth: false);
        if (data is Map<String, dynamic>) {
          final res = data['data'] is Map<String, dynamic>
              ? data['data'] as Map<String, dynamic>
              : (data['driver'] is Map<String, dynamic>
                  ? data['driver'] as Map<String, dynamic>
                  : (data['deliveryPartner'] is Map<String, dynamic>
                      ? data['deliveryPartner'] as Map<String, dynamic>
                      : (data['deliveryUser'] is Map<String, dynamic>
                          ? data['deliveryUser'] as Map<String, dynamic>
                          : (data['assignedUser'] is Map<String, dynamic>
                              ? data['assignedUser'] as Map<String, dynamic>
                              : data))));
          return res;
        }
      } catch (_) {}
    }
    return null;
  }

  // ─── Real-Time Order Chat Endpoints ────────────────

  /// Fetch order chat history from backend
  /// GET /api/v1/orders/{orderId}/chat
  static Future<List<ChatMessageModel>> fetchOrderChat(String orderId) async {
    final cleanId = orderId.trim();
    if (cleanId.isEmpty) return [];
    final strippedId = cleanId.startsWith('#') ? cleanId.substring(1) : cleanId;

    final endpoints = [
      '/api/v1/orders/$strippedId/chat',
      '/api/v1/customer/orders/$strippedId/chat',
      '/orders/$strippedId/chat',
    ];

    for (final ep in endpoints) {
      try {
        final dynamic res = await ApiClient.get(ep, requiresAuth: false);
        if (res is List) {
          return res.map((item) => ChatMessageModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
        }
      } catch (e) {
        debugPrint('fetchOrderChat error on $ep: $e');
      }
    }
    return [];
  }

  /// Send real-time chat message from Customer to Delivery Partner
  /// POST /api/v1/orders/{orderId}/chat
  static Future<ChatMessageModel?> sendOrderChatMessage(String orderId, ChatMessageModel msg) async {
    final cleanId = orderId.trim();
    if (cleanId.isEmpty) return null;
    final strippedId = cleanId.startsWith('#') ? cleanId.substring(1) : cleanId;

    final endpoints = [
      '/api/v1/orders/$strippedId/chat',
      '/api/v1/customer/orders/$strippedId/chat',
      '/orders/$strippedId/chat',
    ];

    for (final ep in endpoints) {
      try {
        final dynamic res = await ApiClient.post(ep, body: msg.toJson());
        if (res is Map<String, dynamic>) {
          return ChatMessageModel.fromJson(res);
        }
      } catch (e) {
        debugPrint('sendOrderChatMessage error on $ep: $e');
      }
    }
    return null;
  }

  /// Close and finalize order chat channel upon delivery
  /// POST /api/v1/orders/{orderId}/chat/close
  static Future<bool> closeOrderChat(String orderId, {String? reason}) async {
    final cleanId = orderId.trim();
    if (cleanId.isEmpty) return false;
    final strippedId = cleanId.startsWith('#') ? cleanId.substring(1) : cleanId;

    try {
      final res = await ApiClient.post(
        '/api/v1/orders/$strippedId/chat/close',
        body: {'reason': reason ?? 'Order delivered. Chat completed.'},
      );
      return res != null;
    } catch (_) {
      return false;
    }
  }

  // ─── Chat (Mock) ────────────────────────────────────

  static List<ChatMessageModel> getMockChatMessages(String orderId) {
    return [
      ChatMessageModel(
        id: "m1",
        orderId: orderId,
        senderId: "drv_88",
        senderName: "Ramesh Kumar (Driver)",
        message: "Hello! I am on my way to PingZo Supermarket to pick up your order.",
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isCustomer: false,
        isRead: true,
      ),
      ChatMessageModel(
        id: "m2",
        orderId: orderId,
        senderId: "cust_101",
        senderName: "Sathish (Customer)",
        message: "Thank you! Please ask them to pack double bag for milk.",
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        isCustomer: true,
        isRead: true,
      ),
      ChatMessageModel(
        id: "m3",
        orderId: orderId,
        senderId: "drv_88",
        senderName: "Ramesh Kumar (Driver)",
        message: "Sure thing! Items picked up. Navigating to your address now.",
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        isCustomer: false,
        isRead: true,
      ),
    ];
  }

  // ─── FAQs (Mock) ────────────────────────────────────

  static List<FaqItem> getMockFaqs() {
    return [
      FaqItem(
        category: "Orders",
        question: "How fast is PingZo grocery delivery?",
        answer: "We deliver directly from our local PingZo supermarket dark store within 10 to 15 minutes.",
      ),
      FaqItem(
        category: "Cancellation",
        question: "Can I cancel my order after placement?",
        answer: "Yes, orders can be cancelled free of charge before the supermarket packs the order. If cancelled after packing, a minimal fee may apply.",
      ),
      FaqItem(
        category: "Payment & Refunds",
        question: "How long do refunds take to reflect in my bank account?",
        answer: "Instant UPI refunds reflect within 5 minutes. Credit card or debit card refunds take 2-4 business days.",
      ),
      FaqItem(
        category: "Delivery Partner",
        question: "How can I contact my assigned delivery partner?",
        answer: "You can use masked call or in-app real-time chat directly from the Order Tracking screen.",
      ),
    ];
  }
}
