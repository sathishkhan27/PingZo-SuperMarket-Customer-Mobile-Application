import 'package:flutter/material.dart';
import '../../../core/theme/bento_theme.dart';


class DriverPerformanceScreen extends StatelessWidget {
  const DriverPerformanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BentoTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: BentoTheme.cardDark,
        elevation: 0,
        title: const Text("Partner Performance", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            // Overall Score Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BentoTheme.bentoCardDecoration(color: BentoTheme.cardDark),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                    child: const Text("4.9", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("EXCELLENT PERFORMANCE", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber)),
                      Text("Top 5% Fleet Partner in Bengaluru", style: TextStyle(fontSize: 12, color: BentoTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Performance Metrics Bento Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _metricTile("Acceptance Rate", "96.5%", "High Priority", BentoTheme.pingzoGreen),
                _metricTile("Rejection Rate", "3.5%", "Low Rejection", BentoTheme.pingzoPurple),
                _metricTile("Avg Delivery Time", "11.2 mins", "Express Speed", BentoTheme.pingzoOrange),
                _metricTile("Cancellation Rate", "0.0%", "Perfect Record", BentoTheme.pingzoGreen),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricTile(String title, String value, String tag, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BentoTheme.bentoCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: BentoTheme.textSecondary, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(tag, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
