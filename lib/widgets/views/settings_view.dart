import 'package:flutter/material.dart';
import '../../services/inventory_store.dart';
import '../../theme/app_colors.dart';

class SettingsView extends StatefulWidget {
  final InventoryStore store;

  const SettingsView({
    super.key,
    required this.store,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late TextEditingController _storeNameCtrl;
  late TextEditingController _taglineCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _taxRateCtrl;
  late TextEditingController _serviceFeeCtrl;
  late TextEditingController _thresholdCtrl;

  late bool _taxEnabled;
  late bool _serviceFeeEnabled;
  late String _printerName;
  late String _paperWidth;
  late bool _autoPrintReceipt;
  late bool _soundAlerts;
  late bool _lowStockNotif;
  late bool _dailyReportEmail;
  late String _language;

  @override
  void initState() {
    super.initState();
    final s = widget.store.settings;
    _storeNameCtrl = TextEditingController(text: s.storeName);
    _taglineCtrl = TextEditingController(text: s.storeTagline);
    _emailCtrl = TextEditingController(text: s.email);
    _phoneCtrl = TextEditingController(text: s.phone);
    _addressCtrl = TextEditingController(text: s.address);
    _taxRateCtrl = TextEditingController(text: s.taxRate.toStringAsFixed(0));
    _serviceFeeCtrl = TextEditingController(text: s.serviceFeeRate.toStringAsFixed(0));
    _thresholdCtrl = TextEditingController(text: s.lowStockThreshold.toString());

    _taxEnabled = s.taxEnabled;
    _serviceFeeEnabled = s.serviceFeeEnabled;
    _printerName = s.printerName;
    _paperWidth = s.paperWidth;
    _autoPrintReceipt = s.autoPrintReceipt;
    _soundAlerts = s.soundAlerts;
    _lowStockNotif = s.lowStockNotification;
    _dailyReportEmail = s.dailyReportEmail;
    _language = s.language;
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _taglineCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _taxRateCtrl.dispose();
    _serviceFeeCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  void _saveAllSettings() {
    final updated = widget.store.settings.copyWith(
      storeName: _storeNameCtrl.text.trim(),
      storeTagline: _taglineCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      taxRate: double.tryParse(_taxRateCtrl.text) ?? 11.0,
      taxEnabled: _taxEnabled,
      serviceFeeRate: double.tryParse(_serviceFeeCtrl.text) ?? 5.0,
      serviceFeeEnabled: _serviceFeeEnabled,
      printerName: _printerName,
      paperWidth: _paperWidth,
      autoPrintReceipt: _autoPrintReceipt,
      soundAlerts: _soundAlerts,
      lowStockThreshold: int.tryParse(_thresholdCtrl.text) ?? 20,
      lowStockNotification: _lowStockNotif,
      dailyReportEmail: _dailyReportEmail,
      language: _language,
    );

    widget.store.updateSettings(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semua konfigurasi sistem dan toko berhasil disimpan!'),
        backgroundColor: AppColors.cardDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Toolbar Header
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
                    'Pengaturan Sistem & Toko',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Profil usaha, PPN 11%, printer POS kasir, dan notifikasi stok',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _saveAllSettings,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                label: const Text('Simpan Perubahan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cardDark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 2. Section: Profil Usaha
          _buildSettingsCard(
            title: 'Profil Bisnis & Perusahaan',
            icon: Icons.business_rounded,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _storeNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Bisnis / Brand *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: _taglineCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Slogan / Tagline Usaha',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Email Resmi *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Telepon / WhatsApp CS *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Alamat Kantor Pusat (Tercetak di Struk Kasir)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 3. Section: Pajak & Biaya Layanan
          _buildSettingsCard(
            title: 'Pajak (PPN) & Biaya Layanan',
            icon: Icons.receipt_long_rounded,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Aktifkan PPN (Pajak Pertambahan Nilai)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Otomatis menghitung pajak pada setiap transaksi POS kasir',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                value: _taxEnabled,
                activeTrackColor: AppColors.cardDark,
                onChanged: (val) => setState(() => _taxEnabled = val),
              ),
              if (_taxEnabled) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: TextField(
                        controller: _taxRateCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tarif PPN (%)',
                          suffixText: '%',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Tarif standar Indonesia berlaku saat ini: 11% (UU HPP No. 7 Tahun 2021)',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ],
              const Divider(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Aktifkan Biaya Layanan (Service Charge)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Tambahan biaya operasional (opsional untuk kafe/resto)',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                value: _serviceFeeEnabled,
                activeTrackColor: AppColors.cardDark,
                onChanged: (val) => setState(() => _serviceFeeEnabled = val),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 4. Section: Printer Thermal Kasir
          _buildSettingsCard(
            title: 'Perangkat Keras & Printer Kasir',
            icon: Icons.print_rounded,
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _printerName,
                decoration: const InputDecoration(
                  labelText: 'Model Printer Thermal Terpasang',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  'Epson TM-T82X (Thermal)',
                  'Panda POS Thermal 80mm (Bluetooth)',
                  'Iware Portable 58mm (Bluetooth)',
                  'Star Micronics TSP143III (LAN)',
                ].map((p) => DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _printerName = val);
                },
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lebar Kertas',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: ['80mm', '58mm'].map((width) {
                      final isSelected = _paperWidth == width;
                      return ChoiceChip(
                        label: Text(width),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _paperWidth = width),
                        selectedColor: AppColors.cardDark,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Cetak Struk Otomatis Setelah Pembayaran Sukses',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Printer langsung memotong kertas (Auto-Cut) setelah struk tercetak',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                value: _autoPrintReceipt,
                activeTrackColor: AppColors.cardDark,
                onChanged: (val) => setState(() => _autoPrintReceipt = val),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Mengirim test print struk ke $_printerName ($_paperWidth)... Berhasil!'),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_rounded, size: 14),
                label: const Text('Test Cetak Struk Sampel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cardDark,
                  side: const BorderSide(color: AppColors.cardBorder),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 5. Section: Notifikasi & AI Memory Engine
          _buildSettingsCard(
            title: 'Notifikasi & Batas Peringatan Stok',
            icon: Icons.notifications_active_rounded,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 170,
                    child: TextField(
                      controller: _thresholdCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Ambang Stok Kritis',
                        suffixText: 'Unit',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const Text(
                    'AI Memory Engine akan otomatis memunculkan rekomendasi restock jika stok di bawah ambang batas ini.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Notifikasi Banner Stok Kritis di Dashboard',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                value: _lowStockNotif,
                activeTrackColor: AppColors.cardDark,
                onChanged: (val) => setState(() => _lowStockNotif = val),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Kirim Rekap Laporan Penjualan Harian via Email',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                value: _dailyReportEmail,
                activeTrackColor: AppColors.cardDark,
                onChanged: (val) => setState(() => _dailyReportEmail = val),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Suara Peringatan Kasir & Scan Barcode',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                value: _soundAlerts,
                activeTrackColor: AppColors.cardDark,
                onChanged: (val) => setState(() => _soundAlerts = val),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.brandLime.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.cardDark),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
      ),
    );
  }
}
