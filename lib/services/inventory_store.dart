import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../models/shipment_item.dart';
import '../models/financial_summary.dart';
import '../models/ai_chat_message.dart';
import '../models/customer_item.dart';
import '../models/store_outlet.dart';
import '../models/store_settings.dart';
import '../models/security_models.dart';
import '../models/help_models.dart';
import 'gemini_service.dart';
import 'tts/tts_service.dart';
enum VoiceSessionState { idle, greeting, listening, processing, speaking }

class InventoryStore extends ChangeNotifier {
  // Navigation
  String _activeNav = 'Dashboard';
  String get activeNav => _activeNav;

  void setActiveNav(String nav) {
    _activeNav = nav;
    notifyListeners();
  }

  void refreshData() {
    notifyListeners();
  }

  // Supri AI Panel Toggle
  bool _isSupriOpen = false;
  bool get isSupriOpen => _isSupriOpen;

  void toggleSupri() {
    _isSupriOpen = !_isSupriOpen;
    notifyListeners();
  }

  void openSupri() {
    _isSupriOpen = true;
    notifyListeners();
  }

  void closeSupri() {
    _isSupriOpen = false;
    notifyListeners();
  }

  // Filter & Search
  String _selectedTag = 'Fast Moving';
  String get selectedTag => _selectedTag;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _selectedTimeframe = 'Monthly';
  String get selectedTimeframe => _selectedTimeframe;

  void setSelectedTag(String tag) {
    _selectedTag = tag;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedTimeframe(String timeframe) {
    _selectedTimeframe = timeframe;
    notifyListeners();
  }

  // Tags
  final List<String> _tags = [
    'Fast Moving',
    'Discounted',
    'Low Demand',
    'Dead Items',
    'New Arrival',
  ];
  List<String> get tags => List.unmodifiable(_tags);

  void addCustomTag(String tag) {
    final clean = tag.trim();
    if (clean.isNotEmpty && !_tags.contains(clean)) {
      _tags.add(clean);
      _selectedTag = clean;
      notifyListeners();
    }
  }

  // Inventory Items (Initial Seed based on Image #1)
  final List<InventoryItem> _items = [
    InventoryItem(
      id: 'prod-1',
      name: 'Headphones',
      sku: 'SKU-300',
      category: 'Electronic',
      totalQty: 200,
      stockIn: 150,
      price: 4000,
      costPrice: 2800,
      priority: PriorityLevel.high,
      tag: 'Fast Moving',
      imageAsset: 'headphones',
    ),
    InventoryItem(
      id: 'prod-2',
      name: 'Helmets',
      sku: 'SKU-900',
      category: 'Watch',
      totalQty: 500,
      stockIn: 350,
      price: 7000,
      costPrice: 4500,
      priority: PriorityLevel.medium,
      tag: 'Discounted',
      imageAsset: 'helmet',
    ),
    InventoryItem(
      id: 'prod-3',
      name: 'T Shirts',
      sku: 'SKU-300',
      category: 'Fashion',
      totalQty: 2000,
      stockIn: 560,
      price: 3000,
      costPrice: 1600,
      priority: PriorityLevel.high,
      tag: 'Fast Moving',
      imageAsset: 'shirt',
    ),
    InventoryItem(
      id: 'prod-4',
      name: 'Sunglasses',
      sku: 'SKU-300',
      category: 'Fashion',
      totalQty: 3000,
      stockIn: 1000,
      price: 5000,
      costPrice: 2900,
      priority: PriorityLevel.low,
      tag: 'Low Demand',
      imageAsset: 'glasses',
    ),
    InventoryItem(
      id: 'prod-5',
      name: 'Water Pot',
      sku: 'SKU-300',
      category: 'Drinks',
      totalQty: 1200,
      stockIn: 420,
      price: 2500,
      costPrice: 1400,
      priority: PriorityLevel.low,
      tag: 'Dead Items',
      imageAsset: 'bottle',
    ),
    InventoryItem(
      id: 'prod-6',
      name: 'Smart Watch X',
      sku: 'SKU-520',
      category: 'Watch',
      totalQty: 450,
      stockIn: 310,
      price: 8500,
      costPrice: 5900,
      priority: PriorityLevel.high,
      tag: 'New Arrival',
      imageAsset: 'watch',
    ),
    InventoryItem(
      id: 'prod-7',
      name: 'Backpack Explorer',
      sku: 'SKU-770',
      category: 'Fashion',
      totalQty: 180,
      stockIn: 25,
      price: 100,
      costPrice: 62,
      priority: PriorityLevel.high,
      tag: 'Fast Moving',
      imageAsset: 'backpack',
    ),
    InventoryItem(
      id: 'prod-8',
      name: 'Leather Hand Bag',
      sku: 'SKU-882',
      category: 'Fashion',
      totalQty: 90,
      stockIn: 0,
      price: 200,
      costPrice: 120,
      priority: PriorityLevel.medium,
      tag: 'Discounted',
      imageAsset: 'handbag',
      isOutOfStock: true,
    ),
    InventoryItem(
      id: 'prod-9',
      name: 'Fresh Milk 1L',
      sku: 'SKU-MLK-01',
      category: 'Drinks',
      totalQty: 25,
      stockIn: 12,
      price: 24000,
      costPrice: 16000,
      priority: PriorityLevel.high,
      tag: 'Fast Moving',
      imageAsset: 'bottle',
      expiryDate: DateTime.now().add(const Duration(days: 3)),
    ),
    InventoryItem(
      id: 'prod-10',
      name: 'Croissant Butter',
      sku: 'SKU-CRS-02',
      category: 'Snacks',
      totalQty: 15,
      stockIn: 5,
      price: 18000,
      costPrice: 10000,
      priority: PriorityLevel.high,
      tag: 'Fast Moving',
      imageAsset: 'shirt',
      expiryDate: DateTime.now().add(const Duration(days: 1)),
    ),
    InventoryItem(
      id: 'prod-11',
      name: 'Matcha Powder 500g',
      sku: 'SKU-MTC-03',
      category: 'Drinks',
      totalQty: 80,
      stockIn: 60,
      price: 45000,
      costPrice: 28000,
      priority: PriorityLevel.medium,
      tag: 'New Arrival',
      imageAsset: 'watch',
      expiryDate: DateTime.now().add(const Duration(days: 90)),
    ),
  ];

  // Expiry & Stock Alert Getters
  List<InventoryItem> get nearExpiryItems =>
      _items.where((i) => i.isNearExpiry).toList();

  List<InventoryItem> get expiredItems =>
      _items.where((i) => i.isExpired).toList();

  List<InventoryItem> get lowStockItems =>
      _items.where((i) => i.isLowStock && !i.isOutOfStock).toList();

  int get totalAlertsCount =>
      nearExpiryItems.length + expiredItems.length + lowStockItems.length;

  List<InventoryItem> get allItems => List.unmodifiable(_items);
  // ==================== CSV IMPORT / EXPORT & CRUD HELPER METHODS ====================
  String exportSalesCsv() {
    final buffer = StringBuffer();
    buffer.writeln('Invoice,Tanggal,Kasir,Pelanggan,Metode_Bayar,Total_Belanja,Status');
    for (final tx in _transactions) {
      final invoice = tx['invoice_number'] ?? tx['id'] ?? '-';
      final date = tx['created_at'] ?? '-';
      final cashier = tx['cashier_name'] ?? '-';
      final customer = tx['customer_name'] ?? '-';
      final payment = tx['payment_method'] ?? 'Cash';
      final total = tx['total_amount'] ?? 0;
      final status = tx['sync_status'] ?? 'Lunas';
      buffer.writeln('$invoice,$date,$cashier,$customer,$payment,$total,$status');
    }
    return buffer.toString();
  }

  Map<String, dynamic> importStockFromCsv(String csvContent) {
    final lines = csvContent
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      return {'importedCount': 0, 'items': <InventoryItem>[], 'alerts': <String>[]};
    }

    final List<InventoryItem> imported = [];
    final List<String> alerts = [];

    int startIndex = 0;
    int nameCol = 0;
    int priceCol = 1;
    int stockCol = 2;
    int categoryCol = -1;
    int expiryCol = -1;

    int headerIndex = -1;
    for (int i = 0; i < lines.length; i++) {
      final l = lines[i].toLowerCase();
      if ((l.contains(',') || l.contains(';')) &&
          (l.contains('nama') ||
              l.contains('name') ||
              l.contains('product') ||
              l.contains('produk') ||
              l.contains('harga') ||
              l.contains('stok'))) {
        headerIndex = i;
        break;
      }
    }

    if (headerIndex >= 0) {
      startIndex = headerIndex + 1;
      final headerLine = lines[headerIndex];
      final delimiter = headerLine.contains(';') ? ';' : ',';
      final headers = headerLine
          .split(delimiter)
          .map((h) => h.trim().toLowerCase())
          .toList();
      for (int i = 0; i < headers.length; i++) {
        final h = headers[i];
        if (h.contains('nama') ||
            h.contains('name') ||
            h.contains('produk') ||
            h.contains('product')) {
          nameCol = i;
        } else if (h.contains('harga') || h.contains('price') || h.contains('jual')) {
          priceCol = i;
        } else if (h.contains('stok') ||
            h.contains('stock') ||
            h.contains('qty') ||
            h.contains('jumlah')) {
          stockCol = i;
        } else if (h.contains('kategori') || h.contains('category')) {
          categoryCol = i;
        } else if (h.contains('expir') ||
            h.contains('kadaluarsa') ||
            h.contains('tgl_exp')) {
          expiryCol = i;
        }
      }
    } else {
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains(',') || lines[i].contains(';')) {
          startIndex = i;
          break;
        }
      }
    }

    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) continue;
      final delimiter = line.contains(';') ? ';' : ',';
      final parts = line.split(delimiter).map((p) => p.trim()).toList();
      if (parts.length <= nameCol) continue;

      final name = parts[nameCol].replaceAll('"', '');
      if (name.isEmpty) continue;

      final price = (parts.length > priceCol)
          ? (double.tryParse(parts[priceCol].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 10000.0)
          : 10000.0;
      final stock = (parts.length > stockCol)
          ? (int.tryParse(parts[stockCol].replaceAll(RegExp(r'[^0-9]'), '')) ?? 50)
          : 50;
      final category = (categoryCol >= 0 && parts.length > categoryCol)
          ? parts[categoryCol].replaceAll('"', '')
          : 'Umum';

      DateTime? expiry;
      if (expiryCol >= 0 && parts.length > expiryCol) {
        final expStr = parts[expiryCol].replaceAll('"', '').trim();
        expiry = DateTime.tryParse(expStr);
      }

      final existingIndex =
          _items.indexWhere((it) => it.name.toLowerCase() == name.toLowerCase());
      if (existingIndex >= 0) {
        final current = _items[existingIndex];
        final updated = current.copyWith(
          stockIn: current.stockIn + stock,
          totalQty: current.totalQty + stock,
          price: price,
          expiryDate: expiry ?? current.expiryDate,
        );
        _items[existingIndex] = updated;
        imported.add(updated);
      } else {
        final newItem = InventoryItem(
          id: 'prod-${DateTime.now().millisecondsSinceEpoch}-$i',
          name: name,
          sku: 'SKU-${(100 + _items.length + i)}',
          category: category,
          totalQty: stock,
          stockIn: stock,
          price: price,
          costPrice: price * 0.6,
          priority: PriorityLevel.medium,
          tag: 'New Arrival',
          imageAsset: 'default',
          expiryDate: expiry,
        );
        _items.add(newItem);
        imported.add(newItem);
      }

      if (expiry != null) {
        final diff = expiry.difference(DateTime.now()).inDays;
        if (diff < 0) {
          alerts.add('❌ Peringatan: Produk "$name" sudah KEDALUWARSA sejak ${-diff} hari lalu!');
        } else if (diff <= 14) {
          alerts.add('⚠️ Perhatian: Produk "$name" akan segera KEDALUWARSA dalam $diff hari (${expiry.toIso8601String().substring(0, 10)})!');
        }
      }
      if (stock <= 15) {
        alerts.add('⚠️ Stok Menipis: Produk "$name" hanya memiliki $stock unit!');
      }
    }

    notifyListeners();
    return {
      'importedCount': imported.length,
      'items': imported,
      'alerts': alerts,
    };
  }

  bool updateProductStockByName(String productName, int newStock) {
    final idx = _items.indexWhere(
        (i) => i.name.toLowerCase().contains(productName.toLowerCase()));
    if (idx >= 0) {
      final current = _items[idx];
      _items[idx] = current.copyWith(
        totalQty: newStock,
        stockIn: newStock,
        isOutOfStock: newStock <= 0,
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  bool addProductStockByName(String productName, int addedQty) {
    final idx = _items.indexWhere(
        (i) => i.name.toLowerCase().contains(productName.toLowerCase()));
    if (idx >= 0) {
      final current = _items[idx];
      final newQty = current.totalQty + addedQty;
      _items[idx] = current.copyWith(
        totalQty: newQty,
        stockIn: current.stockIn + addedQty,
        isOutOfStock: false,
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  bool deleteProductByName(String productName) {
    final idx = _items.indexWhere(
        (i) => i.name.toLowerCase().contains(productName.toLowerCase()));
    if (idx >= 0) {
      final item = _items.removeAt(idx);
      _recentlyDeletedItems.add(item.copyWith(
        deletedAt: DateTime.now(),
        deleteAfter: DateTime.now().add(const Duration(days: 30)),
        deletedReason: 'Dihapus atas perintah Supri AI Agent',
      ));
      notifyListeners();
      return true;
    }
    return false;
  }

  void addCustomProduct({
    required String name,
    required double price,
    required int stock,
    String category = 'Umum',
    DateTime? expiryDate,
  }) {
    final newItem = InventoryItem(
      id: 'prod-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      sku: 'SKU-${(100 + _items.length)}',
      category: category,
      totalQty: stock,
      stockIn: stock,
      price: price,
      costPrice: price * 0.6,
      priority: PriorityLevel.medium,
      tag: 'New Arrival',
      imageAsset: 'default',
      expiryDate: expiryDate,
    );
    _items.add(newItem);
    notifyListeners();
  }

  List<InventoryItem> get filteredItems {
    return _items.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.sku.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesTag =
          _selectedTag.isEmpty || item.tag.toLowerCase() == _selectedTag.toLowerCase();
      return matchesSearch && matchesTag;
    }).toList();
  }

  // Items for Sales & Order card
  List<InventoryItem> get salesAndOrderItems {
    return _items.take(4).toList();
  }

  // Delayed Shipments (Still Not Arrived card)
  final List<ShipmentItem> _shipments = [
    ShipmentItem(
      id: 'ship-1',
      productName: 'Backpack',
      sku: '#Sku-305',
      delayedDays: 5,
      supplier: 'PT Tas Nusantara',
      imageAsset: 'backpack',
    ),
    ShipmentItem(
      id: 'ship-2',
      productName: 'T Shirts',
      sku: '#Sku-305',
      delayedDays: 5,
      supplier: 'CV Solo Textile',
      imageAsset: 'shirt',
    ),
    ShipmentItem(
      id: 'ship-3',
      productName: 'Helmets',
      sku: '#Sku-305',
      delayedDays: 3,
      supplier: 'Surya Helmet Indah',
      imageAsset: 'helmet',
    ),
    ShipmentItem(
      id: 'ship-4',
      productName: 'Sunglass',
      sku: '#Sku-305',
      delayedDays: 3,
      supplier: 'Kacamata Raya Global',
      imageAsset: 'glasses',
    ),
  ];
  List<ShipmentItem> get shipments => List.unmodifiable(_shipments);

  // Financial Summary
  final FinancialSummary _finance = FinancialSummary.demo();
  FinancialSummary get finance => _finance;

  // AI Chat Messages
  final List<AiChatMessage> _chatMessages = [
    AiChatMessage(
      id: 'msg-1',
      role: MessageRole.assistant,
      text:
          'Halo Bos! Saya **Supri**, AI Inventory & Finance Coworker kamu.\n\n'
          'Memory Engine 6 bulan mendeteksi **120 produk** perlu segera di-restock sebelum akhir pekan. Ada juga ide konten promosi TikTok untuk produk trending!',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      widgetType: SupriWidgetType.quickRestock,
      widgetData: {
        'count': 120,
        'items': ['Backpack Explorer', 'T Shirts SKU-300'],
      },
    ),
  ];
  List<AiChatMessage> get chatMessages => List.unmodifiable(_chatMessages);

  // ==================== CUSTOMERS STATE ====================
  String _customerSearchQuery = '';
  String get customerSearchQuery => _customerSearchQuery;

  String _selectedCustomerTier = 'Semua';
  String get selectedCustomerTier => _selectedCustomerTier;

  final List<CustomerItem> _customers = [
    const CustomerItem(
      id: 'cust-01',
      name: 'Budi Santoso',
      email: 'budi.santoso@gmail.com',
      phone: '+62 812-4455-6677',
      tier: 'VIP',
      totalOrders: 38,
      totalSpent: 45200000,
      lastActive: 'Hari ini, 14:20',
      status: 'Aktif',
      city: 'Jakarta Selatan',
      notes: 'Pelanggan setia kategori Fashion & Jam Tangan.',
    ),
    const CustomerItem(
      id: 'cust-02',
      name: 'Siti Rahmawati',
      email: 'siti.rahma@outlook.com',
      phone: '+62 813-8899-1122',
      tier: 'VIP',
      totalOrders: 26,
      totalSpent: 32800000,
      lastActive: 'Kemarin, 16:45',
      status: 'Aktif',
      city: 'Bandung',
      notes: 'Member loyal sejak 2024, prioritas diskon member.',
    ),
    const CustomerItem(
      id: 'cust-03',
      name: 'CV Berkah Perkasa',
      email: 'procurement@berkahperkasa.co.id',
      phone: '+62 811-9900-3344',
      tier: 'Wholesale',
      totalOrders: 54,
      totalSpent: 85000000,
      lastActive: 'Hari ini, 10:15',
      status: 'Aktif',
      city: 'Semarang',
      notes: 'Grosir botol & aksesoris, tempo bayar 14 hari.',
    ),
    const CustomerItem(
      id: 'cust-04',
      name: 'Ahmad Fauzi',
      email: 'ahmad.fauzi@yahoo.com',
      phone: '+62 856-7788-9900',
      tier: 'Regular',
      totalOrders: 14,
      totalSpent: 12500000,
      lastActive: '2 hari lalu',
      status: 'Aktif',
      city: 'Surabaya',
    ),
    const CustomerItem(
      id: 'cust-05',
      name: 'Dewi Lestari',
      email: 'dewi.lestari@gmail.com',
      phone: '+62 878-1122-4455',
      tier: 'Regular',
      totalOrders: 9,
      totalSpent: 8750000,
      lastActive: '5 hari lalu',
      status: 'Aktif',
      city: 'Yogyakarta',
    ),
    const CustomerItem(
      id: 'cust-06',
      name: 'Hendrik Wijaya',
      email: 'hendrik.w@gmail.com',
      phone: '+62 822-3344-5566',
      tier: 'Baru',
      totalOrders: 2,
      totalSpent: 1450000,
      lastActive: 'Hari ini, 11:05',
      status: 'Aktif',
      city: 'Denpasar',
    ),
    const CustomerItem(
      id: 'cust-07',
      name: 'Rina Marlina',
      email: 'rina.marlina@gmail.com',
      phone: '+62 852-6677-8899',
      tier: 'Regular',
      totalOrders: 6,
      totalSpent: 6200000,
      lastActive: '1 minggu lalu',
      status: 'Nonaktif',
      city: 'Medan',
    ),
    const CustomerItem(
      id: 'cust-08',
      name: 'Kevin Pratama',
      email: 'kevin.pratama@gmail.com',
      phone: '+62 819-0011-2233',
      tier: 'Baru',
      totalOrders: 1,
      totalSpent: 950000,
      lastActive: 'Kemarin, 09:30',
      status: 'Aktif',
      city: 'Tangerang',
    ),
  ];

  List<CustomerItem> get customers => List.unmodifiable(_customers);

  List<CustomerItem> get filteredCustomers {
    return _customers.where((c) {
      final matchSearch = _customerSearchQuery.isEmpty ||
          c.name.toLowerCase().contains(_customerSearchQuery.toLowerCase()) ||
          c.email.toLowerCase().contains(_customerSearchQuery.toLowerCase()) ||
          c.phone.contains(_customerSearchQuery) ||
          c.city.toLowerCase().contains(_customerSearchQuery.toLowerCase());
      final matchTier = _selectedCustomerTier == 'Semua' ||
          c.tier.toLowerCase() == _selectedCustomerTier.toLowerCase();
      return matchSearch && matchTier;
    }).toList();
  }

  void setCustomerSearchQuery(String query) {
    _customerSearchQuery = query;
    notifyListeners();
  }

  void setSelectedCustomerTier(String tier) {
    _selectedCustomerTier = tier;
    notifyListeners();
  }

  void addCustomer(CustomerItem customer) {
    _customers.insert(0, customer);
    notifyListeners();
  }

  void updateCustomer(CustomerItem customer) {
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      _customers[index] = customer;
      notifyListeners();
    }
  }

  void deleteCustomer(String id) {
    _customers.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  // ==================== STORE OUTLETS STATE ====================
  final List<StoreOutlet> _outlets = [
    const StoreOutlet(
      id: 'store-01',
      name: 'Vault Central SCBD (Flagship)',
      code: 'JKT-01',
      city: 'Jakarta Selatan',
      address: 'SCBD Lot 8, Jl. Jend. Sudirman Kav. 52-53',
      manager: 'Andi Pratama',
      phone: '+62 812-1111-2222',
      operatingHours: '09:00 - 22:00 WIB',
      isOpen: true,
      terminalsCount: 4,
      dailySales: 18450000,
      monthlySales: 112000000,
      staffCount: 8,
    ),
    const StoreOutlet(
      id: 'store-02',
      name: 'Vault Hub Paris Van Java',
      code: 'BDG-02',
      city: 'Bandung',
      address: 'PVJ Mall GF-12, Jl. Sukajadi No. 137',
      manager: 'Maya Safitri',
      phone: '+62 813-3333-4444',
      operatingHours: '10:00 - 22:00 WIB',
      isOpen: true,
      terminalsCount: 3,
      dailySales: 12200000,
      monthlySales: 78500000,
      staffCount: 5,
    ),
    const StoreOutlet(
      id: 'store-03',
      name: 'Vault Express Tunjungan',
      code: 'SBY-03',
      city: 'Surabaya',
      address: 'Tunjungan Plaza 4 Lt. 2 No. 45',
      manager: 'Bambang Irawan',
      phone: '+62 811-5555-6666',
      operatingHours: '10:00 - 21:30 WIB',
      isOpen: true,
      terminalsCount: 2,
      dailySales: 9800000,
      monthlySales: 54000000,
      staffCount: 4,
    ),
    const StoreOutlet(
      id: 'store-04',
      name: 'Vault Store Seminyak',
      code: 'DPS-04',
      city: 'Bali',
      address: 'Jl. Kayu Aya No. 88, Seminyak, Kuta',
      manager: 'Putu Dharma',
      phone: '+62 819-7777-8888',
      operatingHours: '11:00 - 23:00 WITA',
      isOpen: false,
      terminalsCount: 2,
      dailySales: 6500000,
      monthlySales: 40000000,
      staffCount: 3,
    ),
  ];

  List<StoreOutlet> get outlets => List.unmodifiable(_outlets);

  void toggleStoreStatus(String id) {
    final index = _outlets.indexWhere((s) => s.id == id);
    if (index != -1) {
      _outlets[index] = _outlets[index].copyWith(
        isOpen: !_outlets[index].isOpen,
      );
      notifyListeners();
    }
  }

  void addStoreOutlet(StoreOutlet outlet) {
    _outlets.add(outlet);
    notifyListeners();
  }

  // ==================== STORE SETTINGS STATE ====================
  StoreSettings _settings = StoreSettings.defaultSettings();
  StoreSettings get settings => _settings;

  void updateSettings(StoreSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  // ==================== PRIVACY & SECURITY STATE ====================
  bool _twoFactorAuthEnabled = true;
  bool get twoFactorAuthEnabled => _twoFactorAuthEnabled;

  bool _biometricLoginEnabled = true;
  bool get biometricLoginEnabled => _biometricLoginEnabled;

  bool _customerDataAnonymized = false;
  bool get customerDataAnonymized => _customerDataAnonymized;

  int _sessionTimeoutMinutes = 30;
  int get sessionTimeoutMinutes => _sessionTimeoutMinutes;

  void toggleTwoFactorAuth() {
    _twoFactorAuthEnabled = !_twoFactorAuthEnabled;
    notifyListeners();
  }

  void toggleBiometricLogin() {
    _biometricLoginEnabled = !_biometricLoginEnabled;
    notifyListeners();
  }

  void toggleCustomerDataAnonymized() {
    _customerDataAnonymized = !_customerDataAnonymized;
    notifyListeners();
  }

  void setSessionTimeout(int minutes) {
    _sessionTimeoutMinutes = minutes;
    notifyListeners();
  }

  final List<SecurityAuditLog> _auditLogs = [
    const SecurityAuditLog(
      id: 'log-01',
      timestamp: '10 menit lalu',
      user: 'Evano (Sales Admin)',
      role: 'Superadmin',
      action: 'Restock Otomatis 120 Unit via Supri AI',
      target: 'Inventory Database',
      ipAddress: '192.168.1.10',
      status: 'Sukses',
    ),
    const SecurityAuditLog(
      id: 'log-02',
      timestamp: '1 jam lalu',
      user: 'Evano (Sales Admin)',
      role: 'Superadmin',
      action: 'Penyesuaian Tarif Pajak PPN 11%',
      target: 'Billing Settings',
      ipAddress: '192.168.1.10',
      status: 'Sukses',
    ),
    const SecurityAuditLog(
      id: 'log-03',
      timestamp: '3 jam lalu',
      user: 'Siti (Kasir PVJ)',
      role: 'Kasir POS',
      action: 'Void Transaksi #ORD-8812 (Pelanggan Ganti Pesanan)',
      target: 'POS Terminal 2',
      ipAddress: '192.168.1.42',
      status: 'Peringatan',
    ),
    const SecurityAuditLog(
      id: 'log-04',
      timestamp: 'Kemarin, 23:15',
      user: 'Unknown Actor',
      role: 'Guest / External',
      action: 'Percobaan Brute Force Login 5x Gagal',
      target: 'Auth Gateway',
      ipAddress: '103.45.12.89',
      status: 'Diblokir',
    ),
    const SecurityAuditLog(
      id: 'log-05',
      timestamp: 'Kemarin, 17:30',
      user: 'Maya Safitri',
      role: 'Store Manager',
      action: 'Ekspor Rekap Laporan Penjualan Mingguan',
      target: 'Reports Export',
      ipAddress: '192.168.1.18',
      status: 'Sukses',
    ),
  ];

  List<SecurityAuditLog> get auditLogs => List.unmodifiable(_auditLogs);

  void addAuditLog(SecurityAuditLog log) {
    _auditLogs.insert(0, log);
    notifyListeners();
  }

  final List<UserRolePermission> _userRoles = [
    const UserRolePermission(
      roleName: 'Owner / Super Admin',
      description: 'Akses penuh seluruh sistem, finansial, dan audit log.',
      memberCount: 2,
      permissions: ['Akses Semua Fitur', 'Kelola Keuangan', 'Ubah Kebijakan', 'Backup Database'],
    ),
    const UserRolePermission(
      roleName: 'Store Manager',
      description: 'Mengelola operasional cabang, stok, dan laporan shift kasir.',
      memberCount: 4,
      permissions: ['Kelola Stok Toko', 'Laporan Cabang', 'Void Transaksi', 'Jadwal Kasir'],
    ),
    const UserRolePermission(
      roleName: 'Kasir / POS Cashier',
      description: 'Hanya akses modul kasir POS, cetak struk, dan input pelanggan.',
      memberCount: 14,
      permissions: ['Buat Transaksi POS', 'Input Pelanggan', 'Cetak Ulang Struk'],
    ),
    const UserRolePermission(
      roleName: 'Gudang & Logistik',
      description: 'Input barang masuk (stock in), opname, dan cek pengiriman supplier.',
      memberCount: 3,
      permissions: ['Penerimaan Barang', 'Stock Opname', 'Kontak Supplier'],
    ),
  ];

  List<UserRolePermission> get userRoles => List.unmodifiable(_userRoles);

  // ==================== HELP & SUPPORT STATE ====================
  final List<FaqItem> _faqs = [
    const FaqItem(
      id: 'faq-01',
      category: 'Inventaris & Stok',
      question: 'Bagaimana cara AI Memory Engine menghitung rekomendasi restock?',
      answer:
          'Memory Engine melacak laju penjualan (turnover rate) dan waktu tunggu pengiriman (lead time) supplier selama 6 bulan terakhir. Jika sisa stok diperkirakan habis dalam 3 hari ke depan, sistem otomatis menaikkan status menjadi "CRITICAL" dan menyarankan jumlah restock optimal.',
    ),
    const FaqItem(
      id: 'faq-02',
      category: 'AI Supri Assistant',
      question: 'Apa saja perintah suara / teks yang dapat dipahami Supri AI?',
      answer:
          'Supri dapat menganalisis laba bersih mingguan, mendeteksi produk slow-moving, mengeksekusi order restock satu klik, memberikan ide konten viral TikTok untuk produk tertentu, dan menjawab status pengiriman supplier.',
    ),
    const FaqItem(
      id: 'faq-03',
      category: 'Kasir & POS',
      question: 'Apakah aplikasi dapat beroperasi jika koneksi internet terputus (Offline)?',
      answer:
          'Ya, aplikasi dilengkapi mode Local Cache. Transaksi kasir tetap tersimpan di memori perangkat dan akan otomatis disinkronkan ke cloud saat koneksi internet kembali stabil.',
    ),
    const FaqItem(
      id: 'faq-04',
      category: 'Pajak & Laporan',
      question: 'Bagaimana mengatur tarif PPN 11% dan mencetak laporan resmi?',
      answer:
          'Buka menu Settings > Pajak & Biaya, aktifkan toggle PPN dan tentukan tarif 11%. Anda dapat mengunduh rekap faktur penjualan format PDF atau Excel melalui menu Report kapan saja.',
    ),
    const FaqItem(
      id: 'faq-05',
      category: 'Perangkat & Printer',
      question: 'Printer kasir apa saja yang didukung oleh Vault?',
      answer:
          'Mendukung printer thermal ukuran 58mm dan 80mm via koneksi Bluetooth, USB, maupun Ethernet LAN (seperti Epson, Panda, Iware, Xprinter).',
    ),
  ];

  List<FaqItem> get faqs => List.unmodifiable(_faqs);

  final List<SupportTicket> _tickets = [
    const SupportTicket(
      id: 'TCK-2026-091',
      subject: 'Permintaan Integrasi Mesin EDC BCA ke Kasir Terminal 1',
      category: 'Hardware & EDC',
      status: 'Diproses',
      priority: 'Sedang',
      date: '12 Okt 2026',
    ),
    const SupportTicket(
      id: 'TCK-2026-088',
      subject: 'Sinkronisasi Stok Cabang Seminyak saat Pemadaman Listrik',
      category: 'Sinkronisasi Data',
      status: 'Selesai',
      priority: 'Tinggi',
      date: '10 Okt 2026',
    ),
  ];

  List<SupportTicket> get tickets => List.unmodifiable(_tickets);

  void submitSupportTicket(SupportTicket ticket) {
    _tickets.insert(0, ticket);
    notifyListeners();
  }

  // ==================== REPORTS STATE ====================
  String _reportPeriod = 'Bulan Ini';
  String get reportPeriod => _reportPeriod;

  void setReportPeriod(String period) {
    _reportPeriod = period;
    notifyListeners();
  }

  // ==================== SHIPMENT RECEIVE ACTION ====================
  void markShipmentReceived(String id) {
    final index = _shipments.indexWhere((s) => s.id == id);
    if (index != -1) {
      final received = _shipments.removeAt(index);
      // Add stock to items
      final itemIndex = _items.indexWhere((i) => i.name.toLowerCase() == received.productName.toLowerCase());
      if (itemIndex != -1) {
        _items[itemIndex] = _items[itemIndex].copyWith(
          stockIn: _items[itemIndex].stockIn + 50,
          isOutOfStock: false,
        );
      }
      notifyListeners();
    }
  }

  // Actions
  void addProduct(InventoryItem item) {
    _items.insert(0, item);
    notifyListeners();
  }

  void deleteProduct(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void restockItem(String id, int qty) {
    final index = _items.indexWhere((it) => it.id == id);
    if (index != -1) {
      final current = _items[index];
      _items[index] = current.copyWith(
        stockIn: current.stockIn + qty,
        isOutOfStock: false,
      );
      notifyListeners();
    }
  }

  void executeAllRecommendedRestock() {
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].stockIn < _items[i].totalQty * 0.3 || _items[i].isOutOfStock) {
        _items[i] = _items[i].copyWith(
          stockIn: (_items[i].totalQty * 0.85).round(),
          isOutOfStock: false,
        );
      }
    }

    _chatMessages.add(
      AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        text:
            'Beres Bos! Semua order restock otomatis sebanyak **120 unit** telah dikirim ke supplier. Estimasi barang sampai 2 hari lagi.',
        timestamp: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  void clearDashboardData() {
    _items.clear();
    for (int i = 0; i < _outlets.length; i++) {
      _outlets[i] = _outlets[i].copyWith(dailySales: 0);
    }
    notifyListeners();
  }

  void resetToDemoData() {
    _items.clear();
    _items.addAll([
      InventoryItem(
        id: 'prod-1',
        name: 'Headphones',
        sku: 'SKU-300',
        category: 'Electronic',
        totalQty: 200,
        stockIn: 150,
        price: 4000,
        costPrice: 2800,
        priority: PriorityLevel.high,
        tag: 'Fast Moving',
        imageAsset: 'headphones',
      ),
      InventoryItem(
        id: 'prod-2',
        name: 'Helmets',
        sku: 'SKU-900',
        category: 'Watch',
        totalQty: 500,
        stockIn: 350,
        price: 7000,
        costPrice: 4500,
        priority: PriorityLevel.medium,
        tag: 'Discounted',
        imageAsset: 'helmet',
      ),
      InventoryItem(
        id: 'prod-3',
        name: 'T Shirts',
        sku: 'SKU-300',
        category: 'Fashion',
        totalQty: 2000,
        stockIn: 560,
        price: 3000,
        costPrice: 1600,
        priority: PriorityLevel.high,
        tag: 'Fast Moving',
        imageAsset: 'shirt',
      ),
      InventoryItem(
        id: 'prod-4',
        name: 'Sunglasses',
        sku: 'SKU-300',
        category: 'Fashion',
        totalQty: 3000,
        stockIn: 1000,
        price: 5000,
        costPrice: 2900,
        priority: PriorityLevel.low,
        tag: 'Low Demand',
        imageAsset: 'glasses',
      ),
      InventoryItem(
        id: 'prod-5',
        name: 'Backpack Explorer',
        sku: 'SKU-770',
        category: 'Fashion',
        totalQty: 180,
        stockIn: 25,
        price: 100,
        costPrice: 60,
        priority: PriorityLevel.high,
        tag: 'Fast Moving',
        imageAsset: 'backpack',
      ),
    ]);
    notifyListeners();
  }

  Future<void> sendMessageToSupri(
    String text, {
    String? imageUrl,
    String? fileName,
    String? base64,
  }) async {
    if (text.trim().isEmpty && imageUrl == null && fileName == null) return;

    // Add user message immediately (including attachments)
    _chatMessages.add(
      AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.user,
        text: text,
        timestamp: DateTime.now(),
        attachedImageUrl: imageUrl,
        attachedFileName: fileName,
        attachedImageBase64: base64,
      ),
    );
    notifyListeners();

    final lower = text.toLowerCase();

    // 1. Direct AI Execution: Clear / Wipe Dashboard or Delete all data
    if (lower.contains('kosongin') ||
        lower.contains('kosongkan') ||
        lower.contains('hapus semua produk') ||
        lower.contains('hapus semua data') ||
        lower.contains('clear dashboard') ||
        lower.contains('bersihkan dashboard')) {
      clearDashboardData();

      final confirmationMsg = AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        text:
            'Siap, Bos! Izin diterima dan perintah langsung dieksekusi: Seluruh data dashboard dan inventaris produk telah berhasil dikosongkan total.\n\n'
            'Tampilan dashboard sekarang sudah bersih 100% dan siap digunakan untuk pencatatan baru 👍\n\n'
            '*(Kapan pun Bos ingin mengembalikan data demo awal, cukup ketik "reset data" atau "isi data lagi ya Bos)*.',
        timestamp: DateTime.now(),
      );
      _chatMessages.add(confirmationMsg);
      notifyListeners();
      return;
    }

    // 2. Direct AI Execution: Reset / Restore demo data
    if (lower.contains('isi data demo') ||
        lower.contains('balikin data') ||
        lower.contains('reset data') ||
        lower.contains('pulihkan data')) {
      resetToDemoData();

      final restoreMsg = AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        text:
            'Beres Bos! Seluruh data demo inventaris produk dan metrik penjualan telah berhasil dipulihkan kembali seperti semula.',
        timestamp: DateTime.now(),
      );
      _chatMessages.add(restoreMsg);
      notifyListeners();
      return;
    }

    // 3. AI Agent Action: Update / Tambah / Kurang Stok Produk di Database (CRUD Stock)
    if (lower.contains('stok') &&
        (lower.contains('update') ||
            lower.contains('ubah') ||
            lower.contains('ganti') ||
            lower.contains('tambah') ||
            lower.contains('kurang') ||
            lower.contains('set')) &&
        !lower.contains('tambah produk') &&
        !lower.contains('buat produk')) {
      final numMatches = RegExp(r'\d+').allMatches(text);
      if (numMatches.isNotEmpty) {
        final qty = int.tryParse(numMatches.last.group(0) ?? '') ?? 0;
        InventoryItem? matchedItem;
        for (final item in _items) {
          if (lower.contains(item.name.toLowerCase())) {
            matchedItem = item;
            break;
          }
        }

        if (matchedItem != null) {
          final isAddition = lower.contains('tambah') &&
              !lower.contains('ubah') &&
              !lower.contains('update');
          final oldQty = matchedItem.totalQty;
          final newQty = isAddition ? (oldQty + qty) : qty;

          final idx = _items.indexOf(matchedItem);
          _items[idx] = matchedItem.copyWith(
            totalQty: newQty,
            stockIn: newQty,
            isOutOfStock: newQty <= 0,
          );
          notifyListeners();

          final msgText =
              '✅ **Update Stok Berhasil!**\n\n'
              'Supri telah memperbarui data stok di database:\n'
              '- Produk: **${matchedItem.name}** (${matchedItem.sku})\n'
              '- Stok Sebelumnya: $oldQty unit\n'
              '- **Stok Sekarang: $newQty unit**\n\n'
              'Tampilan katalog dan dashboard langsung tersinkronisasi 👍';

          final confirmationMsg = AiChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            role: MessageRole.assistant,
            text: msgText,
            timestamp: DateTime.now(),
          );
          _chatMessages.add(confirmationMsg);
          notifyListeners();
          TtsService.speakNaturalMaleIndonesian(
              'Beres Bos! Stok untuk ${matchedItem.name} sudah diupdate jadi $newQty unit.');
          return;
        }
      }
    }

    // 4. AI Agent Action: Tambah Produk Baru ke Database (CRUD Create)
    if (lower.startsWith('tambah produk') || lower.contains('buat produk baru')) {
      final nameClean = text.replaceFirst(
          RegExp(r'tambah produk|buat produk baru', caseSensitive: false), '').trim();
      final numMatches = RegExp(r'\d+').allMatches(nameClean);
      double price = 15000;
      int stock = 50;
      if (numMatches.length >= 2) {
        price = double.tryParse(numMatches.elementAt(0).group(0) ?? '15000') ?? 15000;
        stock = int.tryParse(numMatches.elementAt(1).group(0) ?? '50') ?? 50;
      } else if (numMatches.length == 1) {
        price = double.tryParse(numMatches.first.group(0) ?? '15000') ?? 15000;
      }
      final rawName = nameClean
          .replaceAll(RegExp(r'\d+'), '')
          .replaceAll(RegExp(r'harga|stok|kategori|unit|rp', caseSensitive: false), '')
          .trim();
      final finalName = rawName.isNotEmpty ? rawName : 'Produk Baru';

      addCustomProduct(name: finalName, price: price, stock: stock, category: 'Umum');
      final msgText =
          '✅ **Produk Baru Berhasil Didaftarkan!**\n\n'
          '- Nama: **$finalName**\n'
          '- Harga Jual: Rp ${price.toInt()}\n'
          '- Stok Awal: $stock unit\n'
          '- Status: Aktif dan langsung muncul di katalog kasir POS.';

      final confirmationMsg = AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        text: msgText,
        timestamp: DateTime.now(),
      );
      _chatMessages.add(confirmationMsg);
      notifyListeners();
      TtsService.speakNaturalMaleIndonesian(
          'Produk baru $finalName berhasil didaftarkan ke sistem inventaris ya Bos.');
      return;
    }

    // 5. AI Agent Action: Hapus Produk dari Database (CRUD Delete)
    if (lower.startsWith('hapus produk') || lower.startsWith('delete produk')) {
      final target = text.replaceFirst(
          RegExp(r'hapus produk|delete produk', caseSensitive: false), '').trim();
      final ok = deleteProductByName(target);
      final msgText = ok
          ? '🗑️ **Produk Berhasil Dihapus!**\n\nProduk "$target" telah dihapus dari inventaris aktif dan dipindahkan ke Recently Deleted (masa retensi 30 hari).'
          : 'Produk "$target" tidak ditemukan di katalog toko Bos. Coba cek kembali nama produknya.';

      final confirmationMsg = AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        text: msgText,
        timestamp: DateTime.now(),
      );
      _chatMessages.add(confirmationMsg);
      notifyListeners();
      TtsService.speakNaturalMaleIndonesian(ok
          ? 'Produk $target berhasil dihapus ya Bos.'
          : 'Produk tidak ditemukan Bos.');
      return;
    }
    final isCsvUpload = fileName?.toLowerCase().endsWith('.csv') == true ||
        lower.startsWith('ekstrak csv') ||
        lower.startsWith('extract csv') ||
        lower.startsWith('impor csv') ||
        (text.contains('\n') &&
            (text.contains(',') || text.contains(';')) &&
            (lower.contains('nama') ||
                lower.contains('harga') ||
                lower.contains('stok') ||
                lower.contains('product') ||
                lower.contains('produk')));

    // 6. AI Agent Action: Notifikasi Expired & Stok Menipis
    if (!isCsvUpload &&
        (lower.contains('expired') ||
            lower.contains('kadaluarsa') ||
            lower.contains('stok menipis') ||
            lower.contains('barang mau habis') ||
            lower.contains('peringatan') ||
            (lower.contains('notifikasi') && !lower.contains('csv')))) {
      final nearExp = nearExpiryItems;
      final exp = expiredItems;
      final low = lowStockItems;
      final buffer = StringBuffer();
      buffer.writeln('🔔 **Laporan Notifikasi & Peringatan Dini Supri:**\n');

      if (exp.isNotEmpty) {
        buffer.writeln('❌ **SUDAH KEDALUWARSA (${exp.length} Produk):**');
        for (final it in exp) {
          buffer.writeln(
              '- **${it.name}** (Kadaluarsa: ${it.expiryDate?.toIso8601String().substring(0, 10)}) -> *Segera tarik dari etalase!*');
        }
        buffer.writeln('');
      }

      if (nearExp.isNotEmpty) {
        buffer.writeln('⚠️ **MENDEKATI KEDALUWARSA ≤14 HARI (${nearExp.length} Produk):**');
        for (final it in nearExp) {
          buffer.writeln(
              '- **${it.name}**: sisa ${it.daysUntilExpiry} hari (${it.expiryDate?.toIso8601String().substring(0, 10)}) - Stok: ${it.totalQty} unit');
        }
        buffer.writeln('💡 *Saran Supri: Buat promo flash sale atau bundling diskon 30-50% untuk produk ini!*\n');
      }

      if (low.isNotEmpty) {
        buffer.writeln('⚠️ **STOK MENIPIS / INGIN HABIS (${low.length} Produk):**');
        for (final it in low) {
          buffer.writeln('- **${it.name}**: tersisa **${it.totalQty} unit** (Stok di rak: ${it.stockIn})');
        }
        buffer.writeln('💡 *Saran Supri: Segera buat pesanan restock sebelum kehabisan saat weekend!*');
      }

      if (exp.isEmpty && nearExp.isEmpty && low.isEmpty) {
        buffer.writeln('🎉 Kondisi toko aman! Tidak ada barang kedaluwarsa dan seluruh stok masih di atas batas minimum.');
      }

      final confirmationMsg = AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        text: buffer.toString(),
        timestamp: DateTime.now(),
      );
      _chatMessages.add(confirmationMsg);
      notifyListeners();
      final ttsSummary = (exp.isNotEmpty || nearExp.isNotEmpty || low.isNotEmpty)
          ? 'Perhatian Bos! Ada ${nearExp.length} produk mendekati tanggal kedaluwarsa dan ${low.length} produk yang stoknya menipis.'
          : 'Semua aman terkendali Bos! Tidak ada barang kedaluwarsa dan stok aman.';
      TtsService.speakNaturalMaleIndonesian(ttsSummary);
      return;
    }

    // 7. AI Agent Action: Analisa Keseluruhan Keuangan
    if ((lower.contains('keuangan') &&
            (lower.contains('analisa') ||
                lower.contains('analisis') ||
                lower.contains('laporan') ||
                lower.contains('ringkasan') ||
                lower.contains('evaluasi') ||
                lower.contains('keseluruhan'))) ||
        lower.contains('laba rugi') ||
        lower.contains('finansial') ||
        (lower.contains('omzet') && lower.contains('toko')) ||
        lower.contains('laba bersih')) {
      final rev = _finance.totalRevenue;
      final profit = _finance.netProfit;
      final cash = _finance.cashInHand;
      final marginPct =
          (rev > 0) ? ((profit / rev) * 100).toStringAsFixed(1) : '27.4';

      final msgText =
          '📊 **Analisis Menyeluruh Keuangan Toko oleh Supri:**\n\n'
          '1. **Metrik Finansial Utama:**\n'
          '   - Total Omzet Toko: **Rp ${(rev / 1000000).toStringAsFixed(1)} Juta**\n'
          '   - Laba Bersih: **Rp ${(profit / 1000000).toStringAsFixed(1)} Juta** (Net Margin: $marginPct%)\n'
          '   - Kas di Tangan (Liquidity): **Rp ${(cash / 1000000).toStringAsFixed(1)} Juta**\n'
          '   - Status Finansial: **SEHAT & PROFITABEL**\n\n'
          '💡 **3 Rekomendasi Taktis Supri Minggu Ini:**\n'
          '1. **Genjot Bundling Menu Terlaris**: Pasangkan item Fast Moving dengan item margin tebal untuk menaikkan nilai rata-rata belanja kasir.\n'
          '2. **Amankan Stok Kritis**: Terbitkan PO restock segera untuk ${lowStockItems.length} produk yang stoknya tersisa sedikit agar tidak kehilangan omzet.\n'
          '3. **Optimasi Diskon Barang Mendekati Expired**: Jalankan promo bundling untuk ${nearExpiryItems.length} produk makanan/minuman yang mendekati tanggal expired.';

      final confirmationMsg = AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        text: msgText,
        timestamp: DateTime.now(),
      );
      _chatMessages.add(confirmationMsg);
      notifyListeners();
      TtsService.speakNaturalMaleIndonesian(
          'Berikut analisa keuangan menyeluruh toko kita Bos. Total omzet mencapai Rp ${(rev / 1000000).toStringAsFixed(1)} Juta dengan net margin $marginPct persen.');
      return;
    }

    // 8. AI Agent Action: Ekspor Data Penjualan Menjadi CSV yang Rapih
    if (lower.contains('ekspor') ||
        lower.contains('export') ||
        lower.contains('unduh csv') ||
        lower.contains('download csv') ||
        lower.contains('csv penjualan') ||
        lower.contains('laporan csv')) {
      final csvData = exportSalesCsv();
      final msgText =
          'Siap Bos! Data penjualan telah berhasil Supri ekspor ke format CSV yang rapih:\n\n'
          '```csv\n$csvData```\n'
          '📌 **Ringkasan Ekspor Penjualan:**\n'
          '- Total Transaksi: ${_transactions.length} struk kasir\n'
          '- Format Kolom: Invoice, Tanggal, Kasir, Pelanggan, Metode_Bayar, Total_Belanja, Status\n'
          '- Data terstruktur rapi dan siap diunduh atau diproses ke sistem akuntansi 👍';

      final confirmationMsg = AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        text: msgText,
        timestamp: DateTime.now(),
      );
      _chatMessages.add(confirmationMsg);
      notifyListeners();
      TtsService.speakNaturalMaleIndonesian(
          'Beres Bos! Data penjualan sudah berhasil diekspor ke format CSV yang rapih.');
      return;
    }

    // 9. AI Agent Action: Ekstrak CSV dari Pengguna untuk Masuk ke Stok (dengan Expiry & Alerts)
    if (isCsvUpload) {
      final result = importStockFromCsv(text);
      final int importedCount = result['importedCount'] as int;
      final List<String> alerts = result['alerts'] as List<String>;
      final List<InventoryItem> itemsList = result['items'] as List<InventoryItem>;

      final buffer = StringBuffer();
      buffer.writeln('📦 **Ekstraksi CSV Stok Sukses!**\n');
      buffer.writeln('Supri telah memproses $importedCount produk langsung masuk ke database stok:');
      for (final it in itemsList.take(6)) {
        final expStr = it.expiryDate != null
            ? ' | Exp: ${it.expiryDate!.toIso8601String().substring(0, 10)}'
            : '';
        buffer.writeln('- **${it.name}**: Rp ${it.price.toInt()} (Stok: ${it.totalQty}$expStr)');
      }
      if (itemsList.length > 6) {
        buffer.writeln('*(dan ${itemsList.length - 6} produk lainnya)*');
      }

      if (alerts.isNotEmpty) {
        buffer.writeln('\n🚨 **NOTIFIKASI PERINGATAN DARI SUPRI:**');
        for (final a in alerts) {
          buffer.writeln(a);
        }
      } else {
        buffer.writeln('\n✅ Seluruh produk dalam kondisi aman dan stok telah diperbarui.');
      }

      final confirmationMsg = AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        text: buffer.toString(),
        timestamp: DateTime.now(),
      );
      _chatMessages.add(confirmationMsg);
      notifyListeners();
      final ttsSummary = alerts.isNotEmpty
          ? 'Beres Bos! Ekstraksi CSV sukses untuk $importedCount produk. Perhatian, ada ${alerts.length} produk yang stoknya menipis atau mendekati tanggal kedaluwarsa!'
          : 'Beres Bos! Ekstraksi CSV sukses, $importedCount produk sudah masuk ke stok toko.';
      TtsService.speakNaturalMaleIndonesian(ttsSummary);
      return;
    }
    // 10. Call Gemini API with unconstrained general AI personality, vision & memory context
    final response = await GeminiService.askGemini(
      prompt: text.isNotEmpty
          ? text
          : (fileName != null
              ? 'Tolong analisa file $fileName ini.'
              : 'Tolong analisa gambar ini.'),
      items: _items,
      finance: _finance,
      history: _chatMessages,
      attachedImageBase64: base64,
      attachedFileName: fileName,
    );
    _chatMessages.add(response);
    notifyListeners();
    TtsService.speakNaturalMaleIndonesian(response.text);
  }

  // ==================== RECENTLY DELETED (SOFT DELETE HOLD) ====================
  final List<InventoryItem> _recentlyDeletedItems = [];
  List<InventoryItem> get recentlyDeletedItems => List.unmodifiable(_recentlyDeletedItems);

  void softDeleteProduct(String id, {String reason = 'Discontinued', int holdDays = 30}) {
    final index = _items.indexWhere((it) => it.id == id);
    if (index != -1) {
      final removed = _items.removeAt(index);
      final now = DateTime.now();
      _recentlyDeletedItems.insert(
        0,
        removed.copyWith(
          deletedAt: now,
          deleteAfter: now.add(Duration(days: holdDays)),
          deletedReason: reason,
        ),
      );
      notifyListeners();
    }
  }

  void restoreProduct(String id) {
    final index = _recentlyDeletedItems.indexWhere((it) => it.id == id);
    if (index != -1) {
      final restored = _recentlyDeletedItems.removeAt(index).copyWith(clearDeleted: true);
      _items.insert(0, restored);
      notifyListeners();
    }
  }

  int purgeExpiredDeletedProducts({bool forceAll = false}) {
    final now = DateTime.now();
    final before = _recentlyDeletedItems.length;
    if (forceAll) {
      _recentlyDeletedItems.clear();
    } else {
      _recentlyDeletedItems.removeWhere(
        (it) => it.deleteAfter != null && !it.deleteAfter!.isAfter(now),
      );
    }
    final purged = before - _recentlyDeletedItems.length;
    if (purged > 0) notifyListeners();
    return purged;
  }

  // ==================== POS TERMINAL & OFFLINE-FIRST QUEUE ====================
  final Map<String, int> _cartQuantities = {};
  Map<String, int> get cartQuantities => Map.unmodifiable(_cartQuantities);

  bool _isOfflineMode = false;
  bool get isOfflineMode => _isOfflineMode;

  void setOfflineMode(bool offline) {
    _isOfflineMode = offline;
    if (!offline && _offlineQueue.isNotEmpty) {
      syncOfflineTransactions();
    } else {
      notifyListeners();
    }
  }

  final List<Map<String, dynamic>> _transactions = [
    {
      'id': 'tx-1001',
      'invoice_number': 'INV-20261026-0001',
      'created_at': '26/10/2026 14:20',
      'customer_name': 'Budi Santoso',
      'cashier_name': 'Budi Santoso',
      'outlet_name': 'Vault Central SCBD (Flagship)',
      'payment_method': 'QRIS',
      'payment_status': 'Completed',
      'sync_status': 'synced',
      'subtotal': 69000.0,
      'discount': 0.0,
      'tax_amount': 7590.0,
      'service_fee': 0.0,
      'total_amount': 76590.0,
      'amount_paid': 76590.0,
      'items': [
        {'name': 'Headphones', 'quantity': 1, 'price': 25000.0, 'subtotal': 25000.0},
        {'name': 'T Shirts', 'quantity': 2, 'price': 22000.0, 'subtotal': 44000.0},
      ],
    },
  ];
  List<Map<String, dynamic>> get transactions => List.unmodifiable(_transactions);

  final List<Map<String, dynamic>> _offlineQueue = [];
  List<Map<String, dynamic>> get offlineQueue => List.unmodifiable(_offlineQueue);

  void addToCart(InventoryItem item) {
    if (item.stockIn <= 0 || item.isOutOfStock) return;
    final current = _cartQuantities[item.id] ?? 0;
    if (current < item.stockIn) {
      _cartQuantities[item.id] = current + 1;
      notifyListeners();
    }
  }

  void updateCartQuantity(String productId, int qty) {
    final idx = _items.indexWhere((i) => i.id == productId);
    if (idx == -1) return;
    if (qty <= 0) {
      _cartQuantities.remove(productId);
    } else {
      _cartQuantities[productId] = qty > _items[idx].stockIn ? _items[idx].stockIn : qty;
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cartQuantities.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _cartQuantities.clear();
    notifyListeners();
  }

  Map<String, dynamic>? checkoutPosTransaction({
    String paymentMethod = 'Cash',
    String customerName = 'Walk-in Customer',
    String outletName = 'Vault Central SCBD (Flagship)',
    double discount = 0,
    double? amountPaid,
  }) {
    if (_cartQuantities.isEmpty) return null;

    double subtotal = 0;
    final List<Map<String, dynamic>> txItems = [];

    for (final entry in _cartQuantities.entries) {
      final idx = _items.indexWhere((i) => i.id == entry.key);
      if (idx == -1) continue;
      final prod = _items[idx];
      final qty = entry.value > prod.stockIn ? prod.stockIn : entry.value;
      if (qty <= 0) continue;

      final lineSubtotal = prod.price * qty;
      subtotal += lineSubtotal;

      final remainingStock = prod.stockIn - qty;
      _items[idx] = prod.copyWith(
        stockIn: remainingStock,
        isOutOfStock: remainingStock <= 0,
      );

      txItems.add({
        'product_id': prod.id,
        'name': prod.name,
        'sku': prod.sku,
        'quantity': qty,
        'price': prod.price,
        'subtotal': lineSubtotal,
      });
    }

    if (txItems.isEmpty) return null;

    final taxable = (subtotal - discount) < 0 ? 0.0 : (subtotal - discount);
    final taxAmount = _settings.taxEnabled ? (taxable * _settings.taxRate / 100.0) : 0.0;
    final serviceFee = _settings.serviceFeeEnabled ? (taxable * _settings.serviceFeeRate / 100.0) : 0.0;
    final totalAmount = taxable + taxAmount + serviceFee;
    final paid = amountPaid ?? totalAmount;

    final invoiceNo = _isOfflineMode
        ? 'INV-OFFLINE-${(_offlineQueue.length + 1).toString().padLeft(4, '0')}'
        : 'INV-20261026-${(_transactions.length + 1).toString().padLeft(4, '0')}';

    final record = <String, dynamic>{
      'id': 'tx-${DateTime.now().millisecondsSinceEpoch}',
      'invoice_number': invoiceNo,
      'created_at': '26/10/2026 14:35',
      'customer_name': customerName,
      'cashier_name': 'Budi Santoso',
      'outlet_name': outletName,
      'payment_method': paymentMethod,
      'payment_status': 'Completed',
      'sync_status': _isOfflineMode ? 'pending' : 'synced',
      'subtotal': subtotal,
      'discount': discount,
      'tax_amount': taxAmount,
      'service_fee': serviceFee,
      'total_amount': totalAmount,
      'amount_paid': paid,
      'change_amount': (paid - totalAmount) > 0 ? (paid - totalAmount) : 0.0,
      'items': txItems,
    };

    _transactions.insert(0, record);
    if (_isOfflineMode) {
      _offlineQueue.add(record);
    }
    _cartQuantities.clear();
    notifyListeners();
    return record;
  }

  int syncOfflineTransactions() {
    final count = _offlineQueue.length;
    for (final queued in _offlineQueue) {
      queued['sync_status'] = 'synced';
      if (queued['invoice_number'].toString().startsWith('INV-OFFLINE-')) {
        queued['invoice_number'] = queued['invoice_number'].toString().replaceFirst('INV-OFFLINE-', 'INV-SYNCED-');
      }
    }
    _offlineQueue.clear();
    notifyListeners();
    return count;
  }

  String formatEscPosReceipt(Map<String, dynamic> tx, {String? paperWidth}) {
    final width = (paperWidth ?? _settings.paperWidth) == '80mm' ? 48 : 32;
    String line([String ch = '-']) => List.filled(width, ch).join();
    String center(String text) {
      final s = text.length > width ? text.substring(0, width) : text;
      final pad = ((width - s.length) / 2).floor();
      return '${' ' * (pad < 0 ? 0 : pad)}$s';
    }
    String row(String left, String right) {
      final space = width - left.length - right.length;
      if (space >= 1) return '$left${' ' * space}$right';
      final maxLeft = (width - right.length - 1).clamp(1, width);
      return '${left.substring(0, maxLeft)} $right';
    }

    final items = (tx['items'] as List?) ?? const [];
    final lines = <String>[
      line('='),
      center('PAKASIR VAULT'),
      center((tx['outlet_name'] ?? 'SCBD Flagship Store').toString()),
      center('Jl. Jend. Sudirman Kav. 52'),
      center('Telp: +62 812-3456-7890'),
      line('='),
      'No. Faktur : ${tx['invoice_number'] ?? 'INV-20261026-0042'}',
      'Waktu      : ${tx['created_at'] ?? '26/10/2026 14:35'}',
      'Kasir      : ${tx['cashier_name'] ?? 'Budi Santoso'}',
      'Pelanggan  : ${tx['customer_name'] ?? 'Walk-in Customer'}',
      line('-'),
      for (final it in items)
        row('${it['quantity']}x ${it['name']}', 'Rp ${(it['subtotal'] as num).toStringAsFixed(0)}'),
      line('-'),
      row('Subtotal', 'Rp ${(tx['subtotal'] as num? ?? 0).toStringAsFixed(0)}'),
      row('PPN (${_settings.taxRate.toStringAsFixed(0)}%)', 'Rp ${(tx['tax_amount'] as num? ?? 0).toStringAsFixed(0)}'),
      line('-'),
      row('TOTAL AKHIR', 'Rp ${(tx['total_amount'] as num? ?? 0).toStringAsFixed(0)}'),
      'Metode Bayar : ${tx['payment_method'] ?? 'QRIS Dinamis'}',
      'Status       : ${tx['sync_status'] == 'pending' ? 'ANTRIAN OFFLINE' : 'LUNAS'}',
      line('='),
      center('Terima kasih atas kunjungan'),
      center('Barang yang sudah dibeli'),
      center('tidak dapat ditukar kembali'),
      line('='),
    ];
    return lines.join('\n');
  }

  // ==================== 2-WAY VOICE SESSION STATE MACHINE ====================
  VoiceSessionState _voiceState = VoiceSessionState.idle;
  VoiceSessionState get voiceState => _voiceState;

  String _voiceStatusMessage = '';
  String get voiceStatusMessage => _voiceStatusMessage;

  void startVoiceSession() {
    _voiceState = VoiceSessionState.greeting;
    const greetingText =
        'Halo Bos! Supri di sini, siap bantu kelola inventaris, cek stok, atau analisa omzet toko hari ini. Mau cek apa nih Bos?';
    _voiceStatusMessage = greetingText;

    if (_chatMessages.isEmpty || _chatMessages.last.text != greetingText) {
      _chatMessages.add(
        AiChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: MessageRole.assistant,
          text: greetingText,
          timestamp: DateTime.now(),
        ),
      );
    }
    notifyListeners();

    TtsService.speakNaturalMaleIndonesian(greetingText, onComplete: () {
      _voiceState = VoiceSessionState.listening;
      notifyListeners();
    });
  }

  void triggerMicGreeting() {
    startVoiceSession();
  }

  void stopVoiceSession() {
    TtsService.stop();
    _voiceState = VoiceSessionState.idle;
    _voiceStatusMessage = '';
    notifyListeners();
  }

  Future<void> processVoiceTranscript(String transcript) async {
    if (transcript.trim().isEmpty) {
      stopVoiceSession();
      return;
    }
    _voiceState = VoiceSessionState.processing;
    _voiceStatusMessage = transcript;
    notifyListeners();
    await sendMessageToSupri(transcript);
    _voiceState = VoiceSessionState.speaking;
    _voiceStatusMessage = _chatMessages.isNotEmpty ? _chatMessages.last.text : '';
    notifyListeners();
    TtsService.speakNaturalMaleIndonesian(_voiceStatusMessage, onComplete: () {
      _voiceState = VoiceSessionState.listening;
      notifyListeners();
    });
  }
}
