import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/bento_theme.dart';
import '../models/app_notification_model.dart';
import '../views/customer/order_tracking/live_order_tracking_screen.dart';

class NotificationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static OverlayEntry? _currentOverlay;

  /// Trigger custom animated top overlay banner notification
  static void showInAppNotification({
    required String title,
    required String body,
    AppNotificationType type = AppNotificationType.systemAlert,
    String? orderId,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    // Dismiss existing banner if showing
    _currentOverlay?.remove();
    _currentOverlay = null;

    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _InAppNotificationBanner(
        title: title,
        body: body,
        type: type,
        orderId: orderId,
        onTap: () {
          entry.remove();
          if (_currentOverlay == entry) _currentOverlay = null;

          if (onTap != null) {
            onTap();
          } else if (orderId != null && orderId.isNotEmpty) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => LiveOrderTrackingScreen(orderId: orderId),
              ),
            );
          }
        },
        onDismissed: () {
          entry.remove();
          if (_currentOverlay == entry) _currentOverlay = null;
        },
        duration: duration,
      ),
    );

    _currentOverlay = entry;
    overlayState.insert(entry);
  }

  /// Dismiss active banner programmatically
  static void dismissActiveBanner() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

class _InAppNotificationBanner extends StatefulWidget {
  final String title;
  final String body;
  final AppNotificationType type;
  final String? orderId;
  final VoidCallback onTap;
  final VoidCallback onDismissed;
  final Duration duration;

  const _InAppNotificationBanner({
    Key? key,
    required this.title,
    required this.body,
    required this.type,
    this.orderId,
    required this.onTap,
    required this.onDismissed,
    required this.duration,
  }) : super(key: key);

  @override
  State<_InAppNotificationBanner> createState() => _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<_InAppNotificationBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward();

    // Auto-dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismissed();
      }
    });
  }

  Color _getAccentColor() {
    switch (widget.type) {
      case AppNotificationType.driverAssigned:
      case AppNotificationType.outForDelivery:
        return BentoTheme.pingzoOrange;
      case AppNotificationType.orderDelivered:
        return BentoTheme.pingzoGreen;
      case AppNotificationType.orderCancelled:
        return BentoTheme.accentRed;
      case AppNotificationType.orderPacking:
      case AppNotificationType.orderPlaced:
        return const Color(0xFF3B82F6);
      case AppNotificationType.promo:
        return const Color(0xFF8B5CF6);
      case AppNotificationType.systemAlert:
        return BentoTheme.textPrimaryDark;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case AppNotificationType.driverAssigned:
        return Icons.two_wheeler_rounded;
      case AppNotificationType.outForDelivery:
        return Icons.local_shipping_rounded;
      case AppNotificationType.orderDelivered:
        return Icons.verified_rounded;
      case AppNotificationType.orderCancelled:
        return Icons.cancel_rounded;
      case AppNotificationType.orderPacking:
        return Icons.inventory_2_rounded;
      case AppNotificationType.orderPlaced:
        return Icons.shopping_bag_rounded;
      case AppNotificationType.promo:
        return Icons.local_offer_rounded;
      case AppNotificationType.systemAlert:
        return Icons.notifications_active_rounded;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final accentColor = _getAccentColor();

    return Positioned(
      top: topPadding + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: widget.onTap,
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                _dismiss();
              }
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.15),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icon Circle
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: Icon(_getIcon(), color: accentColor, size: 22),
                    ),
                    const SizedBox(width: 12),

                    // Notification Text
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  widget.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: BentoTheme.textPrimaryDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Text(
                                "Just now",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: BentoTheme.textSecondaryDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.body,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: BentoTheme.textSecondaryDark,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Arrow indicator
                    Icon(
                      Icons.chevron_right_rounded,
                      color: BentoTheme.textSecondaryDark.withValues(alpha: 0.5),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
