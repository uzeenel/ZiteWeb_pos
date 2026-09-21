import 'package:zite_web_pos/models/sales_return.dart';
import 'package:zite_web_pos/models/sale.dart';
import 'package:zite_web_pos/services/api_service.dart';

class SalesReturnService {
  // Get sale by invoice number
  Future<Sale?> getSaleByInvoice(String invoiceNumber) async {
    try {
      final response = await ApiService.getSaleByInvoice(invoiceNumber);
      if (response != null) {
        return _mapToSale(response);
      }
      return null;
    } catch (e) {
      print('Error fetching sale by invoice from API: $e');
      return null;
    }
  }

  // Get sale items available for return
  Future<List<Map<String, dynamic>>> getSaleItemsForReturn(
    String invoiceNumber,
  ) async {
    try {
      final response = await ApiService.getSaleItemsForReturn(invoiceNumber);
      return response;
    } catch (e) {
      print('Error fetching sale items for return from API: $e');
      return [];
    }
  }

  // Create return request
  Future<SalesReturn> createReturn({
    required int saleId,
    required String invoiceNumber,
    required List<Map<String, dynamic>> items,
    required String reason,
    required int? cashierId,
  }) async {
    try {
      final response = await ApiService.createReturn(
        saleId: saleId,
        invoiceNumber: invoiceNumber,
        items: items,
        reason: reason,
        cashierId: cashierId,
      );
      return SalesReturn.fromMap(response);
    } catch (e) {
      print('Error creating return via API: $e');
      rethrow;
    }
  }

  // Approve return
  Future<SalesReturn> approveReturn(int returnId) async {
    try {
      final response = await ApiService.approveReturn(returnId);
      return SalesReturn.fromMap(response);
    } catch (e) {
      print('Error approving return via API: $e');
      rethrow;
    }
  }

  // Complete return (process refund and restock)
  Future<SalesReturn> completeReturn(int returnId) async {
    try {
      final response = await ApiService.completeReturn(returnId);
      return SalesReturn.fromMap(response);
    } catch (e) {
      print('Error completing return via API: $e');
      rethrow;
    }
  }

  // Reject return
  Future<SalesReturn> rejectReturn(int returnId, String rejectionReason) async {
    try {
      final response = await ApiService.rejectReturn(returnId, rejectionReason);
      return SalesReturn.fromMap(response);
    } catch (e) {
      print('Error rejecting return via API: $e');
      rethrow;
    }
  }

  // Get returns by date range
  Future<List<SalesReturn>> getReturnsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await ApiService.getReturnsByDateRange(start, end);
      return response.map((json) => SalesReturn.fromMap(json)).toList();
    } catch (e) {
      print('Error fetching returns by date range from API: $e');
      return [];
    }
  }

  // Get return by ID
  Future<SalesReturn?> getReturn(int id) async {
    try {
      final response = await ApiService.getReturn(id);
      if (response.isNotEmpty) {
        return SalesReturn.fromMap(response);
      }
      return null;
    } catch (e) {
      print('Error fetching return by ID from API: $e');
      return null;
    }
  }

  // Get returns by status
  Future<List<SalesReturn>> getReturnsByStatus(ReturnStatus status) async {
    try {
      final response = await ApiService.getReturnsByStatus(status);
      return response.map((json) => SalesReturn.fromMap(json)).toList();
    } catch (e) {
      print('Error fetching returns by status from API: $e');
      return [];
    }
  }

  // Helper to map API response to Sale object
  Sale _mapToSale(Map<String, dynamic> map) {
    double _toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    List<SaleItem> items = [];
    if (map['items'] != null && map['items'] is List) {
      items = (map['items'] as List)
          .map(
            (item) => SaleItem(
              id: _toInt(item['id']),
              saleId: _toInt(map['id']),
              productId: _toInt(item['product_id']),
              quantity: _toInt(item['quantity']),
              unitPrice: _toDouble(item['unit_price']),
              total: _toDouble(item['total']),
              isVatExempt: item['is_vat_exempt'] == 1,
              productName: item['product_name'],
              sku: item['sku'],
              categoryName: item['category_name'],
            ),
          )
          .toList();
    }

    return Sale(
      id: _toInt(map['id']),
      invoiceNumber: map['invoice_number'] ?? '',
      saleDate: DateTime.parse(map['sale_date']),
      subtotal: _toDouble(map['subtotal']),
      tax: _toDouble(map['tax']),
      total: _toDouble(map['total']),
      paymentMethod: map['payment_method'] ?? 'Cash',
      paidAmount: _toDouble(map['paid_amount']),
      change: _toDouble(map['change_amount']),
      customerId: _toInt(map['customer_id']),
      cashierId: _toInt(map['cashier_id']),
      items: items,
    );
  }
}
