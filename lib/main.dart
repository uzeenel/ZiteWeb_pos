import 'package:flutter/material.dart';
import 'package:zite_web_pos/screens/landing_screen.dart';
import 'package:zite_web_pos/screens/login_screen.dart';
import 'package:zite_web_pos/screens/signup_screen.dart';
import 'package:zite_web_pos/screens/billing_screen.dart';
import 'package:zite_web_pos/screens/billing_callback_screen.dart';
import 'package:zite_web_pos/screens/home_screen.dart';
import 'package:zite_web_pos/screens/product_management_screen.dart';
import 'package:zite_web_pos/screens/category_management_screen.dart';
import 'package:zite_web_pos/screens/company_settings_screen.dart';
import 'package:zite_web_pos/screens/stock_report_screen.dart';
import 'package:zite_web_pos/screens/sales_report_screen.dart';
import 'package:zite_web_pos/screens/cash_book_screen.dart';
import 'package:zite_web_pos/screens/bank_book_screen.dart';
import 'package:zite_web_pos/screens/expenses_screen.dart';
import 'package:zite_web_pos/screens/sales_return_screen.dart';
import 'package:zite_web_pos/screens/unit_management_screen.dart';
import 'package:zite_web_pos/screens/vendor_payment_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZiteMart POS',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/billing': (context) => const BillingScreen(),
        '/billing-callback': (context) => const BillingCallbackScreen(),
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
