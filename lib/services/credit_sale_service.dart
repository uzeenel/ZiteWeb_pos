import 'package:zite_web_pos/models/credit_sale.dart';
import 'package:zite_web_pos/services/api_service.dart';

class CreditSaleService {
  Future<List<CreditSale>> getPendingCreditSales() async {
    try {
      final response = await ApiService.getCreditSales(status: 'pending');
      return response.map((c) => CreditSale.fromMap(c)).toList();
    } catch (e) {
      print('Error fetching pending credit sales: $e');
      return [];
    }
  }

  Future<List<CreditSale>> getCreditSalesByStatus(String status) async {
    try {
      final response = await ApiService.getCreditSales(status: status);
      return response.map((c) => CreditSale.fromMap(c)).toList();
    } catch (e) {
      print('Error fetching credit sales: $e');
      return [];
    }
  }

  Future<CreditSale?> createCreditSale({
    required int saleId,
    required int customerId,
    required String invoiceNumber,
    required double total,
    required DateTime dueDate,
    String? notes,
  }) async {
    try {
      final response = await ApiService.createCreditSale({
        'sale_id': saleId,
        'customer_id': customerId,
        'invoice_number': invoiceNumber,
        'total': total,
        'due_date': dueDate.toIso8601String().split('T')[0],
        'notes': notes,
      });
      return CreditSale.fromMap(response);
    } catch (e) {
      print('Error creating credit sale: $e');
      return null;
    }
  }

  Future<bool> approveCreditSale(int creditSaleId) async {
    try {
      await ApiService.approveCreditSale(creditSaleId);
      return true;
    } catch (e) {
      print('Error approving credit sale: $e');
      return false;
    }
  }

  Future<bool> rejectCreditSale(int creditSaleId, String reason) async {
    try {
      await ApiService.rejectCreditSale(creditSaleId, reason);
      return true;
    } catch (e) {
      print('Error rejecting credit sale: $e');
      return false;
    }
  }
}
