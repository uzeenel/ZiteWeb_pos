import 'package:flutter/material.dart';
import 'package:pos_system/screens/dashboard_screen.dart';
import 'package:pos_system/screens/pos_screen.dart';
import 'package:pos_system/screens/sales_history_screen.dart';
import 'package:pos_system/screens/customer_screen.dart';
import 'package:pos_system/screens/category_management_screen.dart';
import 'package:pos_system/screens/product_management_screen.dart';
import 'package:pos_system/screens/vendor_management_screen.dart';
import 'package:pos_system/screens/purchase_order_screen.dart';
import 'package:pos_system/screens/unit_management_screen.dart';
import 'package:pos_system/screens/company_settings_screen.dart';
import 'package:pos_system/screens/purchase_order_list_screen.dart';
import 'package:pos_system/screens/receive_stock_screen.dart';
import 'package:pos_system/screens/stock_report_screen.dart';
import 'package:pos_system/screens/sales_report_screen.dart';
import 'package:pos_system/screens/cash_book_screen.dart';
import 'package:pos_system/screens/bank_book_screen.dart';
import 'package:pos_system/screens/sales_return_screen.dart';
import 'package:pos_system/screens/expenses_screen.dart';
import 'package:pos_system/screens/user_management_screen.dart';
import 'package:pos_system/services/auth_service.dart';
import 'package:pos_system/screens/login_screen.dart';

class Sidebar extends StatefulWidget {
  final Widget child;
  final int selectedIndex;

  const Sidebar({super.key, required this.child, required this.selectedIndex});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  final AuthService _authService = AuthService();
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    // Force rebuild when user changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  void _navigateTo(BuildContext context, Widget screen, int index) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  // Helper methods to check permissions directly from current user
  bool get _isAdmin => _authService.currentUser?.isAdmin ?? false;
  bool get _isManager => _authService.currentUser?.isManager ?? false;
  bool get _canManageProducts => _isAdmin || _isManager;
  bool get _canManageCategories => _isAdmin || _isManager;
  bool get _canManageVendors => _isAdmin || _isManager;
  bool get _canManagePurchaseOrders => _isAdmin || _isManager;
  bool get _canManageUnits => _isAdmin || _isManager;
  bool get _canManageCompanySettings => _isAdmin;
  bool get _canManageUsers => _isAdmin;

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    final userRole =
        currentUser?.role.toString().split('.').last ?? 'Not logged in';

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isCollapsed ? 60 : 280,
            color: const Color(0xFF1e3a8a),
            child: Column(
              children: [
                // Header
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isCollapsed ? Icons.menu_open : Icons.menu,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _isCollapsed = !_isCollapsed;
                          });
                        },
                      ),
                      if (!_isCollapsed)
                        const Expanded(
                          child: Text(
                            'POS System',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white54),
                Expanded(
                  child: ListView(
                    children: [
                      // Main Section - Always visible
                      _buildMenuItem(
                        icon: Icons.dashboard,
                        label: 'Dashboard',
                        index: 0,
                        screen: const DashboardScreen(),
                      ),
                      _buildMenuItem(
                        icon: Icons.shopping_cart,
                        label: 'Point of Sale',
                        index: 1,
                        screen: const POSScreen(),
                      ),
                      _buildMenuItem(
                        icon: Icons.history,
                        label: 'Sales History',
                        index: 2,
                        screen: const SalesHistoryScreen(),
                      ),
                      _buildMenuItem(
                        icon: Icons.bar_chart,
                        label: 'Sales Report',
                        index: 3,
                        screen: const SalesReportScreen(),
                      ),
                      _buildMenuItem(
                        icon: Icons.assessment,
                        label: 'Stock Report',
                        index: 4,
                        screen: const StockReportScreen(),
                      ),
                      _buildMenuItem(
                        icon: Icons.book,
                        label: 'Cash Book',
                        index: 5,
                        screen: const CashBookScreen(),
                      ),
                      _buildMenuItem(
                        icon: Icons.account_balance,
                        label: 'Bank Book',
                        index: 6,
                        screen: const BankBookScreen(),
                      ),
                      _buildMenuItem(
                        icon: Icons.receipt,
                        label: 'Expenses',
                        index: 7,
                        screen: const ExpensesScreen(),
                      ),
                      _buildMenuItem(
                        icon: Icons.assignment_return,
                        label: 'Sales Returns',
                        index: 8,
                        screen: const SalesReturnScreen(),
                      ),

                      const Divider(color: Colors.white54, height: 24),

                      // Management Section
                      _buildMenuItem(
                        icon: Icons.people,
                        label: 'Customers',
                        index: 9,
                        screen: const CustomerScreen(),
                      ),
                      // Categories - Admin/Manager only
                      if (_canManageCategories)
                        _buildMenuItem(
                          icon: Icons.category,
                          label: 'Categories',
                          index: 10,
                          screen: const CategoryManagementScreen(),
                        ),
                      // Products - Admin/Manager only
                      if (_canManageProducts)
                        _buildMenuItem(
                          icon: Icons.inventory,
                          label: 'Products',
                          index: 11,
                          screen: const ProductManagementScreen(),
                        ),
                      // Vendors - Admin/Manager only
                      if (_canManageVendors)
                        _buildMenuItem(
                          icon: Icons.business,
                          label: 'Vendors',
                          index: 12,
                          screen: const VendorManagementScreen(),
                        ),

                      const Divider(color: Colors.white54, height: 24),

                      // Inventory Section
                      // Purchase Orders - Admin/Manager only
                      if (_canManagePurchaseOrders)
                        _buildMenuItem(
                          icon: Icons.add_shopping_cart,
                          label: 'Purchase Orders',
                          index: 13,
                          screen: const PurchaseOrderScreen(),
                        ),
                      // Purchase Order List - Admin/Manager only
                      if (_canManagePurchaseOrders)
                        _buildMenuItem(
                          icon: Icons.receipt_long,
                          label: 'Purchase Order List',
                          index: 14,
                          screen: const PurchaseOrderListScreen(),
                        ),
                      // Receive Stock - Admin/Manager only
                      if (_canManageProducts)
                        _buildMenuItem(
                          icon: Icons.inventory_2,
                          label: 'Receive Stock',
                          index: 15,
                          screen: const ReceiveStockScreen(),
                        ),
                      // Units - Admin/Manager only
                      if (_canManageUnits)
                        _buildMenuItem(
                          icon: Icons.square_foot,
                          label: 'Units',
                          index: 16,
                          screen: const UnitManagementScreen(),
                        ),

                      const Divider(color: Colors.white54, height: 24),

                      // System Section
                      // Company Settings - Admin only
                      if (_canManageCompanySettings)
                        _buildMenuItem(
                          icon: Icons.settings,
                          label: 'Company Settings',
                          index: 17,
                          screen: const CompanySettingsScreen(),
                        ),
                      // User Management - Admin only
                      if (_canManageUsers)
                        _buildMenuItem(
                          icon: Icons.people_outline,
                          label: 'User Management',
                          index: 18,
                          screen: const UserManagementScreen(),
                        ),
                    ],
                  ),
                ),
                // User info and logout
                const Divider(color: Colors.white54),
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.white),
                  title: !_isCollapsed
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser?.fullName?.split(' ').first ??
                                  'No User',
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              'Role: $userRole',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        )
                      : null,
                  trailing: !_isCollapsed
                      ? IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: () async {
                            await _authService.logout();
                            if (mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            }
                          },
                        )
                      : null,
                  onTap: !_isCollapsed
                      ? null
                      : () async {
                          await _authService.logout();
                          if (mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          }
                        },
                ),
              ],
            ),
          ),
          // Main content
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required int index,
    required Widget screen,
  }) {
    final isSelected = widget.selectedIndex == index;

    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70),
      title: !_isCollapsed
          ? Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            )
          : null,
      selected: isSelected,
      selectedTileColor: const Color(0xFF0f2b5e),
      onTap: () {
        if (widget.selectedIndex != index) {
          _navigateTo(context, screen, index);
        }
      },
    );
  }
}
