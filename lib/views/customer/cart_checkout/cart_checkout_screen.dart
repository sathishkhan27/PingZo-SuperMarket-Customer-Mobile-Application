import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/bento_theme.dart';
import '../../../models/order_model.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_provider.dart';
import '../../../services/cart_provider.dart';
import '../../../services/order_provider.dart';
import '../../../services/location_provider.dart';
import '../../../services/notification_provider.dart';
import '../../location/location_map_picker_screen.dart';
import '../auth/customer_auth_screen.dart';
import '../order_tracking/live_order_tracking_screen.dart';

class CartCheckoutScreen extends StatefulWidget {
  const CartCheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CartCheckoutScreen> createState() => _CartCheckoutScreenState();
}

class _CartCheckoutScreenState extends State<CartCheckoutScreen> {
  String _selectedPaymentMethod = 'UPI';
  bool _isProcessingPayment = false;

  void _showCouponPicker(BuildContext context, CartProvider cart) {
    final coupons = ApiService.getMockCoupons();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Available Supermarket Coupons",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: BentoTheme.textPrimaryDark),
              ),
              const SizedBox(height: 16),
              ...coupons.map((c) {
                bool isEligible = cart.subtotal >= c.minOrderAmount;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: BentoTheme.bgLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BentoTheme.borderLight),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(c.code, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: BentoTheme.pingzoGreen)),
                              const SizedBox(width: 8),
                              Text("Min Order ₹${c.minOrderAmount.toInt()}", style: const TextStyle(fontSize: 11, color: BentoTheme.textSecondaryDark)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(c.description, style: const TextStyle(fontSize: 12, color: BentoTheme.textSecondaryDark)),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEligible ? BentoTheme.pingzoGreen : BentoTheme.borderLight,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isEligible
                            ? () {
                                cart.applyCoupon(c);
                                Navigator.pop(context);
                              }
                            : null,
                        child: Text(
                          isEligible ? "APPLY" : "LOCKED",
                          style: TextStyle(color: isEligible ? Colors.white : BentoTheme.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _showAuthRequiredDialog(BuildContext context, CartProvider cart, OrderProvider orderProv) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: BentoTheme.pingzoOrange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded, color: BentoTheme.pingzoOrange, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Login Required",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: BentoTheme.textPrimaryDark),
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "You must be logged in with a verified phone number to place and track your grocery order.",
                style: TextStyle(fontSize: 14, color: BentoTheme.textSecondaryDark, height: 1.4),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: BentoTheme.pingzoGreen),
                  SizedBox(width: 6),
                  Text("Your cart items are saved safely", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: BentoTheme.textPrimaryDark)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("CANCEL", style: TextStyle(color: BentoTheme.textSecondaryDark, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: BentoTheme.pingzoGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final loggedIn = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomerAuthScreen(popOnSuccess: true)),
                );
                if (loggedIn == true && mounted) {
                  _handlePlaceOrder(cart, orderProv);
                }
              },
              child: const Text("LOGIN / SIGN UP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handlePlaceOrder(CartProvider cart, OrderProvider orderProv) async {
    if (cart.items.isEmpty) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated || auth.currentUser == null) {
      _showAuthRequiredDialog(context, cart, orderProv);
      return;
    }

    setState(() => _isProcessingPayment = true);

    // Simulate Payment Gateway Callback & Backend Verification
    final orderItems = cart.items.map((i) {
      return OrderItemModel(
        productId: i.product.id,
        productName: i.product.name,
        quantity: i.quantity,
        unitPrice: i.product.discountPrice,
        totalPrice: i.product.discountPrice * i.quantity,
        sgstAmount: i.product.discountPrice * i.quantity * (i.product.sgstPercentage / 100.0),
        cgstAmount: i.product.discountPrice * i.quantity * (i.product.cgstPercentage / 100.0),
        isVegetableOrFruit: i.product.isVegetableOrFruit,
      );
    }).toList();

    final locationProv = Provider.of<LocationProvider>(context, listen: false);
    String address = cart.selectedLocation;
    if (address.isEmpty || address == "Select Location") {
      address = locationProv.activeAddressTitle;
    }

    try {
      final newOrder = await ApiService.createOrder(
        items: orderItems,
        subtotal: cart.subtotal,
        deliveryFee: cart.deliveryFee,
        couponDiscount: cart.couponDiscountAmount,
        grossTotal: cart.grossTotal,
        deliveryAddress: address,
        paymentMethod: _selectedPaymentMethod,
        customerId: auth.currentUser!.id,
        customerName: auth.currentUser!.name,
      );

      orderProv.addOrder(newOrder);
      cart.clearCart();

      if (mounted) {
        Provider.of<NotificationProvider>(context, listen: false).notifyOrderPlaced(newOrder);
        setState(() => _isProcessingPayment = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => LiveOrderTrackingScreen(
              orderId: newOrder.id,
              initialOrder: newOrder,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        final fallbackOrder = OrderModel(
          id: "PZ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
          customerId: auth.currentUser?.id ?? "",
          customerName: auth.currentUser?.name ?? "",
          deliveryAddress: address,
          driverLatitude: 12.9716,
          driverLongitude: 77.5946,
          items: orderItems,
          subtotal: cart.subtotal,
          sgstTotal: cart.subtotal * 0.025,
          cgstTotal: cart.subtotal * 0.025,
          deliveryFee: cart.deliveryFee,
          couponDiscount: cart.couponDiscountAmount,
          grossTotal: cart.grossTotal,
          orderStatus: "PLACED",
          paymentStatus: "SUCCESS",
          paymentMethod: _selectedPaymentMethod,
          estimatedDeliveryEta: "15-20 mins",
        );
        orderProv.addOrder(fallbackOrder);
        cart.clearCart();
        Provider.of<NotificationProvider>(context, listen: false).notifyOrderPlaced(fallbackOrder);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => LiveOrderTrackingScreen(
              orderId: fallbackOrder.id,
              initialOrder: fallbackOrder,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final orderProv = Provider.of<OrderProvider>(context);

    return Scaffold(
      backgroundColor: BentoTheme.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Checkout & Order Summary",
          style: TextStyle(color: BentoTheme.textPrimaryDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BentoTheme.textPrimaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 72, color: BentoTheme.textSecondaryDark),
                  const SizedBox(height: 16),
                  const Text("Your Cart is Empty", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: BentoTheme.textPrimaryDark)),
                  const SizedBox(height: 8),
                  const Text("Explore fresh vegetables & groceries to place an order.", style: TextStyle(color: BentoTheme.textSecondaryDark)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BentoTheme.pingzoOrange,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Start Shopping", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Customer Authentication Status Banner ───
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      final isAuth = auth.isAuthenticated && auth.currentUser != null;
                      if (isAuth) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: BentoTheme.pingzoGreenLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: BentoTheme.pingzoGreen.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_user_rounded, color: BentoTheme.pingzoGreen, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Ordering as ${auth.currentUser?.name ?? 'Customer'} (${auth.currentUser?.phone ?? ''})",
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BentoTheme.pingzoGreenDark),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline_rounded, color: BentoTheme.accentRed, size: 20),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Login Required to Order", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: BentoTheme.accentRed)),
                                  SizedBox(height: 2),
                                  Text("Please login with mobile OTP to complete checkout.", style: TextStyle(fontSize: 11, color: BentoTheme.textSecondaryDark)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: BentoTheme.accentRed,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CustomerAuthScreen(popOnSuccess: true)),
                                );
                              },
                              child: const Text("LOGIN", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Delivery Address Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: BentoTheme.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.location_on, color: BentoTheme.pingzoOrange, size: 20),
                                SizedBox(width: 6),
                                Text("Delivery Address", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: BentoTheme.textPrimaryDark)),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationMapPickerScreen()));
                              },
                              child: const Text("CHANGE", style: TextStyle(color: BentoTheme.pingzoOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(cart.selectedLocation, style: const TextStyle(fontSize: 13, color: BentoTheme.textSecondaryDark, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cart Products List Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: BentoTheme.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Items in Order", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: BentoTheme.textPrimaryDark)),
                        const SizedBox(height: 12),
                        ...cart.items.map((item) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(item.product.imageUrl, width: 48, height: 48, fit: BoxFit.cover),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: BentoTheme.textPrimaryDark)),
                                      Text(item.product.unit, style: const TextStyle(fontSize: 11, color: BentoTheme.textSecondaryDark)),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: BentoTheme.pingzoOrange, size: 22),
                                      onPressed: () => cart.removeFromCart(item.product.id),
                                    ),
                                    Text("${item.quantity}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: BentoTheme.textPrimaryDark)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: BentoTheme.pingzoGreen, size: 22),
                                      onPressed: () => cart.addToCart(item.product),
                                    ),
                                  ],
                                ),
                                Text("₹${(item.product.discountPrice * item.quantity).toInt()}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: BentoTheme.textPrimaryDark)),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Coupon Box Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: BentoTheme.borderLight),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_offer_rounded, color: BentoTheme.pingzoOrange),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cart.appliedCoupon != null ? "Coupon Applied: ${cart.appliedCoupon!.code}" : "Have a promo coupon?",
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: BentoTheme.textPrimaryDark),
                                ),
                                if (cart.appliedCoupon != null)
                                  Text("Saved ₹${cart.couponDiscountAmount.toStringAsFixed(0)}", style: const TextStyle(fontSize: 12, color: BentoTheme.pingzoGreen, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        cart.appliedCoupon != null
                            ? TextButton(
                                onPressed: () => cart.removeCoupon(),
                                child: const Text("REMOVE", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                              )
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: BentoTheme.pingzoOrange,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => _showCouponPicker(context, cart),
                                child: const Text("APPLY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bill Breakdown Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: BentoTheme.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Bill Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: BentoTheme.textPrimaryDark)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Item Subtotal", style: TextStyle(color: BentoTheme.textSecondaryDark)),
                            Text("₹${cart.subtotal.toStringAsFixed(2)}", style: const TextStyle(color: BentoTheme.textPrimaryDark, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (cart.couponDiscountAmount > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Coupon Discount", style: TextStyle(color: BentoTheme.pingzoGreen, fontWeight: FontWeight.bold)),
                              Text("-₹${cart.couponDiscountAmount.toStringAsFixed(2)}", style: const TextStyle(color: BentoTheme.pingzoGreen, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Delivery Charge", style: TextStyle(color: BentoTheme.textSecondaryDark)),
                            Text(cart.deliveryFee == 0 ? "FREE" : "₹${cart.deliveryFee.toStringAsFixed(2)}", style: TextStyle(color: cart.deliveryFee == 0 ? BentoTheme.pingzoGreen : BentoTheme.textPrimaryDark, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Taxes (SGST 2.5% + CGST 2.5%)", style: TextStyle(color: BentoTheme.textSecondaryDark, fontSize: 12)),
                            Text("₹${(cart.totalSgst + cart.totalCgst).toStringAsFixed(2)}", style: const TextStyle(color: BentoTheme.textPrimaryDark, fontSize: 12)),
                          ],
                        ),
                        const Divider(color: BentoTheme.borderLight, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("To Pay", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: BentoTheme.textPrimaryDark)),
                            Text("₹${cart.grossTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: BentoTheme.pingzoOrange)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Payment Method Selector Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: BentoTheme.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Select Payment Method", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: BentoTheme.textPrimaryDark)),
                        const SizedBox(height: 10),
                        _buildPaymentOption('UPI', 'UPI (Google Pay / PhonePe / Paytm)', Icons.account_balance_wallet),
                        _buildPaymentOption('CARD', 'Credit / Debit Card', Icons.credit_card),
                        _buildPaymentOption('COD', 'Cash on Delivery', Icons.payments),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      final isAuth = auth.isAuthenticated && auth.currentUser != null;
                      return SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAuth ? BentoTheme.pingzoOrange : const Color(0xFF1E293B),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _isProcessingPayment ? null : () => _handlePlaceOrder(cart, orderProv),
                          icon: _isProcessingPayment
                              ? const SizedBox.shrink()
                              : Icon(isAuth ? Icons.check_circle_outline_rounded : Icons.lock_rounded, color: Colors.white, size: 20),
                          label: _isProcessingPayment
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  isAuth
                                      ? "Pay ₹${cart.grossTotal.toStringAsFixed(0)} & Place Order"
                                      : "Login & Pay ₹${cart.grossTotal.toStringAsFixed(0)}",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentOption(String value, String title, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? BentoTheme.pingzoGreenLight : BentoTheme.bgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? BentoTheme.pingzoGreen : BentoTheme.borderLight,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? BentoTheme.pingzoGreen : BentoTheme.textSecondaryDark, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: BentoTheme.textPrimaryDark,
                ),
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: BentoTheme.pingzoGreen, size: 20),
          ],
        ),
      ),
    );
  }
}
