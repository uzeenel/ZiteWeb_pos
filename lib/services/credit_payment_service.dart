import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class CreditPaymentService {
  static Future<Map<String, dynamic>> getCustomerCreditSummary(
    int customerId,
  ) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/customers/$customerId/credit-summary'),
      headers: ApiService.authHeaders,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load credit summary');
  }

  static Future<List<Map<String, dynamic>>> getCustomerOutstandingSales(
    int customerId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '${ApiService.baseUrl}/customers/$customerId/outstanding-sales',
      ),
      headers: ApiService.authHeaders,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load outstanding sales');
  }

  static Future<void> recordPayment({
    required int creditSaleId,
    required int customerId,
    required double amount,
    required String paymentMethod,
    String? referenceNumber,
    String? notes,
    String? accountName,
    String? bankName,
    int? bankAccountId,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/credit-payments'),
      headers: ApiService.authHeaders,
      body: jsonEncode({
        'credit_sale_id': creditSaleId,
        'customer_id': customerId,
        'amount': amount,
        'payment_method': paymentMethod,
        'reference_number': referenceNumber,
        'notes': notes,
        'account_name': accountName,
        'bank_name': bankName,
        'bank_account_id': bankAccountId,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to record payment');
    }
  }
}
