import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/bento_theme.dart';
import '../../../models/order_model.dart';
import '../../../services/driver_provider.dart';

import 'assignment_alert_dialog.dart';
import '../earnings/driver_earnings_screen.dart';
import '../performance/driver_performance_screen.dart';
import '../../splash/splash_screen.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({Key? key}) : super(key: key);

  void _triggerAssignment(BuildContext context, DriverProvider driverProv) {
    final seedItem = OrderItemModel(
      productId: "p1",
      productName: "Fresh Hybrid Tomatoes",
      quantity: 2,
      unitPrice: 28.0,
      totalPrice: 56.0,
      sgstAmount: 0,
      cgstAmount: 0,
      isVegetableOrFruit: true,
    );

    final mockOrder = OrderModel(
      id: "PZ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
      customerId: "cust_101",
      customerName: "Sathish Kumar",
      deliveryAddress: "Koramangala 4th Block, Bengaluru",
      driverLatitude: 12.9716,
      driverLongitude: 77.5946,
      items: [seedItem],
      subtotal: 150.0,
      sgstTotal: 0,
      cgstTotal: 0,
      deliveryFee: 0,
      couponDiscount: 20,
      grossTotal: 130.0,
      orderStatus: "READY_FOR_PICKUP",
      paymentStatus: "SUCCESS",
      estimatedDeliveryEta: "8 mins",
    );

    driverProv.triggerMockAssignment(mockOrder);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AssignmentAlertDialog(order: mockOrder),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driverProv = Provider.of<DriverProvider>(context);

    return Scaffold(
      backgroundColor: BentoTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: BentoTheme.cardDark,
        elevation: 0,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: BentoTheme.pingzoPurple,
              child: Icon(Icons.two_wheeler_rounded, size: 18, color: Colors.white),
            ),
            SizedBox(width: 8),
            Text("PingZo Driver Partner", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SplashScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // GO ONLINE / OFFLINE TOGGLE CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BentoTheme.bentoCardDecoration(
                color: driverProv.isOnline ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverProv.isOnline ? "YOU ARE ONLINE ⚡" : "YOU ARE OFFLINE 🌙",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        driverProv.isOnline ? "Ready to receive nearby delivery assignments" : "Toggle online to start receiving orders",
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                  Switch(
                    value: driverProv.isOnline,
                    activeThumbColor: BentoTheme.pingzoGreen,
                    onChanged: (val) => driverProv.toggleOnlineStatus(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // TODAY'S SUMMARY BENTO GRID
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Today's Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _summaryMetricCard(
                  title: "Today's Earnings",
                  value: "₹${driverProv.todayEarnings.toStringAsFixed(0)}",
                  subtitle: "+₹140 Incentives",
                  icon: Icons.account_balance_wallet_rounded,
                  color: BentoTheme.pingzoGreen,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverEarningsScreen())),
                ),
                _summaryMetricCard(
                  title: "Completed Orders",
                  value: "${driverProv.todayDeliveriesCount}",
                  subtitle: "100% Fulfilled",
                  icon: Icons.check_circle_rounded,
                  color: BentoTheme.pingzoPurple,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverPerformanceScreen())),
                ),
                _summaryMetricCard(
                  title: "Distance Covered",
                  value: "${driverProv.todayDistanceKm} KM",
                  subtitle: "EV Scooter Fuel",
                  icon: Icons.two_wheeler_rounded,
                  color: BentoTheme.pingzoOrange,
                  onTap: () {},
                ),
                _summaryMetricCard(
                  title: "Partner Rating",
                  value: "⭐ ${driverProv.driverRating}",
                  subtitle: "96.5% Acceptance",
                  icon: Icons.star_rounded,
                  color: Colors.amber,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverPerformanceScreen())),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // SIMULATE ASSIGNMENT ACTION BUTTON
            if (driverProv.isOnline)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BentoTheme.pingzoPurple,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.notifications_active_rounded, color: Colors.white),
                label: const Text("Simulate New Delivery Assignment", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                onPressed: () => _triggerAssignment(context, driverProv),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: BentoTheme.cardDark,
        selectedItemColor: BentoTheme.pingzoPurple,
        unselectedItemColor: BentoTheme.textSecondary,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverEarningsScreen()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverPerformanceScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: "Earnings"),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: "Performance"),
        ],
      ),
    );
  }

  Widget _summaryMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BentoTheme.bentoCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: BentoTheme.textSecondary, fontWeight: FontWeight.bold)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(subtitle, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
