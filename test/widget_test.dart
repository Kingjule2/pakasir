import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakasir2/main.dart';

void main() {
  testWidgets('Vault SaaS Dashboard renders full Bento Grid & Supri AI',
      (WidgetTester tester) async {
    // Set a wide viewport for desktop/tablet layout
    tester.view.physicalSize = const Size(1440, 1080);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const VaultSaaSApp());
    await tester.pumpAndSettle();

    // Verify Brand Logo & Navigation
    expect(find.text('vault'), findsOneWidget);
    expect(find.text('Inventory'), findsWidgets);

    // Verify 4 Metric Cards
    expect(find.text('Total Orders'), findsOneWidget);
    expect(find.text('Already Delivered'), findsOneWidget);
    expect(find.text('Product Return'), findsOneWidget);
    expect(find.text('Turnover Rate'), findsOneWidget);

    // Verify Bento Chart & AI Tables
    expect(find.text('Total Stock Volume vs Consume Rate'), findsOneWidget);
    expect(find.text('Custom Tags & Labels'), findsOneWidget);
    expect(find.text('Sales & Order'), findsOneWidget);
    expect(find.text('AI Restock Recommendation'), findsOneWidget);
    expect(find.text('Still Not Arrived'), findsOneWidget);

    // Verify Supri AI exists
    expect(find.text('Supri AI'), findsWidgets);

    // Open Supri AI panel by tapping header button
    await tester.tap(find.text('Supri AI').first);
    await tester.pumpAndSettle();

    // Verify Supri Coworker panel elements
    expect(find.text('Super Intelligent'), findsOneWidget);
    expect(find.text('Berapa laba bersih minggu ini?'), findsOneWidget);
  });
}
