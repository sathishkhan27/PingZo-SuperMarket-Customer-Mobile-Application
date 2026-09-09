import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/bento_theme.dart';
import '../../../models/order_model.dart';
import '../../../services/driver_provider.dart';
import '../../../services/order_provider.dart';
import '../navigation/driver_pickup_screen.dart';

class AssignmentAlertDialog extends StatelessWidget {
  final OrderModel order;
  const AssignmentAlertDialog({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final driverProv = Provider.of<DriverProvider>(context);

    return Dialog(
      backgroundColor: BentoTheme.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("NEW DELIVERY ASSIGNMENT ⚡", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: BentoTheme.pingzoGreen)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: const BoxDecoration(color: BentoTheme.accentRed, shape: BoxShape.circle),
                  child: Text(
                    "${driverProv.assignmentCountdown}s",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pickup & Drop Cards
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BentoTheme.bentoCardDecoration(color: BentoTheme.primaryDark),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storefront_rounded, color: BentoTheme.pingzoGreen, size: 20),
                      SizedBox(width: 8),
                      Text("PICKUP: PingZo DarkStore #04", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 28),
                    child: Text("Koramangala 80ft Road • 0.8 km away", style: TextStyle(color: BentoTheme.textSecondary, fontSize: 11)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BentoTheme.bentoCardDecoration(color: BentoTheme.primaryDark),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: BentoTheme.pingzoOrange, size: 20),
                      SizedBox(width: 8),
                      Text("DROP: Customer Location", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: Text("${order.deliveryAddress} • 2.4 km away", style: const TextStyle(color: BentoTheme.textSecondary, fontSize: 11)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text("Est. Payout", style: TextStyle(color: BentoTheme.textSecondary, fontSize: 11)),
                    Text("₹85.00", style: const TextStyle(color: BentoTheme.pingzoGreen, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    const Text("Total Distance", style: TextStyle(color: BentoTheme.textSecondary, fontSize: 11)),
                    const Text("3.2 KM", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: BentoTheme.accentRed),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      driverProv.rejectAssignment();
                      Navigator.pop(context);
                    },
                    child: const Text("REJECT", style: TextStyle(color: BentoTheme.accentRed, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BentoTheme.pingzoGreen,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      final orderProv = Provider.of<OrderProvider>(context, listen: false);
                      driverProv.acceptAssignment(orderProv: orderProv);
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DriverPickupScreen()),
                      );
                    },
                    child: const Text("ACCEPT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
