import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/bento_theme.dart';
import '../../../services/driver_provider.dart';
import '../../../services/order_provider.dart';

class DeliveryConfirmationDialog {
  static void show(BuildContext context) {
    final TextEditingController otpController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return Consumer<DriverProvider>(
          builder: (context, driverProv, child) {
            return AlertDialog(
              backgroundColor: BentoTheme.cardDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Customer Delivery Verification", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Ask customer for their 4-digit Delivery OTP (or use 4829):", style: TextStyle(color: BentoTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 6),
                    decoration: InputDecoration(
                      hintText: "••••",
                      counterText: "",
                      hintStyle: const TextStyle(color: BentoTheme.textSecondary),
                      filled: true,
                      fillColor: BentoTheme.primaryDark,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCEL", style: TextStyle(color: BentoTheme.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: BentoTheme.pingzoGreen),
                  onPressed: () {
                    final orderProv = Provider.of<OrderProvider>(context, listen: false);
                    bool verified = driverProv.verifyCustomerOtp(otpController.text, orderProv: orderProv);
                    if (verified) {
                      Navigator.pop(context); // Close modal
                      driverProv.completeDeliveryAndReturnOnline();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Delivery Completed! ₹85 added to earnings ⚡"), backgroundColor: BentoTheme.pingzoGreen),
                      );
                      Navigator.pop(context); // Return to Driver Home
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Invalid Customer OTP. Try 4829."), backgroundColor: BentoTheme.accentRed),
                      );
                    }
                  },
                  child: const Text("VERIFY & COMPLETE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
