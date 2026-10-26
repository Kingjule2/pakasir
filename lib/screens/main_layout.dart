import 'package:flutter/material.dart';
import '../models/shipment_item.dart';
import '../services/inventory_store.dart';
import '../theme/app_colors.dart';
import '../widgets/add_product_dialog.dart';
import '../widgets/neural_memory_dialog.dart';
import '../widgets/supri_assistant_panel.dart';
import '../widgets/views/customers_view.dart';
import '../widgets/views/dashboard_view.dart';
import '../widgets/views/help_view.dart';
import '../widgets/views/mobile_inventory_view.dart';
import '../widgets/views/pos_view.dart';
import '../widgets/views/privacy_view.dart';
import '../widgets/views/reports_view.dart';
import '../widgets/views/settings_view.dart';
import '../widgets/views/shipment_view.dart';
import '../widgets/views/store_view.dart';

class MainDashboardLayout extends StatefulWidget {
  const MainDashboardLayout({super.key});

  @override
  State<MainDashboardLayout> createState() => _MainDashboardLayoutState();
}

class _MainDashboardLayoutState extends State<MainDashboardLayout> {
  final InventoryStore store = InventoryStore();
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    store.removeListener(_onStoreChanged);
    store.dispose();
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideViewport = constraints.maxWidth > 540;

        return Scaffold(
          backgroundColor: isWideViewport ? const Color(0xFFEEF2F9) : AppColors.appBg,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWideViewport ? 480 : double.infinity,
                ),
                child: Container(
                  decoration: isWideViewport
                      ? BoxDecoration(
                          color: AppColors.appBg,
                          border: Border.symmetric(
                            vertical: BorderSide(color: AppColors.borderSubtle),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F0F4A).withValues(alpha: 0.07),
                              blurRadius: 24,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        )
                      : const BoxDecoration(color: AppColors.appBg),
                  child: Scaffold(
                    backgroundColor: AppColors.appBg,
                    body: Column(
                      children: [
                        // 1. Stitch Top Mobile Header Bar (Clean, no extra pills row below)
                        _buildStitchMobileHeader(context, constraints.maxWidth),

                        // 2. Collapsible Search Input Bar (only when search icon is tapped)
                        if (_showSearchBar)
                          Container(
                            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
                            ),
                            child: SizedBox(
                              height: 38,
                              child: TextField(
                                onChanged: store.setSearchQuery,
                                style: const TextStyle(fontSize: 12.5),
                                decoration: InputDecoration(
                                  hintText: 'Cari produk, SKU, pelanggan...',
                                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 16),
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      store.setSearchQuery('');
                                      setState(() => _showSearchBar = false);
                                    },
                                  ),
                                  filled: true,
                                  fillColor: AppColors.surfaceAlt,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(99),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // 3. Active Mobile Screen Content
                        Expanded(
                          child: _buildActiveContent(constraints),
                        ),
                      ],
                    ),
                    // 4. Stitch Bottom Navigation Bar (Inside mobile container!)
                    bottomNavigationBar: _buildStitchBottomNav(context),
                    floatingActionButton: (!store.isSupriOpen && store.activeNav != 'POS')
                        ? FloatingActionButton.small(
                            backgroundColor: const Color(0xFF12134D),
                            foregroundColor: Colors.white,
                            tooltip: 'Tanya Supri AI Voice',
                            onPressed: () {
                              store.openSupri();
                              _showSupriBottomSheet(context);
                            },
                            child: const Icon(Icons.mic_rounded, size: 20),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStitchMobileHeader(BuildContext context, double screenWidth) {
    final isCompactPhone = screenWidth < 360;
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: isCompactPhone ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: const Border(bottom: BorderSide(color: AppColors.borderSubtle)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Stitch Brand Mark + Title + Active Subtitle
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF12134D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Inventor',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF141B2B),
                          letterSpacing: -0.3,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        store.activeNav,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right Action Buttons (Search, Notifications/Memory, Supri AI, Avatar)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => setState(() => _showSearchBar = !_showSearchBar),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  child: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF46464F)),
                ),
              ),
              InkWell(
                onTap: () => NeuralMemoryDialog.show(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_none_rounded, size: 20, color: Color(0xFF46464F)),
                      Positioned(
                        top: 1,
                        right: 1,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFFBA1A1A),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  store.openSupri();
                  _showSupriBottomSheet(context);
                },
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: isCompactPhone ? 8 : 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBDDDFF),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.smart_toy_outlined, size: 14, color: Color(0xFF12134D)),
                      SizedBox(width: 4),
                      Text(
                        'Supri AI',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF12134D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _showAddProductDialog(context),
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF12134D),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'EV',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Exact Stitch Mobile Bottom Navigation Bar:
  // <nav class="fixed bottom-0 w-full z-50 pb-safe bg-surface/90 backdrop-blur-xl shadow-[0_-1px_12px_rgba(0,0,0,0.05)]">
  //   <div class="h-16 px-space-xs flex items-center justify-around">
  //     <a class="flex-1 flex flex-col items-center justify-center h-12 rounded-lg mx-0.5 bg-secondary-container text-on-surface font-semibold">
  Widget _buildStitchBottomNav(BuildContext context) {
    final active = store.activeNav;
    final isMoreActive = !['Dashboard', 'Inventory', 'POS', 'Sales'].contains(active);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.borderSubtle)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStitchNavTab(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
            label: 'Dashboard',
            isSelected: active == 'Dashboard',
            onTap: () => store.setActiveNav('Dashboard'),
          ),
          _buildStitchNavTab(
            icon: Icons.inventory_2_outlined,
            activeIcon: Icons.inventory_2_rounded,
            label: 'Inventory',
            isSelected: active == 'Inventory',
            onTap: () => store.setActiveNav('Inventory'),
          ),
          _buildStitchNavTab(
            icon: Icons.point_of_sale_outlined,
            activeIcon: Icons.point_of_sale_rounded,
            label: 'POS Kasir',
            isSelected: active == 'POS',
            onTap: () => store.setActiveNav('POS'),
          ),
          _buildStitchNavTab(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_rounded,
            label: 'Sales',
            isSelected: active == 'Sales',
            onTap: () => store.setActiveNav('Sales'),
          ),
          _buildStitchNavTab(
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view_rounded,
            label: 'More',
            isSelected: isMoreActive,
            onTap: () => _showMoreBottomSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStitchNavTab({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFBDDDFF) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 20,
                  color: isSelected ? const Color(0xFF141B2B) : AppColors.textSecondary,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? const Color(0xFF141B2B) : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMoreBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Menu & Modul Lainnya',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF141B2B)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildMoreOption(ctx, Icons.people_outline_rounded, 'Customers', 'Direktori CRM'),
                  _buildMoreOption(ctx, Icons.storefront_outlined, 'Store', 'Cabang & Outlet'),
                  _buildMoreOption(ctx, Icons.insights_rounded, 'Report', 'Laporan Finansial'),
                  _buildMoreOption(ctx, Icons.local_shipping_outlined, 'Shipment', 'Pengadaan & PO'),
                  _buildMoreOption(ctx, Icons.help_outline_rounded, 'Help', 'Pusat Bantuan'),
                  _buildMoreOption(ctx, Icons.settings_outlined, 'Settings', 'Pengaturan & Printer'),
                  _buildMoreOption(ctx, Icons.shield_outlined, 'Privacy', 'Keamanan & Audit'),
                  _buildMoreOption(ctx, Icons.smart_toy_outlined, 'Supri', 'Asisten AI Suara'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreOption(BuildContext ctx, IconData icon, String navId, String subtitle) {
    final isSelected = store.activeNav == navId;
    return InkWell(
      onTap: () {
        Navigator.pop(ctx);
        if (navId == 'Supri') {
          store.openSupri();
          _showSupriBottomSheet(context);
        } else {
          store.setActiveNav(navId);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 155,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFBDDDFF) : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF99CBFF) : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF12134D)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    navId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF141B2B)),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSupriBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: SupriAssistantPanel(
          messages: store.chatMessages,
          onSendMessage: store.sendMessageToSupri,
          onSendAttachmentMessage: store.sendMessageToSupri,
          onClose: () => Navigator.pop(ctx),
          onExecuteRestock: () {
            store.executeAllRecommendedRestock();
            Navigator.pop(ctx);
          },
          items: store.allItems,
        ),
      ),
    );
  }

  Widget _buildActiveContent(BoxConstraints constraints) {
    switch (store.activeNav) {
      case 'Dashboard':
        return DashboardView(
          store: store,
          onNavigateToInventory: () => store.setActiveNav('Inventory'),
          onNavigateToCustomers: () => store.setActiveNav('Customers'),
          onNavigateToStore: () => store.setActiveNav('Store'),
          onNavigateToReports: () => store.setActiveNav('Report'),
          onOpenSupri: () {
            store.openSupri();
            _showSupriBottomSheet(context);
          },
          onAddProduct: () => _showAddProductDialog(context),
        );
      case 'Inventory':
        return MobileInventoryView(store: store);
      case 'POS':
        return PosCashierView(store: store);
      case 'Sales':
        return SalesHistoryView(store: store);
      case 'Shipment':
        return ShipmentView(
          store: store,
          onContactSupplier: (ctx, ship) => _showContactSupplierDialog(ctx, ship),
        );
      case 'Customers':
        return CustomersView(store: store);
      case 'Store':
        return StoreView(
          store: store,
          onNavigateToInventory: () => store.setActiveNav('Inventory'),
        );
      case 'Report':
        return ReportsView(
          store: store,
          onBackToInventory: () => store.setActiveNav('Inventory'),
        );
      case 'Help':
        return HelpView(
          store: store,
          onOpenSupri: () {
            store.openSupri();
            _showSupriBottomSheet(context);
          },
        );
      case 'Settings':
        return SettingsView(store: store);
      case 'Privacy':
        return PrivacyView(store: store);
      default:
        return DashboardView(
          store: store,
          onNavigateToInventory: () => store.setActiveNav('Inventory'),
          onNavigateToCustomers: () => store.setActiveNav('Customers'),
          onNavigateToStore: () => store.setActiveNav('Store'),
          onNavigateToReports: () => store.setActiveNav('Report'),
          onOpenSupri: () {
            store.openSupri();
            _showSupriBottomSheet(context);
          },
          onAddProduct: () => _showAddProductDialog(context),
        );
    }
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AddProductDialog(
        onAdd: (item) {
          store.addProduct(item);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Produk "${item.name}" berhasil ditambahkan!'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _showContactSupplierDialog(BuildContext context, ShipmentItem ship) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.support_agent_rounded, color: AppColors.statusInfo),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Hubungi ${ship.supplier}', style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Barang: ${ship.productName} (${ship.sku})'),
            const SizedBox(height: 4),
            Text('Keterlambatan: ${ship.delayedDays} Hari'),
            Text(
              'Template Pesan WhatsApp Supri:\n"Halo tim logistik, kami menanyakan status pengiriman PO untuk item tersebut yang tertunda ${ship.delayedDays} hari. Mohon update resi terbaru."',
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Pesan pengingat dikirim ke supplier ${ship.supplier}!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF12134D)),
            child: const Text('Kirim Pesan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
