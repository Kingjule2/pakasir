import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppSidebar extends StatelessWidget {
  final String activeNav;
  final ValueChanged<String> onNavSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const AppSidebar({
    super.key,
    required this.activeNav,
    required this.onNavSelected,
    this.isCollapsed = false,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isCollapsed ? 76 : 220,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Collapse Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 16, 20),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (!isCollapsed) ...[
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.brandLime,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.grid_view_rounded,
                          size: 16,
                          color: AppColors.cardDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'vault',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
                IconButton(
                  onPressed: onToggleCollapse,
                  icon: Icon(
                    isCollapsed
                        ? Icons.chevron_right_rounded
                        : Icons.menu_open_rounded,
                    color: AppColors.textMutedOnDark,
                    size: 20,
                  ),
                  tooltip: isCollapsed ? 'Expand Menu' : 'Collapse Menu',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                if (!isCollapsed)
                  const Padding(
                    padding: EdgeInsets.only(left: 10, bottom: 8, top: 4),
                    child: Text(
                      'MENU',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMutedOnDark,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),

                _buildNavItem(
                  title: 'Dashboard',
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  isSelected: activeNav == 'Dashboard',
                  onTap: () => onNavSelected('Dashboard'),
                ),
                _buildNavItem(
                  title: 'Inventory',
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2_rounded,
                  isSelected: activeNav == 'Inventory',
                  onTap: () => onNavSelected('Inventory'),
                ),
                _buildNavItem(
                  title: 'Shipment',
                  icon: Icons.local_shipping_outlined,
                  activeIcon: Icons.local_shipping_rounded,
                  isSelected: activeNav == 'Shipment',
                  onTap: () => onNavSelected('Shipment'),
                ),
                _buildNavItem(
                  title: 'Customers',
                  icon: Icons.people_outline_rounded,
                  activeIcon: Icons.people_rounded,
                  isSelected: activeNav == 'Customers',
                  onTap: () => onNavSelected('Customers'),
                ),
                _buildNavItem(
                  title: 'Store',
                  icon: Icons.storefront_outlined,
                  activeIcon: Icons.storefront_rounded,
                  isSelected: activeNav == 'Store',
                  onTap: () => onNavSelected('Store'),
                ),
                _buildNavItem(
                  title: 'Report',
                  icon: Icons.analytics_outlined,
                  activeIcon: Icons.analytics_rounded,
                  isSelected: activeNav == 'Report',
                  onTap: () => onNavSelected('Report'),
                ),

                const SizedBox(height: 20),

                if (!isCollapsed)
                  const Padding(
                    padding: EdgeInsets.only(left: 10, bottom: 8),
                    child: Text(
                      'GENERAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMutedOnDark,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),

                _buildNavItem(
                  title: 'Help',
                  icon: Icons.help_outline_rounded,
                  activeIcon: Icons.help_rounded,
                  isSelected: activeNav == 'Help',
                  onTap: () => onNavSelected('Help'),
                ),
                _buildNavItem(
                  title: 'Settings',
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  isSelected: activeNav == 'Settings',
                  onTap: () => onNavSelected('Settings'),
                ),
                _buildNavItem(
                  title: 'Privacy',
                  icon: Icons.shield_outlined,
                  activeIcon: Icons.shield_rounded,
                  isSelected: activeNav == 'Privacy',
                  onTap: () => onNavSelected('Privacy'),
                ),

                const SizedBox(height: 24),

                // Look For Pro? Card
                if (!isCollapsed) _buildProBanner(context),
              ],
            ),
          ),

          // User Profile Card (Evano - Sales Admin)
          _buildUserProfile(),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String title,
    required IconData icon,
    required IconData activeIcon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCollapsed ? 12 : 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandLime.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(
                    color: AppColors.brandLime.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment:
                isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 19,
                color: isSelected ? AppColors.brandLime : AppColors.textMutedOnDark,
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.brandLime
                          : const Color(0xFFC0C5CC),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2126),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2B2F36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  size: 16,
                  color: AppColors.cardDark,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Look For Pro ?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Unlock premium features with 20% off – for a limited time!',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textMutedOnDark,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('SaaS Pro Tier: Unlimited Memory Engine active!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D323A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Upgrade Now',
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

  Widget _buildUserProfile() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 12 : 16,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF22262B)),
        ),
      ),
      child: Row(
        mainAxisAlignment:
            isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFF4F46E5),
            child: const Text(
              'E',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Evano',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Sales Admin',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMutedOnDark,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_right_rounded,
              size: 16,
              color: AppColors.textMutedOnDark,
            ),
          ],
        ],
      ),
    );
  }
}
