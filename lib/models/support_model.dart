class FaqItem {
  final String category;
  final String question;
  final String answer;

  FaqItem({
    required this.category,
    required this.question,
    required this.answer,
  });
}

class SupportTicket {
  final String id;
  final String category;
  final String subject;
  final String description;
  final String status; // 'OPEN', 'IN_PROGRESS', 'RESOLVED'
  final DateTime createdAt;

  SupportTicket({
    required this.id,
    required this.category,
    required this.subject,
    required this.description,
    required this.status,
    required this.createdAt,
  });
}
