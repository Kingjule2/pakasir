import 'package:flutter/material.dart';
import '../../models/help_models.dart';
import '../../services/inventory_store.dart';
import '../../theme/app_colors.dart';

class HelpView extends StatefulWidget {
  final InventoryStore store;
  final VoidCallback onOpenSupri;

  const HelpView({
    super.key,
    required this.store,
    required this.onOpenSupri,
  });

  @override
  State<HelpView> createState() => _HelpViewState();
}

class _HelpViewState extends State<HelpView> {
  String _selectedCategory = 'Semua';
  String _faqSearch = '';

  @override
  Widget build(BuildContext context) {
    final faqs = widget.store.faqs.where((faq) {
      final matchCat = _selectedCategory == 'Semua' || faq.category == _selectedCategory;
      final matchSearch = _faqSearch.isEmpty ||
          faq.question.toLowerCase().contains(_faqSearch.toLowerCase()) ||
          faq.answer.toLowerCase().contains(_faqSearch.toLowerCase());
      return matchCat && matchSearch;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero Search & Contact Banner
          _buildHeroBanner(context),

          const SizedBox(height: 20),

          // 2. 4 Quick Topic Guides
          _buildTopicGuides(context),

          const SizedBox(height: 20),

          // 3. Middle Section: FAQ Accordion
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pertanyaan Umum (FAQ)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Jawaban cepat untuk pertanyaan yang sering diajukan',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateTicketDialog(context),
                      icon: const Icon(Icons.support_agent_rounded, size: 14),
                      label: const Text('Buat Tiket Bantuan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardDark,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Category Filter Pills
                _buildFaqFilterBar(),

                const SizedBox(height: 16),

                // FAQ Accordions
                if (faqs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Tidak ada FAQ yang cocok dengan pencarian.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: faqs.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = faqs[index];
                      return Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(bottom: 12),
                          title: Text(
                            item.question,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              item.category,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                item.answer,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          ),

          const SizedBox(height: 20),

          // 4. Support Tickets History Card
          _buildTicketsHistoryCard(context),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandLime.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.help_center_rounded,
                  size: 20,
                  color: AppColors.brandLime,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pusat Bantuan & Dukungan Teknis Vault',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Butuh bantuan seputar stok, integrasi kasir, atau konfigurasi Supri AI?',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMutedOnDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search box inside banner
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _faqSearch = val),
              style: const TextStyle(fontSize: 12.5),
              decoration: const InputDecoration(
                hintText: 'Ketik kata kunci kendala (misal: restock, printer, kasir, PPN)...',
                hintStyle: TextStyle(fontSize: 12, color: AppColors.textLight),
                prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicGuides(BuildContext context) {
    final topics = [
      {
        'title': 'Restock Otomatis',
        'desc': 'Panduan AI Memory Engine mendeteksi stok kritis',
        'icon': Icons.bolt_rounded,
        'color': AppColors.brandLime,
      },
      {
        'title': 'Printer & Kasir',
        'desc': 'Setting thermal 58mm/80mm Bluetooth & USB',
        'icon': Icons.print_rounded,
        'color': AppColors.statusInfo,
      },
      {
        'title': 'Pajak & Finansial',
        'desc': 'Konfigurasi PPN 11% dan ekspor laporan resmi',
        'icon': Icons.receipt_long_rounded,
        'color': const Color(0xFFEAB308),
      },
      {
        'title': 'Tanya Supri AI',
        'desc': 'Perintah suara, cek laba rugi & ide konten TikTok',
        'icon': Icons.smart_toy_rounded,
        'color': AppColors.supriOrange,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth = constraints.maxWidth > 850
            ? (constraints.maxWidth - 3 * 14) / 4
            : (constraints.maxWidth - 14) / 2;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: topics.map((t) {
            final color = t['color'] as Color;
            return SizedBox(
              width: itemWidth,
              child: InkWell(
                onTap: () {
                  if (t['title'] == 'Tanya Supri AI') {
                    widget.onOpenSupri();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Membuka panduan: ${t['title']}')),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(t['icon'] as IconData, size: 18, color: color),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        t['title'] as String,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        t['desc'] as String,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFaqFilterBar() {
    final categories = [
      'Semua',
      'Inventaris & Stok',
      'AI Supri Assistant',
      'Kasir & POS',
      'Pajak & Laporan',
      'Perangkat & Printer',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedCategory = cat),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.cardDark : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTicketsHistoryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiket Bantuan Aktif',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          const Text(
            'Pantau status penanganan kendala teknis oleh tim engineering Vault',
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.store.tickets.length,
            separatorBuilder: (context, index) => const Divider(height: 14),
            itemBuilder: (context, index) {
              final t = widget.store.tickets[index];
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      t.id,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.subject,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Kategori: ${t.category} • Dibuat: ${t.date}',
                          style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: t.status == 'Selesai'
                          ? AppColors.statusSuccessBg
                          : AppColors.statusWarningBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      t.status,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: t.status == 'Selesai'
                            ? AppColors.statusSuccess
                            : AppColors.statusWarning,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCreateTicketDialog(BuildContext context) {
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String category = 'Hardware & EDC';
    String priority = 'Sedang';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text(
              'Buat Tiket Bantuan Teknis',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: subjectCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Judul Kendala *',
                        hintText: 'Misal: Kertas printer kasir tidak keluar',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Kategori Masalah'),
                      items: ['Hardware & EDC', 'Sinkronisasi Stok', 'Akun & Akses', 'Laporan & Pajak']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => category = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: priority,
                      decoration: const InputDecoration(labelText: 'Prioritas Kendala'),
                      items: ['Rendah', 'Sedang', 'Tinggi']
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => priority = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: messageCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Detail Deskripsi *',
                        hintText: 'Jelaskan kronologi kendala secara lengkap...',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () {
                  if (subjectCtrl.text.trim().isEmpty) return;
                  final newTicket = SupportTicket(
                    id: 'TCK-${DateTime.now().year}-${100 + widget.store.tickets.length}',
                    subject: subjectCtrl.text.trim(),
                    category: category,
                    status: 'Menunggu',
                    priority: priority,
                    date: 'Hari ini',
                  );
                  widget.store.submitSupportTicket(newTicket);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tiket #${newTicket.id} berhasil dikirim ke tim support.')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cardDark,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Kirim Tiket'),
              ),
            ],
          );
        },
      ),
    );
  }
}
