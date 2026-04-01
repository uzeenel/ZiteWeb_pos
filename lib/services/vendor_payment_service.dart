import 'package:pos_system/models/vendor_payment.dart';
import 'package:pos_system/services/api_service.dart';

class VendorPaymentService {
  // Helper to safely convert to double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Helper to safely convert to int
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Get all vendor payments
  Future<List<VendorPayment>> getAllPayments() async {
    try {
      final response = await ApiService.getVendorPayments();
      return response.map((json) => VendorPayment.fromMap(json)).toList();
    } catch (e) {
      print('Error fetching vendor payments: $e');
      return [];
    }
  }

  // Get payments by vendor
  Future<List<VendorPayment>> getPaymentsByVendor(int vendorId) async {
    try {
      final response = await ApiService.getVendorPaymentsByVendor(vendorId);
      return response.map((json) => VendorPayment.fromMap(json)).toList();
    } catch (e) {
      print('Error fetching vendor payments: $e');
      return [];
    }
  }

  // Get payments by date range
  Future<List<VendorPayment>> getPaymentsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await ApiService.getVendorPaymentsByDateRange(
        start,
        end,
      );
      return response.map((json) => VendorPayment.fromMap(json)).toList();
    } catch (e) {
      print('Error fetching vendor payments by date range: $e');
      return [];
    }
  }

  // Get vendor payment summary
  Future<List<VendorPaymentSummary>> getVendorPaymentSummary() async {
    try {
      final response = await ApiService.getVendorPaymentSummary();
      return response
          .map(
            (json) => VendorPaymentSummary(
              vendorId: _toInt(json['vendor_id']),
              vendorName: json['vendor_name']?.toString() ?? '',
              totalPurchases: _toDouble(json['total_purchases']),
              totalPayments: _toDouble(json['total_payments']),
              balance: _toDouble(json['balance']),
            ),
          )
          .toList();
    } catch (e) {
      print('Error fetching vendor payment summary: $e');
      return [];
    }
  }

  // Add payment
  Future<VendorPayment> addPayment({
    required int vendorId,
    int? purchaseOrderId,
    required DateTime paymentDate,
    required double amount,
    required String paymentMethod,
    String? reference,
    String? notes,
    int? createdBy,
  }) async {
    try {
      final paymentData = {
        'vendorId': vendorId,
        'purchaseOrderId': purchaseOrderId,
        'paymentDate': paymentDate.toIso8601String(),
        'amount': amount,
        'paymentMethod': paymentMethod,
        'reference': reference,
        'notes': notes,
        'createdBy': createdBy,
      };

      final response = await ApiService.addVendorPayment(paymentData);
      return VendorPayment.fromMap(response);
    } catch (e) {
      print('Error adding vendor payment: $e');
      rethrow;
    }
  }

  // Delete payment
  Future<bool> deletePayment(int id) async {
    try {
      await ApiService.deleteVendorPayment(id);
      return true;
    } catch (e) {
      print('Error deleting vendor payment: $e');
      return false;
    }
  }
}
