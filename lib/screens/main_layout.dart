import 'package:flutter/material.dart';
import '../models/shipment_item.dart';
import '../services/inventory_store.dart';
import '../theme/app_colors.dart';
import '../widgets/add_product_dialog.dart';
import '../widgets/ai_restock_card.dart';
import '../widgets/charts/stock_volume_chart.dart';
import '../widgets/custom_tags_table.dart';
import '../widgets/views/dashboard_view.dart';
import '../widgets/views/customers_view.dart';
import '../widgets/views/store_view.dart';
import '../widgets/views/reports_view.dart';
import '../widgets/views/help_view.dart';
import '../widgets/views/settings_view.dart';
import '../widgets/views/privacy_view.dart';
import '../widgets/views/shipment_view.dart';
import '../widgets/header.dart';
import '../widgets/metric_cards.dart';
import '../widgets/sales_order_list.dart';
import '../widgets/sidebar.dart';
import '../widgets/still_not_arrived_list.dart';
import '../widgets/supri_assistant_panel.dart';

class MainDashboardLayout extends StatefulWidget {
  const MainDashboardLayout({super.key});

  @override
  State<MainDashboardLayout> createState() => _MainDashboardLayoutState();
}

class _MainDashboardLayoutState extends State<MainDashboardLayout> {
  final InventoryStore store = InventoryStore();
  bool _isSidebarCollapsed = false;

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
        final isDesktop = constraints.maxWidth >= 1024;
        final isMobile = constraints.maxWidth < 700;

        return Scaffold(
          backgroundColor: AppColors.scaffoldBg,
          drawer: isMobile
              ? Drawer(
                  child: AppSidebar(
                    activeNav: store.activeNav,
                    onNavSelected: (nav) {
                      store.setActiveNav(nav);
                      Navigator.pop(context);
                    },
                    isCollapsed: false,
                    onToggleCollapse: () {},
                  ),
                )
              : null,
          endDrawer: (!isDesktop && store.isSupriOpen)
              ? Drawer(
                  width: 380,
                  child: SupriAssistantPanel(
                    messages: store.chatMessages,
                    onSendMessage: store.sendMessageToSupri,
                    onSendAttachmentMessage: store.sendMessageToSupri,
                    onClose: () => Navigator.pop(context),
                    onExecuteRestock: () {
                      store.executeAllRecommendedRestock();
                      Navigator.pop(context);
                    },
                    items: store.allItems,
                  ),
                )
              : null,
          body: Row(
            children: [
              // 1. Persistent Sidebar for Desktop/Tablet
              if (!isMobile)
                AppSidebar(
                  activeNav: store.activeNav,
                  onNavSelected: store.setActiveNav,
                  isCollapsed: _isSidebarCollapsed,
                  onToggleCollapse: () {
                    setState(() {
                      _isSidebarCollapsed = !_isSidebarCollapsed;
                    });
                  },
                ),

              // 2. Main Center Content
              Expanded(
                child: Column(
                  children: [
                    // Top App Header
                    AppHeader(
                      title: store.activeNav,
                      searchQuery: store.searchQuery,
                      onSearchChanged: store.setSearchQuery,
                      onAddProduct: () => _showAddProductDialog(context),
                      onToggleSupri: () {
                        if (isDesktop) {
                          store.toggleSupri();
                        } else {
                          store.openSupri();
                          Scaffold.of(context).openEndDrawer();
                        }
                      },
                      isSupriOpen: store.isSupriOpen,
                      onRefresh: () {
                        store.refreshData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tampilan dashboard & data berhasil diperbarui (Refresh)!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),

                    // Page Content Area
                    Expanded(
                      child: _buildActiveContent(constraints, isDesktop),
                    ),
                  ],
                ),
              ),

              // 3. Docked Supri Assistant Panel for Widescreen Desktop
              if (isDesktop && store.isSupriOpen)
                SupriAssistantPanel(
                  messages: store.chatMessages,
                  onSendMessage: store.sendMessageToSupri,
                  onSendAttachmentMessage: store.sendMessageToSupri,
                  onClose: store.closeSupri,
                  onExecuteRestock: store.executeAllRecommendedRestock,
                  items: store.allItems,
                ),
            ],
          ),
          // Floating Supri Button if panel is closed
          floatingActionButton: (!store.isSupriOpen)
              ? FloatingActionButton.extended(
                  onPressed: () {
                    if (isDesktop) {
                      store.openSupri();
                    } else {
                      store.openSupri();
                      Scaffold.of(context).openEndDrawer();
                    }
                  },
                  backgroundColor: AppColors.cardDark,
                  icon: const Icon(
                    Icons.smart_toy_rounded,
                    color: AppColors.brandLime,
                    size: 20,
                  ),
                  label: const Text(
                    'Tanya Supri',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildActiveContent(BoxConstraints constraints, bool isDesktop) {
    switch (store.activeNav) {
      case 'Dashboard':
        return DashboardView(
          store: store,
          onNavigateToInventory: () => store.setActiveNav('Inventory'),
          onNavigateToCustomers: () => store.setActiveNav('Customers'),
          onNavigateToStore: () => store.setActiveNav('Store'),
          onNavigateToReports: () => store.setActiveNav('Report'),
          onOpenSupri: () {
            if (isDesktop) {
              store.openSupri();
            } else {
              store.openSupri();
              Scaffold.of(context).openEndDrawer();
            }
          },
          onAddProduct: () => _showAddProductDialog(context),
        );
      case 'Inventory':
        return _buildInventoryBentoGrid(constraints);
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
            if (isDesktop) {
              store.openSupri();
            } else {
              store.openSupri();
              Scaffold.of(context).openEndDrawer();
            }
          },
        );
      case 'Settings':
        return SettingsView(store: store);
      case 'Privacy':
        return PrivacyView(store: store);
      default:
        return _buildInventoryBentoGrid(constraints);
    }
  }

  Widget _buildInventoryBentoGrid(BoxConstraints constraints) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: 4 KPI Bento Cards
          const MetricCardsGrid(),

          const SizedBox(height: 18),

          // Row 2: Middle Bento Section (Stock Volume Chart vs Custom Tags Table)
          LayoutBuilder(
            builder: (context, middleConstraints) {
              if (middleConstraints.maxWidth > 920) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Total Stock Volume vs Consume Rate
                    Expanded(
                      flex: 11,
                      child: StockVolumeChart(
                        activeTimeframe: store.selectedTimeframe,
                        onTimeframeChanged: store.setSelectedTimeframe,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Right Column: Custom Tags & Labels
                    Expanded(
                      flex: 12,
                      child: CustomTagsTableCard(
                        tags: store.tags,
                        selectedTag: store.selectedTag,
                        onTagSelected: store.setSelectedTag,
                        onAddTag: store.addCustomTag,
                        items: store.filteredItems,
                        onDeleteItem: store.deleteProduct,
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    StockVolumeChart(
                      activeTimeframe: store.selectedTimeframe,
                      onTimeframeChanged: store.setSelectedTimeframe,
                    ),
                    const SizedBox(height: 16),
                    CustomTagsTableCard(
                      tags: store.tags,
                      selectedTag: store.selectedTag,
                      onTagSelected: store.setSelectedTag,
                      onAddTag: store.addCustomTag,
                      items: store.filteredItems,
                      onDeleteItem: store.deleteProduct,
                    ),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 18),

          // Row 3: Bottom Bento Section (Sales & Order, AI Restock, Still Not Arrived)
          LayoutBuilder(
            builder: (context, bottomConstraints) {
              if (bottomConstraints.maxWidth > 980) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bottom Left: Sales & Order
                    Expanded(
                      flex: 4,
                      child: SalesOrderListCard(
                        items: store.salesAndOrderItems,
                        onDeleteItem: store.deleteProduct,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Bottom Middle: AI Restock Recommendation
                    Expanded(
                      flex: 3,
                      child: AiRestockCard(
                        onRestockNow: () {
                          store.executeAllRecommendedRestock();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Restock order (120 Items) berhasil dieksekusi otomatis oleh Memory Engine!'),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        },
                        onSeeAll: () {
                          store.setSelectedTag('Fast Moving');
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Bottom Right: Still Not Arrived
                    Expanded(
                      flex: 3,
                      child: StillNotArrivedCard(
                        shipments: store.shipments,
                        onContactSupplier: (ship) {
                          _showContactSupplierDialog(context, ship);
                        },
                        onSeeAll: () {
                          store.setActiveNav('Shipment');
                        },
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    SalesOrderListCard(
                      items: store.salesAndOrderItems,
                      onDeleteItem: store.deleteProduct,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AiRestockCard(
                            onRestockNow: () {
                              store.executeAllRecommendedRestock();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Restock order (120 Items) berhasil dieksekusi otomatis!'),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            },
                            onSeeAll: () => store.setSelectedTag('Fast Moving'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: StillNotArrivedCard(
                            shipments: store.shipments,
                            onContactSupplier: (ship) {
                              _showContactSupplierDialog(context, ship);
                            },
                            onSeeAll: () => store.setActiveNav('Shipment'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
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
            const Icon(Icons.support_agent_rounded,
                color: AppColors.statusInfo),
            const SizedBox(width: 8),
            Text('Hubungi ${ship.supplier}',
                style: const TextStyle(fontSize: 16)),
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
                  content: Text(
                      'Pesan pengingat dikirim ke supplier ${ship.supplier}!'),
                ),
              );
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.cardDark),
            child: const Text('Kirim Pesan',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
