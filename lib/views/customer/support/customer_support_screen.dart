import 'package:flutter/material.dart';
import '../../../core/theme/bento_theme.dart';
import '../../../models/support_model.dart';
import '../../../services/api_service.dart';

class CustomerSupportScreen extends StatefulWidget {
  const CustomerSupportScreen({Key? key}) : super(key: key);

  @override
  State<CustomerSupportScreen> createState() => _CustomerSupportScreenState();
}

class _CustomerSupportScreenState extends State<CustomerSupportScreen> {
  final List<FaqItem> _faqs = ApiService.getMockFaqs();
  final List<SupportTicket> _tickets = [
    SupportTicket(
      id: "TICK-9082",
      category: "Missing Item",
      subject: "1 kg Tomato missing from order #PZ-884920",
      description: "Package was sealed but tomatoes were not included.",
      status: "IN_PROGRESS",
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _selectedCategory = "Order Issues";

  void _showCreateTicketModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BentoTheme.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Raise Support Ticket", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              const Text("Issue Category", style: TextStyle(fontSize: 12, color: BentoTheme.textSecondary)),
              DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                dropdownColor: BentoTheme.cardDark,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: ["Order Issues", "Payment & Refund", "Missing / Damaged Item", "Delivery Partner", "Account & App"]
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _subjectController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Brief Subject...",
                  hintStyle: const TextStyle(color: BentoTheme.textSecondary, fontSize: 13),
                  filled: true,
                  fillColor: BentoTheme.primaryDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Describe your issue in detail...",
                  hintStyle: const TextStyle(color: BentoTheme.textSecondary, fontSize: 13),
                  filled: true,
                  fillColor: BentoTheme.primaryDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BentoTheme.pingzoGreen,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (_subjectController.text.isEmpty) return;
                  setState(() {
                    _tickets.insert(
                      0,
                      SupportTicket(
                        id: "TICK-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}",
                        category: _selectedCategory,
                        subject: _subjectController.text,
                        description: _descController.text,
                        status: "OPEN",
                        createdAt: DateTime.now(),
                      ),
                    );
                  });
                  _subjectController.clear();
                  _descController.clear();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Support ticket raised successfully!"), backgroundColor: BentoTheme.pingzoGreen),
                  );
                },
                child: const Text("Submit Ticket", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BentoTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: BentoTheme.cardDark,
        elevation: 0,
        title: const Text("Help & Customer Support", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Raise Ticket Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BentoTheme.bentoCardDecoration(color: BentoTheme.cardDark),
              child: Row(
                children: [
                  const Icon(Icons.support_agent_rounded, size: 40, color: BentoTheme.pingzoGreen),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Need help with an order?", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text("Our 24/7 support team resolves issues in mins", style: TextStyle(fontSize: 12, color: BentoTheme.textSecondary)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: BentoTheme.pingzoGreen),
                    onPressed: _showCreateTicketModal,
                    child: const Text("Raise Ticket", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Active Support Tickets
            if (_tickets.isNotEmpty) ...[
              const Text("Your Support Tickets", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              ..._tickets.map((t) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BentoTheme.bentoCardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(t.id, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: BentoTheme.pingzoGreen)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: BentoTheme.pingzoOrange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                            child: Text(t.status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BentoTheme.pingzoOrange)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(t.subject, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(t.description, style: const TextStyle(fontSize: 12, color: BentoTheme.textSecondary)),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
            ],

            // FAQ Accordion Section
            const Text("Frequently Asked Questions (FAQ)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            ..._faqs.map((faq) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BentoTheme.bentoCardDecoration(),
                child: ExpansionTile(
                  title: Text(faq.question, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  iconColor: BentoTheme.pingzoGreen,
                  collapsedIconColor: BentoTheme.textSecondary,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      child: Text(faq.answer, style: const TextStyle(color: BentoTheme.textSecondary, fontSize: 13)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
