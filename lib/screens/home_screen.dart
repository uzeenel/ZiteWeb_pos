import 'package:flutter/material.dart';
import 'package:pos_system/screens/pos_screen.dart';
import 'package:pos_system/screens/dashboard_screen.dart';
import 'package:pos_system/screens/stock_report_screen.dart';
import 'package:pos_system/screens/sales_report_screen.dart';
import 'package:pos_system/screens/cash_book_screen.dart';
import 'package:pos_system/screens/bank_book_screen.dart';
import 'package:pos_system/screens/expenses_screen.dart';
import 'package:pos_system/screens/sales_return_screen.dart';
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
import 'package:pos_system/screens/user_management_screen.dart';
import 'package:pos_system/services/auth_service.dart';
import 'package:pos_system/screens/login_screen.dart';
import 'package:pos_system/screens/vendor_payment_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;

  // Section collapse states
  bool _isMainExpanded = true;
  bool _isManagementExpanded = true;
  bool _isInventoryExpanded = true;
  bool _isSystemExpanded = true;

  // All screens in order matching sidebar indices
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
    const CompanySettingsScreen(),
    const UserManagementScreen(),
  ];

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    final isAdmin = currentUser?.isAdmin ?? false;
    final isManager = currentUser?.isManager ?? false;
    final userRole =
        currentUser?.role.toString().split('.').last.toUpperCase() ?? '';

    return Scaffold(
      body: Row(
        children: [
          // Sidebar - Animated width
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isSidebarCollapsed ? 70 : 280,
            color: const Color(0xFF1e3a8a),
            child: Column(
              children: [
                // Header with collapse button
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: Color(0xFF0f2b5e)),
                  child: Row(
                    children: [
                      if (!_isSidebarCollapsed) ...[
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'POS System',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      IconButton(
                        icon: Icon(
                          _isSidebarCollapsed ? Icons.menu_open : Icons.menu,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSidebarCollapsed = !_isSidebarCollapsed;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                // User info
                if (_isSidebarCollapsed)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        const Icon(Icons.person, color: Colors.white, size: 32),
                        const SizedBox(height: 4),
                        Tooltip(
                          message: currentUser?.fullName ?? 'User',
                          child: Text(
                            currentUser?.fullName?.split(' ').first ?? 'U',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white24)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser?.fullName ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userRole,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Menu items
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // MAIN Section
                      _buildCollapsibleSection(
                        title: 'MAIN',
                        isExpanded: _isMainExpanded,
                        onToggle: () =>
                            setState(() => _isMainExpanded = !_isMainExpanded),
                        isCollapsed: _isSidebarCollapsed,
                        children: [
                          _buildMenuItem(
                            icon: Icons.dashboard,
                            label: 'Dashboard',
                            index: 0,
                            isSelected: _selectedIndex == 0,
                          ),
                          _buildMenuItem(
                            icon: Icons.shopping_cart,
                            label: 'Point of Sale',
                            index: 1,
                            isSelected: _selectedIndex == 1,
                          ),
                          _buildMenuItem(
                            icon: Icons.history,
                            label: 'Sales History',
                            index: 2,
                            isSelected: _selectedIndex == 2,
                          ),
                          _buildMenuItem(
                            icon: Icons.bar_chart,
                            label: 'Sales Report',
                            index: 3,
                            isSelected: _selectedIndex == 3,
                          ),
                          _buildMenuItem(
                            icon: Icons.assessment,
                            label: 'Stock Report',
                            index: 4,
                            isSelected: _selectedIndex == 4,
                          ),
                          _buildMenuItem(
                            icon: Icons.book,
                            label: 'Cash Book',
                            index: 5,
                            isSelected: _selectedIndex == 5,
                          ),
                          _buildMenuItem(
                            icon: Icons.account_balance,
                            label: 'Bank Book',
                            index: 6,
                            isSelected: _selectedIndex == 6,
                          ),
                          _buildMenuItem(
                            icon: Icons.receipt,
                            label: 'Expenses',
                            index: 7,
                            isSelected: _selectedIndex == 7,
                          ),
                          _buildMenuItem(
                            icon: Icons.assignment_return,
                            label: 'Sales Returns',
                            index: 8,
                            isSelected: _selectedIndex == 8,
                          ),
                        ],
                      ),

                      // MANAGEMENT Section
                      if (isAdmin || isManager)
                        _buildCollapsibleSection(
                          title: 'MANAGEMENT',
                          isExpanded: _isManagementExpanded,
                          onToggle: () => setState(
                            () =>
                                _isManagementExpanded = !_isManagementExpanded,
                          ),
                          isCollapsed: _isSidebarCollapsed,
                          children: [
                            _buildMenuItem(
                              icon: Icons.people,
                              label: 'Customers',
                              index: 9,
                              isSelected: _selectedIndex == 9,
                            ),
                            _buildMenuItem(
                              icon: Icons.category,
                              label: 'Categories',
                              index: 10,
                              isSelected: _selectedIndex == 10,
                            ),
                            _buildMenuItem(
                              icon: Icons.inventory,
                              label: 'Products',
                              index: 11,
                              isSelected: _selectedIndex == 11,
                            ),
                            _buildMenuItem(
                              icon: Icons.business,
                              label: 'Vendors',
                              index: 12,
                              isSelected: _selectedIndex == 12,
                            ),
                            _buildMenuItem(
                              icon: Icons.payment,
                              label: 'Vendor Payments',
                              index: 13,
                              isSelected: _selectedIndex == 13,
                            )
                          ],
                        ),

                      // INVENTORY Section
                      if (isAdmin || isManager)
                        _buildCollapsibleSection(
                          title: 'INVENTORY',
                          isExpanded: _isInventoryExpanded,
                          onToggle: () => setState(
                            () => _isInventoryExpanded = !_isInventoryExpanded,
                          ),
                          isCollapsed: _isSidebarCollapsed,
                          children: [
                            _buildMenuItem(
                              icon: Icons.add_shopping_cart,
                              label: 'Purchase Orders',
                              index: 14,
                              isSelected: _selectedIndex == 14,
                            ),
                            _buildMenuItem(
                              icon: Icons.receipt_long,
                              label: 'Purchase Order List',
                              index: 15,
                              isSelected: _selectedIndex == 15,
                            ),
                            _buildMenuItem(
                              icon: Icons.inventory_2,
                              label: 'Receive Stock',
                              index: 16,
                              isSelected: _selectedIndex == 16,
                            ),
                            _buildMenuItem(
                              icon: Icons.square_foot,
                              label: 'Units',
                              index: 17,
                              isSelected: _selectedIndex == 17,
                            ),
                          ],
                        ),

                      // SYSTEM Section
                      if (isAdmin)
                        _buildCollapsibleSection(
                          title: 'SYSTEM',
                          isExpanded: _isSystemExpanded,
                          onToggle: () => setState(
                            () => _isSystemExpanded = !_isSystemExpanded,
                          ),
                          isCollapsed: _isSidebarCollapsed,
                          children: [
                            _buildMenuItem(
                              icon: Icons.settings,
                              label: 'Company Settings',
                              index: 18,
                              isSelected: _selectedIndex == 18,
                            ),
                            _buildMenuItem(
                              icon: Icons.people_outline,
                              label: 'User Management',
                              index: 19,
                              isSelected: _selectedIndex == 19,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                // Footer with weather and logout
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                  ),
                  child: _isSidebarCollapsed
                      ? IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white70),
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
                          tooltip: 'Logout',
                        )
                      : Row(
                          children: [
                            const Icon(
                              Icons.wb_sunny,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            const Flexible(
                              child: Text(
                                '30°C',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Flexible(
                              child: Text(
                                'Mostly cloudy',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(
                                Icons.logout,
                                color: Colors.white70,
                                size: 20,
                              ),
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
                              tooltip: 'Logout',
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required bool isCollapsed,
    required List<Widget> children,
  }) {
    if (isCollapsed) {
      // Collapsed mode - show only icons
      return Column(children: children);
    }

    // Expanded mode - show collapsible section
    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.only(
              top: 12,
              bottom: 4,
              left: 16,
              right: 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white54,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...children,
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    final iconWidget = Icon(
      icon,
      color: isSelected ? Colors.white : Colors.white70,
      size: 20,
    );

    if (_isSidebarCollapsed) {
      // Collapsed mode - show tooltip on icon
      return Tooltip(
        message: label,
        child: ListTile(
          leading: iconWidget,
          selected: isSelected,
          selectedTileColor: const Color(0xFF0f2b5e),
          dense: true,
          onTap: () {
            if (_selectedIndex != index) {
              _onItemSelected(index);
            }
          },
        ),
      );
    }

    // Expanded mode - show with text
    return ListTile(
      leading: iconWidget,
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFF0f2b5e),
      dense: true,
      onTap: () {
        if (_selectedIndex != index) {
          _onItemSelected(index);
        }
      },
    );
  }
}
