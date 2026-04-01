import 'package:pos_system/models/vendor.dart';
import 'package:pos_system/models/region.dart';
import 'package:pos_system/services/api_service.dart';

class VendorService {
  // Get all vendors
  Future<List<Vendor>> getAllVendors() async {
    try {
      final response = await ApiService.getVendors();
      return response.map((json) => Vendor.fromMap(json)).toList();
    } catch (e) {
      print('Error fetching vendors from API: $e');
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

  // Get vendor by ID
  Future<Vendor?> getVendorById(int id) async {
    try {
      final response = await ApiService.getVendorById(id);
      if (response.isNotEmpty) {
        return Vendor.fromMap(response);
      }
      return null;
    } catch (e) {
      print('Error fetching vendor by ID from API: $e');
      return null;
    }
  }

  // Get vendor by phone
  Future<Vendor?> getVendorByPhone(String phone) async {
    try {
      final vendors = await getAllVendors();
      return vendors.firstWhere(
        (v) => v.phone == phone,
        orElse: () => throw Exception('Vendor not found'),
      );
    } catch (e) {
      print('Error fetching vendor by phone from API: $e');
      return null;
    }
  }

  // Get vendor by email
  Future<Vendor?> getVendorByEmail(String email) async {
    try {
      final vendors = await getAllVendors();
      return vendors.firstWhere(
        (v) => v.email == email,
        orElse: () => throw Exception('Vendor not found'),
      );
    } catch (e) {
      print('Error fetching vendor by email from API: $e');
      return null;
    }
  }

  // Add new vendor
  Future<Vendor> addVendor({
    required String name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    int? stateId,
    String? taxId,
    String? paymentTerms,
    bool? isVatRegistered,
  }) async {
    try {
      final vendorData = {
        'name': name,
        'contactPerson': contactPerson,
        'phone': phone,
        'email': email,
        'address': address,
        'stateId': stateId,
        'taxId': taxId,
        'paymentTerms': paymentTerms,
        'isVatRegistered': isVatRegistered ?? false,
      };

      final response = await ApiService.addVendor(vendorData);
      return Vendor.fromMap(response);
    } catch (e) {
      print('Error adding vendor via API: $e');
      rethrow;
    }
  }

  // Update vendor
  Future<bool> updateVendor({
    required int id,
    required String name,
    String? phone,
    String? email,
    String? address,
    int? stateId,
    String? contactPerson,
    String? taxId,
    String? paymentTerms,
    bool? isVatRegistered,
  }) async {
    try {
      final vendorData = {
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'stateId': stateId,
        'contactPerson': contactPerson,
        'taxId': taxId,
        'paymentTerms': paymentTerms,
        'isVatRegistered': isVatRegistered ?? false,
        'isActive': 1,
      };

      await ApiService.updateVendor(id, vendorData);
      return true;
    } catch (e) {
      print('Error updating vendor via API: $e');
      return false;
    }
  }

  // Delete vendor
  Future<bool> deleteVendor(int id) async {
    try {
      await ApiService.deleteVendor(id);
      return true;
    } catch (e) {
      print('Error deleting vendor via API: $e');
      return false;
    }
  }

  // Search vendors
  Future<List<Vendor>> searchVendors(String query) async {
    try {
      final vendors = await getAllVendors();
      return vendors.where((v) {
        return v.name.toLowerCase().contains(query.toLowerCase()) ||
            (v.contactPerson?.toLowerCase().contains(query.toLowerCase()) ??
                false) ||
            (v.phone?.contains(query) ?? false) ||
            (v.email?.toLowerCase().contains(query.toLowerCase()) ?? false);
      }).toList();
    } catch (e) {
      print('Error searching vendors via API: $e');
      return [];
    }
  }

  // Get vendor purchase history
  Future<List<Map<String, dynamic>>> getVendorPurchaseHistory(
    int vendorId,
  ) async {
    try {
      return await ApiService.getVendorPurchaseHistory(vendorId);
    } catch (e) {
      print('Error fetching vendor purchase history from API: $e');
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
