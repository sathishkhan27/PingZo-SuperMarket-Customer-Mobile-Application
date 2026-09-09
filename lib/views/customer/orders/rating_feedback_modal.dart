import 'package:flutter/material.dart';
import '../../../core/theme/bento_theme.dart';
import '../../../services/order_provider.dart';

class RatingFeedbackModal {
  static void show(BuildContext context, String orderId, OrderProvider orderProv) {
    double selectedRating = 5.0;
    final TextEditingController feedbackController = TextEditingController();
    final List<String> tags = ["Fast Delivery ⚡", "Friendly Partner 😊", "Neat Packaging 📦", "Super Fresh Veggies 🥦"];
    final List<String> selectedTags = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BentoTheme.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("Rate Delivery Experience", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  const Text("How was your delivery partner and supermarket order?", style: TextStyle(fontSize: 13, color: BentoTheme.textSecondary)),
                  const SizedBox(height: 20),

                  // Star Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      int star = index + 1;
                      return IconButton(
                        iconSize: 36,
                        icon: Icon(
                          star <= selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                        ),
                        onPressed: () => setModalState(() => selectedRating = star.toDouble()),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Tag Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.map((t) {
                      bool isSel = selectedTags.contains(t);
                      return FilterChip(
                        selected: isSel,
                        label: Text(t),
                        labelStyle: TextStyle(color: isSel ? Colors.white : BentoTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                        backgroundColor: BentoTheme.primaryDark,
                        selectedColor: BentoTheme.pingzoGreen,
                        onSelected: (val) {
                          setModalState(() {
                            if (val) {
                              selectedTags.add(t);
                            } else {
                              selectedTags.remove(t);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: feedbackController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Write optional feedback for the delivery partner...",
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
                      String fullFeedback = "${selectedTags.join(', ')} ${feedbackController.text}".trim();
                      orderProv.addRating(orderId, selectedRating, fullFeedback);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Thank you for your rating! ⭐"), backgroundColor: BentoTheme.pingzoGreen),
                      );
                    },
                    child: const Text("Submit Feedback", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
