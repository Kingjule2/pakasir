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

      // Tap Customers on Sidebar
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

      // Tap Store on Sidebar
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

      // Tap Report on Sidebar
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

      // Tap Help on Sidebar
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

      // Tap Settings on Sidebar
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

      // Tap Privacy on Sidebar
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
  });
}
