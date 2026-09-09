import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/bento_theme.dart';
import '../../../services/auth_provider.dart';
import '../home/customer_home_screen.dart';

class CustomerAuthScreen extends StatefulWidget {
  final bool popOnSuccess;
  const CustomerAuthScreen({Key? key, this.popOnSuccess = false}) : super(key: key);

  @override
  State<CustomerAuthScreen> createState() => _CustomerAuthScreenState();
}

class _CustomerAuthScreenState extends State<CustomerAuthScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  bool _isOtpStep = false;
  bool _isLoading = false;
  int _resendCountdown = 30;
  Timer? _countdownTimer;

  bool _nameTouched = false;
  bool _phoneTouched = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      setState(() {});
    });
    _phoneController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    _countdownTimer?.cancel();
    super.dispose();
  }

  bool get _isNameValid {
    final name = _nameController.text.trim();
    return name.length >= 2 && RegExp(r"^[a-zA-Z\s\.]+$").hasMatch(name);
  }

  bool get _isPhoneValid {
    final phone = _phoneController.text.trim();
    return RegExp(r"^[6-9]\d{9}$").hasMatch(phone);
  }

  bool get _isFormValid => _isNameValid && _isPhoneValid;

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _resendCountdown = 30);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleSendOtp() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    setState(() {
      _nameTouched = true;
      _phoneTouched = true;
    });

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your full name'),
          backgroundColor: BentoTheme.accentRed,
        ),
      );
      return;
    }

    if (!_isNameValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid name (at least 2 letters, alphabets only)'),
          backgroundColor: BentoTheme.accentRed,
        ),
      );
      return;
    }

    if (!_isPhoneValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number starting with 6, 7, 8, or 9'),
          backgroundColor: BentoTheme.accentRed,
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.sendOtp(phone, name: name);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isOtpStep = true;
    });
    _startCountdown();
    // Auto-focus first OTP box
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _otpFocusNodes[0].requestFocus();
    });
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 4-digit verification code (e.g. 1234)'),
          backgroundColor: BentoTheme.accentRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool success = await auth.loginWithOtp(
      _phoneController.text.trim(),
      otp,
      name: _nameController.text.trim(),
    );
    setState(() => _isLoading = false);

    if (success && mounted) {
      HapticFeedback.mediumImpact();
      if (widget.popOnSuccess) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
        );
      }
    } else if (mounted) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid OTP. Please try 1234 or your verification code.'),
          backgroundColor: BentoTheme.accentRed,
        ),
      );
    }
  }

  void _handleSkip() async {
    HapticFeedback.lightImpact();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.skipAuth();
    if (!mounted) return;
    if (widget.popOnSuccess) {
      Navigator.pop(context, false);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final enteredOtp = _otpControllers.map((c) => c.text).join();
    final isOtpFilled = enteredOtp.length == 4;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // ─── 1. TOP ILLUSTRATION BANNER WITH SKIP & BACK BUTTON ───
              _buildTopBannerSection(),

              // ─── 2. MAIN CONTENT AREA (NAME + PHONE INPUT OR OTP VERIFICATION) ───
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isOtpStep ? _buildOtpVerificationView(isOtpFilled) : _buildInputView(),
                  ),
                ),
              ),

              // ─── 3. FOOTER TERMS & CONDITIONS ───
              _buildFooterTerms(),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Top Banner Graphic Header
  // ─────────────────────────────────────────────────────────────
  Widget _buildTopBannerSection() {
    return Container(
      width: double.infinity,
      height: 290,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFE9E3FE),
            Color(0xFFDDD6FE),
            Color(0xFFF3E8FF),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Background soft cloud / lightning decorative vectors
          Positioned(
            left: 20,
            top: 50,
            child: Icon(Icons.cloud_rounded, size: 70, color: Colors.white.withValues(alpha: 0.6)),
          ),
          Positioned(
            right: 40,
            top: 60,
            child: Icon(Icons.cloud_rounded, size: 90, color: Colors.white.withValues(alpha: 0.5)),
          ),
          Positioned(
            left: 130,
            top: 80,
            child: Icon(Icons.bolt_rounded, size: 28, color: Colors.white.withValues(alpha: 0.8)),
          ),
          Positioned(
            left: 155,
            top: 70,
            child: Icon(Icons.bolt_rounded, size: 34, color: Colors.white.withValues(alpha: 0.9)),
          ),

          // Top Header Action Row (Back Button & Skip Pill)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_isOtpStep)
                    GestureDetector(
                      onTap: () {
                        setState(() => _isOtpStep = false);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: BentoTheme.textPrimaryDark),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 40),

                  // Skip Pill Button
                  GestureDetector(
                    onTap: _handleSkip,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        "Skip",
                        style: TextStyle(
                          color: Color(0xFF8B2FC9),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Illustration Art: Hands delivering PingZo bag with veggies to smiling customer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                height: 190,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Happy Customer with Purple Headphones
                    Positioned(
                      right: 24,
                      bottom: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFDE047),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 15,
                                  left: 20,
                                  right: 20,
                                  child: Container(
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E1B4B),
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 28,
                                  left: 26,
                                  right: 26,
                                  child: Container(
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFD1BA),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.sentiment_satisfied_alt_rounded, size: 26, color: Color(0xFF831843)),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  left: 10,
                                  right: 10,
                                  child: Container(
                                    height: 24,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFF8B2FC9), width: 5),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 30,
                                  left: 8,
                                  child: Container(
                                    width: 16,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8B2FC9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 30,
                                  right: 8,
                                  child: Container(
                                    width: 16,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8B2FC9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Delivery Person Hand (Left side sleeve in violet/blue)
                    Positioned(
                      left: 0,
                      bottom: 35,
                      child: Container(
                        width: 75,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6366F1),
                          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
                        ),
                      ),
                    ),

                    // Grocery Bag Branded "pingzo" with Veggies sticking out
                    Positioned(
                      bottom: 0,
                      left: 55,
                      right: 105,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(color: Color(0xFF86EFAC), shape: BoxShape.circle),
                                child: const Icon(Icons.eco_rounded, color: Color(0xFF15803D), size: 16),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 22,
                                height: 28,
                                decoration: BoxDecoration(color: const Color(0xFF93C5FD), borderRadius: BorderRadius.circular(4)),
                                child: const Center(child: Text("🥛", style: TextStyle(fontSize: 12))),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                                child: const Center(child: Text("🍅", style: TextStyle(fontSize: 14))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Container(
                            height: 90,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "ping",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF581C87),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      Text(
                                        "zo",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: BentoTheme.pingzoOrange,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      "10 MIN DELIVERY",
                                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF3B0764)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 1. Name & Phone Input View with Live Validation
  // ─────────────────────────────────────────────────────────────
  Widget _buildInputView() {
    final showNameError = _nameTouched && !_isNameValid && _nameController.text.isNotEmpty;
    final showPhoneError = _phoneTouched && !_isPhoneValid && _phoneController.text.isNotEmpty;

    return Column(
      key: const ValueKey('phone_view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title: "Groceries delivered in minutes"
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: BentoTheme.textPrimaryDark, height: 1.3),
            children: [
              TextSpan(text: "Groceries delivered in "),
              TextSpan(
                text: "minutes",
                style: TextStyle(color: Color(0xFF8B2FC9)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ─── 1. FULL NAME FIELD ───
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: showNameError
                  ? BentoTheme.accentRed
                  : (_isNameValid ? BentoTheme.pingzoGreen : const Color(0xFFCBD5E1)),
              width: _isNameValid || showNameError ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.person_outline_rounded, color: Color(0xFF8B2FC9), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  keyboardType: TextInputType.name,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(40),
                  ],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: BentoTheme.textPrimaryDark,
                  ),
                  decoration: const InputDecoration(
                    hintText: "Enter Full Name",
                    hintStyle: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (_) {
                    if (!_nameTouched) setState(() => _nameTouched = true);
                  },
                ),
              ),
              if (_isNameValid)
                const Icon(Icons.check_circle_rounded, color: BentoTheme.pingzoGreen, size: 20)
              else if (showNameError)
                const Icon(Icons.error_outline_rounded, color: BentoTheme.accentRed, size: 20),
            ],
          ),
        ),
        if (showNameError)
          const Padding(
            padding: EdgeInsets.only(top: 4, left: 8),
            child: Text(
              "Please enter at least 2 letters (alphabets only)",
              style: TextStyle(fontSize: 11, color: BentoTheme.accentRed, fontWeight: FontWeight.w600),
            ),
          ),

        const SizedBox(height: 12),

        // ─── 2. PHONE NUMBER FIELD ───
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: showPhoneError
                  ? BentoTheme.accentRed
                  : (_isPhoneValid ? BentoTheme.pingzoGreen : const Color(0xFFCBD5E1)),
              width: _isPhoneValid || showPhoneError ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Indian Flag + +91 + Arrow
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 15,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      children: [
                        Expanded(child: Container(color: const Color(0xFFFF9933))),
                        Expanded(child: Container(color: Colors.white)),
                        Expanded(child: Container(color: const Color(0xFF138808))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "+91",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: BentoTheme.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: BentoTheme.textSecondaryDark),
                ],
              ),

              const SizedBox(width: 10),
              Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
              const SizedBox(width: 12),

              // Phone Number Input
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: BentoTheme.textPrimaryDark,
                    letterSpacing: 1.0,
                  ),
                  decoration: const InputDecoration(
                    hintText: "Enter Mobile Number",
                    hintStyle: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (_) {
                    if (!_phoneTouched) setState(() => _phoneTouched = true);
                  },
                  onSubmitted: (_) {
                    if (_isFormValid) _handleSendOtp();
                  },
                ),
              ),

              if (_isPhoneValid)
                const Icon(Icons.check_circle_rounded, color: BentoTheme.pingzoGreen, size: 20)
              else if (showPhoneError)
                const Icon(Icons.error_outline_rounded, color: BentoTheme.accentRed, size: 20),
            ],
          ),
        ),
        if (showPhoneError)
          const Padding(
            padding: EdgeInsets.only(top: 4, left: 8),
            child: Text(
              "Enter a valid 10-digit mobile number starting with 6, 7, 8, or 9",
              style: TextStyle(fontSize: 11, color: BentoTheme.accentRed, fontWeight: FontWeight.w600),
            ),
          ),

        const SizedBox(height: 20),

        // ─── CONTINUE BUTTON ───
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFormValid ? const Color(0xFF8B2FC9) : const Color(0xFFF1F5F9),
              foregroundColor: _isFormValid ? Colors.white : const Color(0xFF94A3B8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _isFormValid && !_isLoading ? _handleSendOtp : null,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(
                    "Continue",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _isFormValid ? Colors.white : const Color(0xFF94A3B8),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 2. OTP Verification View
  // ─────────────────────────────────────────────────────────────
  Widget _buildOtpVerificationView(bool isOtpFilled) {
    return Column(
      key: const ValueKey('otp_view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // Heading: "OTP Verification"
        const Text(
          "OTP Verification",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: BentoTheme.textPrimaryDark),
        ),
        const SizedBox(height: 6),

        // Subtitle: "OTP has been sent to +91 9791212813 ✎"
        Row(
          children: [
            Expanded(
              child: Text(
                "OTP sent to +91 ${_phoneController.text} (${_nameController.text.trim()})",
                style: const TextStyle(fontSize: 13, color: BentoTheme.textSecondaryDark, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                setState(() => _isOtpStep = false);
              },
              child: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF8B2FC9)),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Discrete OTP Input Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (index) {
            final isCurrent = _otpFocusNodes[index].hasFocus;
            final isFilled = _otpControllers[index].text.isNotEmpty;

            return Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCurrent
                      ? const Color(0xFF8B2FC9)
                      : (isFilled ? BentoTheme.textPrimaryDark : const Color(0xFFE2E8F0)),
                  width: isCurrent ? 1.8 : 1.2,
                ),
              ),
              child: Center(
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: BentoTheme.textPrimaryDark,
                  ),
                  decoration: const InputDecoration(
                    counterText: "",
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                    if (val.isNotEmpty) {
                      if (index < 3) {
                        _otpFocusNodes[index + 1].requestFocus();
                      } else {
                        _otpFocusNodes[index].unfocus();
                        _handleVerifyOtp();
                      }
                    } else if (val.isEmpty && index > 0) {
                      _otpFocusNodes[index - 1].requestFocus();
                    }
                    setState(() {});
                  },
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 20),

        // Resend OTP Countdown Timer
        if (_resendCountdown > 0)
          Text(
            "Resend OTP in ${_resendCountdown}s",
            style: const TextStyle(fontSize: 13, color: BentoTheme.textSecondaryDark, fontWeight: FontWeight.w600),
          )
        else
          GestureDetector(
            onTap: () {
              _startCountdown();
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("OTP re-sent! Use 1234")),
              );
            },
            child: const Text(
              "Resend OTP",
              style: TextStyle(fontSize: 13, color: Color(0xFF8B2FC9), fontWeight: FontWeight.bold),
            ),
          ),

        const SizedBox(height: 28),

        // Verify & Continue Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isOtpFilled ? const Color(0xFF8B2FC9) : const Color(0xFFF1F5F9),
              foregroundColor: isOtpFilled ? Colors.white : const Color(0xFF94A3B8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: isOtpFilled && !_isLoading ? _handleVerifyOtp : null,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(
                    "Verify & Continue",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isOtpFilled ? Colors.white : const Color(0xFF94A3B8),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Footer Terms of Use & Privacy Policy
  // ─────────────────────────────────────────────────────────────
  Widget _buildFooterTerms() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 4),
      child: Column(
        children: [
          const Text(
            "By continuing, you agree to our",
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {},
                child: const Text(
                  "Terms of Use",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B2FC9)),
                ),
              ),
              const Text(" & ", style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  "Privacy Policy",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B2FC9)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
