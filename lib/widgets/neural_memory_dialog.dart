import 'package:flutter/material.dart';
import '../services/memory_engine.dart';
import '../theme/app_colors.dart';

class NeuralMemoryDialog extends StatefulWidget {
  const NeuralMemoryDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const NeuralMemoryDialog(),
    );
  }

  @override
  State<NeuralMemoryDialog> createState() => _NeuralMemoryDialogState();
}

class _NeuralMemoryDialogState extends State<NeuralMemoryDialog> {
  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final memories = MemoryEngine.activeMemories.where((m) {
      final matchCat = _selectedCategory == 'Semua' ||
          _mapCategoryName(m.type) == _selectedCategory;
      final matchSearch = _searchQuery.isEmpty ||
          m.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.type.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.brandLime.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: AppColors.cardDark,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Neural Memory Engine Inspector',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pusat memori semantik & aturan bisnis yang dipelajari AI Supri (Arsitektur aibrain)',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Tutup',
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 2. Toolbar: Search + Category Pills + Add Memory
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Search Box
                  SizedBox(
                    width: 220,
                    height: 38,
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Cari memori...',
                        hintStyle: const TextStyle(fontSize: 11.5, color: AppColors.textLight),
                        prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                        isDense: true,
                      ),
                    ),
                  ),

                  // Filter Pills
                  Wrap(
                    spacing: 6,
                    children: [
                      'Semua',
                      'Batasan Bisnis',
                      'Keputusan',
                      'Pola Penjualan',
                      'Strategi Marketing',
                      'Preferensi',
                    ].map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return InkWell(
                        onTap: () => setState(() => _selectedCategory = cat),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      );
                    }).toList(),
                  ),

                  // Add New Memory Button
                  ElevatedButton.icon(
                    onPressed: _showTrainMemoryModal,
                    icon: const Icon(Icons.add_rounded, size: 14),
                    label: const Text('Latih Memori Baru'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandLime,
                      foregroundColor: AppColors.cardDark,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // 3. Memories List
              Expanded(
                child: memories.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada memori yang cocok dengan pencarian.',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      )
                    : ListView.separated(
                        itemCount: memories.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final mem = memories[index];
                          final typeColor = _getTypeColor(mem.type);

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: typeColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        mem.type.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: typeColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE5E7EB),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Penting: ${mem.importance}/10',
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Akurasi: ${(mem.confidence * 100).toInt()}%',
                                      style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  mem.content,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTrainMemoryModal() {
    final textCtrl = TextEditingController();
    String selectedType = 'marketing_rule';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            title: const Text(
              'Latih Aturan / Memori Baru',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'Tipe Memori'),
                    items: const [
                      DropdownMenuItem(value: 'constraint', child: Text('Batasan Bisnis (Constraint)')),
                      DropdownMenuItem(value: 'decision', child: Text('Keputusan Strategis (Decision)')),
                      DropdownMenuItem(value: 'sales_pattern', child: Text('Pola Penjualan (Sales Pattern)')),
                      DropdownMenuItem(value: 'marketing_rule', child: Text('Strategi Pemasaran (Marketing Rule)')),
                      DropdownMenuItem(value: 'preference', child: Text('Preferensi Owner (Preference)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedType = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: textCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Isi Pengetahuan / Aturan Baru *',
                      hintText: 'Misal: Setiap pembelian di atas Rp 200.000 berikan kupon undian bulanan...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () {
                  if (textCtrl.text.trim().isEmpty) return;
                  MemoryEngine.recordMemory(
                    textCtrl.text.trim(),
                    type: selectedType,
                    importance: 8,
                  );
                  Navigator.pop(ctx);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Aturan baru berhasil dilatih dan disimpan ke Neural Memory Engine!'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cardDark,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Simpan ke Memory Engine'),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _mapCategoryName(String type) {
    switch (type) {
      case 'constraint':
        return 'Batasan Bisnis';
      case 'decision':
        return 'Keputusan';
      case 'sales_pattern':
        return 'Pola Penjualan';
      case 'marketing_rule':
        return 'Strategi Marketing';
      case 'preference':
        return 'Preferensi';
      default:
        return 'Semua';
    }
  }

  static Color _getTypeColor(String type) {
    switch (type) {
      case 'constraint':
        return AppColors.statusDanger;
      case 'decision':
        return AppColors.supriPurple;
      case 'sales_pattern':
        return AppColors.statusInfo;
      case 'marketing_rule':
        return AppColors.statusSuccess;
      case 'preference':
        return const Color(0xFFEAB308);
      default:
        return AppColors.textSecondary;
    }
  }
}
