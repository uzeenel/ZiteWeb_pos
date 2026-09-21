import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/product_management_screen.dart';
import 'screens/category_management_screen.dart';
import 'screens/company_settings_screen.dart';
import 'screens/stock_report_screen.dart';
import 'screens/sales_report_screen.dart';
import 'screens/cash_book_screen.dart';
import 'screens/bank_book_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/sales_return_screen.dart';
import 'screens/unit_management_screen.dart';
import 'screens/vendor_payment_screen.dart';
import 'services/backend_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Start the backend (desktop only; no-op on web)
  await BackendService.startBackend();

  // TODO: re-enable license check before shipping
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _initWindow();
    _loadTheme();
  }

  Future<void> _initWindow() async {
    await windowManager.ensureInitialized();
    windowManager.addListener(this);
    await windowManager.setTitle('ZiteMart POS');
    await windowManager.setMinimumSize(const Size(1024, 768));
    await windowManager.setResizable(true);
    await windowManager.setMaximizable(true);

    Future.delayed(const Duration(milliseconds: 100), () async {
      await windowManager.maximize();
      await windowManager.show();
    });
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = _themeMode == ThemeMode.dark;
    setState(() {
      _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    });
    await prefs.setBool('isDarkMode', !isDark);
  }

  @override
  void onWindowClose() async {
    await windowManager.destroy();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZiteMart POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1e3a8a),
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0f172a),
          foregroundColor: Colors.white,
        ),
      ),
      themeMode: _themeMode,
      home: LoginScreen(),
      routes: {
        '/home': (context) => HomeScreen(onToggleTheme: _toggleTheme),
        '/products': (context) => const ProductManagementScreen(),
        '/categories': (context) => const CategoryManagementScreen(),
        '/settings': (context) => const CompanySettingsScreen(),
        '/stock': (context) => const StockReportScreen(),
        '/sales-report': (context) => const SalesReportScreen(),
        '/cash-book': (context) => const CashBookScreen(),
        '/bank-book': (context) => const BankBookScreen(),
        '/expenses': (context) => const ExpensesScreen(),
        '/sales-returns': (context) => const SalesReturnScreen(),
        '/units': (context) => const UnitManagementScreen(),
        '/vendor-payments': (context) => const VendorPaymentScreen(),
      },
    );
  }
}
