import 'package:pos_system/services/api_service.dart';
import 'package:pos_system/models/cart_item.dart';
import 'package:pos_system/models/sale.dart';

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
      final response = await ApiService.getSalesByDateRange(start, end);
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

    final sale = Sale(
      id: map['id'],
      invoiceNumber: map['invoice_number'] ?? '',
      saleDate: saleDate,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['payment_method'] ?? 'Cash',
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0,
      change: (map['change_amount'] as num?)?.toDouble() ?? 0,
      customerId: map['customer_id'],
      cashierId: map['cashier_id'],
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
    } else {
      quantity = 0;
    }

    return SaleItem(
      id: map['id'] ?? 0,
      saleId: saleId,
      productId: map['product_id'] ?? 0,
      quantity: quantity,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      isVatExempt: map['is_vat_exempt'] == true || map['is_vat_exempt'] == 1,
      productName: map['product_name'],
      sku: map['sku'],
      categoryName: map['category_name'],
    );
  }
}
