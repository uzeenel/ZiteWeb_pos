import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zite_web_pos/models/bank.dart';
import 'package:zite_web_pos/models/bank_account.dart';
import 'api_service.dart';

class BankService {
  static Future<List<Bank>> getBanks() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/banks'),
      headers: ApiService.authHeaders,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Bank.fromMap(json)).toList();
    }
    throw Exception('Failed to load banks');
  }

  static Future<List<BankAccount>> getBankAccounts() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/bank-accounts'),
      headers: ApiService.authHeaders,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => BankAccount.fromMap(json)).toList();
    }
    throw Exception('Failed to load bank accounts');
  }

  static Future<BankAccount> addBankAccount(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/bank-accounts'),
      headers: ApiService.authHeaders,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return BankAccount.fromMap(jsonDecode(response.body));
    }
    throw Exception('Failed to add bank account');
  }

  static Future<void> updateBankAccountBalance(
    int accountId,
    double amount,
    String type,
  ) async {
    final response = await http.patch(
      Uri.parse('${ApiService.baseUrl}/bank-accounts/$accountId/balance'),
      headers: ApiService.authHeaders,
      body: jsonEncode({'amount': amount, 'type': type}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update bank account balance');
    }
  }

  static Future<void> addBank(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/banks'),
      headers: ApiService.authHeaders,
      body: jsonEncode(data),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add bank');
    }
  }

  static Future<void> updateBank(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/banks/$id'),
      headers: ApiService.authHeaders,
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update bank');
    }
  }

  static Future<void> deleteBank(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/banks/$id'),
      headers: ApiService.authHeaders,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete bank');
    }
  }
}
