import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/product_management_screen.dart';
import 'screens/category_management_screen.dart';
import 'screens/company_settings_screen.dart';
import 'screens/user_management_screen.dart'; // Remove this line
import 'screens/stock_report_screen.dart';
import 'screens/sales_report_screen.dart';
import 'screens/cash_book_screen.dart';
import 'screens/bank_book_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/sales_return_screen.dart';
import 'package:pos_system/screens/unit_management_screen.dart';
import 'package:pos_system/screens/vendor_payment_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('🚀 Starting POS System...');
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    _initWindow();
  }

  Future<void> _initWindow() async {
    await windowManager.ensureInitialized();
    windowManager.addListener(this);
    await windowManager.setTitle('POS System');
    await windowManager.setMinimumSize(const Size(1024, 768));
    await windowManager.setResizable(true);
    await windowManager.setMaximizable(true);

    Future.delayed(const Duration(milliseconds: 100), () async {
      await windowManager.maximize();
      await windowManager.show();
    });
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
      title: 'POS System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1e3a8a),
          foregroundColor: Colors.white,
        ),
      ),
      home: const LoginScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/products': (context) => const ProductManagementScreen(),
        '/categories': (context) => const CategoryManagementScreen(),
        '/settings': (context) => const CompanySettingsScreen(),
        '/users': (context) => UserManagementScreen(), // Remove this line
        '/stock': (context) => const StockReportScreen(),
        '/sales-report': (context) => SalesReportScreen(),
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
