import 'package:zite_web_pos/models/user.dart';
import 'package:zite_web_pos/services/api_service.dart';
import 'package:zite_web_pos/utils/permissions.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Future<bool> login(String username, String password) async {
    final result = await ApiService.login(username, password);
    if (result) {
      // Load this user's permissions and make them available app-wide
      final perms = await ApiService.getMyPermissions();
      Permissions.setPermissions(perms);
    }
    return result;
  }

  Future<void> logout() async {
    await ApiService.logout();
    Permissions.clear();
  }

  User? get currentUser => ApiService.currentUser;

  bool get isLoggedIn => ApiService.currentUser != null;

  bool get isAdmin => ApiService.currentUser?.isAdmin ?? false;

  bool get isManager => ApiService.currentUser?.isManager ?? false;

  // These methods will need API endpoints - we'll add them later
  Future<List<User>> getAllUsers() async {
    return [];
  }

  Future<User> createUser({
    required String username,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    throw UnimplementedError();
  }

  Future<void> toggleUserActive(int userId) async {}

  Future<void> deleteUser(int userId) async {}

  Future<User?> getUser(int userId) async {
    return null;
  }
}
