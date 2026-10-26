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
  final bool isMobilePreview;
  final VoidCallback? onToggleMobilePreview;
  const AppHeader({
    super.key,
    required this.title,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onAddProduct,
    required this.onToggleSupri,
    required this.isSupriOpen,
    this.onRefresh,
    this.isMobilePreview = false,
    this.onToggleMobilePreview,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 750;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 24, vertical: 14),
          color: Colors.transparent,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isCompact ? 120 : 160, minWidth: 60),
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
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (onToggleMobilePreview != null)
                    InkWell(
                      onTap: onToggleMobilePreview,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isMobilePreview ? AppColors.tableHeaderBg : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isMobilePreview ? AppColors.primaryNavy : AppColors.cardBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone_iphone_rounded, size: 14, color: isMobilePreview ? AppColors.primaryNavy : AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              isMobilePreview ? 'Phone View' : 'Wide View',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isMobilePreview ? AppColors.primaryNavy : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  _buildCircleIconButton(
                    icon: Icons.tune_rounded,
                    tooltip: 'Filter options',
                    onTap: () {},
                  ),
                  _buildCircleIconButton(
                    icon: Icons.refresh_rounded,
                    tooltip: 'Refresh / Perbarui Data',
                    onTap: onRefresh ?? () {},
                  ),
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
                  _buildCircleIconButton(
                    icon: Icons.psychology_outlined,
                    tooltip: 'Neural Memory Engine (aibrain)',
                    onTap: () => NeuralMemoryDialog.show(context),
                  ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
