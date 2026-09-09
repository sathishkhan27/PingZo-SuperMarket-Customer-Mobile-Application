import 'package:flutter/material.dart';
import '../../../core/theme/bento_theme.dart';
import '../../customer/chat/driver_chat_screen.dart';

class DriverNavigationScreen extends StatefulWidget {
  const DriverNavigationScreen({Key? key}) : super(key: key);

  @override
  State<DriverNavigationScreen> createState() => _DriverNavigationScreenState();
}

class _DriverNavigationScreenState extends State<DriverNavigationScreen> {
  String _currentStage = "PICKED_UP";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BentoTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: BentoTheme.cardDark,
        title: const Text("Driver Navigation", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFF1E293B),
              child: GridPaper(
                color: Colors.white.withValues(alpha: 0.05),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.turn_right_rounded, color: BentoTheme.pingzoGreen, size: 54),
                      SizedBox(height: 8),
                      Text("In 200m, turn right onto 80 Feet Road", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BentoTheme.bentoCardDecoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Customer: Sathish Kumar", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text("Koramangala 4th Block • +91 98765 43210", style: TextStyle(fontSize: 12, color: BentoTheme.textSecondary)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_rounded, color: BentoTheme.pingzoGreen, size: 28),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverChatScreen())),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BentoTheme.pingzoGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      if (_currentStage == "PICKED_UP") {
                        setState(() => _currentStage = "OUT_FOR_DELIVERY");
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Status: Out for Delivery!")));
                      } else {
                        setState(() => _currentStage = "DELIVERED");
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Delivered!")));
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      _currentStage == "PICKED_UP" ? "Mark Order Picked Up" : "Complete & Mark Delivered ⚡",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
