import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakasir2/main.dart';

void main() {
  testWidgets('Vault SaaS Dashboard renders Mobile View, KPIs & Supri AI',
      (WidgetTester tester) async {
    // Set viewport
    tester.view.physicalSize = const Size(1440, 1080);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const VaultSaaSApp());
    await tester.pumpAndSettle();

    // Verify Mobile Inventor Brand & Header
    expect(find.text('Inventor'), findsWidgets);
    expect(find.text('Selamat Datang kembali, Evano!'), findsOneWidget);
    expect(find.text('Penjualan Hari Ini'), findsOneWidget);
    expect(find.text('Omset Bulan Ini'), findsOneWidget);
    expect(find.text('Tingkat Ketersediaan Stok'), findsOneWidget);

    // Verify 5-Tab Bottom Navigation Bar
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Inventory'), findsWidgets);
    expect(find.text('Sales'), findsWidgets);

    // Verify Supri AI exists
    expect(find.text('Supri AI'), findsWidgets);
  });
}
