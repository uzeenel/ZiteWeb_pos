enum UserRole { admin, manager, cashier }

class User {
  int? id;
  String username;
  String password; // Will be hashed
  String fullName;
  UserRole role;
  bool isActive;
  DateTime? lastLogin;
  DateTime createdAt;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.fullName,
    required this.role,
    this.isActive = true,
    this.lastLogin,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'full_name': fullName,
      'role': _roleToString(role),
      'is_active': isActive ? 1 : 0,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    // Helper for safe string conversion
    String getString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }

    // Helper for safe int conversion
    int getInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // Helper for safe double conversion
    double getDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Helper for safe bool conversion
    bool getBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value == '1' || value.toLowerCase() == 'true';
      return false;
    }

    // Helper for safe DateTime conversion
    DateTime? getDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        return null;
      }
    }

    return User(
      id: getInt(map['id']),
      username: getString(map['username']),
      password: getString(map['password']),
      fullName: getString(map['full_name'] ?? map['fullName']),
      role: _stringToRole(getString(map['role'])),
      isActive: getBool(map['is_active']),
      lastLogin: getDateTime(map['last_login']),
      createdAt: getDateTime(map['created_at']) ?? DateTime.now(),
    );
  }

  static String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.manager:
        return 'manager';
      case UserRole.cashier:
        return 'cashier';
    }
  }

  static UserRole _stringToRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      case 'cashier':
        return UserRole.cashier;
      default:
        return UserRole.cashier;
    }
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isManager => role == UserRole.manager || role == UserRole.admin;
  bool get isCashier => true;
}
