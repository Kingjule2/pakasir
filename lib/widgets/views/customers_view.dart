import 'package:flutter/material.dart';
import '../../models/customer_item.dart';
import '../../services/inventory_store.dart';
import '../../theme/app_colors.dart';

class CustomersView extends StatelessWidget {
  final InventoryStore store;

  const CustomersView({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    final customers = store.filteredCustomers;
    final totalSpentSum = store.customers.fold<double>(
      0,
      (sum, c) => sum + c.totalSpent,
    );
    final vipCount = store.customers.where((c) => c.tier == 'VIP').length;
    final totalOrdersSum = store.customers.fold<int>(
      0,
      (sum, c) => sum + c.totalOrders,
    );
    final avgOrderPerCustomer = store.customers.isNotEmpty
        ? (totalOrdersSum / store.customers.length).toStringAsFixed(1)
        : '0';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. KPI Cards for Customers
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
                    child: _buildCrmKpiCard(
                      title: 'Total Pelanggan',
                      value: '${store.customers.length}',
                      subtitle: 'Database terverifikasi',
                      icon: Icons.people_outline_rounded,
                      color: AppColors.cardDark,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildCrmKpiCard(
                      title: 'Pelanggan VIP',
                      value: '$vipCount',
                      subtitle: 'Loyalitas belanja tinggi',
                      icon: Icons.star_rounded,
                      color: const Color(0xFFEAB308),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildCrmKpiCard(
                      title: 'Akumulasi Belanja',
                      value: 'Rp ${_formatRupiah(totalSpentSum)}',
                      subtitle: 'Lifetime customer value',
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppColors.statusSuccess,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildCrmKpiCard(
                      title: 'Rata-rata Order',
                      value: '$avgOrderPerCustomer Pesanan',
                      subtitle: 'Per pelanggan aktif',
                      icon: Icons.shopping_bag_outlined,
                      color: AppColors.statusInfo,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // 2. Main Customers Table Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toolbar: Search, Filters & Add Button
                _buildToolbar(context),

                const SizedBox(height: 18),

                // Table / List of Customers
                if (customers.isEmpty)
                  _buildEmptyState()
                else
                  _buildCustomerTable(context, customers),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrmKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 17, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final tiers = ['Semua', 'VIP', 'Wholesale', 'Regular', 'Baru'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 750;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Direktori Pelanggan & CRM',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Kelola profil, riwayat belanja, dan segmentasi loyalty member',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddCustomerDialog(context),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 15),
                  label: const Text('Tambah Pelanggan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Search Input
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isNarrow ? double.infinity : 260,
                    minWidth: 180,
                  ),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: TextField(
                      onChanged: store.setCustomerSearchQuery,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        hintText: 'Cari nama, email, kota...',
                        hintStyle: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textLight,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ),

                // Tier Filter Pills
                Wrap(
                  spacing: 6,
                  children: tiers.map((tier) {
                    final isSelected = store.selectedCustomerTier == tier;
                    return InkWell(
                      onTap: () => store.setSelectedCustomerTier(tier),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.cardDark
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tier,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCustomerTable(
    BuildContext context,
    List<CustomerItem> customers,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 750) {
          // Mobile / Narrow Card View
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: customers.length,
            separatorBuilder: (context, index) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final c = customers[index];
              return _buildCustomerMobileCard(context, c);
            },
          );
        }

        // Desktop Table View
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 56,
              dataRowMaxHeight: 64,
              horizontalMargin: 8,
              columnSpacing: 20,
              columns: const [
                DataColumn(
                  label: Text(
                    'PELANGGAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'TIER / STATUS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'KONTAK & KOTA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'TOTAL TRANSAKSI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'AKTIVITAS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'AKSI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
              rows: customers.map((c) {
                return DataRow(
                  cells: [
                    // Name & Email
                    DataCell(
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: _getTierColor(c.tier).withValues(alpha: 0.15),
                            child: Text(
                              _getInitials(c.name),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _getTierColor(c.tier),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                c.name,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                c.email,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Tier & Status
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _getTierColor(c.tier).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              c.tier,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: _getTierColor(c.tier),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: c.status == 'Aktif'
                                  ? AppColors.statusSuccess
                                  : AppColors.textLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Phone & City
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            c.phone,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            c.city,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Orders & Spending
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Rp ${_formatRupiah(c.totalSpent)}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${c.totalOrders} Pesanan',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Last active
                    DataCell(
                      Text(
                        c.lastActive,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    // Actions
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            tooltip: 'Lihat Detail',
                            onPressed: () => _showCustomerDetailDialog(context, c),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            tooltip: 'Edit Data',
                            onPressed: () => _showEditCustomerDialog(context, c),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: AppColors.statusDanger,
                            ),
                            tooltip: 'Hapus Pelanggan',
                            onPressed: () => _confirmDeleteCustomer(context, c),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomerMobileCard(BuildContext context, CustomerItem c) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              CircleAvatar(
                radius: 16,
                backgroundColor: _getTierColor(c.tier).withValues(alpha: 0.15),
                child: Text(
                  _getInitials(c.name),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _getTierColor(c.tier),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${c.email} • ${c.phone}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _getTierColor(c.tier).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  c.tier,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _getTierColor(c.tier),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${c.totalOrders} Pesanan • Rp ${_formatRupiah(c.totalSpent)}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    onPressed: () => _showCustomerDetailDialog(context, c),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    onPressed: () => _showEditCustomerDialog(context, c),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 40,
              color: AppColors.textLight,
            ),
            SizedBox(height: 10),
            Text(
              'Tidak ada pelanggan ditemukan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Coba ubah kata kunci pencarian atau filter kategori tier.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String selectedTier = 'Regular';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text(
              'Tambah Pelanggan Baru',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap *',
                        hintText: 'Contoh: Rian Anggara',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Alamat Email',
                        hintText: 'rian@gmail.com',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nomor WhatsApp / HP *',
                        hintText: '+62 812-xxxx-xxxx',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Kota Domisili',
                        hintText: 'Jakarta Selatan',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedTier,
                      decoration: const InputDecoration(labelText: 'Tier Keanggotaan'),
                      items: ['Regular', 'VIP', 'Wholesale', 'Baru']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedTier = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Khusus',
                        hintText: 'Preferensi produk, alamat kirim, dll.',
                      ),
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
                  final newCustomer = CustomerItem(
                    id: 'cust-${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim().isEmpty
                        ? 'pelanggan@mail.com'
                        : emailCtrl.text.trim(),
                    phone: phoneCtrl.text.trim().isEmpty
                        ? '+62 812-0000-0000'
                        : phoneCtrl.text.trim(),
                    tier: selectedTier,
                    totalOrders: 0,
                    totalSpent: 0,
                    lastActive: 'Baru saja',
                    status: 'Aktif',
                    city: cityCtrl.text.trim().isEmpty
                        ? 'Jakarta'
                        : cityCtrl.text.trim(),
                    notes: notesCtrl.text.trim(),
                  );
                  store.addCustomer(newCustomer);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pelanggan "${newCustomer.name}" berhasil ditambahkan!'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cardDark,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Simpan Pelanggan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditCustomerDialog(BuildContext context, CustomerItem customer) {
    final nameCtrl = TextEditingController(text: customer.name);
    final emailCtrl = TextEditingController(text: customer.email);
    final phoneCtrl = TextEditingController(text: customer.phone);
    final cityCtrl = TextEditingController(text: customer.city);
    String selectedTier = customer.tier;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(
              'Edit Data: ${customer.name}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cityCtrl,
                      decoration: const InputDecoration(labelText: 'Kota'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedTier,
                      decoration: const InputDecoration(labelText: 'Tier Keanggotaan'),
                      items: ['Regular', 'VIP', 'Wholesale', 'Baru']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedTier = val);
                        }
                      },
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
                  final updated = customer.copyWith(
                    name: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    city: cityCtrl.text.trim(),
                    tier: selectedTier,
                  );
                  store.updateCustomer(updated);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perubahan data pelanggan berhasil disimpan!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cardDark,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCustomerDetailDialog(BuildContext context, CustomerItem customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _getTierColor(customer.tier).withValues(alpha: 0.15),
              child: Text(
                _getInitials(customer.name),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _getTierColor(customer.tier),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Member ${customer.tier} • ${customer.status}',
                    style: TextStyle(fontSize: 11, color: _getTierColor(customer.tier)),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Email', customer.email),
              _buildDetailRow('Telepon', customer.phone),
              _buildDetailRow('Kota Domisili', customer.city),
              _buildDetailRow('Total Belanja', 'Rp ${_formatRupiah(customer.totalSpent)}'),
              _buildDetailRow('Frekuensi Order', '${customer.totalOrders} kali transaksi'),
              _buildDetailRow('Aktivitas Terakhir', customer.lastActive),
              if (customer.notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'Catatan CRM:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  customer.notes,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCustomer(BuildContext context, CustomerItem customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pelanggan?'),
        content: Text('Apakah Anda yakin ingin menghapus pelanggan "${customer.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              store.deleteCustomer(customer.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Pelanggan "${customer.name}" telah dihapus.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  static Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  static Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'vip':
        return const Color(0xFFEAB308);
      case 'wholesale':
        return AppColors.supriPurple;
      case 'baru':
        return AppColors.supriOrange;
      default:
        return AppColors.statusInfo;
    }
  }

  static String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.isNotEmpty && parts[0].isNotEmpty
        ? parts[0][0].toUpperCase()
        : 'U';
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
