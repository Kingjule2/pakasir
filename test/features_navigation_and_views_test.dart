import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakasir2/main.dart';
import 'package:pakasir2/models/customer_item.dart';
import 'package:pakasir2/services/inventory_store.dart';

void main() {
  group('Feature Views and Navigation Tests', () {
    testWidgets('Dashboard View renders KPIs, outlets leaderboard, and top products',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const VaultSaaSApp());
      await tester.pumpAndSettle();

      // Tap Dashboard on Sidebar
      await tester.tap(find.text('Dashboard').first);
      await tester.pumpAndSettle();

      // Verify Dashboard Header & KPIs
      expect(find.text('Selamat Datang kembali, Evano!'), findsOneWidget);
      expect(find.text('Penjualan Hari Ini'), findsOneWidget);
      expect(find.text('Omset Bulan Ini'), findsOneWidget);
      expect(find.text('Pelanggan Terdaftar'), findsOneWidget);
      expect(find.text('Performa Cabang Toko'), findsOneWidget);
      expect(find.text('Top Produk Paling Laris'), findsOneWidget);
      expect(find.text('Aktivitas Sistem Terkini'), findsOneWidget);
    });

    testWidgets('Customers View renders CRM table, search, and tiers',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const VaultSaaSApp());
      await tester.pumpAndSettle();

      // Open More sheet on Stitch Bottom Nav and tap Customers
      await tester.tap(find.text('More').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Customers').first);
      await tester.pumpAndSettle();
      // Verify Customers page
      expect(find.text('Direktori Pelanggan & CRM'), findsOneWidget);
      expect(find.text('Total Pelanggan'), findsOneWidget);
      expect(find.text('Pelanggan VIP'), findsOneWidget);
      expect(find.text('Akumulasi Belanja'), findsOneWidget);
      expect(find.text('Tambah Pelanggan'), findsOneWidget);

      // Verify Demo customer data
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Siti Rahmawati'), findsOneWidget);
    });

    testWidgets('Store View renders multi-outlets and status toggling',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const VaultSaaSApp());
      await tester.pumpAndSettle();

      // Open More sheet on Stitch Bottom Nav and tap Store
      await tester.tap(find.text('More').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Store').first);
      await tester.pumpAndSettle();
      // Verify Store page
      expect(find.text('Daftar Cabang & Outlet Toko'), findsOneWidget);
      expect(find.text('Status Operasional'), findsOneWidget);
      expect(find.text('Terminal POS Kasir'), findsOneWidget);
      expect(find.text('Vault Central SCBD (Flagship)'), findsOneWidget);
      expect(find.text('Vault Hub Paris Van Java'), findsOneWidget);
    });

    testWidgets('Report View renders financial P&L and payment methods',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const VaultSaaSApp());
      await tester.pumpAndSettle();

      // Open More sheet on Stitch Bottom Nav and tap Report
      await tester.tap(find.text('More').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Report').first);
      await tester.pumpAndSettle();
      // Verify Report page
      expect(find.text('Laporan Keuangan & Analitik Penjualan'), findsOneWidget);
      expect(find.text('Laporan Laba Rugi (P&L)'), findsOneWidget);
      expect(find.text('Alokasi Dana & Kulakan Stok'), findsOneWidget);
      expect(find.text('Metode Pembayaran Kasir'), findsOneWidget);
      expect(find.text('Saldo Kas di Tangan (Cash in Hand)'), findsOneWidget);
    });

    testWidgets('Help View renders FAQs and topic guides',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const VaultSaaSApp());
      await tester.pumpAndSettle();

      // Open More sheet on Stitch Bottom Nav and tap Help
      await tester.tap(find.text('More').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Help').first);
      await tester.pumpAndSettle();
      // Verify Help page
      expect(find.text('Pusat Bantuan & Dukungan Teknis Vault'), findsOneWidget);
      expect(find.text('Pertanyaan Umum (FAQ)'), findsOneWidget);
      expect(find.text('Tiket Bantuan Aktif'), findsOneWidget);
      expect(find.text('Buat Tiket Bantuan'), findsOneWidget);
    });

    testWidgets('Settings View renders profile, PPN 11%, and printer options',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const VaultSaaSApp());
      await tester.pumpAndSettle();

      // Open More sheet on Stitch Bottom Nav and tap Settings
      await tester.tap(find.text('More').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings').first);
      await tester.pumpAndSettle();
      // Verify Settings page
      expect(find.text('Pengaturan Sistem & Toko'), findsWidgets);
      expect(find.text('Profil Bisnis & Perusahaan'), findsOneWidget);
      expect(find.text('Pajak (PPN) & Biaya Layanan'), findsOneWidget);
      expect(find.text('Perangkat Keras & Printer Kasir'), findsOneWidget);
      expect(find.text('Notifikasi & Batas Peringatan Stok'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);
    });

    testWidgets('Privacy View renders RBAC roles and security audit log',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const VaultSaaSApp());
      await tester.pumpAndSettle();

      // Open More sheet on Stitch Bottom Nav and tap Privacy
      await tester.tap(find.text('More').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Privacy').first);
      await tester.pumpAndSettle();
      // Verify Privacy page
      expect(find.text('Pusat Privasi, Keamanan & Hak Akses (RBAC)'), findsOneWidget);
      expect(find.text('Peran Pengguna & Pembagian Wewenang (RBAC)'), findsOneWidget);
      expect(find.text('Pengaturan Keamanan Akun & Sesi Login'), findsOneWidget);
      expect(find.text('Catatan Aktivitas Keamanan Realtime (Audit Logs)'), findsOneWidget);
      expect(find.text('Backup Database Sekarang'), findsOneWidget);
    });

    test('InventoryStore CRUD operations for Customer, Store, and Settings', () {
      final store = InventoryStore();

      // Customer CRUD test
      final initialCustomerCount = store.customers.length;
      final newCust = const CustomerItem(
        id: 'test-cust',
        name: 'Test Customer',
        email: 'test@example.com',
        phone: '+62 811-1234-5678',
        tier: 'VIP',
        totalOrders: 10,
        totalSpent: 15000000,
        lastActive: 'Baru saja',
        status: 'Aktif',
        city: 'Surabaya',
      );
      store.addCustomer(newCust);
      expect(store.customers.length, equals(initialCustomerCount + 1));
      expect(store.customers.first.name, equals('Test Customer'));

      store.deleteCustomer('test-cust');
      expect(store.customers.length, equals(initialCustomerCount));

      // Store Outlets test
      final outlet = store.outlets.first;
      final statusBefore = outlet.isOpen;
      store.toggleStoreStatus(outlet.id);
      expect(store.outlets.first.isOpen, equals(!statusBefore));

      // Settings test
      expect(store.settings.taxRate, equals(11.0));
      store.updateSettings(store.settings.copyWith(taxRate: 12.0));
      expect(store.settings.taxRate, equals(12.0));
    });

    test('Mobile Blueprint: Soft Delete, Recently Deleted, POS Checkout, Offline Queue, ESC/POS & Voice State Machine', () {
      final store = InventoryStore();
      final initialCount = store.allItems.length;
      final firstItem = store.allItems.first;

      // 1. Soft Delete -> Recently Deleted -> Restore
      store.softDeleteProduct(firstItem.id, reason: 'Discontinued', holdDays: 14);
      expect(store.allItems.length, equals(initialCount - 1));
      expect(store.recentlyDeletedItems.length, equals(1));
      expect(store.recentlyDeletedItems.first.deletedReason, equals('Discontinued'));
      expect(store.recentlyDeletedItems.first.daysRemaining, greaterThanOrEqualTo(13));

      store.restoreProduct(firstItem.id);
      expect(store.allItems.length, equals(initialCount));
      expect(store.recentlyDeletedItems.isEmpty, isTrue);

      // 2. POS Cart & Offline-First Checkout + Sync
      store.setOfflineMode(true);
      store.addToCart(firstItem);
      store.updateCartQuantity(firstItem.id, 2);
      final receipt = store.checkoutPosTransaction(
        paymentMethod: 'QRIS',
        customerName: 'Budi Santoso',
      );
      expect(receipt, isNotNull);
      expect(receipt!['sync_status'], equals('pending'));
      expect(store.offlineQueue.length, equals(1));

      // Format ESC/POS 58mm thermal receipt
      final escPos = store.formatEscPosReceipt(receipt, paperWidth: '58mm');
      expect(escPos.contains('PAKASIR VAULT'), isTrue);
      expect(escPos.contains(firstItem.name), isTrue);

      // Reconnect & sync offline queue
      store.setOfflineMode(false);
      expect(store.offlineQueue.isEmpty, isTrue);
      expect(store.transactions.first['sync_status'], equals('synced'));

      // 3. 2-Way Voice Session State Machine
      expect(store.voiceState, equals(VoiceSessionState.idle));
      store.startVoiceSession();
      expect(store.voiceState, equals(VoiceSessionState.listening));
      store.stopVoiceSession();
      expect(store.voiceState, equals(VoiceSessionState.idle));
    });

    testWidgets('Mobile viewport renders 5-Tab BottomNavigationBar and navigates to POS Kasir',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const VaultSaaSApp());
      await tester.pumpAndSettle();

      expect(find.text('POS Kasir'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
      await tester.tap(find.text('POS Kasir'));
      await tester.pumpAndSettle();

      expect(find.text('Terminal Kasir POS (Fast Checkout)'), findsOneWidget);
    });

    testWidgets('All 11 modules render responsively without overflow across 320px, 360px, 390px, and 412px phone screens',
        (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final phoneSizes = [
        const Size(320, 640),
        const Size(360, 800),
        const Size(390, 844),
        const Size(412, 915),
      ];

      final directBottomTabs = ['Dashboard', 'Inventory', 'POS Kasir', 'Sales'];
      final moreSheetTabs = ['Shipment', 'Customers', 'Store', 'Report', 'Help', 'Settings', 'Privacy'];

      for (final size in phoneSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(const VaultSaaSApp());
        await tester.pumpAndSettle();

        for (final label in directBottomTabs) {
          await tester.tap(find.text(label).last);
          await tester.pumpAndSettle();
        }

        for (final label in moreSheetTabs) {
          await tester.tap(find.text('More').last);
          await tester.pumpAndSettle();
          final itemFinder = find.text(label).last;
          await tester.ensureVisible(itemFinder);
          await tester.tap(itemFinder);
          await tester.pumpAndSettle();
        }
      }
    });
  });
}
