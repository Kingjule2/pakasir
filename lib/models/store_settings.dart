class StoreSettings {
  final String storeName;
  final String storeTagline;
  final String email;
  final String phone;
  final String address;
  final String currencySymbol;
  final String currencyCode;
  final double taxRate;
  final bool taxEnabled;
  final double serviceFeeRate;
  final bool serviceFeeEnabled;
  final String printerName;
  final String paperWidth;
  final bool autoPrintReceipt;
  final bool soundAlerts;
  final int lowStockThreshold;
  final bool lowStockNotification;
  final bool dailyReportEmail;
  final String language;

  const StoreSettings({
    required this.storeName,
    required this.storeTagline,
    required this.email,
    required this.phone,
    required this.address,
    required this.currencySymbol,
    required this.currencyCode,
    required this.taxRate,
    required this.taxEnabled,
    required this.serviceFeeRate,
    required this.serviceFeeEnabled,
    required this.printerName,
    required this.paperWidth,
    required this.autoPrintReceipt,
    required this.soundAlerts,
    required this.lowStockThreshold,
    required this.lowStockNotification,
    required this.dailyReportEmail,
    required this.language,
  });

  factory StoreSettings.defaultSettings() {
    return const StoreSettings(
      storeName: 'Vault Retail & Lifestyle',
      storeTagline: 'SaaS Smart Inventory & POS Management',
      email: 'owner@vault-retail.id',
      phone: '+62 821-8899-7766',
      address: 'Jl. Jenderal Sudirman No. 52, SCBD Jakarta Selatan 12190',
      currencySymbol: 'Rp',
      currencyCode: 'IDR',
      taxRate: 11.0,
      taxEnabled: true,
      serviceFeeRate: 5.0,
      serviceFeeEnabled: false,
      printerName: 'Epson TM-T82X (Thermal)',
      paperWidth: '80mm',
      autoPrintReceipt: true,
      soundAlerts: true,
      lowStockThreshold: 20,
      lowStockNotification: true,
      dailyReportEmail: true,
      language: 'Bahasa Indonesia',
    );
  }

  StoreSettings copyWith({
    String? storeName,
    String? storeTagline,
    String? email,
    String? phone,
    String? address,
    String? currencySymbol,
    String? currencyCode,
    double? taxRate,
    bool? taxEnabled,
    double? serviceFeeRate,
    bool? serviceFeeEnabled,
    String? printerName,
    String? paperWidth,
    bool? autoPrintReceipt,
    bool? soundAlerts,
    int? lowStockThreshold,
    bool? lowStockNotification,
    bool? dailyReportEmail,
    String? language,
  }) {
    return StoreSettings(
      storeName: storeName ?? this.storeName,
      storeTagline: storeTagline ?? this.storeTagline,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyCode: currencyCode ?? this.currencyCode,
      taxRate: taxRate ?? this.taxRate,
      taxEnabled: taxEnabled ?? this.taxEnabled,
      serviceFeeRate: serviceFeeRate ?? this.serviceFeeRate,
      serviceFeeEnabled: serviceFeeEnabled ?? this.serviceFeeEnabled,
      printerName: printerName ?? this.printerName,
      paperWidth: paperWidth ?? this.paperWidth,
      autoPrintReceipt: autoPrintReceipt ?? this.autoPrintReceipt,
      soundAlerts: soundAlerts ?? this.soundAlerts,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      lowStockNotification:
          lowStockNotification ?? this.lowStockNotification,
      dailyReportEmail: dailyReportEmail ?? this.dailyReportEmail,
      language: language ?? this.language,
    );
  }
}
