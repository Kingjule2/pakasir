import 'package:flutter/material.dart';
import '../../models/shipment_item.dart';
import '../../services/inventory_store.dart';
import '../../theme/app_colors.dart';

class ShipmentView extends StatelessWidget {
  final InventoryStore store;
  final void Function(BuildContext, ShipmentItem) onContactSupplier;

  const ShipmentView({
    super.key,
    required this.store,
    required this.onContactSupplier,
  });

  @override
  Widget build(BuildContext context) {
    final shipments = store.shipments;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & KPI cards
          LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth = constraints.maxWidth > 850
                  ? (constraints.maxWidth - 2 * 14) / 3
                  : constraints.maxWidth;

              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _buildShipmentKpi(
                      title: 'Pengiriman Tertunda (Delayed)',
                      value: '${shipments.length} Pengiriman',
                      subtitle: 'Perlu konfirmasi ke supplier',
                      icon: Icons.timer_outlined,
                      color: AppColors.statusDanger,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildShipmentKpi(
                      title: 'Supplier Aktif',
                      value: '4 Mitra Pabrik',
                      subtitle: 'Lead time rata-rata 3 hari',
                      icon: Icons.local_shipping_outlined,
                      color: AppColors.brandLime,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildShipmentKpi(
                      title: 'Estimasi Tiba (ETA)',
                      value: '2-3 Hari Lagi',
                      subtitle: 'Restock otomatis Memory Engine',
                      icon: Icons.calendar_today_rounded,
                      color: AppColors.statusInfo,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // Main Shipments Card
          Container(
            padding: const EdgeInsets.all(22),
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
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pelacakan Pengiriman Supplier (Shipment Tracking)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pantau status kiriman barang dari pabrik dan supplier masuk ke gudang',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        store.executeAllRecommendedRestock();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Order restock batch baru telah dikirim ke supplier via Memory Engine.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 15),
                      label: const Text('Buat Order Pengiriman'),
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
                const SizedBox(height: 18),

                if (shipments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 36, color: AppColors.statusSuccess),
                          SizedBox(height: 8),
                          Text(
                            'Semua pengiriman supplier telah diterima dengan baik!',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: shipments.length,
                    separatorBuilder: (context, index) => const Divider(height: 18),
                    itemBuilder: (context, index) {
                      final ship = shipments[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.statusDangerBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.local_shipping_outlined,
                                color: AppColors.statusDanger,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        ship.productName,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.statusDangerBg,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Terlambat ${ship.delayedDays} Hari',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.statusDanger,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'SKU: ${ship.sku} • Supplier: ${ship.supplier}',
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => onContactSupplier(context, ship),
                                  icon: const Icon(Icons.phone_in_talk_rounded, size: 14),
                                  label: const Text('Hubungi Supplier'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.cardDark,
                                    side: const BorderSide(color: AppColors.cardBorder),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    store.markShipmentReceived(ship.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Barang "${ship.productName}" telah diterima & stok diperbarui!'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.check_rounded, size: 14),
                                  label: const Text('Barang Sampai'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.cardDark,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentKpi({
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
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
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
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
