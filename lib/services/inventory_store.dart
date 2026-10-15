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
class InventoryStore extends ChangeNotifier {
  // Navigation
  String _activeNav = 'Inventory';
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
  ];

  List<InventoryItem> get allItems => List.unmodifiable(_items);

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
  List<String> markAllShipmentsReceived() {
    final receivedNames = <String>[];
    for (final received in List<ShipmentItem>.from(_shipments)) {
      receivedNames.add(received.productName);
      final itemIndex = _items.indexWhere((i) => i.name.toLowerCase() == received.productName.toLowerCase());
      if (itemIndex != -1) {
        _items[itemIndex] = _items[itemIndex].copyWith(
          stockIn: _items[itemIndex].stockIn + 50,
          isOutOfStock: false,
        );
      }
    }
    _shipments.clear();
    notifyListeners();
    return receivedNames;
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
    _shipments.clear();
    _shipments.addAll([
      ShipmentItem(
        id: 'ship-1',
        productName: 'Backpack',
        sku: '#Sku-305',
        delayedDays: 5,
        supplier: 'PT Tas Nusantara',
      ),
      ShipmentItem(
        id: 'ship-2',
        productName: 'T Shirts',
        sku: '#Sku-305',
        delayedDays: 5,
        supplier: 'CV Solo Textile',
      ),
      ShipmentItem(
        id: 'ship-3',
        productName: 'Helmets',
        sku: '#Sku-305',
        delayedDays: 3,
        supplier: 'Surya Helmet Indah',
      ),
      ShipmentItem(
        id: 'ship-4',
        productName: 'Sunglass',
        sku: '#Sku-305',
        delayedDays: 3,
        supplier: 'Kacamata Raya',
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
    // 3. Direct AI Execution: Mark Shipment Received ("Barang Sampai")
    final isShipmentIntent = (lower.contains('shipmen') ||
            lower.contains('shipment') ||
            lower.contains('pengiriman') ||
            lower.contains('kiriman') ||
            lower.contains('supplier') ||
            lower.contains('barang')) &&
        (lower.contains('sampai') ||
            lower.contains('sampe') ||
            lower.contains('tiba') ||
            lower.contains('diterima') ||
            lower.contains('terima') ||
            lower.contains('acc') ||
            lower.contains('pencet') ||
            lower.contains('masuk'));

    if (isShipmentIntent) {
      if (_shipments.isEmpty) {
        final alreadyEmptyMsg = AiChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: MessageRole.assistant,
          text:
              'Halo Bos! Semua pengiriman supplier saat ini sudah berstatus **"Delivered/Diterima"** dan tidak ada antrean barang tertunda di menu Shipment 👍',
          timestamp: DateTime.now(),
        );
        _chatMessages.add(alreadyEmptyMsg);
        notifyListeners();
        return;
      }

      // Check if specific shipment item is mentioned
      final matchingShipment = _shipments.firstWhere(
        (s) => lower.contains(s.productName.toLowerCase()),
        orElse: () => ShipmentItem(id: '', productName: '', sku: '', delayedDays: 0, supplier: ''),
      );

      final isAll = lower.contains('semua') ||
          lower.contains('all') ||
          matchingShipment.id.isEmpty;

      if (isAll) {
        final count = _shipments.length;
        final names = markAllShipmentsReceived();
        final namesStr = names.join(', ');

        final confirmMsg = AiChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: MessageRole.assistant,
          text:
              'Siap, Bos! Perintah langsung dieksekusi ke sistem:\n\n'
              '✅ Tombol **"Barang Sampai"** untuk seluruh **$count pengiriman** ($namesStr) telah berhasil di-acc dan diterima di sistem.\n'
              '📦 Stok masing-masing barang di gudang otomatis bertambah **+50 unit**.\n'
              '📊 Status pada pelacakan pengiriman (Shipment Tracking) sekarang sudah bersih 100% dan dashboard telah sinkron real-time!',
          timestamp: DateTime.now(),
        );
        _chatMessages.add(confirmMsg);
        notifyListeners();
        return;
      } else {
        final pName = matchingShipment.productName;
        markShipmentReceived(matchingShipment.id);

        final confirmMsg = AiChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: MessageRole.assistant,
          text:
              'Siap, Bos! Pengiriman untuk **$pName** telah saya acc via tombol **"Barang Sampai"**.\n\n'
              'Stok $pName di gudang sudah otomatis ditambahkan **+50 unit** dan status pengirimannya sudah diselesaikan.',
          timestamp: DateTime.now(),
        );
        _chatMessages.add(confirmMsg);
        notifyListeners();
        return;
      }
    }

    // 4. Direct AI Execution: Execute Restock
    if ((lower.contains('restock') || lower.contains('kulakan')) &&
        (lower.contains('eksekusi') ||
            lower.contains('sekarang') ||
            lower.contains('langsung') ||
            lower.contains('semua') ||
            lower.contains('otomatis'))) {
      executeAllRecommendedRestock();
      return;
    }

    // 3. Call Gemini API with unconstrained general AI personality, vision & memory context
    final response = await GeminiService.askGemini(
      prompt: text.isNotEmpty ? text : (fileName != null ? 'Tolong analisa file $fileName ini.' : 'Tolong analisa gambar ini.'),
      items: _items,
      finance: _finance,
      history: _chatMessages,
      attachedImageBase64: base64,
      attachedFileName: fileName,
    );
    _chatMessages.add(response);
    notifyListeners();
  }
}
