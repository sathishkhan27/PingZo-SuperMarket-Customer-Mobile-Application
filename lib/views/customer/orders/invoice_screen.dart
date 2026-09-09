import 'package:flutter/material.dart';
import '../../../core/theme/bento_theme.dart';
import '../../../models/order_model.dart';

class InvoiceScreen extends StatelessWidget {
  final OrderModel order;
  const InvoiceScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BentoTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: BentoTheme.cardDark,
        elevation: 0,
        title: Text("Invoice #${order.id}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BentoTheme.bentoCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("PINGZO SUPERMARKET", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: BentoTheme.pingzoGreen)),
                      Text("GSTIN: 29AAACP9928K1Z5", style: TextStyle(fontSize: 11, color: BentoTheme.textSecondary)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: BentoTheme.pingzoGreen, borderRadius: BorderRadius.circular(6)),
                    child: const Text("PAID", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 28),
              Text("Order ID: #${order.id}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text("Date: ${order.createdAt.toString().split('.')[0]}", style: const TextStyle(color: BentoTheme.textSecondary, fontSize: 12)),
              Text("Customer: ${order.customerName}", style: const TextStyle(color: BentoTheme.textSecondary, fontSize: 12)),
              Text("Delivery Address: ${order.deliveryAddress}", style: const TextStyle(color: BentoTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 20),

              // Itemized Table
              const Text("Item Summary", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              ...order.items.map((i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text("${i.quantity}x ${i.productName}", style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                      Text("₹${i.totalPrice.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                );
              }).toList(),
              const Divider(color: Colors.white24, height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Subtotal", style: TextStyle(color: BentoTheme.textSecondary)),
                  Text("₹${order.subtotal.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white)),
                ],
              ),
              if (order.couponDiscount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Coupon Discount", style: TextStyle(color: BentoTheme.pingzoGreen)),
                    Text("-₹${order.couponDiscount.toStringAsFixed(2)}", style: const TextStyle(color: BentoTheme.pingzoGreen)),
                  ],
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Taxes (SGST + CGST)", style: TextStyle(color: BentoTheme.textSecondary)),
                  Text("₹${(order.sgstTotal + order.cgstTotal).toStringAsFixed(2)}", style: const TextStyle(color: Colors.white)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Delivery Fee", style: TextStyle(color: BentoTheme.textSecondary)),
                  Text(order.deliveryFee == 0 ? "FREE" : "₹${order.deliveryFee.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white)),
                ],
              ),
              const Divider(color: Colors.white24, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Grand Total", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text("₹${order.grossTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: BentoTheme.pingzoGreen)),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.download_rounded, color: BentoTheme.pingzoGreen),
                      label: const Text("Download PDF", style: TextStyle(color: BentoTheme.pingzoGreen)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Downloading PDF Invoice..."), backgroundColor: BentoTheme.pingzoGreen),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: BentoTheme.pingzoGreen),
                      icon: const Icon(Icons.share_rounded, color: Colors.white),
                      label: const Text("Share Invoice", style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Invoice link copied to clipboard!")),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
