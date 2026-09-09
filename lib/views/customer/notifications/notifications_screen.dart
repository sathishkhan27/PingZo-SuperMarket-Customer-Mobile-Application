import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/bento_theme.dart';
import '../../../models/app_notification_model.dart';
import '../../../services/notification_provider.dart';
import '../order_tracking/live_order_tracking_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final notifProv = Provider.of<NotificationProvider>(context);
    final allNotifs = notifProv.notifications;

    final filteredNotifs = allNotifs.where((n) {
      if (_selectedFilter == 'ORDERS') {
        return n.type != AppNotificationType.promo && n.type != AppNotificationType.systemAlert;
      } else if (_selectedFilter == 'OFFERS') {
        return n.type == AppNotificationType.promo;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: BentoTheme.bgLight,
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          if (allNotifs.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: BentoTheme.textPrimaryDark),
              onSelected: (val) {
                if (val == 'read_all') {
                  notifProv.markAllAsRead();
                } else if (val == 'clear_all') {
                  notifProv.clearAll();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'read_all',
                  child: Row(
                    children: [
                      Icon(Icons.done_all_rounded, size: 18, color: BentoTheme.pingzoGreen),
                      SizedBox(width: 8),
                      Text("Mark all as read"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_rounded, size: 18, color: BentoTheme.accentRed),
                      SizedBox(width: 8),
                      Text("Clear all"),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip("ALL", "All (${allNotifs.length})"),
                const SizedBox(width: 8),
                _buildFilterChip(
                  "ORDERS",
                  "Orders (${allNotifs.where((n) => n.type != AppNotificationType.promo && n.type != AppNotificationType.systemAlert).length})",
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  "OFFERS",
                  "Offers (${allNotifs.where((n) => n.type == AppNotificationType.promo).length})",
                ),
              ],
            ),
          ),

          // Notifications List
          Expanded(
            child: filteredNotifs.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredNotifs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notif = filteredNotifs[index];
                      return _buildNotificationCard(notif, notifProv);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? BentoTheme.pingzoOrange : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? BentoTheme.pingzoOrange : BentoTheme.borderLight,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: BentoTheme.pingzoOrange.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : BentoTheme.textSecondaryDark,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotificationModel notif, NotificationProvider prov) {
    Color accentColor;
    IconData iconData;

    switch (notif.type) {
      case AppNotificationType.driverAssigned:
      case AppNotificationType.outForDelivery:
        accentColor = BentoTheme.pingzoOrange;
        iconData = Icons.two_wheeler_rounded;
        break;
      case AppNotificationType.orderDelivered:
        accentColor = BentoTheme.pingzoGreen;
        iconData = Icons.verified_rounded;
        break;
      case AppNotificationType.orderCancelled:
        accentColor = BentoTheme.accentRed;
        iconData = Icons.cancel_rounded;
        break;
      case AppNotificationType.orderPacking:
      case AppNotificationType.orderPlaced:
        accentColor = const Color(0xFF3B82F6);
        iconData = Icons.inventory_2_rounded;
        break;
      case AppNotificationType.promo:
        accentColor = const Color(0xFF8B5CF6);
        iconData = Icons.local_offer_rounded;
        break;
      case AppNotificationType.systemAlert:
        accentColor = BentoTheme.textPrimaryDark;
        iconData = Icons.notifications_active_rounded;
        break;
    }

    final timeStr = DateFormat('dd MMM, hh:mm a').format(notif.timestamp);

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: BentoTheme.accentRed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: BentoTheme.accentRed),
      ),
      onDismissed: (_) {
        prov.deleteNotification(notif.id);
      },
      child: GestureDetector(
        onTap: () {
          prov.markAsRead(notif.id);
          if (notif.orderId != null && notif.orderId!.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LiveOrderTrackingScreen(orderId: notif.orderId),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notif.isRead ? Colors.white : const Color(0xFFFFFBF5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notif.isRead ? BentoTheme.borderLight : accentColor.withValues(alpha: 0.4),
              width: notif.isRead ? 1.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Circle
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),

              // Texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: notif.isRead ? FontWeight.bold : FontWeight.w900,
                              color: BentoTheme.textPrimaryDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentColor,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notif.body,
                      style: const TextStyle(
                        fontSize: 12,
                        color: BentoTheme.textSecondaryDark,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 10,
                            color: BentoTheme.textSecondaryDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (notif.orderId != null && notif.orderId!.isNotEmpty)
                          const Row(
                            children: [
                              Text(
                                "Track Order",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: BentoTheme.pingzoOrange,
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, size: 14, color: BentoTheme.pingzoOrange),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: BentoTheme.bgLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 56,
              color: BentoTheme.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "No Notifications Yet",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: BentoTheme.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "You will see real-time updates for your grocery\norders, rider tracking, and deals here.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: BentoTheme.textSecondaryDark,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
