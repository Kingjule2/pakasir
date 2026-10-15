import 'package:flutter/material.dart';
import 'screens/main_layout.dart';
import 'theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VaultSaaSApp());
}

class VaultSaaSApp extends StatelessWidget {
  const VaultSaaSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vault — SaaS Inventory Management & AI Assistant Supri',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.scaffoldBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.cardDark,
          primary: AppColors.cardDark,
          secondary: AppColors.brandLime,
          surface: AppColors.cardBg,
        ),
        fontFamily: 'Segoe UI',
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
        ),
      ),
      home: const MainDashboardLayout(),
    );
  }
}
