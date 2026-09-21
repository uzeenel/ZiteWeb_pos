import 'package:zite_web_pos/services/api_service.dart';
import 'package:zite_web_pos/models/cart_item.dart';
import 'package:zite_web_pos/models/sale.dart';

class SaleService {
  // Get all sales as maps (for SalesHistoryScreen)
  Future<List<Map<String, dynamic>>> getSales() async {
    try {
      return await ApiService.getSales();
    } catch (e) {
      print('Error fetching sales from API: $e');
      return [];
    }
  }

  // Get sales by date range as maps
  Future<List<Map<String, dynamic>>> getSalesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      print('=== GET SALES BY DATE RANGE ===');
      print('Start: ${start.toIso8601String()}');
      print('End: ${end.toIso8601String()}');

      final response = await ApiService.getSalesByDateRange(start, end);
      print('API Response length: ${response.length}');
      for (var sale in response) {
        print(
          'Sale: ${sale['invoice_number']}, Date: ${sale['sale_date']}, Total: ${sale['total']}',
        );
      }
      return response;
    } catch (e) {
      print('Error fetching sales by date range from API: $e');
      return [];
    }
  }

  // Get all sales as Sale objects (for reports)
  Future<List<Sale>> getAllSalesAsObjects() async {
    try {
      final response = await ApiService.getSales();
      return response.map((saleMap) => _mapToSale(saleMap)).toList();
    } catch (e) {
      print('Error fetching sales from API: $e');
      return [];
    }
  }

  // Get sale detail by ID
  Future<Map<String, dynamic>> getSaleDetail(int saleId) async {
    try {
      return await ApiService.getSaleDetail(saleId);
    } catch (e) {
      print('Error fetching sale detail from API: $e');
      return {'sale': {}, 'items': []};
    }
  }

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

  // Save sale to API
  Future<Map<String, dynamic>> saveSale({
    required List<CartItem> cart,
    required double subtotal,
    required double tax,
    required double total,
    required String paymentMethod,
    required double paidAmount,
    int? customerId,
    int? cashierId,
  }) async {
    try {
      final result = await ApiService.saveSale(
        cart: cart,
        subtotal: subtotal,
        tax: tax,
        total: total,
        paymentMethod: paymentMethod,
        paidAmount: paidAmount,
        cashierId: cashierId,
      );
      return result;
    } catch (e) {
      print('Error saving sale to API: $e');
      rethrow;
    }
  }

  // Helper method to convert API map to Sale object
  Sale _mapToSale(Map<String, dynamic> map) {
    DateTime saleDate;
    if (map['sale_date'] != null) {
      saleDate = DateTime.parse(map['sale_date']);
    } else {
      saleDate = DateTime.now();
    }

    double _toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int? _toIntOrNull(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }

    final sale = Sale(
      id: _toIntOrNull(map['id']),
      invoiceNumber: map['invoice_number'] ?? '',
      saleDate: saleDate,
      subtotal: _toDouble(map['subtotal']),
      tax: _toDouble(map['tax']),
      total: _toDouble(map['total']),
      paymentMethod: map['payment_method'] ?? 'Cash',
      paidAmount: _toDouble(map['paid_amount']),
      change: _toDouble(map['change_amount']),
      customerId: _toIntOrNull(map['customer_id']),
      cashierId: _toIntOrNull(map['cashier_id']),
    );

    if (map['items'] != null && map['items'] is List) {
      final itemsList = map['items'] as List;
      sale.items = itemsList
          .map((itemMap) => _mapToSaleItem(itemMap, sale.id!))
          .toList();
    }

    return sale;
  }

  // Helper method to convert API item map to SaleItem object
  SaleItem _mapToSaleItem(Map<String, dynamic> map, int saleId) {
    int quantity;
    if (map['quantity'] is int) {
      quantity = map['quantity'];
    } else if (map['quantity'] is double) {
      quantity = (map['quantity'] as double).toInt();
    } else if (map['quantity'] is String) {
      quantity = int.tryParse(map['quantity']) ?? 0;
    } else {
      quantity = 0;
    }

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

    return SaleItem(
      id: _toInt(map['id']),
      saleId: saleId,
      productId: _toInt(map['product_id']),
      quantity: quantity,
      unitPrice: _toDouble(map['unit_price']),
      total: _toDouble(map['total']),
      isVatExempt: map['is_vat_exempt'] == true || map['is_vat_exempt'] == 1,
      productName: map['product_name'],
      sku: map['sku'],
      categoryName: map['category_name'],
    );
  }
}
