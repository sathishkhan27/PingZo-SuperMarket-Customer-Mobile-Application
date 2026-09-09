import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/bento_theme.dart';
import '../../../services/auth_provider.dart';
import '../home/driver_home_screen.dart';

class DriverAuthScreen extends StatefulWidget {
  const DriverAuthScreen({Key? key}) : super(key: key);

  @override
  State<DriverAuthScreen> createState() => _DriverAuthScreenState();
}

class _DriverAuthScreenState extends State<DriverAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;

  Future<void> _handleSendOtp() async {
    if (_phoneController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.toggleMode(true); // Driver Mode
    await auth.sendOtp(_phoneController.text.trim());
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _otpSent = true;
    });
  }

  Future<void> _handleVerifyOtp() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.toggleMode(true); // Driver Mode
    bool success = await auth.loginWithOtp(_phoneController.text.trim(), _otpController.text.trim());
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Partner OTP. Try 1234 or your verification code.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BentoTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.two_wheeler_rounded, size: 48, color: BentoTheme.pingzoPurple),
              const SizedBox(height: 16),
              const Text(
                "PingZo Fleet Partner Portal",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                "Login with your registered fleet partner mobile number",
                style: TextStyle(fontSize: 14, color: BentoTheme.textSecondary),
              ),
              const SizedBox(height: 24),

              // Verification status banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BentoTheme.bentoCardDecoration(color: BentoTheme.cardDark),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: BentoTheme.pingzoGreen),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("KYC Verification Active", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text("Driving License & EV Scooter Approved", style: TextStyle(fontSize: 11, color: BentoTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (!_otpSent) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BentoTheme.bentoCardDecoration(),
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(top: 12, right: 8),
                        child: Text("+91 | ", style: TextStyle(color: BentoTheme.pingzoPurple, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      hintText: "Driver Mobile Number",
                      hintStyle: TextStyle(color: BentoTheme.textSecondary),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BentoTheme.pingzoPurple,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isLoading ? null : _handleSendOtp,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Send Partner OTP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BentoTheme.bentoCardDecoration(),
                  child: TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                    decoration: const InputDecoration(
                      hintText: "••••",
                      counterText: "",
                      hintStyle: TextStyle(color: BentoTheme.textSecondary),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BentoTheme.pingzoPurple,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isLoading ? null : _handleVerifyOtp,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Verify & Go Online", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
