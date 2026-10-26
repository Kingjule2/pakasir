import 'package:flutter/material.dart';
import '../../models/store_outlet.dart';
import '../../services/inventory_store.dart';
import '../../theme/app_colors.dart';

class StoreView extends StatelessWidget {
  final InventoryStore store;
  final VoidCallback onNavigateToInventory;

  const StoreView({
    super.key,
    required this.store,
    required this.onNavigateToInventory,
  });

  @override
  Widget build(BuildContext context) {
    final outlets = store.outlets;
    final openCount = outlets.where((o) => o.isOpen).length;
    final totalTerminals = outlets.fold<int>(0, (sum, o) => sum + o.terminalsCount);
    final totalStaff = outlets.fold<int>(0, (sum, o) => sum + o.staffCount);
    final totalDailySales = outlets.fold<double>(
      0,
      (sum, o) => sum + (o.isOpen ? o.dailySales : 0),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. KPI Cards for Stores
          LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth = constraints.maxWidth > 850
                  ? (constraints.maxWidth - 3 * 14) / 4
                  : (constraints.maxWidth - 14) / 2;

              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _buildStoreKpiCard(
                      title: 'Status Operasional',
                      value: '$openCount / ${outlets.length} Buka',
                      subtitle: 'Cabang aktif melayani',
                      icon: Icons.storefront_rounded,
                      color: AppColors.statusSuccess,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildStoreKpiCard(
                      title: 'Terminal POS Kasir',
                      value: '$totalTerminals Mesin',
                      subtitle: 'Register terintegrasi cloud',
                      icon: Icons.point_of_sale_rounded,
                      color: AppColors.cardDark,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildStoreKpiCard(
                      title: 'Omset Multi-Cabang',
                      value: 'Rp ${_formatRupiah(totalDailySales)}',
                      subtitle: 'Total hari ini (Live)',
                      icon: Icons.payments_outlined,
                      color: AppColors.brandLime,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildStoreKpiCard(
                      title: 'Total Karyawan',
                      value: '$totalStaff Staff',
                      subtitle: 'Kasir & operasional toko',
                      icon: Icons.badge_outlined,
                      color: AppColors.statusInfo,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // 2. Toolbar & Section Title
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
                    'Daftar Cabang & Outlet Toko',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Kelola jam operasional, buka/tutup cabang, dan kasir',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddStoreDialog(context),
                icon: const Icon(Icons.add_business_rounded, size: 14),
                label: const Text('Tambah Cabang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cardDark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3. Grid of Store Outlet Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth = constraints.maxWidth > 900
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: outlets.map((outlet) {
                  return SizedBox(
                    width: cardWidth,
                    child: _buildOutletCard(context, outlet),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStoreKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutletCard(BuildContext context, StoreOutlet outlet) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: outlet.isOpen
              ? AppColors.cardBorder
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Outlet Header: Code, Name, Open/Close Switch
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandLime.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  outlet.code,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.cardDark,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outlet.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${outlet.city} • ${outlet.address}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status Toggle Button
              InkWell(
                onTap: () {
                  store.toggleStoreStatus(outlet.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Status ${outlet.name} diubah menjadi: ${!outlet.isOpen ? 'BUKA' : 'TUTUP'}',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: outlet.isOpen
                        ? AppColors.statusSuccessBg
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: outlet.isOpen
                          ? AppColors.statusSuccess.withValues(alpha: 0.4)
                          : const Color(0xFFD1D5DB),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: outlet.isOpen
                              ? AppColors.statusSuccess
                              : AppColors.textLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        outlet.isOpen ? 'Toko Buka' : 'Tutup',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: outlet.isOpen
                              ? AppColors.statusSuccess
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Detail Info: Manager & Operating Hours
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Manager: ${outlet.manager}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      outlet.operatingHours,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 4 Metric Badges: Daily Sales, Monthly Sales, Terminals, Staff
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Wrap(
              spacing: 14,
              runSpacing: 8,
              alignment: WrapAlignment.spaceAround,
              children: [
                _buildOutletStat('Omset Harian', 'Rp ${_formatRupiah(outlet.dailySales)}'),
                _buildOutletStat('Omset Bulanan', 'Rp ${_formatRupiah(outlet.monthlySales)}'),
                _buildOutletStat('Mesin POS', '${outlet.terminalsCount} Terminal'),
                _buildOutletStat('Staff Aktif', '${outlet.staffCount} Orang'),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Menghubungkan ke ${outlet.terminalsCount} Terminal POS di ${outlet.name}...'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.point_of_sale_rounded, size: 14),
                  label: const Text('Buka Kasir POS'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.cardDark,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onNavigateToInventory,
                  icon: const Icon(Icons.inventory_2_outlined, size: 14),
                  label: const Text('Cek Stok Cabang'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutletStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showAddStoreDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final managerCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final hoursCtrl = TextEditingController(text: '09:00 - 22:00 WIB');
    final terminalsCtrl = TextEditingController(text: '2');
    final staffCtrl = TextEditingController(text: '4');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Tambah Cabang Toko Baru',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Cabang *',
                    hintText: 'Contoh: Vault Store Mall Kelapa Gading',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: codeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Kode Toko *',
                          hintText: 'MKG-05',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: cityCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Kota *',
                          hintText: 'Jakarta Utara',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Alamat Lengkap',
                    hintText: 'Mall Kelapa Gading 3 Lt. Dasar Unit 22',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: managerCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nama Store Manager',
                          hintText: 'Rizky Ramadhan',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Telepon Toko',
                          hintText: '+62 812-7777-9999',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: hoursCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Jam Operasional',
                    hintText: '10:00 - 22:00 WIB',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: terminalsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Jumlah Terminal POS',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: staffCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Jumlah Staff',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              final newOutlet = StoreOutlet(
                id: 'store-${DateTime.now().millisecondsSinceEpoch}',
                name: nameCtrl.text.trim(),
                code: codeCtrl.text.trim().isEmpty ? 'NEW-01' : codeCtrl.text.trim(),
                city: cityCtrl.text.trim().isEmpty ? 'Jakarta' : cityCtrl.text.trim(),
                address: addressCtrl.text.trim().isEmpty ? 'Jl. Raya' : addressCtrl.text.trim(),
                manager: managerCtrl.text.trim().isEmpty ? 'Manager' : managerCtrl.text.trim(),
                phone: phoneCtrl.text.trim().isEmpty ? '+62 812-0000-0000' : phoneCtrl.text.trim(),
                operatingHours: hoursCtrl.text.trim(),
                isOpen: true,
                terminalsCount: int.tryParse(terminalsCtrl.text) ?? 2,
                dailySales: 0,
                monthlySales: 0,
                staffCount: int.tryParse(staffCtrl.text) ?? 3,
              );
              store.addStoreOutlet(newOutlet);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cabang "${newOutlet.name}" berhasil ditambahkan!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardDark,
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan Cabang'),
          ),
        ],
      ),
    );
  }

  static String _formatRupiah(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)} M';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} Jt';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} Rb';
    }
    return amount.toStringAsFixed(0);
  }
}
