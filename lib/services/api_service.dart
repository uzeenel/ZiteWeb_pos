import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pos_system/models/product.dart';
import 'package:pos_system/models/user.dart';
import 'package:pos_system/models/category.dart';
import 'package:pos_system/models/cart_item.dart';
import 'package:pos_system/models/sales_return.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  static String? _token;
  static User? _currentUser;

  static void setToken(String token) {
    _token = token;
  }

  static String? get token => _token;

  static void setCurrentUser(User user) {
    _currentUser = user;
  }

  static User? get currentUser => _currentUser;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_token',
  };

  // ==================== AUTH ====================

  static Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        body: jsonEncode({'username': username, 'password': password}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _token = data['token'];
        final roleString = data['user']['role'].toString();

        _currentUser = User(
          id: data['user']['id'],
          username: data['user']['username'],
          password: '',
          fullName: data['user']['fullName'],
          role: _stringToRole(roleString),
          createdAt: DateTime.now(),
        );

        return true;
      }
      print('Login failed with status: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  static Future<void> logout() async {
    _token = null;
    _currentUser = null;
  }

  // ==================== DASHBOARD ====================

  static Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'totalSalesToday': _toDouble(data['totalSalesToday']),
          'totalSalesThisWeek': _toDouble(data['totalSalesThisWeek']),
          'totalSalesThisMonth': _toDouble(data['totalSalesThisMonth']),
          'totalTransactionsToday': _toInt(data['totalTransactionsToday']),
          'averageTicketToday': _toDouble(data['averageTicketToday']),
          'lowStockCount': _toInt(data['lowStockCount']),
          'outOfStockCount': _toInt(data['outOfStockCount']),
          'salesByCategory': data['salesByCategory'] ?? [],
          'last7DaysSales': data['last7DaysSales'] ?? [],
          'topProducts': data['topProducts'] ?? [],
        };
      }
      return {};
    } catch (e) {
      print('Error fetching dashboard: $e');
      return {};
    }
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // ==================== PRODUCTS ====================

  static Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Product.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  static Future<Product?> getProduct(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return Product.fromMap(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Error fetching product: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> addProduct(
    Map<String, dynamic> product,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: _headers,
        body: jsonEncode(product),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to add product');
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    }
  }

  // Update product
  static Future<void> updateProduct(
    int id,
    Map<String, dynamic> product,
  ) async {
    try {
      // First, get the current product to preserve is_active status
      final currentProduct = await getProduct(id);

      // Prepare update data
      final updateData = {
        'name': product['name'],
        'sku': product['sku'],
        'category_id': product['categoryId'],
        'unit_id': product['unitId'],
        'barcode': product['barcode'],
        'cost_price': product['costPrice'],
        'selling_price': product['sellingPrice'],
        'stock_quantity':
            product['stockQuantity'] ?? (currentProduct?.stockQuantity ?? 0),
        'min_stock_level':
            product['minStockLevel'] ?? (currentProduct?.minStockLevel ?? 0),
        'is_vat_exempt': product['isVatExempt'] == true ? 1 : 0,
        'is_active': currentProduct?.isActive == true
            ? 1
            : 0, // Preserve current active status
      };

      final response = await http.put(
        Uri.parse('$baseUrl/products/$id'),
        headers: _headers,
        body: jsonEncode(updateData),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update product');
      }
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }
  static Future<void> updateStock(int productId, double quantity) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/products/$productId/stock'),
        headers: _headers,
        body: jsonEncode({'quantity': quantity}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update stock');
      }
    } catch (e) {
      print('Error updating stock: $e');
      rethrow;
    }
  }

  static Future<void> deleteProduct(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$id'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete product');
      }
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }

  // ==================== CATEGORIES ====================

  static Future<List<Category>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Category.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> addCategory(
    Map<String, dynamic> category,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categories'),
        headers: _headers,
        body: jsonEncode(category),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to add category');
    } catch (e) {
      print('Error adding category: $e');
      rethrow;
    }
  }

  // Update category
  static Future<void> updateCategory(
    int id,
    Map<String, dynamic> category,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/categories/$id'),
        headers: _headers,
        body: jsonEncode(category),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update category');
      }
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  // Delete category
  static Future<void> deleteCategory(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/categories/$id'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete category');
      }
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }

  // ==================== SALES ====================

  // Save sale
  static Future<Map<String, dynamic>> saveSale({
    required List<CartItem> cart,
    required double subtotal,
    required double tax,
    required double total,
    required String paymentMethod,
    required double paidAmount,
    required int? cashierId,
  }) async {
    try {
      final saleData = {
        'cart': cart
            .map(
              (item) => {
                'product': {
                  'id': item.product.id,
                  'sellingPrice': item.product.sellingPrice,
                  'isVatExempt': item.product.isVatExempt,
                },
                'quantity': item.quantity,
                'subtotal': item.subtotal,
              },
            )
            .toList(),
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'paymentMethod': paymentMethod, // Note: This matches your server
        'paidAmount': paidAmount,
        'cashierId': cashierId,
      };

      print('=== SAVE SALE ===');
      print('URL: $baseUrl/sales');
      print('Data: ${jsonEncode(saleData)}');
      print('Headers: $_headers');

      final response = await http.post(
        Uri.parse('$baseUrl/sales'),
        headers: _headers,
        body: jsonEncode(saleData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception(
        'Failed to save sale: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      print('Error saving sale: $e');
      rethrow;
    }
  }

  // Get all sales (last 30 days)
  static Future<List<Map<String, dynamic>>> getSales() async {
    try {
      final end = DateTime.now();
      final start = end.subtract(const Duration(days: 30));

      final response = await http.get(
        Uri.parse(
          '$baseUrl/sales?start=${start.toIso8601String()}&end=${end.toIso8601String()}',
        ),
        headers: _headers,
      );

      print('=== GET SALES DEBUG ===');
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Success: ${data.length} sales found');
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching sales: $e');
      return [];
    }
  }

  // Get sales by date range
  static Future<List<Map<String, dynamic>>> getSalesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/sales?start=${start.toIso8601String()}&end=${end.toIso8601String()}',
        ),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching sales by date range: $e');
      return [];
    }
  }

  // Get today's sales
  static Future<List<Map<String, dynamic>>> getTodaySales() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await http.get(
        Uri.parse(
          '$baseUrl/sales?start=${startOfDay.toIso8601String()}&end=${endOfDay.toIso8601String()}',
        ),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching today\'s sales: $e');
      return [];
    }
  }

  // Get sale detail by ID
  static Future<Map<String, dynamic>> getSaleDetail(int saleId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sales/$saleId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'sale': {}, 'items': []};
    } catch (e) {
      print('Error fetching sale detail: $e');
      return {'sale': {}, 'items': []};
    }
  }

  // Get sale by invoice number
  static Future<Map<String, dynamic>?> getSaleByInvoice(
    String invoiceNumber,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sales/invoice/$invoiceNumber'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching sale by invoice: $e');
      return null;
    }
  }

  // ==================== USERS ====================

  // Get all users
  static Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: _headers,
      );

      print('=== GET USERS ===');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  // Get user by ID
  static Future<Map<String, dynamic>> getUserById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      print('Error fetching user: $e');
      return {};
    }
  }

  // Create user
  static Future<Map<String, dynamic>> createUser(
    Map<String, dynamic> userData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: _headers,
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to create user');
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  // Update user
  static Future<void> updateUser(int id, Map<String, dynamic> userData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$id'),
        headers: _headers,
        body: jsonEncode(userData),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to update user');
      }
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  // Update user password
  static Future<void> updateUserPassword(int id, String newPassword) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/users/$id/password'),
        headers: _headers,
        body: jsonEncode({'password': newPassword}),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to update password');
      }
    } catch (e) {
      print('Error updating password: $e');
      rethrow;
    }
  }

  // Toggle user active status
  static Future<void> toggleUserActive(int id) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/users/$id/toggle'),
        headers: _headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to toggle user status');
      }
    } catch (e) {
      print('Error toggling user status: $e');
      rethrow;
    }
  }

  // Delete user
  static Future<void> deleteUser(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$id'),
        headers: _headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete user');
      }
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  // ==================== HELPERS ====================

  static UserRole _stringToRole(String role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      default:
        return UserRole.cashier;
    }
  }

  static Future<bool> testConnection() async {
    try {
      if (_token == null) return false;
      final response = await http.get(
        Uri.parse('$baseUrl/test'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  // ==================== CASH BOOK ====================

  // Get cash transactions
  static Future<List<Map<String, dynamic>>> getCashTransactions(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/cash-book?start=${start.toIso8601String()}&end=${end.toIso8601String()}',
        ),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching cash transactions: $e');
      return [];
    }
  }

  // Get cash summary
  static Future<Map<String, dynamic>> getCashSummary(DateTime date) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cash-book/summary?date=${date.toIso8601String()}'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {
        'openingBalance': 0.0,
        'cashIn': 0.0,
        'cashOut': 0.0,
        'closingBalance': 0.0,
      };
    } catch (e) {
      print('Error fetching cash summary: $e');
      return {
        'openingBalance': 0.0,
        'cashIn': 0.0,
        'cashOut': 0.0,
        'closingBalance': 0.0,
      };
    }
  }

  // Add cash transaction
  static Future<Map<String, dynamic>> addCashTransaction({
    required DateTime date,
    required String type,
    required double amount,
    required String category,
    required String description,
    String? reference,
    int? userId,
  }) async {
    try {
      final data = {
        'date': date.toIso8601String(),
        'type': type,
        'amount': amount,
        'category': category,
        'description': description,
        'reference': reference,
        'user_id': userId,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/cash-book'),
        headers: _headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to add cash transaction');
    } catch (e) {
      print('Error adding cash transaction: $e');
      rethrow;
    }
  }

  // Delete cash transaction
  static Future<void> deleteCashTransaction(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cash-book/$id'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete cash transaction');
      }
    } catch (e) {
      print('Error deleting cash transaction: $e');
      rethrow;
    }
  }

  // Get single cash transaction
  static Future<Map<String, dynamic>?> getCashTransaction(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cash-book/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching cash transaction: $e');
      return null;
    }
  }

  // ==================== BANK BOOK ====================

  // Get bank transactions by date range
  static Future<List<Map<String, dynamic>>> getBankTransactions(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/bank-book?start=${start.toIso8601String()}&end=${end.toIso8601String()}',
        ),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching bank transactions: $e');
      return [];
    }
  }

  // Get bank summary for date range
  static Future<Map<String, dynamic>> getBankSummary(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/bank-book/summary?start=${start.toIso8601String()}&end=${end.toIso8601String()}',
        ),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {
        'openingBalance': 0.0,
        'deposits': 0.0,
        'withdrawals': 0.0,
        'netChange': 0.0,
        'closingBalance': 0.0,
        'transactionCount': 0,
      };
    } catch (e) {
      print('Error fetching bank summary: $e');
      return {
        'openingBalance': 0.0,
        'deposits': 0.0,
        'withdrawals': 0.0,
        'netChange': 0.0,
        'closingBalance': 0.0,
        'transactionCount': 0,
      };
    }
  }

  // Add bank transaction
  static Future<Map<String, dynamic>> addBankTransaction({
    required DateTime date,
    required String type,
    required double amount,
    required String accountName,
    required String bankName,
    required String description,
    String? reference,
    int? userId,
  }) async {
    try {
      final data = {
        'date': date.toIso8601String(),
        'type': type,
        'amount': amount,
        'accountName': accountName,
        'bankName': bankName,
        'description': description,
        'reference': reference,
        'userId': userId,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/bank-book'),
        headers: _headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to add bank transaction');
    } catch (e) {
      print('Error adding bank transaction: $e');
      rethrow;
    }
  }

  // Delete bank transaction
  static Future<void> deleteBankTransaction(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/bank-book/$id'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete bank transaction');
      }
    } catch (e) {
      print('Error deleting bank transaction: $e');
      rethrow;
    }
  }

  // Get single bank transaction
  static Future<Map<String, dynamic>?> getBankTransaction(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bank-book/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching bank transaction: $e');
      return null;
    }
  }
  // ==================== COMPANY ====================

  // Get company settings
  static Future<Map<String, dynamic>> getCompany() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/company'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      print('Error fetching company: $e');
      return {};
    }
  }

  // Save company settings (create or update)
  static Future<Map<String, dynamic>> saveCompany(
    Map<String, dynamic> companyData,
  ) async {
    try {
      // First check if company exists
      final checkResponse = await http.get(
        Uri.parse('$baseUrl/company'),
        headers: _headers,
      );

      final companyExists =
          checkResponse.statusCode == 200 &&
          checkResponse.body != '{}' &&
          checkResponse.body.isNotEmpty;

      print('=== SAVE COMPANY ===');
      print('Company exists: $companyExists');
      print('Data: $companyData');

      final response = await http.post(
        Uri.parse('$baseUrl/company'),
        headers: _headers,
        body: jsonEncode(companyData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception(
        'Failed to save company: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      print('Error saving company: $e');
      rethrow;
    }
  }

  

  // ==================== STATES ====================

  // Get all states
  static Future<List<Map<String, dynamic>>> getStates() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/states'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching states: $e');
      return [];
    }
  }

  // Get state by ID
  static Future<Map<String, dynamic>?> getStateById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/states/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching state: $e');
      return null;
    }
  }

  // ==================== EXPENSES ====================

  // Get all expenses
  static Future<List<Map<String, dynamic>>> getExpenses() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/expenses'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching expenses: $e');
      return [];
    }
  }

  // Get expenses by date range
  static Future<List<Map<String, dynamic>>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/expenses?start=${start.toIso8601String()}&end=${end.toIso8601String()}',
        ),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching expenses by date range: $e');
      return [];
    }
  }

  // Get expense by ID
  static Future<Map<String, dynamic>> getExpenseById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/expenses/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      print('Error fetching expense by ID: $e');
      return {};
    }
  }

  // Add expense
  static Future<Map<String, dynamic>> addExpense(
    Map<String, dynamic> expenseData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/expenses'),
        headers: _headers,
        body: jsonEncode(expenseData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to add expense');
    } catch (e) {
      print('Error adding expense: $e');
      rethrow;
    }
  }

  // Update expense
  static Future<void> updateExpense(
    int id,
    Map<String, dynamic> expenseData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/expenses/$id'),
        headers: _headers,
        body: jsonEncode(expenseData),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to update expense');
      }
    } catch (e) {
      print('Error updating expense: $e');
      rethrow;
    }
  }

  // Delete expense
  static Future<void> deleteExpense(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/expenses/$id'),
        headers: _headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete expense');
      }
    } catch (e) {
      print('Error deleting expense: $e');
      rethrow;
    }
  }

  // Get expense summary
  static Future<Map<String, double>> getExpenseSummary() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/expenses/summary'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, double>.from(data);
      }
      return {};
    } catch (e) {
      print('Error fetching expense summary: $e');
      return {};
    }
  }

  // Get expenses by category
  static Future<Map<String, double>> getExpensesByCategory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/expenses/by-category'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, double>.from(data);
      }
      return {};
    } catch (e) {
      print('Error fetching expenses by category: $e');
      return {};
    }
  }
  // ==================== SALES RETURNS ====================

  // Get sale items available for return
  static Future<List<Map<String, dynamic>>> getSaleItemsForReturn(
    String invoiceNumber,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sales-returns/items/$invoiceNumber'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching sale items for return: $e');
      return [];
    }
  }

  // Create return
  static Future<Map<String, dynamic>> createReturn({
    required int saleId,
    required String invoiceNumber,
    required List<Map<String, dynamic>> items,
    required String reason,
    required int? cashierId,
  }) async {
    try {
      final returnData = {
        'saleId': saleId,
        'invoiceNumber': invoiceNumber,
        'items': items,
        'reason': reason,
        'cashierId': cashierId,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/sales-returns'),
        headers: _headers,
        body: jsonEncode(returnData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to create return');
    } catch (e) {
      print('Error creating return: $e');
      rethrow;
    }
  }

  // Approve return
  static Future<Map<String, dynamic>> approveReturn(int returnId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/sales-returns/$returnId/approve'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to approve return');
    } catch (e) {
      print('Error approving return: $e');
      rethrow;
    }
  }

  // Complete return
  static Future<Map<String, dynamic>> completeReturn(int returnId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/sales-returns/$returnId/complete'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to complete return');
    } catch (e) {
      print('Error completing return: $e');
      rethrow;
    }
  }

  // Reject return
  static Future<Map<String, dynamic>> rejectReturn(
    int returnId,
    String reason,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/sales-returns/$returnId/reject'),
        headers: _headers,
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to reject return');
    } catch (e) {
      print('Error rejecting return: $e');
      rethrow;
    }
  }

  // Get returns by date range
  static Future<List<Map<String, dynamic>>> getReturnsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/sales-returns?start=${start.toIso8601String()}&end=${end.toIso8601String()}',
        ),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching returns by date range: $e');
      return [];
    }
  }

  // Get return by ID
  static Future<Map<String, dynamic>> getReturn(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sales-returns/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      print('Error fetching return: $e');
      return {};
    }
  }

  // Get returns by status
  static Future<List<Map<String, dynamic>>> getReturnsByStatus(
    ReturnStatus status,
  ) async {
    try {
      final statusString = status.toString().split('.').last;
      final response = await http.get(
        Uri.parse('$baseUrl/sales-returns?status=$statusString'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching returns by status: $e');
      return [];
    }
  }

  // ==================== CUSTOMERS ====================

  // Get all customers
  static Future<List<Map<String, dynamic>>> getCustomers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customers'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching customers: $e');
      return [];
    }
  }

  // Get customer by ID
  static Future<Map<String, dynamic>> getCustomerById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customers/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      print('Error fetching customer: $e');
      return {};
    }
  }

  // Add customer
  static Future<Map<String, dynamic>> addCustomer(
    Map<String, dynamic> customerData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customers'),
        headers: _headers,
        body: jsonEncode(customerData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception(
        'Failed to add customer: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      print('Error adding customer: $e');
      rethrow;
    }
  }
  // Update customer
  static Future<void> updateCustomer(
    int id,
    Map<String, dynamic> customerData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/customers/$id'),
        headers: _headers,
        body: jsonEncode(customerData),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to update customer');
      }
    } catch (e) {
      print('Error updating customer: $e');
      rethrow;
    }
  }

  // Delete customer
  static Future<void> deleteCustomer(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/customers/$id'),
        headers: _headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete customer');
      }
    } catch (e) {
      print('Error deleting customer: $e');
      rethrow;
    }
  }

  // Get customer balance
  static Future<Map<String, dynamic>> getCustomerBalance(int customerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customers/$customerId/balance'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'balance': 0.0};
    } catch (e) {
      print('Error fetching customer balance: $e');
      return {'balance': 0.0};
    }
  }

  // Get customer purchase history
  static Future<List<Map<String, dynamic>>> getCustomerPurchaseHistory(
    int customerId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customers/$customerId/purchases'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching customer purchase history: $e');
      return [];
    }
  }
  // ==================== VENDORS ====================

  // Get all vendors
  static Future<List<Map<String, dynamic>>> getVendors() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vendors'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching vendors: $e');
      return [];
    }
  }

  // Get vendor by ID
  static Future<Map<String, dynamic>> getVendorById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vendors/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      print('Error fetching vendor: $e');
      return {};
    }
  }

  // Add vendor
  static Future<Map<String, dynamic>> addVendor(
    Map<String, dynamic> vendorData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vendors'),
        headers: _headers,
        body: jsonEncode(vendorData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to add vendor');
    } catch (e) {
      print('Error adding vendor: $e');
      rethrow;
    }
  }

  // Update vendor
  static Future<void> updateVendor(
    int id,
    Map<String, dynamic> vendorData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/vendors/$id'),
        headers: _headers,
        body: jsonEncode(vendorData),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to update vendor');
      }
    } catch (e) {
      print('Error updating vendor: $e');
      rethrow;
    }
  }

  // Delete vendor
  static Future<void> deleteVendor(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/vendors/$id'),
        headers: _headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete vendor');
      }
    } catch (e) {
      print('Error deleting vendor: $e');
      rethrow;
    }
  }

  // Get vendor purchase history
  static Future<List<Map<String, dynamic>>> getVendorPurchaseHistory(
    int vendorId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vendors/$vendorId/purchases'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching vendor purchase history: $e');
      return [];
    }
  }

  // ==================== UNITS ====================

  // Get all units
  static Future<List<Map<String, dynamic>>> getUnits() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/units'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching units: $e');
      return [];
    }
  }

  // Get unit by ID
  static Future<Map<String, dynamic>> getUnitById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/units/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      print('Error fetching unit: $e');
      return {};
    }
  }

  // Add unit
  static Future<Map<String, dynamic>> addUnit(
    Map<String, dynamic> unitData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/units'),
        headers: _headers,
        body: jsonEncode(unitData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to add unit');
    } catch (e) {
      print('Error adding unit: $e');
      rethrow;
    }
  }

  // Update unit
  static Future<void> updateUnit(int id, Map<String, dynamic> unitData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/units/$id'),
        headers: _headers,
        body: jsonEncode(unitData),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to update unit');
      }
    } catch (e) {
      print('Error updating unit: $e');
      rethrow;
    }
  }

  // Delete unit (soft delete)
  static Future<void> deleteUnit(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/units/$id'),
        headers: _headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete unit');
      }
    } catch (e) {
      print('Error deleting unit: $e');
      rethrow;
    }
  }

  // ==================== PURCHASE ORDERS ====================

  // Get all purchase orders
  static Future<List<Map<String, dynamic>>> getPurchaseOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/purchase-orders'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching purchase orders: $e');
      return [];
    }
  }

  // Get purchase order detail by ID
  static Future<Map<String, dynamic>> getPurchaseOrderDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/purchase-orders/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'purchaseOrder': data['purchaseOrder'] ?? {},
          'items': data['items'] ?? [],
        };
      }
      return {'purchaseOrder': {}, 'items': []};
    } catch (e) {
      print('Error fetching purchase order detail: $e');
      return {'purchaseOrder': {}, 'items': []};
    }
  }

  // Create purchase order
  static Future<Map<String, dynamic>> createPurchaseOrder(
    Map<String, dynamic> poData,
  ) async {
    try {
      print('=== CREATE PURCHASE ORDER ===');
      print('Data: $poData');

      final response = await http.post(
        Uri.parse('$baseUrl/purchase-orders'),
        headers: _headers,
        body: jsonEncode(poData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception(
        'Failed to create purchase order: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      print('Error creating purchase order: $e');
      rethrow;
    }
  }

  // Add purchase order item
  static Future<void> addPurchaseOrderItem(
    int poId,
    int productId,
    double quantity,
    double unitPrice,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/purchase-orders/$poId/items'),
        headers: _headers,
        body: jsonEncode({
          'productId': productId,
          'quantity': quantity,
          'unitPrice': unitPrice,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to add purchase order item');
      }
    } catch (e) {
      print('Error adding purchase order item: $e');
      rethrow;
    }
  }

  // Update purchase order status
  static Future<void> updatePurchaseOrderStatus(int id, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/purchase-orders/$id/status'),
        headers: _headers,
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to update purchase order status');
      }
    } catch (e) {
      print('Error updating purchase order status: $e');
      rethrow;
    }
  }

  // Receive purchase order items - Updated to accept Map with additional data
  static Future<void> receivePurchaseOrderItems(
    int poId,
    Map<String, dynamic> receiveData,
  ) async {
    try {
      print('=== RECEIVE PURCHASE ORDER ITEMS ===');
      print('PO ID: $poId');
      print('Data: $receiveData');

      final response = await http.post(
        Uri.parse('$baseUrl/purchase-orders/$poId/receive'),
        headers: _headers,
        body: jsonEncode(receiveData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Failed to receive items: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error receiving items: $e');
      rethrow;
    }
  }

  // Update purchase order (for adding invoice number later)
  static Future<void> updatePurchaseOrder(
    int poId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/purchase-orders/$poId'),
        headers: _headers,
        body: jsonEncode(data),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Failed to update purchase order: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error updating purchase order: $e');
      rethrow;
    }
  }

  // Cancel purchase order
  static Future<void> cancelPurchaseOrder(int id, String reason) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/purchase-orders/$id/cancel'),
        headers: _headers,
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to cancel purchase order');
      }
    } catch (e) {
      print('Error cancelling purchase order: $e');
      rethrow;
    }
  }

  // ==================== VENDOR PAYMENTS ====================

  // Get all vendor payments
  static Future<List<Map<String, dynamic>>> getVendorPayments() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vendor-payments'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching vendor payments: $e');
      return [];
    }
  }

  // Get vendor payments by vendor
  static Future<List<Map<String, dynamic>>> getVendorPaymentsByVendor(
    int vendorId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vendor-payments?vendorId=$vendorId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching vendor payments: $e');
      return [];
    }
  }

  // Get vendor payments by date range
  static Future<List<Map<String, dynamic>>> getVendorPaymentsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/vendor-payments?start=${start.toIso8601String()}&end=${end.toIso8601String()}',
        ),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching vendor payments by date range: $e');
      return [];
    }
  }

  // Get vendor payment summary
  static Future<List<Map<String, dynamic>>> getVendorPaymentSummary() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vendor-payments/summary'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching vendor payment summary: $e');
      return [];
    }
  }

  // Add vendor payment
  static Future<Map<String, dynamic>> addVendorPayment(
    Map<String, dynamic> paymentData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vendor-payments'),
        headers: _headers,
        body: jsonEncode(paymentData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to add vendor payment');
    } catch (e) {
      print('Error adding vendor payment: $e');
      rethrow;
    }
  }

  // Delete vendor payment
  static Future<void> deleteVendorPayment(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/vendor-payments/$id'),
        headers: _headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete vendor payment');
      }
    } catch (e) {
      print('Error deleting vendor payment: $e');
      rethrow;
    }
  }
}
