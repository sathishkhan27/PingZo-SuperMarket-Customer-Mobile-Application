import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/bento_theme.dart';
import 'services/cart_provider.dart';
import 'services/auth_provider.dart';
import 'services/order_provider.dart';
import 'services/driver_provider.dart';
import 'services/product_provider.dart';
import 'services/banner_provider.dart';
import 'services/location_provider.dart';
import 'services/notification_provider.dart';
import 'services/notification_service.dart';
import 'views/splash/splash_screen.dart';

void main() {
  runApp(
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
}

class PingZoEcosystemApp extends StatelessWidget {
  const PingZoEcosystemApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'PingZo Grocery & Fresh Vegetables',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: BentoTheme.bgLight,
        primaryColor: BentoTheme.pingzoOrange,
        colorScheme: const ColorScheme.light(
          primary: BentoTheme.pingzoOrange,
          secondary: BentoTheme.pingzoGreen,
          surface: BentoTheme.cardLight,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: BentoTheme.textPrimaryDark,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

