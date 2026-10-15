class FaqItem {
  final String id;
  final String category;
  final String question;
  final String answer;

  const FaqItem({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
  });
}

class SupportTicket {
  final String id;
  final String subject;
  final String category;
  final String status; // 'Menunggu', 'Diproses', 'Selesai'
  final String priority; // 'Tinggi', 'Sedang', 'Rendah'
  final String date;

  const SupportTicket({
    required this.id,
    required this.subject,
    required this.category,
    required this.status,
    required this.priority,
    required this.date,
  });
}
