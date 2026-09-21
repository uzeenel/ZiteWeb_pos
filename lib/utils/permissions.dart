import 'package:zite_web_pos/services/auth_service.dart';

class Permissions {
  static final AuthService _auth = AuthService();

  // Populated at login and refreshed on demand
  static Set<String> _permissions = {};

  static void setPermissions(Set<String> perms) {
    _permissions = perms;
  }

  static void clear() {
    _permissions = {};
  }

  static bool has(String code) {
    return _permissions.contains(code);
  }

  // ==================== SALES ====================
  static bool get canUsePOS => has('pos_access');
  static bool get canProcessReturns => has('process_returns');
  static bool get canApplyDiscounts => has('apply_discounts');
  static bool get canGenerateDiscountPins => has('generate_discount_pins');
  static bool get canManageLayaway => has('manage_layaway');
  static bool get canManageCreditSales => has('manage_credit_sales');

  // ==================== INVENTORY ====================
  static bool get canManageProducts => has('manage_products');
  static bool get canManageCategories => has('manage_categories');
  static bool get canManageUnits => has('manage_units');
  static bool get canManageStock => has('manage_stock');
  static bool get canReceiveStock => has('receive_stock');
  static bool get canViewBincard => has('view_bincard');

  // ==================== PURCHASING ====================
  static bool get canManageVendors => has('manage_vendors');
  static bool get canManagePurchaseOrders => has('manage_purchase_orders');
  static bool get canManageVendorPayments => has('manage_vendor_payments');

  // ==================== CUSTOMERS ====================
  static bool get canManageCustomers => has('manage_customers');

  // ==================== FINANCE ====================
  static bool get canViewDashboard => has('view_dashboard');
  static bool get canViewReports => has('view_reports');
  static bool get canManageCashBook => has('manage_cash_book');
  static bool get canManageBankBook => has('manage_bank_book');
  static bool get canManageBankAccounts => has('manage_bank_accounts');
  static bool get canManageBanks => has('manage_banks');
  static bool get canManageExpenses => has('manage_expenses');

  // ==================== SYSTEM ====================
  static bool get canManageCompanySettings => has('manage_company_settings');
  static bool get canManageUsers => has('manage_users');
  static bool get canManageRoles => has('manage_roles');
  static bool get canManageSystem => has('manage_system');

  // ==================== LEGACY COMPAT ====================
  // Some screens still reference old names. Map them to the new permissions.
  static bool get canManageInventory => has('manage_stock');
}
