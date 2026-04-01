import 'package:pos_system/services/auth_service.dart';
import 'package:pos_system/models/user.dart';

class Permissions {
  static final AuthService _auth = AuthService();

  static bool get canManageProducts {
    final user = _auth.currentUser;
    return user != null && (user.isAdmin || user.isManager);
  }

  static bool get canManageCategories {
    final user = _auth.currentUser;
    return user != null && (user.isAdmin || user.isManager);
  }

  static bool get canManageVendors {
    final user = _auth.currentUser;
    return user != null && (user.isAdmin || user.isManager);
  }

  static bool get canManagePurchaseOrders {
    final user = _auth.currentUser;
    return user != null && (user.isAdmin || user.isManager);
  }

  static bool get canManageUnits {
    final user = _auth.currentUser;
    return user != null && (user.isAdmin || user.isManager);
  }

  static bool get canViewDashboard {
    final user = _auth.currentUser;
    return user != null && (user.isAdmin || user.isManager);
  }

  static bool get canReceiveStock {
    final user = _auth.currentUser;
    return user != null && (user.isAdmin || user.isManager);
  }

  static bool get canManageCustomers {
    final user = _auth.currentUser;
    return user != null && (user.isAdmin || user.isManager);
  }

  static bool get canManageVendorPayments {
    final user = _auth.currentUser;
    return user != null && (user.isAdmin || user.isManager);
  }

  static bool get canManageCompanySettings {
    final user = _auth.currentUser;
    return user != null && user.isAdmin;
  }

  static bool get canManageUsers {
    final user = _auth.currentUser;
    return user != null && user.isAdmin;
  }

  static bool get canViewReports {
    final user = _auth.currentUser;
    return user != null;
  }

  static bool get canManageCashBook {
    final user = _auth.currentUser;
    return user != null && user.isAdmin;
  }

  static bool get canManageBankBook {
    final user = _auth.currentUser;
    return user != null && (user.isAdmin || user.isManager);
  }

  static bool get canManageExpenses {
    final user = _auth.currentUser;
    return user != null && (user.isAdmin || user.isManager);
  }

  static bool get canProcessReturns {
    final user = _auth.currentUser;
    return user != null && (user.isAdmin || user.isManager);
  }
}
