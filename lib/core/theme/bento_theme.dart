import 'package:flutter/material.dart';

class BentoTheme {
  // Primary PingZo Brand Colors (matching UI screenshots)
  static const Color pingzoOrange = Color(0xFFFF4500); // #FF4500 Vibrant Orange
  static const Color pingzoOrangeLight = Color(0xFFFF6B00);
  static const Color pingzoOrangeDark = Color(0xFFCC3700);

  static const Color pingzoGreen = Color(0xFF00B36B); // #00B36B Vivid Fresh Green
  static const Color pingzoGreenLight = Color(0xFFE6F7F0);
  static const Color pingzoGreenDark = Color(0xFF00804C);

  static const Color pingzoPink = Color(0xFFFF2A55); // #FF2A55 Pinkish-Red Add button
  static const Color pingzoPurple = Color(0xFF6366F1); // #6366F1 Accent Indigo

  // Background & Surfaces
  static const Color bgLight = Color(0xFFF8FAFC); // Slate 50 off-white
  static const Color cardLight = Colors.white;
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200 border
  static const Color borderSubtle = Color(0xFFF1F5F9);

  // Dark fallback theme constants
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color cardDark = Color(0xFF1E293B);

  // Text Colors
  static const Color textPrimaryDark = Color(0xFF0F172A); // High contrast dark navy
  static const Color textSecondaryDark = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8);

  // Backward compatibility getters
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color accentRed = Color(0xFFEF4444);

  static const Color textPrimaryLight = Colors.white;
  static const Color textSecondaryLight = Color(0xFFCBD5E1);

  // Card & Container Styling
  static BoxDecoration bentoCardDecoration({
    Color? color,
    Color? borderColor,
    double borderRadius = 18.0,
    bool isElevated = true,
  }) {
    return BoxDecoration(
      color: color ?? cardLight,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? borderLight,
        width: 1,
      ),
      boxShadow: isElevated
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );
  }

  // Gradients
  static const LinearGradient bannerGradient = LinearGradient(
    colors: [Color(0xFFFF5500), Color(0xFFFF1E56), Color(0xFFD90429)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pingzoGradient = LinearGradient(
    colors: [pingzoOrange, Color(0xFFFF6B00)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [pingzoGreen, Color(0xFF00C853)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [pingzoGreen, Color(0xFF00C853)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color cardLightDark = Color(0xFF334155);

  static TextStyle titleStyle({double size = 16, Color color = textPrimaryDark}) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.bold,
      color: color,
    );
  }

  static TextStyle bodyStyle({double size = 14, Color color = textSecondaryDark}) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.normal,
      color: color,
    );
  }
}



