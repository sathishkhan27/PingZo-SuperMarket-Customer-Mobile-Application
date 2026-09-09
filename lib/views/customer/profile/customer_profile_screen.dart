import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/bento_theme.dart';
import '../../../services/auth_provider.dart';
import '../auth/customer_auth_screen.dart';
import '../../location/location_map_picker_screen.dart';
import '../orders/customer_orders_screen.dart';
import '../support/customer_support_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../splash/splash_screen.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final isAuth = auth.isAuthenticated && user != null;

    return Scaffold(
      backgroundColor: BentoTheme.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text("My Profile", style: TextStyle(color: BentoTheme.textPrimaryDark, fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BentoTheme.textPrimaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Profile Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: BentoTheme.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isAuth
                  ? Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: BentoTheme.pingzoOrange,
                          ),
                          child: Center(
                            child: Text(
                              user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : "U",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: BentoTheme.textPrimaryDark)),
                              const SizedBox(height: 2),
                              Text("${user.phone} • ${user.email.isNotEmpty ? user.email : 'customer@pingzo.com'}", style: const TextStyle(fontSize: 12, color: BentoTheme.textSecondaryDark)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(color: BentoTheme.pingzoGreenLight, borderRadius: BorderRadius.circular(8)),
                                child: const Text("PingZo Gold Member ⚡", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: BentoTheme.pingzoGreenDark)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF8B2FC9).withValues(alpha: 0.15),
                              ),
                              child: const Icon(Icons.person_outline_rounded, color: Color(0xFF8B2FC9), size: 28),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Guest Customer", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: BentoTheme.textPrimaryDark)),
                                  SizedBox(height: 2),
                                  Text("Login for live order tracking & faster checkout", style: TextStyle(fontSize: 12, color: BentoTheme.textSecondaryDark)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B2FC9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CustomerAuthScreen(popOnSuccess: true)),
                              );
                            },
                            child: const Text("LOGIN / SIGN UP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 20),

            // Profile Options Menu (SOP Section 24)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: BentoTheme.borderLight),
              ),
              child: Column(
                children: [
                  _buildProfileTile(
                    icon: Icons.receipt_long_rounded,
                    title: "My Orders",
                    subtitle: "Order history, live tracking & invoices",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerOrdersScreen()));
                    },
                  ),
                  const Divider(color: BentoTheme.borderLight, height: 1, indent: 60),
                  _buildProfileTile(
                    icon: Icons.location_on_outlined,
                    title: "Delivery Addresses",
                    subtitle: "Manage home & work addresses",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationMapPickerScreen()));
                    },
                  ),
                  const Divider(color: BentoTheme.borderLight, height: 1, indent: 60),
                  _buildProfileTile(
                    icon: Icons.notifications_none_rounded,
                    title: "Notifications",
                    subtitle: "Order updates & offer alerts",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                    },
                  ),
                  const Divider(color: BentoTheme.borderLight, height: 1, indent: 60),
                  _buildProfileTile(
                    icon: Icons.headset_mic_outlined,
                    title: "Customer Support",
                    subtitle: "24x7 chat & order assistance",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerSupportScreen()));
                    },
                  ),
                  const Divider(color: BentoTheme.borderLight, height: 1, indent: 60),
                  _buildProfileTile(
                    icon: Icons.policy_outlined,
                    title: "Terms & Privacy Policy",
                    subtitle: "PingZo quick commerce policies",
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout or Login Action Button
            if (isAuth)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  label: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                  onPressed: () async {
                    await auth.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const SplashScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: BentoTheme.bgLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: BentoTheme.pingzoOrange, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: BentoTheme.textPrimaryDark)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: BentoTheme.textSecondaryDark)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: BentoTheme.textSecondaryDark, size: 14),
      onTap: onTap,
    );
  }
}

