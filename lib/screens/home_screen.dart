import 'package:flutter/material.dart';
import 'package:zite_web_pos/services/auth_service.dart';
import 'package:zite_web_pos/screens/login_screen.dart';

// keep ALL your 29 screen imports here
import 'package:zite_web_pos/screens/dashboard_screen.dart';
import 'package:zite_web_pos/screens/pos_screen.dart';
import 'package:zite_web_pos/screens/sales_history_screen.dart';
import 'package:zite_web_pos/screens/sales_report_screen.dart';
import 'package:zite_web_pos/screens/stock_report_screen.dart';
import 'package:zite_web_pos/screens/cash_book_screen.dart';
import 'package:zite_web_pos/screens/bank_book_screen.dart';
import 'package:zite_web_pos/screens/expenses_screen.dart';
import 'package:zite_web_pos/screens/sales_return_screen.dart';
import 'package:zite_web_pos/screens/customer_screen.dart';
import 'package:zite_web_pos/screens/category_management_screen.dart';
import 'package:zite_web_pos/screens/product_management_screen.dart';
import 'package:zite_web_pos/screens/vendor_management_screen.dart';
import 'package:zite_web_pos/screens/vendor_payment_screen.dart';
import 'package:zite_web_pos/screens/purchase_order_screen.dart';
import 'package:zite_web_pos/screens/purchase_order_list_screen.dart';
import 'package:zite_web_pos/screens/receive_stock_screen.dart';
import 'package:zite_web_pos/screens/unit_management_screen.dart';
import 'package:zite_web_pos/screens/stock_movement_screen.dart';
import 'package:zite_web_pos/screens/company_settings_screen.dart';
import 'package:zite_web_pos/screens/user_management_screen.dart';
import 'package:zite_web_pos/screens/credit_sales_approval_screen.dart';
import 'package:zite_web_pos/screens/customer_credit_screen.dart';
import 'package:zite_web_pos/screens/bank_account_screen.dart';
import 'package:zite_web_pos/screens/bank_management_screen.dart';
import 'package:zite_web_pos/screens/backup_screen.dart';
import 'package:zite_web_pos/screens/stock_adjustment_screen.dart';
import 'package:zite_web_pos/screens/layaway_management_screen.dart';
import 'package:zite_web_pos/screens/opening_balance_screen.dart';
import 'discount_pin_generate_screen.dart';
import 'discount_pin_report_screen.dart';
import 'roles_screen.dart';


import 'sidebar.dart'; // new file

class HomeScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  const HomeScreen({super.key, this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const POSScreen(),
    const SalesHistoryScreen(),
    const SalesReportScreen(),
    const StockReportScreen(),
    const CashBookScreen(),
    const BankBookScreen(),
    const ExpensesScreen(),
    const SalesReturnScreen(),
    const CustomerScreen(),
    const CategoryManagementScreen(),
    const ProductManagementScreen(),
    const VendorManagementScreen(),
    const VendorPaymentScreen(),
    const PurchaseOrderScreen(),
    const PurchaseOrderListScreen(),
    const ReceiveStockScreen(),
    const UnitManagementScreen(),
    const StockMovementScreen(),
    const CompanySettingsScreen(),
    const UserManagementScreen(),
    const CreditSalesApprovalScreen(),
    const CustomerCreditScreen(),
    const BankAccountScreen(),
    const BankManagementScreen(),
    const BackupScreen(),
    const StockAdjustmentScreen(), // Add this
    const LayawayScreen(),
    const OpeningBalanceScreen(),
    const DiscountPinGenerateScreen(),
    const DiscountPinReportScreen(),
    const RolesScreen(),
  ];

  void _onItemSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: _onItemSelected,
            onToggleTheme: widget.onToggleTheme,
            onLogout: _logout,
          ),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}
