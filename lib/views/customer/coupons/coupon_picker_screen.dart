import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/bento_theme.dart';
import '../../../services/api_service.dart';
import '../../../services/cart_provider.dart';

class CouponPickerScreen extends StatelessWidget {
  const CouponPickerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final availableCoupons = ApiService.getMockCoupons();

    return Scaffold(
      backgroundColor: BentoTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: BentoTheme.cardDark,
        title: const Text("Apply Coupon Code", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: availableCoupons.length,
        itemBuilder: (context, idx) {
          final coupon = availableCoupons[idx];
          final eligible = cart.subtotal >= coupon.minOrderAmount;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BentoTheme.bentoCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: BentoTheme.pingzoGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: BentoTheme.pingzoGreen),
                      ),
                      child: Text(coupon.code, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: BentoTheme.pingzoGreen)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: eligible ? BentoTheme.pingzoGreen : Colors.grey,
                      ),
                      onPressed: eligible
                          ? () {
                              cart.applyCoupon(coupon);
                              Navigator.pop(context);
                            }
                          : null,
                      child: Text(
                        eligible ? "APPLY" : "LOCKED",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: eligible ? Colors.white : Colors.white54),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(coupon.description, style: const TextStyle(fontSize: 13, color: BentoTheme.textSecondary)),
              ],
            ),
          );
        },
      ),
    );
  }
}
