import 'package:flutter/material.dart';
import '../models/shipment_item.dart';
import '../theme/app_colors.dart';

class StillNotArrivedCard extends StatelessWidget {
  final List<ShipmentItem> shipments;
  final ValueChanged<ShipmentItem> onContactSupplier;
  final VoidCallback onSeeAll;

  const StillNotArrivedCard({
    super.key,
    required this.shipments,
    required this.onContactSupplier,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Still Not Arrived',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),

          // Column headers
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'Product Name',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Delayed',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Action',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 0.8, color: Color(0xFFF5F6F8)),

          // Shipment Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: shipments.take(4).length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              thickness: 0.8,
              color: Color(0xFFF5F6F8),
            ),
            itemBuilder: (context, index) {
              final ship = shipments[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
                child: Row(
                  children: [
                    // Product & SKU
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          _buildThumb(ship.productName),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ship.productName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  ship.sku,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Delayed Days
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${ship.delayedDays} Days',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

                    // Action: Contact button
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () => onContactSupplier(ship),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: const Text(
                              'Contact',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 14),

          // See All Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSeeAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cardDark,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text(
                'See All',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumb(String name) {
    Color bg = const Color(0xFFF1F5F9);
    IconData icon = Icons.shopping_bag_outlined;

    if (name.toLowerCase().contains('backpack')) {
      bg = const Color(0xFFE2E8F0);
      icon = Icons.backpack_outlined;
    } else if (name.toLowerCase().contains('shirt')) {
      bg = const Color(0xFFE0F2FE);
      icon = Icons.checkroom_outlined;
    } else if (name.toLowerCase().contains('helmet')) {
      bg = const Color(0xFFDCFCE7);
      icon = Icons.sports_motorsports_outlined;
    } else if (name.toLowerCase().contains('glass')) {
      bg = const Color(0xFFFEF3C7);
      icon = Icons.visibility_outlined;
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 15, color: AppColors.textSecondary),
    );
  }
}
