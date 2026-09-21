import 'package:zite_web_pos/models/customer.dart';
import 'package:zite_web_pos/models/region.dart';
import 'package:zite_web_pos/services/api_service.dart';

class CustomerService {
  // Get all customers
  Future<List<Customer>> getAllCustomers() async {
    try {
      final response = await ApiService.getCustomers();
      return response.map((json) => Customer.fromMap(json)).toList();
    } catch (e) {
      print('Error fetching customers from API: $e');
      return [];
    }
  }

  // Get all states/regions
  Future<List<Region>> getAllStates() async {
    try {
      final response = await ApiService.getStates();
      return response.map((json) => Region.fromMap(json)).toList();
    } catch (e) {
      print('Error fetching states from API: $e');
      return [];
    }
  }

  // Get customer by ID
  Future<Customer?> getCustomerById(int id) async {
    try {
      final response = await ApiService.getCustomerById(id);
      if (response.isNotEmpty) {
        return Customer.fromMap(response);
      }
      return null;
    } catch (e) {
      print('Error fetching customer by ID from API: $e');
      return null;
    }
  }

  // Get customer by phone
  Future<Customer?> getCustomerByPhone(String phone) async {
    try {
      final customers = await getAllCustomers();
      return customers.firstWhere(
        (c) => c.phone == phone,
        orElse: () => throw Exception('Customer not found'),
      );
    } catch (e) {
      print('Error fetching customer by phone from API: $e');
      return null;
    }
  }

  // Get customer by email
  Future<Customer?> getCustomerByEmail(String email) async {
    try {
      final customers = await getAllCustomers();
      return customers.firstWhere(
        (c) => c.email == email,
        orElse: () => throw Exception('Customer not found'),
      );
    } catch (e) {
      print('Error fetching customer by email from API: $e');
      return null;
    }
  }

  // Add new customer
  Future<Customer> addCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
    int? stateId,
    String? taxId,
    double? creditLimit,
    int? creditDays,
  }) async {
    try {
      final customerData = {
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'stateId': stateId,
        'taxId': taxId,
        'creditLimit': creditLimit ?? 0,
        'creditDays': creditDays ?? 0,
      };

      final response = await ApiService.addCustomer(customerData);
      return Customer.fromMap(response);
    } catch (e) {
      print('Error adding customer via API: $e');
      rethrow;
    }
  }

  // Update customer
  Future<bool> updateCustomer(Customer customer) async {
    try {
      final customerData = {
        'name': customer.name,
        'phone': customer.phone,
        'email': customer.email,
        'address': customer.address,
        'stateId': customer.stateId,
        'taxId': customer.taxId,
        'creditLimit': customer.creditLimit,
        'creditDays': customer.creditDays,
        'isActive': customer.isActive
            ? 1
            : 0, // Always preserve the current status
      };

      await ApiService.updateCustomer(customer.id, customerData);
      return true;
    } catch (e) {
      print('Error updating customer via API: $e');
      return false;
    }
  }

  // Delete customer
  Future<bool> deleteCustomer(int id) async {
    try {
      await ApiService.deleteCustomer(id);
      return true;
    } catch (e) {
      print('Error deleting customer via API: $e');
      return false;
    }
  }

  // Search customers
  Future<List<Customer>> searchCustomers(String query) async {
    try {
      final customers = await getAllCustomers();
      return customers.where((c) {
        return c.name.toLowerCase().contains(query.toLowerCase()) ||
            (c.phone?.contains(query) ?? false) ||
            (c.email?.toLowerCase().contains(query.toLowerCase()) ?? false);
      }).toList();
    } catch (e) {
      print('Error searching customers via API: $e');
      return [];
    }
  }

  // Get customer balance
  Future<double> getCustomerBalance(int customerId) async {
    try {
      final response = await ApiService.getCustomerBalance(customerId);
      return _toDouble(response['balance']);
    } catch (e) {
      print('Error fetching customer balance from API: $e');
      return 0.0;
    }
  }

  // Get customer purchase history
  Future<List<Map<String, dynamic>>> getCustomerPurchaseHistory(
    int customerId,
  ) async {
    try {
      return await ApiService.getCustomerPurchaseHistory(customerId);
    } catch (e) {
      print('Error fetching customer purchase history from API: $e');
      return [];
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
