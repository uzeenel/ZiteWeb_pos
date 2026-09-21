import 'package:flutter/material.dart';

class Sidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback? onToggleTheme;
  final VoidCallback onLogout;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.onToggleTheme,
    required this.onLogout,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool _isCollapsed = true;
  bool _isMainExpanded = true;
  bool _isManagementExpanded = true;
  bool _isInventoryExpanded = true;
  bool _isReportsExpanded = true;
  bool _isSystemExpanded = true;

  Widget _buildMenuItem(IconData icon, String title, int index) {
    final isSelected = widget.selectedIndex == index;
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade700 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: ListTile(
          leading: Icon(icon, color: Colors.white, size: 22),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          onTap: () => widget.onItemSelected(index),
          dense: true,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          horizontalTitleGap: 8,
          minLeadingWidth: 24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isCollapsed ? 70 : 280,
      color: const Color(0xFF1e3a8a),
      child: Column(
        children: [
          // header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Color(0xFF0f2b5e)),
            child: Row(
              children: [
                if (!_isCollapsed)
                  const Expanded(
                    child: Text(
                      'ZiteMart',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    _isCollapsed ? Icons.menu_open : Icons.menu,
                    color: Colors.white,
                  ),
                  onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
                ),
              ],
            ),
          ),

          // navigation
          Expanded(
            child: _isCollapsed
                ? SingleChildScrollView(
                    child: Column(
                      children: [
                        // Main section icons
                        IconButton(
                          icon: const Icon(Icons.dashboard, color: Colors.white70),
                          onPressed: () => widget.onItemSelected(0),
                          tooltip: 'Dashboard',
                        ),
                        IconButton(
                          icon: const Icon(Icons.shopping_cart, color: Colors.white70),
                          onPressed: () => widget.onItemSelected(1),
                          tooltip: 'POS',
                        ),
                        IconButton(
                          icon: const Icon(Icons.history, color: Colors.white70),
                          onPressed: () => widget.onItemSelected(2),
                          tooltip: 'Sales History',
                        ),
                        const Divider(color: Colors.white24, height: 1),
                        
                        // Management section icons
                        IconButton(
                          icon: const Icon(Icons.people, color: Colors.white70),
                          onPressed: () => widget.onItemSelected(9),
                          tooltip: 'Customers',
                        ),
                        IconButton(
                          icon: const Icon(Icons.category, color: Colors.white70),
                          onPressed: () => widget.onItemSelected(10),
                          tooltip: 'Categories',
                        ),
                        IconButton(
                          icon: const Icon(Icons.inventory, color: Colors.white70),
                          onPressed: () => widget.onItemSelected(11),
                          tooltip: 'Products',
                        ),
                        IconButton(
                          icon: const Icon(Icons.business, color: Colors.white70),
                          onPressed: () => widget.onItemSelected(12),
                          tooltip: 'Vendors',
                        ),
                        IconButton(
                          icon: const Icon(Icons.payment, color: Colors.white70),
                          onPressed: () => widget.onItemSelected(13),
                          tooltip: 'Vendor Payments',
                        ),
                        IconButton(
                          icon: const Icon(Icons.people_outline, color: Colors.white70),
                          onPressed: () => widget.onItemSelected(20),
                          tooltip: 'User Management',
                        ),
                        const Divider(color: Colors.white24, height: 1),
                        
                        // Inventory section icons
                        IconButton(
                          icon: const Icon(Icons.add_shopping_cart, color: Colors.white70),
                          onPressed: () => widget.onItemSelected(14),
                          tooltip: 'Purchase Order',
                        ),
                        IconButton(
                          icon: const Icon(Icons.list_alt, color: Colors.white70),
                          onPressed: () => widget.onItemSelected(15),
                          tooltip: 'PO List',
                        ),
                        IconButton(
                          icon: const Icon(Icons.inbox, color: Colors.white70),
                          onPressed: () => widget.onItemSelected(16),
                          tooltip: 'Receive Stock',
                        ),
                        IconButton(
                          icon: const Icon(Icons.rule, color: Colors.white70),
                          onPressed: () => widget.onItemSelected(17),
                          tooltip: 'Units',
                        ),
                        IconButton(
                          icon: const Icon(Icons.trending_up, color: Colors.white70),
                          onPressed: () => widget.onItemSelected(18),
                          tooltip: 'Stock Movement',
                        ),
                        const Divider(color: Colors.white24, height: 1),
                        
                        // Reports section icons
                        IconButton(
                          icon: const Icon(Icons.receipt_long, color: Colors.white70),
                          onPressed: () => widget.onItemSelected(3),
                          tooltip: 'Sales Report',
                        ),
                        IconButton(
                          icon: const Icon(Icons.inventory, color: Colors.white70),
                          onPressed: () => widget.onItemSelected(4),
                          tooltip: 'Stock Report',
                        ),
                        IconButton(
                          icon: const Icon(Icons.account_balance_wallet, color: Colors.white70),
                          onPressed: () => widget.onItemSelected(5),
                          tooltip: 'Cash Book',
                        ),
                        IconButton(
                          icon: const Icon(Icons.account_balance, color: Colors.white70),
                          onPressed: () => widget.onItemSelected(6),
                          tooltip: 'Bank Book',
                        ),
                        IconButton(
                          icon: const Icon(Icons.money_off, color: Colors.white70),
                          onPressed: () => widget.onItemSelected(7),
                          tooltip: 'Expenses',
                        ),
                        IconButton(
                          icon: const Icon(Icons.undo, color: Colors.white70),
                          onPressed: () => widget.onItemSelected(8),
                          tooltip: 'Sales Return',
                        ),
                        const Divider(color: Colors.white24, height: 1),
                        
                        // System section icons
                        IconButton(
                          icon: const Icon(Icons.business_center, color: Colors.white70),
                          onPressed: () => widget.onItemSelected(19),
                          tooltip: 'Company Settings',
                        ),
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.white70),
                          onPressed: () => widget.onItemSelected(21),
                          tooltip: 'Credit Approval',
                        ),
                        IconButton(
                          icon: const Icon(Icons.credit_card, color: Colors.white70),
                          onPressed: () => widget.onItemSelected(22),
                          tooltip: 'Customer Credit',
                        ),
                        IconButton(
                          icon: const Icon(Icons.account_balance, color: Colors.white70),
                          onPressed: () => widget.onItemSelected(23),
                          tooltip: 'Bank Accounts',
                        ),
                        IconButton(
                          icon: const Icon(Icons.business, color: Colors.white70),
                          onPressed: () => widget.onItemSelected(24),
                          tooltip: 'Bank Management',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.vpn_key,
                            color: Colors.white70,
                          ),
                          onPressed: () => widget.onItemSelected(29),
                          tooltip: 'Discount PINS',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.assignment,
                            color: Colors.white70,
                          ),
                          onPressed: () => widget.onItemSelected(30),
                          tooltip: 'PIN Report',
                        ),                        
                        IconButton(
                          icon: const Icon(
                            Icons.security,
                            color: Colors.white70,
                          ),
                          onPressed: () => widget.onItemSelected(31),
                          tooltip: 'Roles & Permissions',
                        ),
                        IconButton(
                          icon: const Icon(Icons.backup, color: Colors.white70),
                          onPressed: () => widget.onItemSelected(25),
                          tooltip: 'Backup',
                        ),
                      ],
                    ),
                  )
                : ListView(
                    children: [
                      // Main
                      ExpansionTile(
                        leading: const Icon(Icons.home, color: Colors.white70),
                        title: const Text(
                          'Main',
                          style: TextStyle(color: Colors.white),
                        ),
                        iconColor: Colors.white70,
                        collapsedIconColor: Colors.white70,
                        backgroundColor: Colors.transparent,
                        collapsedBackgroundColor: Colors.transparent,
                        initiallyExpanded: _isMainExpanded,
                        onExpansionChanged: (expanded) =>
                            setState(() => _isMainExpanded = expanded),
                        children: [
                          _buildMenuItem(Icons.dashboard, 'Dashboard', 0),
                          _buildMenuItem(Icons.shopping_cart, 'POS', 1),
                          _buildMenuItem(Icons.credit_card, "Layaway", 27),
                          _buildMenuItem(Icons.history, 'Sales History', 2),
                        ],
                      ),
                      // Management
                      ExpansionTile(
                        leading: const Icon(
                          Icons.manage_accounts,
                          color: Colors.white70,
                        ),
                        title: const Text(
                          'Management',
                          style: TextStyle(color: Colors.white),
                        ),
                        iconColor: Colors.white70,
                        collapsedIconColor: Colors.white70,
                        backgroundColor: Colors.transparent,
                        collapsedBackgroundColor: Colors.transparent,
                        initiallyExpanded: _isManagementExpanded,
                        onExpansionChanged: (expanded) =>
                            setState(() => _isManagementExpanded = expanded),
                        children: [
                          _buildMenuItem(Icons.people, 'Customers', 9),
                          _buildMenuItem(Icons.category, 'Categories', 10),
                          _buildMenuItem(Icons.inventory, 'Products', 11),
                          _buildMenuItem(Icons.business, 'Vendors', 12),
                          _buildMenuItem(Icons.payment, 'Vendor Payments', 13),
                          _buildMenuItem(Icons.people_outline, 'User Management', 20),                         
                        ],
                      ),
                      // Inventory
                      ExpansionTile(
                        leading: const Icon(
                          Icons.inventory_2,
                          color: Colors.white70,
                        ),
                        title: const Text(
                          'Inventory',
                          style: TextStyle(color: Colors.white),
                        ),
                        iconColor: Colors.white70,
                        collapsedIconColor: Colors.white70,
                        backgroundColor: Colors.transparent,
                        collapsedBackgroundColor: Colors.transparent,
                        initiallyExpanded: _isInventoryExpanded,
                        onExpansionChanged: (expanded) =>
                            setState(() => _isInventoryExpanded = expanded),
                        children: [
                          _buildMenuItem(Icons.add_shopping_cart, 'Purchase Order', 14),
                          _buildMenuItem(Icons.list_alt, 'Purchase Orders List', 15),
                          _buildMenuItem(Icons.inbox, 'Receive Stock', 16),
                          _buildMenuItem(Icons.rule, 'Units', 17),
                          _buildMenuItem(Icons.trending_up, 'Stock Movement', 18),
                          _buildMenuItem(Icons.settings_overscan, 'Stock Adjustment', 26),                          
                          _buildMenuItem(Icons.account_balance, "Opening Balance", 28)
                        ],
                      ),
                      // Reports
                      ExpansionTile(
                        leading: const Icon(
                          Icons.bar_chart,
                          color: Colors.white70,
                        ),
                        title: const Text(
                          'Reports',
                          style: TextStyle(color: Colors.white),
                        ),
                        iconColor: Colors.white70,
                        collapsedIconColor: Colors.white70,
                        backgroundColor: Colors.transparent,
                        collapsedBackgroundColor: Colors.transparent,
                        initiallyExpanded: _isReportsExpanded,
                        onExpansionChanged: (expanded) =>
                            setState(() => _isReportsExpanded = expanded),
                        children: [
                          _buildMenuItem(Icons.receipt_long, 'Sales Report', 3),
                          _buildMenuItem(Icons.inventory, 'Stock Report', 4),
                          _buildMenuItem(Icons.account_balance_wallet, 'Cash Book', 5),
                          _buildMenuItem(Icons.account_balance, 'Bank Book', 6),
                          _buildMenuItem(Icons.money_off, 'Expenses', 7),
                          _buildMenuItem(Icons.undo, 'Sales Return', 8),
                        ],
                      ),
                      // System
                      ExpansionTile(
                        leading: const Icon(
                          Icons.settings,
                          color: Colors.white70,
                        ),
                        title: const Text(
                          'System',
                          style: TextStyle(color: Colors.white),
                        ),
                        iconColor: Colors.white70,
                        collapsedIconColor: Colors.white70,
                        backgroundColor: Colors.transparent,
                        collapsedBackgroundColor: Colors.transparent,
                        initiallyExpanded: _isSystemExpanded,
                        onExpansionChanged: (expanded) =>
                            setState(() => _isSystemExpanded = expanded),
                        children: [
                          _buildMenuItem(Icons.business_center, 'Company Settings', 19),
                          _buildMenuItem(Icons.check_circle, 'Credit Sales Approval', 21),
                          _buildMenuItem(Icons.credit_card, 'Customer Credit', 22),
                          _buildMenuItem(Icons.account_balance, 'Bank Accounts', 23),
                          _buildMenuItem(Icons.business, 'Bank Management', 24),
                          _buildMenuItem(Icons.vpn_key, 'Discount PINs', 29,),
                          _buildMenuItem(Icons.assignment, 'PIN Report', 30),
                          _buildMenuItem(Icons.security, 'Roles & Permissions', 31),
                          _buildMenuItem(Icons.backup, 'Backup', 25),
                        ],
                      ),
                    ],
                  ),
          ),

          // footer
          Container(
            padding: const EdgeInsets.all(12),
            child: _isCollapsed
                ? Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          Theme.of(context).brightness == Brightness.dark
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          color: Colors.white70,
                        ),
                        onPressed: () => widget.onToggleTheme?.call(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white70),
                        onPressed: widget.onLogout,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Theme.of(context).brightness == Brightness.dark
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          color: Colors.white70,
                        ),
                        onPressed: () => widget.onToggleTheme?.call(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white70),
                        onPressed: widget.onLogout,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
