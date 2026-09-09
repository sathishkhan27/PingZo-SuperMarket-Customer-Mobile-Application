import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/bento_theme.dart';
import '../../../services/auth_provider.dart';
import '../../../services/driver_provider.dart';
import '../../splash/splash_screen.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final driverProv = Provider.of<DriverProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: BentoTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: BentoTheme.cardDark,
        title: const Text("Fleet Partner Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Driver Profile Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BentoTheme.bentoCardDecoration(),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: BentoTheme.pingzoPurple,
                    child: Icon(Icons.two_wheeler_rounded, size: 30, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? "Ramesh Kumar", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text("Vehicle: ${user?.vehicleNumber ?? 'KA-05-PZ-9988'} (${user?.vehicleType ?? 'EV Scooter'})", style: const TextStyle(fontSize: 12, color: BentoTheme.textSecondary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                            Text("${driverProv.driverRating} Rating (${driverProv.todayDeliveriesCount} Today)", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Earnings & Performance Summary Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BentoTheme.bentoCardDecoration(color: const Color(0xFF064E3B)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Today's Earnings", style: TextStyle(fontSize: 12, color: Colors.white70)),
                        Text("₹${driverProv.todayEarnings.toStringAsFixed(0)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: BentoTheme.pingzoGreen)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BentoTheme.bentoCardDecoration(color: const Color(0xFF312E81)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Completed Orders", style: TextStyle(fontSize: 12, color: Colors.white70)),
                        Text("${driverProv.todayDeliveriesCount} Orders", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: BentoTheme.pingzoPurple)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Partner Support Hotline
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BentoTheme.bentoCardDecoration(),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_center_rounded, color: BentoTheme.pingzoGreen),
                      SizedBox(width: 10),
                      Text("Partner Support & Help Center", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text("Need help with vehicle breakdown, route issues, or wallet payout? Call PingZo Partner Hotline: 1800-PINGZO-FLEET",
                      style: TextStyle(fontSize: 13, color: BentoTheme.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: BentoTheme.cardDark,
                side: const BorderSide(color: BentoTheme.pingzoPurple),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.swap_horiz_rounded, color: BentoTheme.pingzoPurple),
              label: const Text("Switch to App Mode Launcher", style: TextStyle(color: BentoTheme.pingzoPurple, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SplashScreen())),
            ),
          ],
        ),
      ),
    );
  }
}
