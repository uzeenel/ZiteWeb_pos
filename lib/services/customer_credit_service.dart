// lib/services/customer_credit_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/credit_sale.dart';
import 'api_service.dart';

class CustomerCreditService {
  static const String baseUrl = ApiService.baseUrl;

  static Future<Map<String, dynamic>> getCustomerCreditBalance(
    int customerId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/customers/$customerId/credit-balance'),
      headers: ApiService._headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load credit balance');
  }

  static Future<List<CreditSale>> getCustomerCreditSales(int customerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/customers/$customerId/credit-sales'),
      headers: ApiService._headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => CreditSale.fromJson(json)).toList();
    }
    throw Exception('Failed to load credit sales');
  }

  static Future<void> recordPayment({
    required int creditSaleId,
    required int customerId,
    required double amount,
    required String paymentMethod,
    String? referenceNumber,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/credit-payments'),
      headers: ApiService._headers,
      body: jsonEncode({
        'credit_sale_id': creditSaleId,
        'customer_id': customerId,
        'amount': amount,
        'payment_method': paymentMethod,
        'reference_number': referenceNumber,
        'notes': notes,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to record payment');
    }
  }
}
