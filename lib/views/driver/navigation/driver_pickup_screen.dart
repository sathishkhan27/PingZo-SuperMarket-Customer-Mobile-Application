import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/bento_theme.dart';
import '../../../services/driver_provider.dart';
import '../../../services/order_provider.dart';
import 'driver_delivery_route_screen.dart';

class DriverPickupScreen extends StatefulWidget {
  const DriverPickupScreen({Key? key}) : super(key: key);

  @override
  State<DriverPickupScreen> createState() => _DriverPickupScreenState();
}

class _DriverPickupScreenState extends State<DriverPickupScreen> {
  final TextEditingController _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final driverProv = Provider.of<DriverProvider>(context);
    final order = driverProv.assignedOrder;

    return Scaffold(
      backgroundColor: BentoTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: BentoTheme.cardDark,
        elevation: 0,
        title: const Text("Stage 1: Navigate to Store", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Map Route to Supermarket Simulation
          Expanded(
            child: Container(
              color: const Color(0xFF1E293B),
              child: GridPaper(
                color: Colors.white.withValues(alpha: 0.05),
                divisions: 4,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.navigation_rounded, size: 54, color: BentoTheme.pingzoGreen),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: BentoTheme.cardDark, borderRadius: BorderRadius.circular(16)),
                        child: const Text("0.8 KM to PingZo Supermarket Darkstore #04", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Supermarket Pickup Confirmation Sheet
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: BentoTheme.cardDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("ORDER #${order?.id ?? 'PZ-884920'}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: BentoTheme.pingzoGreen.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                      child: const Text("PACKED & READY", style: TextStyle(color: BentoTheme.pingzoGreen, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text("Items Package Checklist:", style: TextStyle(fontSize: 12, color: BentoTheme.textSecondary)),
                const SizedBox(height: 6),
                const Text("• 1x Sealed Grocery Bag #04A\n• 1x Organic Veggie Pouch #04B", style: TextStyle(color: Colors.white, fontSize: 13)),
                const SizedBox(height: 16),

                const Text("Enter Store Pickup Verification Code:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BentoTheme.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        decoration: InputDecoration(
                          hintText: "Enter 4-digit code (or 1234)",
                          hintStyle: const TextStyle(color: BentoTheme.textSecondary, fontSize: 13),
                          filled: true,
                          fillColor: BentoTheme.primaryDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BentoTheme.pingzoGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final orderProv = Provider.of<OrderProvider>(context, listen: false);
                        driverProv.confirmStorePickup(_otpController.text, orderProv: orderProv);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const DriverDeliveryRouteScreen()),
                        );
                      },
                      child: const Text("CONFIRM PICKUP", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
