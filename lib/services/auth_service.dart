import 'package:pos_system/models/user.dart';
import 'package:pos_system/services/api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Future<bool> login(String username, String password) async {
    final result = await ApiService.login(username, password);
    // Force refresh of currentUser reference
    return result;
  }

  Future<void> logout() async {
    await ApiService.logout();
  }

  User? get currentUser => ApiService.currentUser;

  bool get isLoggedIn => ApiService.currentUser != null;

  bool get isAdmin => ApiService.currentUser?.isAdmin ?? false;

  bool get isManager => ApiService.currentUser?.isManager ?? false;

  // These methods will need API endpoints - we'll add them later
  Future<List<User>> getAllUsers() async {
    // TODO: Implement after adding user management endpoints
    return [];
  }

  Future<User> createUser({
    required String username,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    // TODO: Implement after adding user management endpoints
    throw UnimplementedError();
  }

  Future<void> toggleUserActive(int userId) async {
    // TODO: Implement after adding user management endpoints
  }

  Future<void> deleteUser(int userId) async {
    // TODO: Implement after adding user management endpoints
  }

  Future<User?> getUser(int userId) async {
    // TODO: Implement after adding user management endpoints
    return null;
  }
}
