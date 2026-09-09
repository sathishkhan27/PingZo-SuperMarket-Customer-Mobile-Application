import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/bento_theme.dart';
import '../../services/auth_provider.dart';
import '../customer/auth/customer_auth_screen.dart';
import '../customer/home/customer_home_screen.dart';
import '../driver/home/driver_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.loadSession();

    // Splash animation display time
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    if (auth.isDriverMode) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
      );
    } else if (auth.isAuthenticated || auth.hasSkippedAuth) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CustomerAuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background subtle central radial glow
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    BentoTheme.pingzoOrange.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                // Main Logo Icon Container (Orange squircle + Green Sparkle Badge)
                Center(
                  child: SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Orange Main Squircle Box
                        Center(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: BentoTheme.pingzoOrange,
                              borderRadius: BorderRadius.circular(36),
                              boxShadow: [
                                BoxShadow(
                                  color: BentoTheme.pingzoOrange.withValues(alpha: 0.35),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.flash_on_rounded,
                                size: 68,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        // Top Right Green Sparkle Badge
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: BentoTheme.pingzoGreen,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: BentoTheme.pingzoGreen.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .scale(duration: 700.ms, curve: Curves.easeOutBack)
                    .fadeIn(duration: 400.ms),
                const SizedBox(height: 32),
                // App Name Title: "Ping" (Navy) + "Zo" (Orange)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Ping",
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: BentoTheme.textPrimaryDark,
                        letterSpacing: -1.0,
                      ),
                    ),
                    Text(
                      "Zo",
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: BentoTheme.pingzoOrange,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 8),
                Text(
                  "LIGHTNING FAST DELIVERIES",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: BentoTheme.textSecondaryDark.withValues(alpha: 0.7),
                    letterSpacing: 2.5,
                  ),
                ).animate().fadeIn(delay: 450.ms),
                const Spacer(),
                // Bottom Feature Icons (Bag, Scooter, Timer)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFeatureCircle(Icons.local_mall_outlined),
                    const SizedBox(width: 20),
                    _buildFeatureCircle(Icons.two_wheeler_outlined),
                    const SizedBox(width: 20),
                    _buildFeatureCircle(Icons.timer_outlined),
                  ],
                ).animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 24),
                // App Mode Switcher Link for testing (Driver / Customer)
                GestureDetector(
                  onTap: () {
                    auth.toggleMode(!auth.isDriverMode);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Switched to ${auth.isDriverMode ? 'Delivery Partner' : 'Customer'} Mode"),
                        duration: const Duration(seconds: 1),
                        backgroundColor: BentoTheme.pingzoOrange,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: BentoTheme.bgLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: BentoTheme.borderLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          auth.isDriverMode ? Icons.two_wheeler : Icons.shopping_bag,
                          size: 14,
                          color: BentoTheme.pingzoOrange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Mode: ${auth.isDriverMode ? 'Delivery Partner' : 'Customer'} (Tap to toggle)",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: BentoTheme.textSecondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCircle(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: BentoTheme.bgLight,
        border: Border.all(color: BentoTheme.borderLight.withValues(alpha: 0.8)),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 22,
          color: BentoTheme.textSecondaryDark.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

