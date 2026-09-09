import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/bento_theme.dart';
import '../../../services/driver_provider.dart';

class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final driverProv = Provider.of<DriverProvider>(context);

    return Scaffold(
      backgroundColor: BentoTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: BentoTheme.cardDark,
        elevation: 0,
        title: const Text("Earnings & Incentives", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Payout Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BentoTheme.bentoCardDecoration(color: BentoTheme.cardDark),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("THIS WEEK'S EARNINGS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BentoTheme.textSecondary, letterSpacing: 1.1)),
                  const SizedBox(height: 8),
                  const Text("₹8,920.50", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: BentoTheme.pingzoGreen)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _earningStat("Today", "₹${driverProv.todayEarnings.toStringAsFixed(0)}"),
                      _earningStat("Incentives", "₹650.00"),
                      _earningStat("Tips", "₹340.00"),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text("Recent Delivery Payouts", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),

            _payoutItem("Order #PZ-884920", "2.4 km • 12 mins", "₹85.00", "COMPLETED"),
            _payoutItem("Order #PZ-884811", "1.8 km • 9 mins", "₹65.00", "COMPLETED"),
            _payoutItem("Order #PZ-884709", "3.1 km • 15 mins", "₹110.00", "COMPLETED"),
            _payoutItem("Daily Target Bonus", "Completed 12 orders goal", "₹150.00", "BONUS"),
          ],
        ),
      ),
    );
  }

  Widget _earningStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: BentoTheme.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _payoutItem(String title, String subtitle, String amount, String tag) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BentoTheme.bentoCardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: BentoTheme.textSecondary)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: BentoTheme.pingzoGreen)),
              Text(tag, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BentoTheme.pingzoPurple)),
            ],
          ),
        ],
      ),
    );
  }
}
