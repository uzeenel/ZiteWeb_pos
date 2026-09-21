import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zite_web_pos/models/product.dart';
import 'package:zite_web_pos/models/user.dart';
import 'package:zite_web_pos/models/category.dart';
import 'package:zite_web_pos/models/cart_item.dart';
import 'package:zite_web_pos/models/sales_return.dart';

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
  static Map<String, String> get authHeaders => _headers;

  // ==================== AUTH ====================

  static Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        body: jsonEncode({'username': username, 'password': password}),
        headers: {'Content-Type': 'application/json'},
      );

      print('=== LOGIN RESPONSE ===');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed data: $data');
        print('Token: ${data['token']}');
        print('User: ${data['user']}');

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
          'totalCustomers': _toInt(data['totalCustomers']),
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

  static Future<String> getNextSku(int categoryId, String productName) async {
    try {
      if (productName.trim().isEmpty) return '';
      final url = Uri.parse(
        '$baseUrl/products/next-sku?category_id=$categoryId&name=${Uri.encodeComponent(productName)}',
      );
      print('getNextSku: Requesting URL: $url');
      final response = await http.get(url, headers: _headers);
      print('getNextSku: Response status: ${response.statusCode}');
      print('getNextSku: Response body: ${response.body}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final nextSku = data['nextSku'] ?? '';
        print('getNextSku: Parsed nextSku = "$nextSku"');
        return nextSku;
      }
      print('getNextSku: Non-200 status, returning empty');
      return '';
    } catch (e) {
      print('getNextSku error: $e');
      return '';
    }
  }

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

    static Future<void> updateProduct(
    int id,
    Map<String, dynamic> product,
  ) async {
    try {
      final updateData = {
        'name': product['name'],
        'sku': product['sku'],
        'category_id': product['category_id'],
        'unit_id': product['unit_id'],
        'barcode': product['barcode'],
        'cost_price': product['cost_price'],
        'selling_price': product['selling_price'],
        'stock_quantity': product['stock_quantity'],
        'min_stock_level': product['min_stock_level'],
        'is_vat_exempt': product['is_vat_exempt'],
        'image_url': product['image_url'],
        'markup_percent': product['markup_percent'],
        'markup_is_manual': product['markup_is_manual'],
        'is_active': 1,
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
    print('🔴 API CALL: updateStock productId=$productId, quantity=$quantity');
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

  static Future<void> updateCategory(
    int id,
    Map<String, dynamic> category,
  ) async {
    try {
      final updateData = {
        'name': category['name'],
        'description': category['description'],
        'is_vat_exempt': category['isVatExempt'] == true ? 1 : 0,
        'is_active': 1,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/categories/$id'),
        headers: _headers,
        body: jsonEncode(updateData),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to update category');
      }
    } catch (e) {
      print('Error updating category via API: $e');
      rethrow;
    }
  }

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

    static Future<Map<String, dynamic>> saveSale({
    required List<CartItem> cart,
    required double subtotal,
    required double tax,
    required double total,
    required String paymentMethod,
    required double paidAmount,
    required int? cashierId,
    int? customerId,
    String? discountType,
    double? discountValue,
    String? discountPin,
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
        'paymentMethod': paymentMethod,
        'paidAmount': paidAmount,
        'cashierId': cashierId,
        'customerId': customerId,
        'discountType': discountType,
        'discountValue': discountValue,
        'discountPin': discountPin, 
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
        final data = jsonDecode(response.body);
        print('Save sale response data: $data');
        return {
          'invoiceNumber': data['invoiceNumber'],
          'change': data['change'],
          'saleId': data['saleId'],
        };
      }
      throw Exception('Failed to save sale');
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

      final url = '$baseUrl/sales?start=${start.toIso8601String()}&end=${end.toIso8601String()}';
      print('📊 GET SALES URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      print('📊 GET SALES RESPONSE: status=${response.statusCode}');
      print('📊 GET SALES BODY: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('📊 Found ${data.length} sales');
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      print('❌ GET SALES failed with status: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Error fetching sales: $e');
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

      print('=== API GET SALES BY DATE RANGE ===');
      print('URL: $baseUrl/sales?start=${start.toIso8601String()}&end=${end.toIso8601String()}');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

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

      print('🔴 getSaleByInvoice response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching sale by invoice: $e');
      return null;
    }
  }

  // ==================== CREDIT SALES ====================

  static Future<List<Map<String, dynamic>>> getCreditSales({
    String? status,
  }) async {
    try {
      String url = '$baseUrl/credit-sales';
      if (status != null) {
        url += '?status=$status';
      }
      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching credit sales: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> createCreditSale(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/credit-sales'),
        headers: _headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to create credit sale');
    } catch (e) {
      print('Error creating credit sale: $e');
      rethrow;
    }
  }

  static Future<void> approveCreditSale(int creditSaleId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/credit-sales/$creditSaleId/approve'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to approve credit sale');
      }
    } catch (e) {
      print('Error approving credit sale: $e');
      rethrow;
    }
  }

  static Future<void> rejectCreditSale(int creditSaleId, String reason) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/credit-sales/$creditSaleId/reject'),
        headers: _headers,
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to reject credit sale');
      }
    } catch (e) {
      print('Error rejecting credit sale: $e');
      rethrow;
    }
  }

  static Future<void> completeCreditSale(int creditSaleId) async {
    try {
      print('📤 COMPLETING CREDIT SALE - ID: $creditSaleId');
      print('📤 URL: $baseUrl/credit-sales/$creditSaleId/complete');

      final response = await http.patch(
        Uri.parse('$baseUrl/credit-sales/$creditSaleId/complete'),
        headers: _headers,
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode != 200) {
        print('❌ Failed with status: ${response.statusCode}');
        throw Exception('Failed to complete credit sale');
      }

      print('✅ Credit sale completed successfully');
    } catch (e) {
      print('❌ Error completing credit sale: $e');
      rethrow;
    }
  }

  // ==================== USERS ====================

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

  // ==================== CUSTOMERS ====================

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

  static Future<List<Map<String, dynamic>>> getVendorInvoices(
    int vendorId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vendors/$vendorId/invoices'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching vendor invoices: $e');
      return [];
    }
  }

  // ==================== VENDOR PAYMENTS ====================

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

  // ==================== UNITS ====================

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

  static Future<Map<String, dynamic>> createPurchaseOrder(
    Map<String, dynamic> poData,
  ) async {
    try {
      print('=== CREATE PURCHASE ORDER API CALL ===');
      print('Data being sent: $poData');

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

  // ==================== EXPENSES ====================

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

  // ==================== CASH BOOK ====================

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

  static Future<Map<String, dynamic>> saveCompany(
    Map<String, dynamic> companyData,
  ) async {
    try {
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

  // Upload company logo
  static Future<Map<String, dynamic>> uploadCompanyLogo(File logoFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/company/logo'),
      );
      request.headers.addAll(_headers);
      request.files.add(
        await http.MultipartFile.fromPath('logo', logoFile.path),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      }
      throw Exception('Failed to upload logo: ${response.statusCode}');
    } catch (e) {
      print('Error uploading logo: $e');
      rethrow;
    }
  }

  // Update company (PUT)
  static Future<Map<String, dynamic>> updateCompany(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/company'),
        headers: _headers,
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to update company');
    } catch (e) {
      print('Error updating company: $e');
      rethrow;
    }
  }

  // Delete company logo
  static Future<void> deleteCompanyLogo() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/company/logo'),
        headers: _headers,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to delete logo');
      }
    } catch (e) {
      print('Error deleting logo: $e');
      rethrow;
    }
  }

    static Future<Map<String, dynamic>> generateDiscountPins({
    required int count,
    required String maxDiscountType,
    required double maxDiscountValue,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/discount-pins/generate'),
        headers: _headers,
        body: jsonEncode({
          'count': count,
          'maxDiscountType': maxDiscountType,
          'maxDiscountValue': maxDiscountValue,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to generate PINs');
    } catch (e) {
      print('Error generating discount PINs: $e');
      rethrow;
    }
  }

  // ==================== STATES ====================

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

  // ==================== SALES RETURNS ====================

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

  // ==================== STOCK MOVEMENTS ====================

  static Future<List<Map<String, dynamic>>> getStockMovements({
    int? productId,
    DateTime? start,
    DateTime? end,
    String? reference,
  }) async {
    try {
      String url = '$baseUrl/stock-movements?';
      List<String> params = [];

      if (productId != null) {
        params.add('productId=$productId');
      }
      if (start != null) {
        params.add('start=${start.toIso8601String()}');
      }
      if (end != null) {
        params.add('end=${end.toIso8601String()}');
      }
      if (reference != null) {
        params.add('reference=$reference');
      }

      url += params.join('&');

      print('📡 API CALL: GET $url');

      final response = await http.get(Uri.parse(url), headers: _headers);

      print('📡 RESPONSE STATUS: ${response.statusCode}');
      print('📡 RESPONSE BODY: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('📡 PARSED DATA LENGTH: ${data.length}');
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching stock movements: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getProductBincard(
    int productId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId/bincard'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching product bincard: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> recordStockMovement({
    required int productId,
    required String reference,
    required String movementType,
    required double quantity,
    required String? notes,
    required String? invoiceNumber,
  }) async {
    try {
      final movementData = {
        'product_id': productId,
        'reference': reference,
        'movement_type': movementType,
        'quantity': quantity,
        'notes': notes,
        'invoice_number': invoiceNumber,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/stock-movements'),
        headers: _headers,
        body: jsonEncode(movementData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to record stock movement');
    } catch (e) {
      print('Error recording stock movement: $e');
      rethrow;
    }
  }

  // ==================== NOTIFICATIONS ====================

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  static Future<void> markNotificationRead(int notificationId) async {
    try {
      await http.patch(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: _headers,
      );
    } catch (e) {
      print('Error marking notification read: $e');
    }
  }

  // ==================== BANKS ====================

  static Future<List<Map<String, dynamic>>> getBanks() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/banks'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching banks: $e');
      return [];
    }
  }

  // ==================== BANK ACCOUNTS ====================

  static Future<List<Map<String, dynamic>>> getBankAccounts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bank-accounts'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching bank accounts: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> addBankAccount(
    Map<String, dynamic> accountData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bank-accounts'),
        headers: _headers,
        body: jsonEncode(accountData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to add bank account');
    } catch (e) {
      print('Error adding bank account: $e');
      rethrow;
    }
  }

  static Future<void> updateBankAccountBalance(
    int accountId,
    double amount,
    String type,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/bank-accounts/$accountId/balance'),
        headers: _headers,
        body: jsonEncode({'amount': amount, 'type': type}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update bank account balance');
      }
    } catch (e) {
      print('Error updating bank account balance: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createLayaway(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/layaway'),
        headers: _headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to create layaway');
    } catch (e) {
      print('Error creating layaway: $e');
      rethrow;
    }
  }

   // ==================== LAYAWAY ENDPOINTS ====================

  static Future<List<Map<String, dynamic>>> getLayawayOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/layaway'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching layaway orders: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getLayawayOrder(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/layaway/$id'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching layaway order: $e');
      return null;
    }
  }

  static Future<void> recordLayawayPayment(
    int layawayId,
    double amount,
    String paymentMethod,
  ) async {
    try {
      print('📤 recordLayawayPayment called');
      print('  layawayId: $layawayId');
      print('  amount: $amount');
      print('  paymentMethod: $paymentMethod');

      final response = await http.post(
        Uri.parse('$baseUrl/layaway/$layawayId/payment'),
        headers: _headers,
        body: jsonEncode({'amount': amount, 'payment_method': paymentMethod}),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to record payment');
      }
    } catch (e) {
      print('Error recording layaway payment: $e');
      rethrow;
    }
  }

  static Future<void> completeLayaway(int layawayId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/layaway/$layawayId/complete'),
        headers: _headers,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to complete layaway');
      }
    } catch (e) {
      print('Error completing layaway: $e');
      rethrow;
    }
  }

  static Future<void> cancelLayaway(int layawayId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/layaway/$layawayId/cancel'),
        headers: _headers,
        body: jsonEncode({'reason': 'Cancelled by user'}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to cancel layaway');
      }
    } catch (e) {
      print('Error cancelling layaway: $e');
      rethrow;
    }
  }

  // ==================== LAYAWAY PAYMENTS ====================

  static Future<List<Map<String, dynamic>>> getLayawayPayments(
    int layawayId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/layaway/$layawayId/payments'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching layaway payments: $e');
      return [];
    }
  }

  static Future<void> setStock(int productId, double quantity) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/products/$productId/set-stock'),
        headers: _headers,
        body: jsonEncode({'quantity': quantity}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to set stock');
      }
    } catch (e) {
      print('Error setting stock: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getDiscountPins({
    String? status,
    DateTime? start,
    DateTime? end,
  }) async {
    try {
      String url = '$baseUrl/discount-pins?';
      final params = <String>[];
      if (status != null) params.add('status=$status');
      if (start != null) {
        params.add('start=${start.toIso8601String().split('T')[0]}');
      }
      if (end != null) {
        params.add('end=${end.toIso8601String().split('T')[0]}');
      }
      url += params.join('&');

      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching discount pins: $e');
      return [];
    }
  }

    // ==================== ROLES & PERMISSIONS ====================

  static Future<List<Map<String, dynamic>>> getRoles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/roles'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching roles: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getPermissions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/permissions'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching permissions: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getRoleWithPermissions(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/roles/$id'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      print('Error fetching role: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>> createRole({
    required String name,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/roles'),
      headers: _headers,
      body: jsonEncode({'name': name, 'description': description}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final err = jsonDecode(response.body);
    throw Exception(err['error'] ?? 'Failed to create role');
  }

  static Future<void> updateRole({
    required int id,
    required String name,
    String? description,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/roles/$id'),
      headers: _headers,
      body: jsonEncode({'name': name, 'description': description}),
    );
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Failed to update role');
    }
  }

  static Future<void> deleteRole(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/roles/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Failed to delete role');
    }
  }

  static Future<void> setRolePermissions({
    required int roleId,
    required List<int> permissionIds,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/roles/$roleId/permissions'),
      headers: _headers,
      body: jsonEncode({'permission_ids': permissionIds}),
    );
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Failed to update permissions');
    }
  }

  static Future<Set<String>> getMyPermissions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-permissions'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> perms = data['permissions'] ?? [];
        return perms.map((e) => e.toString()).toSet();
      }
      return {};
    } catch (e) {
      print('Error fetching my permissions: $e');
      return {};
    }
  }


  // ==================== HELPERS ====================

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
}

 