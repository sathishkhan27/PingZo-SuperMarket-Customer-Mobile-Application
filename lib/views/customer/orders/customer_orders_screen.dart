import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/bento_theme.dart';
import '../../../models/order_model.dart';
import '../../../services/order_provider.dart';
import '../order_tracking/live_order_tracking_screen.dart';
import 'invoice_screen.dart';
import 'rating_feedback_modal.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({Key? key}) : super(key: key);

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _showCancelOrderModal(BuildContext context, OrderModel order, OrderProvider orderProv) {
    String selectedReason = "Changed my mind";
    showModalBottomSheet(
      context: context,
      backgroundColor: BentoTheme.cardDark,
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
                  const Text("Cancel Order Eligibility & Refund", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text("Order #${order.id} is eligible for 100% full refund of ₹${order.grossTotal.toStringAsFixed(0)}", style: const TextStyle(fontSize: 13, color: BentoTheme.pingzoGreen)),
                  const SizedBox(height: 16),
                  const Text("Select Reason for Cancellation:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BentoTheme.textSecondary)),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: selectedReason,
                    dropdownColor: BentoTheme.cardDark,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    items: ["Changed my mind", "Delivery time too long", "Incorrect delivery address", "Ordered wrong item"]
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
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
                        SnackBar(content: Text("Order #${order.id} Cancelled. Refund Initiated!"), backgroundColor: BentoTheme.accentRed),
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
    final orders = orderProv.orders;

    final activeOrders = orders.where((o) => o.orderStatus != 'DELIVERED' && o.orderStatus != 'CANCELLED').toList();
    final completedOrders = orders.where((o) => o.orderStatus == 'DELIVERED').toList();
    final cancelledOrders = orders.where((o) => o.orderStatus == 'CANCELLED').toList();

    return Scaffold(
      backgroundColor: BentoTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: BentoTheme.cardDark,
        elevation: 0,
        title: const Text("My Orders & Refunds", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: BentoTheme.pingzoGreen,
          labelColor: BentoTheme.pingzoGreen,
          unselectedLabelColor: BentoTheme.textSecondary,
          tabs: [
            Tab(text: "Active (${activeOrders.length})"),
            Tab(text: "Completed (${completedOrders.length})"),
            Tab(text: "Cancelled (${cancelledOrders.length})"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(activeOrders, orderProv, isActive: true),
          _buildOrderList(completedOrders, orderProv, isCompleted: true),
          _buildOrderList(cancelledOrders, orderProv, isCancelled: true),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> list, OrderProvider orderProv, {bool isActive = false, bool isCompleted = false, bool isCancelled = false}) {
    if (list.isEmpty) {
      return RefreshIndicator(
        color: BentoTheme.pingzoOrange,
        onRefresh: () async => await orderProv.fetchOrders(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 64, color: BentoTheme.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    isActive ? "No Active Orders" : isCompleted ? "No Completed Orders" : "No Cancelled Orders",
                    style: const TextStyle(color: BentoTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: BentoTheme.pingzoOrange,
      onRefresh: () async => await orderProv.fetchOrders(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, idx) {
          final order = list[idx];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BentoTheme.bentoCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("ORDER #${order.id}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCancelled
                            ? BentoTheme.accentRed.withValues(alpha: 0.2)
                            : isCompleted
                                ? BentoTheme.pingzoGreen.withValues(alpha: 0.2)
                                : BentoTheme.pingzoOrange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.orderStatus.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isCancelled ? BentoTheme.accentRed : isCompleted ? BentoTheme.pingzoGreen : BentoTheme.pingzoOrange,
                        ),
                      ),
                    ),
                  ],
                ),
                // Supermarket Store Information
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_rounded, size: 16, color: BentoTheme.pingzoGreenLight),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.supermarketName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Items and Total
                Text("${order.items.length} items • Total ₹${order.grossTotal.toStringAsFixed(0)} • ${order.paymentMethod}", style: const TextStyle(color: BentoTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 4),

                // Delivery Partner or Store Status
                Row(
                  children: [
                    Icon(
                      order.assignedDriverName != null && order.assignedDriverName!.trim().isNotEmpty
                          ? Icons.delivery_dining_rounded
                          : Icons.hourglass_top_rounded,
                      size: 14,
                      color: BentoTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.assignedDriverName != null && order.assignedDriverName!.trim().isNotEmpty
                            ? "Fleet Partner: ${order.assignedDriverName}"
                            : "Fulfilling at Supermarket • Awaiting driver",
                        style: const TextStyle(color: BentoTheme.textSecondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isActive)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: BentoTheme.pingzoGreen),
                        onPressed: () {
                          orderProv.setActiveOrder(order);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LiveOrderTrackingScreen(
                                orderId: order.id,
                                initialOrder: order,
                              ),
                            ),
                          );
                        },
                        child: const Text("Track Live Delivery", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),

                    if (isActive && order.isCancellable)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: BentoTheme.accentRed)),
                        onPressed: () => _showCancelOrderModal(context, order, orderProv),
                        child: const Text("Cancel Order", style: TextStyle(color: BentoTheme.accentRed, fontSize: 12)),
                      ),

                  if (isCompleted) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: BentoTheme.pingzoGreen),
                      label: const Text("View Invoice", style: TextStyle(color: BentoTheme.pingzoGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceScreen(order: order))),
                    ),
                    IconButton(
                      icon: const Icon(Icons.star_half_rounded, color: Colors.amber),
                      onPressed: () => RatingFeedbackModal.show(context, order.id, orderProv),
                    ),
                  ],

                  if (isCancelled)
                    Text("Refund ${order.refundStatus}: ₹${order.refundAmount.toStringAsFixed(0)}", style: const TextStyle(color: BentoTheme.pingzoOrange, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              ],
            ),
          );
        },
      ),
    );
  }
}
