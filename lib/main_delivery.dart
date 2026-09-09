import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/bento_theme.dart';
import 'services/cart_provider.dart';
import 'services/auth_provider.dart';
import 'services/order_provider.dart';
import 'services/driver_provider.dart';
import 'views/driver/home/driver_home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (ctx) {
          final auth = AuthProvider();
          auth.toggleMode(true); // Driver mode
          return auth;
        }),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
      ],
      child: MaterialApp(
        title: 'PingZo Delivery Partner App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: BentoTheme.primaryDark,
          primaryColor: BentoTheme.pingzoGreen,
          colorScheme: const ColorScheme.dark(
            primary: BentoTheme.pingzoGreen,
            secondary: BentoTheme.pingzoPurple,
            surface: BentoTheme.cardDark,
          ),
        ),
        home: const DriverHomeScreen(),
      ),
    ),
  );
}
