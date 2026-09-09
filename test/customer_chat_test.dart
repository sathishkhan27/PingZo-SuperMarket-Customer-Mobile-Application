import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pingzo_mobile/models/order_model.dart';
import 'package:pingzo_mobile/services/order_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Customer Chat initializes, sends message, and completes on order delivery', () async {
    SharedPreferences.setMockInitialValues({});
    final orderProv = OrderProvider();

    final testOrder = OrderModel(
      id: 'PZ-8899',
      customerId: 'cust_101',
      customerName: 'Sathish',
      deliveryAddress: 'Tower 4, Apt 802, Prestige Ferns, Koramangala',
      supermarketName: 'Truffles Supermarket',
      supermarketAddress: '80 Feet Road, Koramangala',
      assignedDriverId: 'drv_88',
      assignedDriverName: 'Ramesh Kumar',
      assignedDriverPhone: '+91 98765 43210',
      driverLatitude: 12.9279,
      driverLongitude: 77.6271,
      items: [],
      subtotal: 350.0,
      sgstTotal: 8.75,
      cgstTotal: 8.75,
      deliveryFee: 30.0,
      couponDiscount: 0.0,
      grossTotal: 397.5,
      orderStatus: 'OUT_FOR_DELIVERY',
      paymentStatus: 'SUCCESS',
      paymentMethod: 'UPI',
      estimatedDeliveryEta: '10-15 mins',
      createdAt: DateTime.now(),
      deliveryOtp: '4829',
    );

    // Add order to provider
    orderProv.addOrder(testOrder);
    expect(orderProv.activeOrder, isNotNull);

    final orderId = testOrder.id;

    // Verify chat is initialized and active
    expect(orderProv.isOrderChatCompleted(orderId), isFalse);
    final initialCount = orderProv.getChatMessagesForOrder(orderId).length;
    expect(initialCount, greaterThanOrEqualTo(2));

    // Send customer chat message
    orderProv.sendChatMessage(
      'Gate code is #8821, Building B',
      isCustomer: true,
      orderId: orderId,
    );
    final messagesAfterCustomer = orderProv.getChatMessagesForOrder(orderId);
    expect(messagesAfterCustomer.length, equals(initialCount + 1));

    // Update order status to DELIVERED
    orderProv.updateOrderStatus(orderId, 'DELIVERED');

    // Chat should immediately be marked as completed
    expect(orderProv.isOrderChatCompleted(orderId), isTrue);

    // Closure system message should exist
    final messagesFinal = orderProv.getChatMessagesForOrder(orderId);
    final closureMsg = messagesFinal.firstWhere((m) => m.isSystem && m.id.startsWith('sys-closed-'));
    expect(closureMsg, isNotNull);
    expect(closureMsg.message.contains('delivered successfully'), isTrue);

    // Attempting to send message after completion should be ignored
    final prevCount = messagesFinal.length;
    orderProv.sendChatMessage(
      'Should not be added',
      isCustomer: true,
      orderId: orderId,
    );
    expect(orderProv.getChatMessagesForOrder(orderId).length, equals(prevCount));
  });
}
