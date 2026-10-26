import 'package:flutter/material.dart';
import '../../models/inventory_item.dart';
import '../../services/inventory_store.dart';
import '../../theme/app_colors.dart';

class PosCashierView extends StatefulWidget {
  final InventoryStore store;

  const PosCashierView({super.key, required this.store});

  @override
  State<PosCashierView> createState() => _PosCashierViewState();
}

class _PosCashierViewState extends State<PosCashierView> {
  String _search = '';
  String _paymentMethod = 'Cash';
  final String _selectedCustomer = 'Walk-in Customer';
  final double _discount = 0;
  double? _cashTendered;
  Map<String, dynamic>? _lastReceipt;

  InventoryStore get store => widget.store;

  double get _subtotal {
    double sum = 0;
    for (final entry in store.cartQuantities.entries) {
      final item = store.allItems.where((i) => i.id == entry.key).firstOrNull;
      if (item != null) {
        sum += item.price * entry.value;
      }
    }
    return sum;
  }

  double get _taxable => (_subtotal - _discount) < 0 ? 0 : (_subtotal - _discount);
  double get _taxAmount => store.settings.taxEnabled ? (_taxable * store.settings.taxRate / 100.0) : 0;
  double get _grandTotal => _taxable + _taxAmount;

  void _openBarcodeScanner(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: AppColors.primaryNavy),
            SizedBox(width: 8),
            Expanded(
              child: Text('Kamera Scan Barcode / QR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pindai kode EAN-13 / Code 128 / QR atau pilih SKU katalog:'),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Masukkan kode SKU (contoh: SKU-300)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: store.allItems.take(4).map((item) {
                return ActionChip(
                  label: Text('${item.sku} · ${item.name}', style: const TextStyle(fontSize: 11)),
                  onPressed: () {
                    store.addToCart(item);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Barcode ${item.sku} (${item.name}) ditambahkan ke keranjang!')),
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
          ElevatedButton(
            onPressed: () {
              final q = controller.text.trim().toLowerCase();
              final match = store.allItems.where((i) => i.sku.toLowerCase() == q || i.name.toLowerCase().contains(q)).firstOrNull;
              Navigator.pop(ctx);
              if (match != null) {
                store.addToCart(match);
              } else {
                setState(() => _search = controller.text.trim());
              }
            },
            child: const Text('Proses Barcode'),
          ),
        ],
      ),
    );
  }

  void _showReceiptDialog(BuildContext context, Map<String, dynamic> receipt) {
    final escPosText = store.formatEscPosReceipt(receipt);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Struk Thermal (${store.settings.paperWidth})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.appBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Text(
              escPosText,
              style: const TextStyle(fontFamily: 'Courier New', fontSize: 11),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Struk dikirim ke Bluetooth Thermal Printer (ESC/POS)!')),
              );
            },
            child: const Text('Cetak Struk Thermal (ESC/POS)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tautan struk WhatsApp siap dikirim ke pelanggan!')),
              );
            },
            child: const Text('Kirim Struk via WhatsApp', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = store.allItems.where((item) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return item.name.toLowerCase().contains(q) || item.sku.toLowerCase().contains(q);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Terminal Kasir POS (Fast Checkout)',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pencarian cepat, scan barcode kamera, multi-pembayaran (Cash/QRIS/EDC), & cetak struk Bluetooth.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    selected: store.isOfflineMode,
                    label: Text(store.isOfflineMode ? 'Offline Queue (${store.offlineQueue.length})' : 'Online Mode'),
                    onSelected: (v) => store.setOfflineMode(v),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openBarcodeScanner(context),
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                    label: const Text('Scan Barcode'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Cari nama atau SKU produk kasir...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: items.map((InventoryItem item) {
              final out = item.stockIn <= 0 || item.isOutOfStock;
              return InkWell(
                onTap: out ? null : () => store.addToCart(item),
                child: Container(
                  width: 155,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: out ? Colors.grey.shade100 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          Text(item.sku, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: out ? AppColors.statusDangerBg : AppColors.statusSuccessBg,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              out ? 'Out of Stock' : '${item.stockIn} unit',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: out ? AppColors.statusDanger : AppColors.statusSuccess,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text('Rp ${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryNavy)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Keranjang Belanja (${store.cartQuantities.values.fold<int>(0, (a, b) => a + b)} Item)',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    DropdownButton<String>(
                      isDense: true,
                      value: _paymentMethod,
                      items: const [
                        DropdownMenuItem(value: 'Cash', child: Text('Tunai (Cash)', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'QRIS', child: Text('QRIS Dinamis', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'EDC', child: Text('Mesin EDC / Kartu', style: TextStyle(fontSize: 12))),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _paymentMethod = v);
                      },
                    ),
                  ],
                ),
                const Divider(),
                if (store.cartQuantities.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Keranjang kosong. Ketuk produk di atas untuk mulai checkout.', style: TextStyle(color: AppColors.textSecondary)),
                  )
                else
                  ...store.cartQuantities.entries.map((entry) {
                    final prod = store.allItems.where((i) => i.id == entry.key).firstOrNull;
                    if (prod == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('${prod.name} (${entry.value}x Rp ${prod.price.toStringAsFixed(0)})')),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 18),
                                onPressed: () => store.updateCartQuantity(prod.id, entry.value - 1),
                              ),
                              Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.w700)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 18),
                                onPressed: () => store.updateCartQuantity(prod.id, entry.value + 1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                if (_paymentMethod == 'Cash' && store.cartQuantities.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ActionChip(label: const Text('Uang Pas'), onPressed: () => setState(() => _cashTendered = _grandTotal)),
                      ActionChip(label: const Text('Rp 50.000'), onPressed: () => setState(() => _cashTendered = 50000)),
                      ActionChip(label: const Text('Rp 100.000'), onPressed: () => setState(() => _cashTendered = 100000)),
                      ActionChip(label: const Text('Rp 200.000'), onPressed: () => setState(() => _cashTendered = 200000)),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Text('Total Akhir (PPN ${store.settings.taxRate.toStringAsFixed(0)}%):', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('Rp ${_grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryNavy)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cardDark,
                      foregroundColor: AppColors.brandLime,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: store.cartQuantities.isEmpty
                        ? null
                        : () {
                            final tx = store.checkoutPosTransaction(
                              paymentMethod: _paymentMethod,
                              customerName: _selectedCustomer,
                              discount: _discount,
                              amountPaid: _cashTendered,
                            );
                            if (tx != null) {
                              setState(() => _lastReceipt = tx);
                              _showReceiptDialog(context, tx);
                            }
                          },
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Bayar Sekarang & Cetak Struk Thermal', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                if (_lastReceipt != null)
                  TextButton(
                    onPressed: () => _showReceiptDialog(context, _lastReceipt!),
                    child: Text('Lihat Struk Terakhir (${_lastReceipt!['invoice_number']})'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SalesHistoryView extends StatelessWidget {
  final InventoryStore store;

  const SalesHistoryView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final txs = store.transactions;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              const Text(
                'Riwayat Transaksi & Penjualan (Sales)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              if (store.offlineQueue.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () {
                    final synced = store.syncOfflineTransactions();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$synced transaksi offline berhasil disinkronkan!')),
                    );
                  },
                  icon: const Icon(Icons.sync_rounded, size: 16),
                  label: Text('Sync Offline (${store.offlineQueue.length})'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ...txs.map((tx) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.receipt_long_rounded, color: AppColors.primaryNavy),
                title: Text('${tx['invoice_number']} · ${tx['customer_name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${tx['created_at']} · Metode: ${tx['payment_method']} · Status: ${tx['sync_status'] == 'pending' ? 'Offline Pending' : 'Completed'}'),
                trailing: Text('Rp ${(tx['total_amount'] as num).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            );
          }),
        ],
      ),
    );
  }
}
