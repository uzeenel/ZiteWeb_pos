import 'package:zite_web_pos/models/user.dart';
import 'package:zite_web_pos/services/api_service.dart';

class UserService {
  // Get all users
  Future<List<User>> getAllUsers() async {
    try {
      final response = await ApiService.getUsers();
      return response.map((json) => User.fromMap(json)).toList();
    } catch (e) {
      print('Error fetching users from API: $e');
      return [];
    }
  }

  // Get user by ID
  Future<User?> getUserById(int id) async {
    try {
      final response = await ApiService.getUserById(id);
      if (response.isNotEmpty) {
        return User.fromMap(response);
      }
      return null;
    } catch (e) {
      print('Error fetching user by ID from API: $e');
      return null;
    }
  }

  // Get user by username
  Future<User?> getUserByUsername(String username) async {
    try {
      final users = await getAllUsers();
      return users.firstWhere(
        (u) => u.username == username,
        orElse: () => throw Exception('User not found'),
      );
    } catch (e) {
      print('Error fetching user by username from API: $e');
      return null;
    }
  }

  // Create new user
  Future<User> createUser({
    required String username,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    try {
      final userData = {
        'username': username,
        'password': password,
        'fullName': fullName,
        'role': _roleToString(role),
      };

      final response = await ApiService.createUser(userData);
      return User.fromMap(response);
    } catch (e) {
      print('Error creating user via API: $e');
      rethrow;
    }
  }

  // Update user
  Future<bool> updateUser(User user) async {
    try {
      final userData = {
        'fullName': user.fullName,
        'role': _roleToString(user.role),
        'isActive': user.isActive ? 1 : 0,
      };

      await ApiService.updateUser(user.id!, userData);
      return true;
    } catch (e) {
      print('Error updating user via API: $e');
      return false;
    }
  }

  // Update user password
  Future<bool> updateUserPassword(int userId, String newPassword) async {
    try {
      await ApiService.updateUserPassword(userId, newPassword);
      return true;
    } catch (e) {
      print('Error updating user password via API: $e');
      return false;
    }
  }

  // Toggle user active status
  Future<bool> toggleUserActive(int userId) async {
    try {
      await ApiService.toggleUserActive(userId);
      return true;
    } catch (e) {
      print('Error toggling user active status via API: $e');
      return false;
    }
  }

  // Delete user
  Future<bool> deleteUser(int id) async {
    try {
      await ApiService.deleteUser(id);
      return true;
    } catch (e) {
      print('Error deleting user via API: $e');
      return false;
    }
  }

  // Search users
  Future<List<User>> searchUsers(String query) async {
    try {
      final users = await getAllUsers();
      return users.where((u) {
        return u.username.toLowerCase().contains(query.toLowerCase()) ||
            u.fullName.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      print('Error searching users via API: $e');
      return [];
    }
  }

  // Helper to convert role to string
  String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.manager:
        return 'manager';
      case UserRole.cashier:
        return 'cashier';
    }
  }
}
