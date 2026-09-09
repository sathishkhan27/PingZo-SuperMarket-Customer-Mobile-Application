import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pingzo_mobile/main.dart';
import 'package:pingzo_mobile/services/cart_provider.dart';
import 'package:pingzo_mobile/services/auth_provider.dart';
import 'package:pingzo_mobile/services/order_provider.dart';
import 'package:pingzo_mobile/services/driver_provider.dart';
import 'package:pingzo_mobile/services/product_provider.dart';
import 'package:pingzo_mobile/services/banner_provider.dart';
import 'package:pingzo_mobile/services/location_provider.dart';
import 'package:pingzo_mobile/services/notification_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PingZo app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => OrderProvider()),
          ChangeNotifierProvider(create: (_) => DriverProvider()),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => BannerProvider()),
          ChangeNotifierProvider(create: (_) => LocationProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ],
        child: const PingZoEcosystemApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
