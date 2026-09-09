import 'package:flutter/material.dart';
import '../../../core/theme/bento_theme.dart';
import '../home/driver_home_screen.dart';

class DriverOnboardingScreen extends StatefulWidget {
  const DriverOnboardingScreen({Key? key}) : super(key: key);

  @override
  State<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends State<DriverOnboardingScreen> {
  final _nameController = TextEditingController(text: "Ramesh Kumar");
  final _phoneController = TextEditingController(text: "+91 98765 43210");
  final _vehicleController = TextEditingController(text: "KA-01-EQ-9920");
  String _vehicleType = "ELECTRIC_VEHICLE";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BentoTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: BentoTheme.cardDark,
        title: const Text("Partner Onboarding", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Register as Fleet Partner", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text("Earn up to ₹35,000/month delivering fresh groceries", style: TextStyle(fontSize: 13, color: BentoTheme.textSecondary)),
            const SizedBox(height: 20),

            _inputField("Full Name", _nameController),
            const SizedBox(height: 12),
            _inputField("Mobile Phone", _phoneController),
            const SizedBox(height: 12),
            _inputField("Vehicle Number", _vehicleController),
            const SizedBox(height: 16),

            const Text("Vehicle Type", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Row(
              children: [
                _vehicleChoice("ELECTRIC_VEHICLE", "Electric EV ⚡"),
                const SizedBox(width: 10),
                _vehicleChoice("BIKE", "Motorcycle 🏍️"),
              ],
            ),
            const SizedBox(height: 20),

            // Document status card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BentoTheme.bentoCardDecoration(),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_user_rounded, color: BentoTheme.pingzoGreen),
                      SizedBox(width: 8),
                      Text("Background Check Status", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text("Aadhaar Card & Driving License APPROVED", style: TextStyle(fontSize: 12, color: BentoTheme.pingzoGreen, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BentoTheme.pingzoGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DriverHomeScreen()));
                },
                child: const Text("Complete Onboarding & Go to App", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: BentoTheme.cardDark,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _vehicleChoice(String type, String label) {
    final sel = _vehicleType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _vehicleType = type),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: sel ? BentoTheme.pingzoGreen.withValues(alpha: 0.2) : BentoTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? BentoTheme.pingzoGreen : Colors.white12),
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: sel ? BentoTheme.pingzoGreen : Colors.white)),
        ),
      ),
    );
  }
}
