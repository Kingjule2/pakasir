import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'neural_memory_dialog.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAddProduct;
  final VoidCallback onToggleSupri;
  final bool isSupriOpen;
  final VoidCallback? onRefresh;

  const AppHeader({
    super.key,
    required this.title,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onAddProduct,
    required this.onToggleSupri,
    required this.isSupriOpen,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      color: Colors.transparent,
      child: Row(
        children: [
          // Page Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),

          const Spacer(),

          // Search Box
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160, minWidth: 60),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: TextField(
                  onChanged: onSearchChanged,
                  style: const TextStyle(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'Search here',
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: InputBorder.none,
                    isDense: true,
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 14),
                            onPressed: () => onSearchChanged(''),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Filter Button
          _buildCircleIconButton(
            icon: Icons.tune_rounded,
            tooltip: 'Filter options',
            onTap: () {},
          ),

          const SizedBox(width: 6),

          // Refresh Button
          _buildCircleIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh / Perbarui Data',
            onTap: onRefresh ?? () {},
          ),

          const SizedBox(width: 6),

          // Notification Bell
          _buildCircleIconButton(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notifications',
            hasBadge: true,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('3 notifikasi stok baru dari Memory Engine.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),

          const SizedBox(width: 6),

          // Neural Memory Engine Inspector
          _buildCircleIconButton(
            icon: Icons.psychology_outlined,
            tooltip: 'Neural Memory Engine (aibrain)',
            onTap: () => NeuralMemoryDialog.show(context),
          ),

          const SizedBox(width: 6),

          // Supri AI Toggle Button
          InkWell(
            onTap: onToggleSupri,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSupriOpen ? AppColors.supriOrange : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSupriOpen
                      ? AppColors.supriOrange
                      : AppColors.brandLime,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSupriOpen
                        ? AppColors.supriOrange.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.smart_toy_rounded,
                    size: 17,
                    color: isSupriOpen ? Colors.white : AppColors.supriOrange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Supri AI',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSupriOpen ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isSupriOpen ? Colors.white : AppColors.brandLime,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Add New Product Button
          ElevatedButton.icon(
            onPressed: onAddProduct,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
            label: const Text(
              'Add New Product',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardDark,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool hasBadge = false,
  }) {
    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Icon(
              icon,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        if (hasBadge)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.statusDanger,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
