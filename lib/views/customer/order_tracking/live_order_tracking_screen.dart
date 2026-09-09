import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/bento_theme.dart';
import '../../../models/order_model.dart';
import '../../../services/order_provider.dart';
import '../chat/driver_chat_screen.dart';
import '../orders/invoice_screen.dart';

class LiveOrderTrackingScreen extends StatefulWidget {
  final String? orderId;
  final OrderModel? initialOrder;

  const LiveOrderTrackingScreen({
    Key? key,
    this.orderId,
    this.initialOrder,
  }) : super(key: key);

  @override
  State<LiveOrderTrackingScreen> createState() => _LiveOrderTrackingScreenState();
}

class _LiveOrderTrackingScreenState extends State<LiveOrderTrackingScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _bikeMovementController;
  late AnimationController _radarWaveController;
  bool _isDetailsExpanded = true;
  bool _isSatelliteView = false;
  double _zoomScale = 1.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Continuous smooth bike cruising animation along the road curve
    _bikeMovementController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    // Continuous radar wave and dashed route flow animation
    _radarWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProv = Provider.of<OrderProvider>(context, listen: false);
      if (widget.initialOrder != null) {
        orderProv.setActiveOrder(widget.initialOrder!);
      }
      final targetId = widget.orderId ?? widget.initialOrder?.id ?? orderProv.activeOrder?.id;
      if (targetId != null && targetId.isNotEmpty) {
        orderProv.startLiveTracking(targetId);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bikeMovementController.dispose();
    _radarWaveController.dispose();
    // Stop tracking when leaving the screen
    final orderProv = Provider.of<OrderProvider>(context, listen: false);
    orderProv.stopLiveTracking();
    super.dispose();
  }

  bool _isDriverAssigned(OrderModel order) {
    final status = order.orderStatus.toUpperCase();
    return (order.assignedDriverName != null &&
            order.assignedDriverName!.trim().isNotEmpty &&
            order.assignedDriverName!.trim().toLowerCase() != 'null' &&
            order.assignedDriverName!.trim().toLowerCase() != 'undefined') ||
        (order.assignedDriverId != null &&
            order.assignedDriverId!.trim().isNotEmpty &&
            order.assignedDriverId!.trim().toLowerCase() != 'null') ||
        status == 'ASSIGNED' ||
        status == 'DRIVER_ASSIGNED' ||
        status == 'PARTNER_ASSIGNED' ||
        status == 'PICKED_UP' ||
        status == 'OUT_FOR_DELIVERY' ||
        status == 'ON_THE_WAY' ||
        status == 'DELIVERED';
  }

  int _getStatusStepIndex(OrderModel order) {
    final status = order.orderStatus.toUpperCase();
    final hasDriver = _isDriverAssigned(order);

    switch (status) {
      case 'DELIVERED':
      case 'COMPLETED':
        return 4;
      case 'OUT_FOR_DELIVERY':
      case 'ON_THE_WAY':
      case 'ARRIVED':
        return 3;
      case 'ASSIGNED':
      case 'DRIVER_ASSIGNED':
      case 'PARTNER_ASSIGNED':
      case 'PICKED_UP':
      case 'READY_FOR_PICKUP':
        return 2;
      case 'PACKED':
      case 'PACKING':
      case 'PREPARING':
      case 'PROCESSING':
        return hasDriver ? 2 : 1;
      case 'PLACED':
      case 'CONFIRMED':
      case 'ACCEPTED':
      case 'PENDING':
        return hasDriver ? 2 : 0;
      default:
        return hasDriver ? 2 : 0;
    }
  }

  void _showCancelOrderModal(BuildContext context, OrderModel order, OrderProvider orderProv) {
    String selectedReason = "Changed my mind";
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Cancel Order & Refund", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: BentoTheme.textPrimaryDark)),
                  const SizedBox(height: 8),
                  Text(
                    "Order #${order.id} is eligible for 100% full refund of ₹${order.grossTotal.toStringAsFixed(0)}",
                    style: const TextStyle(fontSize: 13, color: BentoTheme.pingzoGreen, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  const Text("Select Reason for Cancellation:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BentoTheme.textSecondaryDark)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: BentoTheme.bgLight,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: ["Changed my mind", "Delivery time too long", "Incorrect delivery address", "Ordered wrong item"]
                        .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(color: BentoTheme.textPrimaryDark, fontSize: 13))))
                        .toList(),
                    onChanged: (val) => setModalState(() => selectedReason = val!),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BentoTheme.accentRed,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      orderProv.cancelOrder(order.id, selectedReason);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Order #${order.id} Cancelled. Refund of ₹${order.grossTotal.toStringAsFixed(0)} initiated!"),
                          backgroundColor: BentoTheme.accentRed,
                        ),
                      );
                    },
                    child: const Text("Confirm Cancellation & Refund", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = Provider.of<OrderProvider>(context);

    // Resolve order to track: priority to matching ID in orderProv -> activeOrder -> widget.initialOrder
    OrderModel? order;
    if (widget.orderId != null && widget.orderId!.isNotEmpty) {
      final matches = orderProv.orders.where((o) => o.id == widget.orderId).toList();
      if (matches.isNotEmpty) {
        order = matches.first;
      } else if (orderProv.activeOrder?.id == widget.orderId) {
        order = orderProv.activeOrder;
      } else {
        order = widget.initialOrder;
      }
    } else {
      order = widget.initialOrder ?? orderProv.activeOrder;
    }

    if (order == null) {
      final isFetching = orderProv.isFetchingOrder;
      return Scaffold(
        backgroundColor: BentoTheme.bgLight,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: Text(
            widget.orderId != null ? "Tracking Order #${widget.orderId}" : "Live Order Tracking",
            style: const TextStyle(color: BentoTheme.textPrimaryDark, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: BentoTheme.textPrimaryDark),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isFetching) ...[
                  const CircularProgressIndicator(color: BentoTheme.pingzoOrange),
                  const SizedBox(height: 20),
                  const Text(
                    "Connecting to Live Order Stream...",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: BentoTheme.textPrimaryDark),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Fetching real-time updates from PingZo server",
                    style: TextStyle(fontSize: 13, color: BentoTheme.textSecondaryDark),
                  ),
                ] else ...[
                  const Icon(Icons.receipt_long_outlined, size: 64, color: BentoTheme.textSecondaryDark),
                  const SizedBox(height: 16),
                  Text(
                    widget.orderId != null ? "Order #${widget.orderId} Not Found" : "No Active Order Found",
                    style: const TextStyle(color: BentoTheme.textPrimaryDark, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "The order details could not be retrieved from the server. Please check your network or try refreshing.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: BentoTheme.textSecondaryDark, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Go Back"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: BentoTheme.pingzoOrange),
                        onPressed: () {
                          if (widget.orderId != null) {
                            orderProv.fetchOrderById(widget.orderId!);
                          }
                        },
                        child: const Text("Retry", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final isDriverAssigned = _isDriverAssigned(order);
    final currentStep = _getStatusStepIndex(order);

    final displayStatusText = (isDriverAssigned && (order.orderStatus == 'PLACED' || order.orderStatus == 'CONFIRMED' || order.orderStatus == 'PACKING' || order.orderStatus == 'PROCESSING' || order.orderStatus == 'PACKED'))
        ? 'DRIVER ASSIGNED'
        : order.orderStatus.replaceAll('_', ' ');

    return Scaffold(
      backgroundColor: BentoTheme.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("Order #${order.id}", style: const TextStyle(color: BentoTheme.textPrimaryDark, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                // Live Pulse Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: BentoTheme.pingzoGreenLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: BentoTheme.pingzoGreen.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: BentoTheme.pingzoGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "LIVE",
                        style: TextStyle(color: BentoTheme.pingzoGreenDark, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              "PingZo Express • Supermarket DarkStore",
              style: TextStyle(color: BentoTheme.textSecondaryDark.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BentoTheme.textPrimaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: orderProv.isFetchingOrder
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: BentoTheme.pingzoOrange),
                  )
                : const Icon(Icons.refresh_rounded, color: BentoTheme.textPrimaryDark),
            tooltip: "Refresh Order Status",
            onPressed: () {
              orderProv.fetchOrderById(order!.id);
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Checking live order updates..."),
                  duration: Duration(milliseconds: 900),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: BentoTheme.pingzoOrange,
        onRefresh: () async {
          await orderProv.fetchOrderById(order!.id);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ─── LIVE VECTOR MAP REPRESENTATION ───
              _buildLiveMapSection(order, isDriverAssigned, currentStep),

              // ─── ORDER DETAILS & STATUS CARDS SHEET ───
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ETA + Current Status Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "ESTIMATED DELIVERY",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: BentoTheme.textSecondaryDark, letterSpacing: 1.0),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order.estimatedDeliveryEta,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: BentoTheme.pingzoGreen),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusBgColor(order.orderStatus),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _getStatusTextColor(order.orderStatus).withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                displayStatusText,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _getStatusTextColor(order.orderStatus)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // OTP Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: BentoTheme.bgLight,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: BentoTheme.borderLight),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.pin_rounded, size: 12, color: BentoTheme.textSecondaryDark),
                                  const SizedBox(width: 2),
                                  Text(
                                    "OTP: ${order.deliveryOtp}",
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: BentoTheme.textPrimaryDark),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // ─── Real-Time Step Progress Tracker ───
                    _buildProgressStepper(currentStep, order.orderStatus),

                    const SizedBox(height: 16),

                    // ─── Exact Locations Route Card (Shop Location -> Delivery Address) ───
                    _buildLocationRouteCard(order),

                    const SizedBox(height: 16),

                    // ─── Delivery Partner Details Card (Dynamic from API) ───
                    if (isDriverAssigned)
                      _buildDriverAssignedCard(order)
                    else
                      _buildAwaitingDriverCard(order),

                    const SizedBox(height: 12),

                    // ─── Supermarket Fulfillment Card ───
                    // _buildSupermarketCard(order),

                    const SizedBox(height: 16),

                    // ─── Expandable Order Items & Billing Summary ───
                    _buildOrderItemsAndBillAccordion(order, orderProv),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 1. Live Vector & Satellite Real-Time Map Representation Widget
  // ─────────────────────────────────────────────────────────────
  Widget _buildLiveMapSection(OrderModel order, bool isDriverAssigned, int currentStep) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mapWidth = constraints.maxWidth;
        const mapHeight = 320.0;

        // Exact Cartographic Waypoints (Aligned with Map Streets)
        final p0 = Offset(56, mapHeight * 0.70);
        final p1 = Offset(mapWidth * 0.50, mapHeight * 0.16);
        final p2 = Offset(mapWidth - 56, mapHeight * 0.52);

        return AnimatedBuilder(
          animation: Listenable.merge([_pulseController, _bikeMovementController, _radarWaveController]),
          builder: (context, child) {
            // Calculate base progress along route based on live order status
            double baseProgress = 0.08;
            final status = order.orderStatus.toUpperCase();
            if (status == 'DELIVERED' || status == 'COMPLETED') {
              baseProgress = 1.0;
            } else if (status == 'OUT_FOR_DELIVERY' || status == 'ON_THE_WAY' || status == 'ARRIVED') {
              baseProgress = 0.72;
            } else if (isDriverAssigned || status == 'ASSIGNED' || status == 'DRIVER_ASSIGNED' || status == 'PARTNER_ASSIGNED' || status == 'PICKED_UP' || status == 'READY_FOR_PICKUP') {
              baseProgress = 0.42;
            } else if (status == 'PACKED' || status == 'PACKING' || status == 'PREPARING' || status == 'PROCESSING') {
              baseProgress = 0.20;
            }

            // Real-time smooth cruising movement along the Bézier curve
            final isCruising = (isDriverAssigned || status == 'OUT_FOR_DELIVERY' || status == 'ON_THE_WAY') && status != 'DELIVERED';
            final cruisingOffset = isCruising ? (_bikeMovementController.value * 0.08 - 0.04) : 0.0;
            final liveProgress = (status == 'DELIVERED') ? 1.0 : (baseProgress + cruisingOffset).clamp(0.04, 0.98);

            // Quadratic Bezier interpolation: B(t) = (1-t)^2*p0 + 2(1-t)t*p1 + t^2*p2
            final t = liveProgress;
            final posX = (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * p1.dx + t * t * p2.dx;
            final posY = (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * p1.dy + t * t * p2.dy;

            // Tangent derivative for heading angle: B'(t) = 2(1-t)(p1-p0) + 2t(p2-p1)
            final dx = 2 * (1 - t) * (p1.dx - p0.dx) + 2 * t * (p2.dx - p1.dx);
            final dy = 2 * (1 - t) * (p1.dy - p0.dy) + 2 * t * (p2.dy - p1.dy);
            final headingAngle = math.atan2(dy, dx);

            final driverName = (order.assignedDriverName != null && order.assignedDriverName!.trim().isNotEmpty)
                ? order.assignedDriverName!
                : 'PingZo Fleet Rider';

            return Container(
              height: mapHeight,
              width: mapWidth,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: _isSatelliteView ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              ),
              child: Stack(
                children: [
                  // 1. Realistic Vector City & Street Map Canvas
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RealisticCityMapPainter(
                        isSatellite: _isSatelliteView,
                      ),
                    ),
                  ),

                  // 2. High-Fidelity Animated Delivery Route Line Track
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RealisticRoutePainter(
                        progress: liveProgress,
                        animPhase: _radarWaveController.value,
                        p0: p0,
                        p1: p1,
                        p2: p2,
                        isSatellite: _isSatelliteView,
                      ),
                    ),
                  ),

                  // 3. Store Origin Milestone: Shop Location (Anchored at p0)
                  Positioned(
                    left: (p0.dx - 70).clamp(4.0, mapWidth - 145.0),
                    top: (p0.dy - 78).clamp(4.0, mapHeight - 85.0),
                    width: 140,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: BentoTheme.pingzoGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: BentoTheme.pingzoGreen.withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.storefront_rounded, size: 22, color: Colors.white),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: BentoTheme.pingzoGreen.withValues(alpha: 0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "🏪 SHOP LOCATION",
                                style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900, color: BentoTheme.pingzoGreenDark),
                              ),
                              Text(
                                order.supermarketName,
                                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: BentoTheme.textPrimaryDark),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              if (order.supermarketAddress.isNotEmpty && order.supermarketAddress != 'PingZo Express Hub')
                                Text(
                                  order.supermarketAddress,
                                  style: const TextStyle(fontSize: 8, color: BentoTheme.textSecondaryDark),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4. Customer Destination Milestone: Order Delivery Address (Anchored at p2)
                  Positioned(
                    left: (p2.dx - 75).clamp(4.0, mapWidth - 155.0),
                    top: (p2.dy - 78).clamp(4.0, mapHeight - 85.0),
                    width: 150,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: BentoTheme.pingzoOrange,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: BentoTheme.pingzoOrange.withValues(alpha: 0.5),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.location_on_rounded, size: 24, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: BentoTheme.pingzoOrange.withValues(alpha: 0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "📍 CUSTOMER PLACE",
                                    style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900, color: BentoTheme.pingzoOrange),
                                  ),
                                  const SizedBox(width: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                                    decoration: BoxDecoration(
                                      color: BentoTheme.pingzoGreenLight,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      order.estimatedDeliveryEta,
                                      style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: BentoTheme.pingzoGreenDark),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                order.deliveryAddress,
                                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: BentoTheme.textPrimaryDark),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 5. Live Animated Moving Vehicle Marker (Precisely Centered on Path posX, posY)
                  Positioned(
                    left: posX - 90,
                    top: posY - 68,
                    width: 180,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Floating Real-Time Status Badge with ETA & Live Pulse
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDriverAssigned ? BentoTheme.pingzoOrange : BentoTheme.pingzoGreen,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDriverAssigned ? BentoTheme.pingzoOrange : BentoTheme.pingzoGreen,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isDriverAssigned
                                    ? "$driverName • ${order.estimatedDeliveryEta}"
                                    : "Hub Packing • 10-15m",
                                style: const TextStyle(
                                  color: BentoTheme.textPrimaryDark,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Animated Bike Marker with Heading Rotation & Double Radar Ripple
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // 1st Outer Radar Wave
                            Container(
                              width: 58 + (_radarWaveController.value * 20),
                              height: 58 + (_radarWaveController.value * 20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: (isDriverAssigned ? BentoTheme.pingzoOrange : BentoTheme.pingzoGreen)
                                      .withValues(alpha: (1.0 - _radarWaveController.value).clamp(0.0, 0.6)),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            // 2nd Inner Pulsing Ring
                            ScaleTransition(
                              scale: _pulseAnimation,
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (isDriverAssigned ? BentoTheme.pingzoOrange : BentoTheme.pingzoGreen)
                                      .withValues(alpha: 0.22),
                                ),
                              ),
                            ),
                            // Rotating Animated Bike Scooter
                            Transform.rotate(
                              angle: headingAngle - 0.2, // Align bike along tangent road vector
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isDriverAssigned ? BentoTheme.pingzoOrange : BentoTheme.pingzoGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isDriverAssigned ? BentoTheme.pingzoOrange : BentoTheme.pingzoGreen)
                                          .withValues(alpha: 0.6),
                                      blurRadius: 12,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(Icons.two_wheeler_rounded, size: 24, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 6. Top Right: Map Controls (Satellite Toggle)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Satellite Layer Toggle Button
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isSatelliteView = !_isSatelliteView;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: BentoTheme.borderLight),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isSatelliteView ? Icons.layers_rounded : Icons.satellite_alt_rounded,
                                  size: 13,
                                  color: BentoTheme.pingzoOrange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isSatelliteView ? "Street" : "Satellite",
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BentoTheme.textPrimaryDark),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 7. Bottom Live GPS HUD Banner
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: (_isSatelliteView ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isSatelliteView ? const Color(0xFF334155) : BentoTheme.borderLight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: BentoTheme.pingzoGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isDriverAssigned
                                ? "🛵 Delivery partner on the road • Live GPS Active"
                                : "📦 Order packing at store • Rider preparing for pickup",
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: _isSatelliteView ? Colors.white : BentoTheme.textPrimaryDark,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            order.estimatedDeliveryEta,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: BentoTheme.pingzoOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 2. Real-Time Status Progress Stepper
  // ─────────────────────────────────────────────────────────────
  Widget _buildProgressStepper(int currentStep, String orderStatus) {
    final steps = [
      {"label": "Placed", "icon": Icons.check_circle_outline_rounded},
      {"label": "Packing", "icon": Icons.inventory_2_outlined},
      {"label": "Assigned", "icon": Icons.two_wheeler_rounded},
      {"label": "On Way", "icon": Icons.local_shipping_outlined},
      {"label": "Delivered", "icon": Icons.done_all_rounded},
    ];

    if (orderStatus == 'CANCELLED') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: BentoTheme.accentRed, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Order Cancelled", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: BentoTheme.accentRed)),
                  Text("Full refund has been initiated to your original payment method.", style: TextStyle(fontSize: 11, color: Color(0xFF991B1B))),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: BentoTheme.bgLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BentoTheme.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (idx) {
          final isCompleted = idx <= currentStep;
          final isCurrent = idx == currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCurrent
                              ? BentoTheme.pingzoOrange
                              : (isCompleted ? BentoTheme.pingzoGreen : Colors.white),
                          border: Border.all(
                            color: isCompleted ? (isCurrent ? BentoTheme.pingzoOrange : BentoTheme.pingzoGreen) : BentoTheme.borderLight,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          isCompleted && !isCurrent ? Icons.check : (steps[idx]["icon"] as IconData),
                          size: 14,
                          color: isCompleted ? Colors.white : BentoTheme.textSecondaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[idx]["label"] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isCurrent || isCompleted ? FontWeight.bold : FontWeight.w500,
                          color: isCurrent
                              ? BentoTheme.pingzoOrange
                              : (isCompleted ? BentoTheme.pingzoGreenDark : BentoTheme.textSecondaryDark),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (idx < steps.length - 1)
                  Container(
                    height: 2,
                    width: 14,
                    color: idx < currentStep ? BentoTheme.pingzoGreen : BentoTheme.borderLight,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 2.5 Location Route Card (Shop Location -> Order Delivery Address)
  // ─────────────────────────────────────────────────────────────
  Widget _buildLocationRouteCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BentoTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Delivery Timing & Route Metric Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BentoTheme.pingzoGreenLight.withValues(alpha: 0.6),
                  const Color(0xFFEFF6FF),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BentoTheme.pingzoGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 18, color: BentoTheme.pingzoGreenDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "Delivery Timing: ",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: BentoTheme.textPrimaryDark),
                          ),
                          Text(
                            "Within ${order.estimatedDeliveryEta}",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: BentoTheme.pingzoGreenDark),
                          ),
                        ],
                      ),
                      const Text(
                        "Live direct routing • Express Doorstep Fulfillment",
                        style: TextStyle(fontSize: 10, color: BentoTheme.textSecondaryDark),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: BentoTheme.borderLight),
                  ),
                  child: const Text(
                    "~1.6 km",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: BentoTheme.textPrimaryDark),
                  ),
                ),
              ],
            ),
          ),

          // Shop Origin Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront_rounded, size: 18, color: BentoTheme.pingzoGreenDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "SHOP LOCATION (ORIGIN)",
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: BentoTheme.pingzoGreenDark, letterSpacing: 0.5),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "PICKUP HUB",
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: BentoTheme.pingzoGreenDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.supermarketName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: BentoTheme.textPrimaryDark),
                    ),
                    Text(
                      order.supermarketAddress,
                      style: const TextStyle(fontSize: 11, color: BentoTheme.textSecondaryDark),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Route Connector Line
          Padding(
            padding: const EdgeInsets.only(left: 15, top: 4, bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 2,
                  height: 24,
                  decoration: BoxDecoration(
                    color: BentoTheme.pingzoGreen.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 18),
                Row(
                  children: [
                    const Icon(Icons.two_wheeler_rounded, size: 14, color: BentoTheme.pingzoOrange),
                    const SizedBox(width: 4),
                    Text(
                      _isDriverAssigned(order) ? "Partner in transit to destination" : "Order packed at store hub",
                      style: const TextStyle(fontSize: 10, color: BentoTheme.textSecondaryDark, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Order Destination Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFECE6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_rounded, size: 18, color: BentoTheme.pingzoOrange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "CUSTOMER LOCATION (DOORSTEP)",
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: BentoTheme.pingzoOrange, letterSpacing: 0.5),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFECE6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "ETA ${order.estimatedDeliveryEta}",
                            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: BentoTheme.pingzoOrange),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.customerName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: BentoTheme.textPrimaryDark),
                    ),
                    Text(
                      order.deliveryAddress,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: BentoTheme.textPrimaryDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 3. Driver Assigned Card
  // ─────────────────────────────────────────────────────────────
  Widget _buildDriverAssignedCard(OrderModel order) {
    final driverName = (order.assignedDriverName != null && order.assignedDriverName!.trim().isNotEmpty)
        ? order.assignedDriverName!
        : (order.assignedDriverId != null ? 'Delivery Partner #${order.assignedDriverId}' : 'Delivery Partner');
    final driverPhone = (order.assignedDriverPhone != null && order.assignedDriverPhone!.trim().isNotEmpty)
        ? order.assignedDriverPhone!
        : '';
    final driverId = order.assignedDriverId ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BentoTheme.bgLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BentoTheme.pingzoOrange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: BentoTheme.pingzoOrange,
                ),
                child: const Center(
                  child: Icon(Icons.person, color: Colors.white, size: 28),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: BentoTheme.pingzoGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.two_wheeler_rounded, size: 10, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        driverName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: BentoTheme.textPrimaryDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded, size: 14, color: BentoTheme.pingzoGreen),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 13),
                    const SizedBox(width: 2),
                    Text(
                      driverId.isNotEmpty ? "4.9 • ID: $driverId" : "4.9 • Verified Fleet Partner",
                      style: const TextStyle(fontSize: 11, color: BentoTheme.textSecondaryDark, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (driverPhone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    driverPhone,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: BentoTheme.textSecondaryDark),
                  ),
                ],
              ],
            ),
          ),
          // Real-time Chat Button
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: BentoTheme.borderLight),
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: BentoTheme.pingzoOrange, size: 20),
            tooltip: "Chat with Delivery Partner",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DriverChatScreen(orderId: order.id)),
              );
            },
          ),
          if (driverPhone.isNotEmpty) ...[
            const SizedBox(width: 4),
            // Call Button
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: BentoTheme.pingzoGreen,
              ),
              icon: const Icon(Icons.phone, color: Colors.white, size: 20),
              tooltip: "Call Delivery Partner",
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Calling $driverName ($driverPhone)..."),
                    backgroundColor: BentoTheme.pingzoGreen,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 4. Awaiting Driver Card
  // ─────────────────────────────────────────────────────────────
  Widget _buildAwaitingDriverCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 22),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Assigning Delivery Partner...",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                ),
                SizedBox(height: 2),
                Text(
                  "Supermarket is packing your items. A nearby PingZo fleet partner will be assigned momentarily.",
                  style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 5. Supermarket Info Card
  // ─────────────────────────────────────────────────────────────
  Widget _buildSupermarketCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: BentoTheme.pingzoGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "FULFILLING SUPERMARKET HUB",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: BentoTheme.pingzoGreenDark, letterSpacing: 0.5),
                ),
                Text(
                  order.supermarketName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: BentoTheme.textPrimaryDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  order.supermarketAddress,
                  style: const TextStyle(fontSize: 11, color: BentoTheme.textSecondaryDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 6. Expandable Order Items & Bill Details Accordion
  // ─────────────────────────────────────────────────────────────
  Widget _buildOrderItemsAndBillAccordion(OrderModel order, OrderProvider orderProv) {
    return Container(
      decoration: BoxDecoration(
        color: BentoTheme.bgLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BentoTheme.borderLight),
      ),
      child: Column(
        children: [
          // Header / Toggle
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _isDetailsExpanded = !_isDetailsExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, color: BentoTheme.pingzoOrange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Order Summary (${order.items.length} items)",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: BentoTheme.textPrimaryDark),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        "₹${order.grossTotal.toStringAsFixed(0)}",
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: BentoTheme.textPrimaryDark),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isDetailsExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: BentoTheme.textSecondaryDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (_isDetailsExpanded) ...[
            const Divider(height: 1, color: BentoTheme.borderLight),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Items List
                  ...order.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "${item.quantity}x ${item.productName}",
                              style: const TextStyle(fontSize: 13, color: BentoTheme.textPrimaryDark, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            "₹${item.totalPrice.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: BentoTheme.textPrimaryDark),
                          ),
                        ],
                      ),
                    );
                  }),

                  const Divider(height: 20, color: BentoTheme.borderLight),

                  // Bill Breakdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Item Subtotal", style: TextStyle(fontSize: 12, color: BentoTheme.textSecondaryDark)),
                      Text("₹${order.subtotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: BentoTheme.textPrimaryDark)),
                    ],
                  ),
                  if (order.couponDiscount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Coupon Discount", style: TextStyle(fontSize: 12, color: BentoTheme.pingzoGreen, fontWeight: FontWeight.bold)),
                        Text("-₹${order.couponDiscount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 12, color: BentoTheme.pingzoGreen, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Delivery Fee", style: TextStyle(fontSize: 12, color: BentoTheme.textSecondaryDark)),
                      Text(order.deliveryFee == 0 ? "FREE" : "₹${order.deliveryFee.toStringAsFixed(2)}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: order.deliveryFee == 0 ? BentoTheme.pingzoGreen : BentoTheme.textPrimaryDark)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Taxes (SGST + CGST)", style: TextStyle(fontSize: 12, color: BentoTheme.textSecondaryDark)),
                      Text("₹${(order.sgstTotal + order.cgstTotal).toStringAsFixed(2)}", style: const TextStyle(fontSize: 12, color: BentoTheme.textPrimaryDark)),
                    ],
                  ),
                  const Divider(height: 16, color: BentoTheme.borderLight),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Paid", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: BentoTheme.textPrimaryDark)),
                      Text("₹${order.grossTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: BentoTheme.pingzoOrange)),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Delivery Address
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: BentoTheme.borderLight),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: BentoTheme.pingzoOrange),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("DELIVERY ADDRESS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BentoTheme.textSecondaryDark)),
                              Text(order.deliveryAddress, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: BentoTheme.textPrimaryDark)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Actions row (Invoice / Cancel)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: BentoTheme.pingzoGreen),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: BentoTheme.pingzoGreen),
                          label: const Text("Invoice", style: TextStyle(color: BentoTheme.pingzoGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceScreen(order: order!))),
                        ),
                      ),
                      if (order.isCancellable && order.orderStatus != 'CANCELLED' && order.orderStatus != 'DELIVERED') ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: BentoTheme.accentRed),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.cancel_outlined, size: 16, color: BentoTheme.accentRed),
                            label: const Text("Cancel Order", style: TextStyle(color: BentoTheme.accentRed, fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () => _showCancelOrderModal(context, order!, orderProv),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Status Colors Helper
  // ─────────────────────────────────────────────────────────────
  Color _getStatusBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return BentoTheme.pingzoGreenLight;
      case 'CANCELLED':
        return const Color(0xFFFEE2E2);
      case 'OUT_FOR_DELIVERY':
      case 'ASSIGNED':
        return const Color(0xFFFFECE6);
      default:
        return const Color(0xFFEFF6FF);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return BentoTheme.pingzoGreenDark;
      case 'CANCELLED':
        return BentoTheme.accentRed;
      case 'OUT_FOR_DELIVERY':
      case 'ASSIGNED':
        return BentoTheme.pingzoOrange;
      default:
        return const Color(0xFF1D4ED8);
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Realistic Vector City Map Painter (Urban Blocks, Parks, Water, Roads)
// ─────────────────────────────────────────────────────────────
class _RealisticCityMapPainter extends CustomPainter {
  final bool isSatellite;

  _RealisticCityMapPainter({required this.isSatellite});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base Terrain / Cartographic Background
    final bgPaint = Paint()
      ..color = isSatellite ? const Color(0xFF0A0F1D) : const Color(0xFFF6F5ED);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Water Channel / River (Soft Blue Curving Water Body)
    final riverOuterPaint = Paint()
      ..color = isSatellite ? const Color(0xFF0C4A6E).withValues(alpha: 0.6) : const Color(0xFFBAE6FD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24.0
      ..strokeCap = StrokeCap.round;

    final riverInnerPaint = Paint()
      ..color = isSatellite ? const Color(0xFF0369A1).withValues(alpha: 0.7) : const Color(0xFFE0F2FE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0
      ..strokeCap = StrokeCap.round;

    final riverPath = Path()
      ..moveTo(size.width * 0.05, size.height)
      ..cubicTo(
        size.width * 0.22, size.height * 0.72,
        size.width * 0.40, size.height * 0.85,
        size.width * 0.58, size.height * 0.50,
      )
      ..cubicTo(
        size.width * 0.75, size.height * 0.18,
        size.width * 0.88, size.height * 0.30,
        size.width, size.height * 0.08,
      );

    canvas.drawPath(riverPath, riverOuterPaint);
    canvas.drawPath(riverPath, riverInnerPaint);

    // 3. City Blocks & Urban Parcel Footprints
    final blockPaint1 = Paint()
      ..color = isSatellite ? const Color(0xFF1E293B) : const Color(0xFFEDE9DE)
      ..style = PaintingStyle.fill;

    final blockPaint2 = Paint()
      ..color = isSatellite ? const Color(0xFF162032) : const Color(0xFFE5E0D2)
      ..style = PaintingStyle.fill;

    final blockBorder = Paint()
      ..color = isSatellite ? const Color(0xFF334155).withValues(alpha: 0.4) : const Color(0xFFD8D2C2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final blocks = [
      RRect.fromRectAndRadius(Rect.fromLTWH(12, 12, size.width * 0.26, 52), const Radius.circular(5)),
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.32, 10, size.width * 0.30, 48), const Radius.circular(5)),
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.66, 12, size.width * 0.30, 56), const Radius.circular(5)),
      RRect.fromRectAndRadius(Rect.fromLTWH(12, size.height * 0.72, size.width * 0.28, 65), const Radius.circular(5)),
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.34, size.height * 0.68, size.width * 0.28, 68), const Radius.circular(5)),
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.68, size.height * 0.70, size.width * 0.28, 65), const Radius.circular(5)),
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.12, size.height * 0.28, size.width * 0.18, 55), const Radius.circular(5)),
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.62, size.height * 0.32, size.width * 0.22, 60), const Radius.circular(5)),
    ];

    for (int i = 0; i < blocks.length; i++) {
      canvas.drawRRect(blocks[i], i % 2 == 0 ? blockPaint1 : blockPaint2);
      canvas.drawRRect(blocks[i], blockBorder);
    }

    // 4. Parks & Botanical Landscaping (Lush Green)
    final parkPaint = Paint()
      ..color = isSatellite ? const Color(0xFF064E3B).withValues(alpha: 0.75) : const Color(0xFFD8F3DC)
      ..style = PaintingStyle.fill;
    final parkBorder = Paint()
      ..color = isSatellite ? const Color(0xFF047857).withValues(alpha: 0.5) : const Color(0xFFB7E4C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final park1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.68, size.height * 0.25, size.width * 0.26, 68),
      const Radius.circular(10),
    );
    final park2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(14, size.height * 0.44, size.width * 0.22, 50),
      const Radius.circular(10),
    );

    canvas.drawRRect(park1, parkPaint);
    canvas.drawRRect(park1, parkBorder);
    canvas.drawRRect(park2, parkPaint);
    canvas.drawRRect(park2, parkBorder);

    // 5. Local Street Network (Grid)
    final localRoadPaint = Paint()
      ..color = isSatellite ? const Color(0xFF283548) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSatellite ? 3.5 : 5.0
      ..strokeCap = StrokeCap.round;

    final localRoadBorder = Paint()
      ..color = isSatellite ? const Color(0xFF1E293B) : const Color(0xFFD5D0C2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSatellite ? 5.5 : 7.0
      ..strokeCap = StrokeCap.round;

    final localPaths = [
      Path()..moveTo(0, size.height * 0.26)..lineTo(size.width, size.height * 0.26),
      Path()..moveTo(0, size.height * 0.68)..lineTo(size.width, size.height * 0.68),
      Path()..moveTo(size.width * 0.30, 0)..lineTo(size.width * 0.30, size.height),
      Path()..moveTo(size.width * 0.64, 0)..lineTo(size.width * 0.64, size.height),
      Path()..moveTo(0, size.height * 0.45)..lineTo(size.width * 0.70, 0),
      Path()..moveTo(size.width * 0.25, size.height)..lineTo(size.width, size.height * 0.25),
    ];

    for (final lp in localPaths) {
      canvas.drawPath(lp, localRoadBorder);
      canvas.drawPath(lp, localRoadPaint);
    }

    // 6. Major Arterial Highway / Main Expressway (Gold / Orange Parkway)
    final highwayBorder = Paint()
      ..color = isSatellite ? const Color(0xFF475569) : const Color(0xFFF59E0B).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;

    final highwayInner = Paint()
      ..color = isSatellite ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    final highwayPath = Path()
      ..moveTo(0, size.height * 0.54)
      ..cubicTo(
        size.width * 0.28, size.height * 0.46,
        size.width * 0.58, size.height * 0.58,
        size.width, size.height * 0.48,
      );

    canvas.drawPath(highwayPath, highwayBorder);
    canvas.drawPath(highwayPath, highwayInner);

    // 7. Metro Transit Rail Line (Dashed Track)
    final metroPaint = Paint()
      ..color = isSatellite ? const Color(0xFF64748B) : const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final metroPath = Path()
      ..moveTo(size.width * 0.05, 0)
      ..lineTo(size.width * 0.05, size.height);
    canvas.drawPath(metroPath, metroPaint);

    // 8. Authentic Street & District Labels
    final textStyle = TextStyle(
      color: isSatellite ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      fontSize: 8.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
    );

    _drawText(canvas, "100 FT INNER RING RD", Offset(size.width * 0.24, size.height * 0.51), textStyle);
    _drawText(canvas, "Koramangala 4th Block", Offset(22, size.height * 0.20), textStyle.copyWith(fontSize: 8));
    _drawText(canvas, "Sony World Junction", Offset(size.width * 0.48, size.height * 0.10), textStyle.copyWith(fontSize: 8));
    _drawText(canvas, "🌳 Koramangala Park", Offset(size.width * 0.70, size.height * 0.42), textStyle.copyWith(fontSize: 8, color: const Color(0xFF16A34A)));
    _drawText(canvas, "🌊 Bellandur Lake Canal", Offset(size.width * 0.50, size.height * 0.82), textStyle.copyWith(fontSize: 7.5, color: const Color(0xFF0284C7)));
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _RealisticCityMapPainter oldDelegate) {
    return oldDelegate.isSatellite != isSatellite;
  }
}

// ─────────────────────────────────────────────────────────────
// Realistic Route Painter (Dual Layer Polyline + Animated Progress & Flow)
// ─────────────────────────────────────────────────────────────
class _RealisticRoutePainter extends CustomPainter {
  final double progress;
  final double animPhase;
  final Offset p0;
  final Offset p1;
  final Offset p2;
  final bool isSatellite;

  _RealisticRoutePainter({
    required this.progress,
    required this.animPhase,
    required this.p0,
    required this.p1,
    required this.p2,
    required this.isSatellite,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final routePath = Path()
      ..moveTo(p0.dx, p0.dy)
      ..quadraticBezierTo(p1.dx, p1.dy, p2.dx, p2.dy);

    // 1. Route Outer Glow / Shadow
    final glowPaint = Paint()
      ..color = (isSatellite ? const Color(0xFF10B981) : BentoTheme.pingzoGreen).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(routePath, glowPaint);

    // 2. Base Road Highway Track (Casing + Inner)
    final baseCasing = Paint()
      ..color = isSatellite ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(routePath, baseCasing);

    final baseInner = Paint()
      ..color = isSatellite ? const Color(0xFF0F172A) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(routePath, baseInner);

    final pathMetrics = routePath.computeMetrics().toList();
    if (pathMetrics.isNotEmpty) {
      final metric = pathMetrics.first;
      final totalLen = metric.length;
      final currentDist = totalLen * progress.clamp(0.0, 1.0);

      // 3. Active Completed Route Trail (Vibrant Glowing PingZo Green)
      if (currentDist > 0.0) {
        final completedPath = metric.extractPath(0.0, currentDist);

        final activeGlowPaint = Paint()
          ..color = (isSatellite ? const Color(0xFF10B981) : BentoTheme.pingzoGreen).withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10.0
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(completedPath, activeGlowPaint);

        final activeTrailPaint = Paint()
          ..color = isSatellite ? const Color(0xFF10B981) : BentoTheme.pingzoGreen
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(completedPath, activeTrailPaint);

        final activeCorePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(completedPath, activeCorePaint);
      }

      // 4. Remaining Route: Animated Flowing Navigation Dashes
      if (currentDist < totalLen) {
        const dashLen = 8.0;
        const gapLen = 6.0;
        const cycleLen = dashLen + gapLen;
        final phaseOffset = (animPhase * cycleLen);

        final dashPaint = Paint()
          ..color = isSatellite ? const Color(0xFF38BDF8) : BentoTheme.pingzoOrange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round;

        double dist = currentDist + phaseOffset;
        while (dist < totalLen) {
          final start = dist;
          final end = (dist + dashLen).clamp(0.0, totalLen);
          if (end > start) {
            final dashPath = metric.extractPath(start, end);
            canvas.drawPath(dashPath, dashPaint);
          }
          dist += cycleLen;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RealisticRoutePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.animPhase != animPhase ||
        oldDelegate.p0 != p0 ||
        oldDelegate.p1 != p1 ||
        oldDelegate.p2 != p2 ||
        oldDelegate.isSatellite != isSatellite;
  }
}
