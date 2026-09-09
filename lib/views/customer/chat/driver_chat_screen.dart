import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/bento_theme.dart';
import '../../../models/order_model.dart';
import '../../../models/chat_model.dart';
import '../../../services/order_provider.dart';

class DriverChatScreen extends StatefulWidget {
  final String? orderId;
  final OrderModel? order;

  const DriverChatScreen({
    Key? key,
    this.orderId,
    this.order,
  }) : super(key: key);

  static const List<String> customerQuickReplies = [
    'Where are you currently? 📍',
    'Gate code is #8821, Building B 🔑',
    'Please leave the package at the door 🚪',
    'Coming down to lobby right now 🏃',
    'Please call me once you reach 📞',
    'Thanks! Drive safely.',
  ];

  @override
  State<DriverChatScreen> createState() => _DriverChatScreenState();
}

class _DriverChatScreenState extends State<DriverChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isOrderSummaryExpanded = false;
  Timer? _chatSyncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProv = Provider.of<OrderProvider>(context, listen: false);
      final currentOrder = _resolveOrder(orderProv);
      if (currentOrder.id.isNotEmpty) {
        orderProv.ensureOrderChatInitialized(currentOrder);
        orderProv.syncOrderChat(currentOrder.id);
      }
      _scrollToBottom();
    });

    _chatSyncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      final orderProv = Provider.of<OrderProvider>(context, listen: false);
      final currentOrder = _resolveOrder(orderProv);
      final targetOrderId = currentOrder.id.isNotEmpty ? currentOrder.id : (widget.orderId ?? '');
      if (targetOrderId.isNotEmpty) {
        orderProv.syncOrderChat(targetOrderId);
      }
    });
  }

  @override
  void dispose() {
    _chatSyncTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  OrderModel _resolveOrder(OrderProvider orderProv) {
    if (widget.order != null && widget.order!.id.isNotEmpty) {
      return widget.order!;
    }
    if (widget.orderId != null && widget.orderId!.isNotEmpty) {
      final matches = orderProv.orders.where((o) => o.id == widget.orderId || o.id.contains(widget.orderId!) || widget.orderId!.contains(o.id)).toList();
      if (matches.isNotEmpty) return matches.first;
    }
    return orderProv.activeOrder ?? OrderModel.empty();
  }

  void _sendMessage(OrderProvider orderProv, String targetOrderId, {String? quickText}) {
    final text = quickText ?? _msgController.text;
    if (text.trim().isEmpty) return;

    orderProv.sendChatMessage(
      text,
      isCustomer: true,
      orderId: targetOrderId,
    );

    if (quickText == null) {
      _msgController.clear();
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = Provider.of<OrderProvider>(context);
    final order = _resolveOrder(orderProv);
    final targetOrderId = order.id.isNotEmpty ? order.id : (widget.orderId ?? 'ACTIVE');
    final messages = orderProv.getChatMessagesForOrder(targetOrderId);
    final isChatClosed = orderProv.isOrderChatCompleted(targetOrderId) ||
        order.orderStatus == 'DELIVERED' ||
        order.orderStatus == 'CANCELLED';

    final driverName = (order.assignedDriverName != null && order.assignedDriverName!.isNotEmpty)
        ? order.assignedDriverName!
        : 'PingZo Delivery Partner';
    final driverPhone = order.assignedDriverPhone ?? '+91 98765 43210';
    final timeFormat = DateFormat('hh:mm a');

    return Scaffold(
      backgroundColor: BentoTheme.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: BentoTheme.textPrimaryDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: BentoTheme.pingzoOrange.withValues(alpha: 0.15),
              child: const Icon(Icons.two_wheeler_rounded, color: BentoTheme.pingzoOrange, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driverName,
                    style: const TextStyle(
                      color: BentoTheme.textPrimaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isChatClosed
                        ? 'Order #${order.id} • Chat Closed'
                        : 'Order #${order.id} • ${order.orderStatus.replaceAll('_', ' ')}',
                    style: TextStyle(
                      color: isChatClosed ? BentoTheme.pingzoGreen : BentoTheme.textSecondaryDark,
                      fontSize: 11,
                      fontWeight: isChatClosed ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Order Details Toggle
          IconButton(
            icon: Icon(
              _isOrderSummaryExpanded ? Icons.info_rounded : Icons.info_outline_rounded,
              color: BentoTheme.pingzoOrange,
            ),
            tooltip: 'Order Context',
            onPressed: () {
              setState(() {
                _isOrderSummaryExpanded = !_isOrderSummaryExpanded;
              });
            },
          ),
          // Direct Call Partner
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: BentoTheme.pingzoGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_rounded, color: BentoTheme.pingzoGreen, size: 18),
            ),
            tooltip: 'Call Delivery Partner',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling delivery partner: $driverPhone'),
                  backgroundColor: BentoTheme.pingzoGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // 1. Expandable Order Context Drawer
          if (_isOrderSummaryExpanded && order.id.isNotEmpty)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: BentoTheme.borderLight)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storefront_rounded, size: 16, color: BentoTheme.pingzoOrange),
                          const SizedBox(width: 6),
                          Text(
                            order.supermarketName.isNotEmpty ? order.supermarketName : 'PingZo Supermarket',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: BentoTheme.textPrimaryDark),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: BentoTheme.pingzoOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: BentoTheme.pingzoOrange.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'OTP PIN: ${order.deliveryOtp}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: BentoTheme.pingzoOrange),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: BentoTheme.textSecondaryDark),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          order.deliveryAddress.isNotEmpty ? order.deliveryAddress : 'Delivery Location',
                          style: const TextStyle(fontSize: 12, color: BentoTheme.textSecondaryDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Total: ₹${order.grossTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: BentoTheme.textPrimaryDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // 2. Chat Messages Stream
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: messages.length,
              itemBuilder: (context, idx) {
                final msg = messages[idx];
                final isCustomer = msg.isCustomer;
                final isSystem = msg.isSystem;

                // System Message or Closure Banner
                if (isSystem) {
                  final isClosureMsg = msg.id.startsWith('sys-closed-') ||
                      msg.message.toLowerCase().contains('delivered') ||
                      msg.message.toLowerCase().contains('cancelled') ||
                      msg.message.toLowerCase().contains('closed');

                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isClosureMsg
                            ? BentoTheme.pingzoGreen.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isClosureMsg
                              ? BentoTheme.pingzoGreen.withValues(alpha: 0.35)
                              : BentoTheme.borderLight,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isClosureMsg ? Icons.verified_rounded : Icons.info_outline_rounded,
                            size: 16,
                            color: isClosureMsg ? BentoTheme.pingzoGreen : BentoTheme.textSecondaryDark,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              msg.message,
                              style: TextStyle(
                                fontSize: 12,
                                color: isClosureMsg ? BentoTheme.textPrimaryDark : BentoTheme.textSecondaryDark,
                                fontWeight: isClosureMsg ? FontWeight.w600 : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Normal Chat Bubble
                return Align(
                  alignment: isCustomer ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isCustomer ? BentoTheme.pingzoOrange : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isCustomer ? 18 : 4),
                        bottomRight: Radius.circular(isCustomer ? 4 : 18),
                      ),
                      border: isCustomer ? null : Border.all(color: BentoTheme.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: isCustomer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isCustomer ? '👤 You' : '🛵 $driverName',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isCustomer ? Colors.white.withValues(alpha: 0.9) : BentoTheme.pingzoOrange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          msg.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: isCustomer ? Colors.white : BentoTheme.textPrimaryDark,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              timeFormat.format(msg.timestamp),
                              style: TextStyle(
                                fontSize: 10,
                                color: isCustomer ? Colors.white.withValues(alpha: 0.7) : BentoTheme.textSecondaryDark,
                              ),
                            ),
                            if (isCustomer) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.done_all_rounded, size: 12, color: Colors.white70),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Driver Typing Indicator
          if (!isChatClosed && orderProv.isDriverTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: BentoTheme.pingzoOrange),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$driverName is typing...',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: BentoTheme.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),

          // 4. Quick Response Pills (Customer Actions)
          if (!isChatClosed)
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  ...DriverChatScreen.customerQuickReplies.map(
                    (reply) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: BentoTheme.borderLight),
                        label: Text(
                          reply,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: BentoTheme.textPrimaryDark,
                          ),
                        ),
                        onPressed: () => _sendMessage(orderProv, targetOrderId, quickText: reply),
                      ),
                    ),
                  ),
                  if (order.deliveryOtp.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        backgroundColor: BentoTheme.pingzoOrange.withValues(alpha: 0.1),
                        side: BorderSide(color: BentoTheme.pingzoOrange.withValues(alpha: 0.4)),
                        label: Text(
                          'My PIN is ${order.deliveryOtp} 🔢',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: BentoTheme.pingzoOrange,
                          ),
                        ),
                        onPressed: () => _sendMessage(
                          orderProv,
                          targetOrderId,
                          quickText: 'My delivery confirmation PIN is ${order.deliveryOtp}',
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // 5. Input Bar vs. Closed Conversation Card
          if (!isChatClosed)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: BentoTheme.borderLight)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: BentoTheme.bgLight,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: BentoTheme.borderLight),
                        ),
                        child: TextField(
                          controller: _msgController,
                          style: const TextStyle(color: BentoTheme.textPrimaryDark, fontSize: 14),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(orderProv, targetOrderId),
                          decoration: InputDecoration(
                            hintText: 'Message $driverName...',
                            hintStyle: const TextStyle(color: BentoTheme.textSecondaryDark, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: BentoTheme.pingzoOrange,
                      shape: const CircleBorder(),
                      elevation: 3,
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        onPressed: () => _sendMessage(orderProv, targetOrderId),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: BentoTheme.borderLight)),
              ),
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: BentoTheme.pingzoGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BentoTheme.pingzoGreen.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        color: BentoTheme.pingzoGreen,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Chat Completed • Delivery Finished',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: BentoTheme.pingzoGreen,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'This order conversation is closed to protect customer privacy.',
                              style: TextStyle(
                                fontSize: 11,
                                color: BentoTheme.textSecondaryDark,
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
}
