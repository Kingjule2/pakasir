import 'package:flutter_test/flutter_test.dart';
import 'package:pakasir2/services/inventory_store.dart';

void main() {
  group('Supri AI Agent Autonomous Capabilities Tests', () {
    late InventoryStore store;

    setUp(() {
      store = InventoryStore();
    });

    test('Mic Logo Greeting activates voice state and adds spoken greeting', () {
      expect(store.voiceState, VoiceSessionState.idle);

      store.triggerMicGreeting();

      expect(store.voiceState, anyOf(VoiceSessionState.greeting, VoiceSessionState.listening));
      expect(store.chatMessages.isNotEmpty, true);
      expect(store.chatMessages.last.text, contains('Halo Bos! Supri di sini'));
    });

    test('Supri Agent CRUD: Updates product stock in database via conversation', () async {
      final initialStock = store.allItems.firstWhere((i) => i.name == 'Headphones').totalQty;

      await store.sendMessageToSupri('Supri, tolong update stok Headphones jadi 285 unit');

      final updatedItem = store.allItems.firstWhere((i) => i.name == 'Headphones');
      expect(updatedItem.totalQty, 285);
      expect(updatedItem.totalQty, isNot(initialStock));
      expect(store.chatMessages.last.text, contains('Update Stok Berhasil'));
      expect(store.chatMessages.last.text, contains('285 unit'));
    });

    test('Supri Agent CRUD: Adds new product to catalog and inventory', () async {
      final initialCount = store.allItems.length;

      await store.sendMessageToSupri('tambah produk Kopi Gula Aren harga 18000 stok 75 kategori Drinks');

      expect(store.allItems.length, initialCount + 1);
      final newItem = store.allItems.firstWhere((i) => i.name.contains('Kopi Gula Aren'));
      expect(newItem.price, 18000.0);
      expect(newItem.totalQty, 75);
      expect(store.chatMessages.last.text, contains('Produk Baru Berhasil Didaftarkan'));
    });

    test('Supri Agent CRUD: Deletes product and archives to Recently Deleted', () async {
      final itemToDelete = store.allItems.firstWhere((i) => i.name == 'Helmets');
      expect(store.allItems.contains(itemToDelete), true);

      await store.sendMessageToSupri('hapus produk Helmets');

      final foundAfter = store.allItems.where((i) => i.name == 'Helmets');
      expect(foundAfter.isEmpty, true);
      expect(store.chatMessages.last.text, contains('Produk Berhasil Dihapus'));
    });

    test('Supri Agent Export: Generates clean CSV of sales transactions', () async {
      await store.sendMessageToSupri('Supri, ekspor data penjualan ke csv yang rapih');

      final lastMsg = store.chatMessages.last.text;
      expect(lastMsg, contains('```csv'));
      expect(lastMsg, contains('Invoice,Tanggal,Kasir,Pelanggan,Metode_Bayar,Total_Belanja,Status'));
      expect(lastMsg, contains('INV-'));
    });

    test('Supri Agent Extract CSV: Parses user CSV into stock with expiry and stock alerts', () async {
      const userCsv = '''nama,harga,stok,kategori,expired
Roti Keju Spesial,15000,10,Snacks,2026-10-29
Yogurt Strawberry,22000,50,Drinks,2026-10-31
Kopi Arabika 250g,65000,100,Coffee,2027-01-15''';

      await store.sendMessageToSupri('Ini file csv untuk dimasukkan ke stok:\n$userCsv');

      final lastMsg = store.chatMessages.last.text;
      expect(lastMsg, contains('Ekstraksi CSV Stok Sukses'));
      expect(lastMsg, contains('Roti Keju Spesial'));
      expect(lastMsg, contains('Yogurt Strawberry'));

      // Check item added to store
      final roti = store.allItems.firstWhere((i) => i.name == 'Roti Keju Spesial');
      expect(roti.price, 15000.0);
      expect(roti.totalQty, 10);
      expect(roti.expiryDate, isNotNull);

      // Check alert warning generated for near-expiry and low stock
      expect(lastMsg, contains('NOTIFIKASI PERINGATAN DARI SUPRI'));
    });

    test('Supri Agent Notifications: Evaluates near-expiry, expired, and low stock items', () async {
      expect(store.nearExpiryItems.isNotEmpty, true);

      await store.sendMessageToSupri('Supri, cek produk expired dan barang mau habis');

      final lastMsg = store.chatMessages.last.text;
      expect(lastMsg, contains('Laporan Notifikasi & Peringatan Dini Supri'));
      expect(lastMsg, contains('MENDEKATI KEDALUWARSA'));
      expect(lastMsg, contains('Fresh Milk 1L'));
      expect(lastMsg, contains('STOK MENIPIS'));
    });

    test('Supri Agent Financial: Computes comprehensive financials and provides 3 tactical recommendations', () async {
      await store.sendMessageToSupri('Pri, analisa keseluruhan keuangan toko');

      final lastMsg = store.chatMessages.last.text;
      expect(lastMsg, contains('Analisis Menyeluruh Keuangan Toko oleh Supri'));
      expect(lastMsg, contains('Total Omzet Toko'));
      expect(lastMsg, contains('Laba Bersih'));
      expect(lastMsg, contains('3 Rekomendasi Taktis Supri Minggu Ini'));
      expect(lastMsg, contains('1.'));
      expect(lastMsg, contains('2.'));
      expect(lastMsg, contains('3.'));
    });
  });
}
