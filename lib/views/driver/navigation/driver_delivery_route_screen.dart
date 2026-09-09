import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/bento_theme.dart';
import '../../../services/driver_provider.dart';
import '../../customer/chat/driver_chat_screen.dart';
import 'delivery_confirmation_dialog.dart';

class DriverDeliveryRouteScreen extends StatelessWidget {
  const DriverDeliveryRouteScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final driverProv = Provider.of<DriverProvider>(context);
    final order = driverProv.assignedOrder;

    return Scaffold(
      backgroundColor: BentoTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: BentoTheme.cardDark,
        elevation: 0,
        title: const Text("Stage 2: Out for Delivery", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Map Route to Customer Simulation
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
                      const Icon(Icons.two_wheeler_rounded, size: 54, color: BentoTheme.pingzoPurple),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: BentoTheme.cardDark, borderRadius: BorderRadius.circular(16)),
                        child: const Text("Navigating to Customer • 2.4 KM (7 mins)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Customer Delivery Details Sheet
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Customer: ${order?.customerName ?? 'Sathish Kumar'}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(order?.deliveryAddress ?? "Koramangala 4th Block, Bengaluru", style: const TextStyle(fontSize: 12, color: BentoTheme.textSecondary)),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.phone_rounded, color: BentoTheme.pingzoGreen),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Calling Customer via Masked Privacy Number..."), backgroundColor: BentoTheme.pingzoGreen),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat_rounded, color: BentoTheme.pingzoPurple),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverChatScreen()));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: BentoTheme.primaryDark, borderRadius: BorderRadius.circular(10)),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: BentoTheme.pingzoOrange, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text("Instruction: Ring door bell & leave package at door if requested.", style: TextStyle(fontSize: 11, color: BentoTheme.textSecondary)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BentoTheme.pingzoGreen,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => DeliveryConfirmationDialog.show(context),
                  child: const Text("ARRIVED AT LOCATION & VERIFY OTP", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
