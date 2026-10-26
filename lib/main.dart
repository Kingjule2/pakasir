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
        scaffoldBackgroundColor: AppColors.appBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryNavy,
          primary: AppColors.primaryNavy,
          secondary: AppColors.accentSkyBlue,
          surface: AppColors.surface,
        ),
        fontFamily: 'Inter',
        dividerTheme: const DividerThemeData(
          color: AppColors.borderSubtle,
          thickness: 1,
        ),
      ),
      home: const MainDashboardLayout(),
    );
  }
}
