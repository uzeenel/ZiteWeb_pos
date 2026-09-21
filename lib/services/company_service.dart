import 'dart:io';
import 'package:zite_web_pos/models/company.dart';
import 'package:zite_web_pos/models/region.dart';
import 'package:zite_web_pos/services/api_service.dart';

class CompanyService {
  // Get company settings
  Future<Company?> getCompany() async {
    try {
      final response = await ApiService.getCompany();
      if (response.isNotEmpty) {
        return Company.fromMap(response);
      }
      return null;
    } catch (e) {
      print('Error fetching company from API: $e');
      return null;
    }
  }

  // Get all regions/states
  Future<List<Region>> getAllStates() async {
    try {
      final response = await ApiService.getStates();
      return response.map((json) => Region.fromMap(json)).toList();
    } catch (e) {
      print('Error fetching states from API: $e');
      return [];
    }
  }

  // Save or update company settings
    Future<int> saveCompany({
    required String name,
    String? address,
    String? phone,
    String? email,
    String? taxId,
    int? stateId,
    bool? autoCashBook,
    bool? autoBankBook,
    double? defaultMarkupPercent,
    bool? vatEnabled,
    double? vatRate,
    File? logoFile,
  }) async {
    try {
      final companyData = {
        'name': name,
        'address': address,
        'phone': phone,
        'email': email,
        'taxId': taxId,
        'stateId': stateId,
        'autoCashBook': autoCashBook ?? true,
        'autoBankBook': autoBankBook ?? true,
        'defaultMarkupPercent': defaultMarkupPercent ?? 0,
        'vatEnabled': vatEnabled ?? true,
        'vatRate': vatRate ?? 7.5,
      };

      // Upload logo if provided
      if (logoFile != null) {
        await ApiService.uploadCompanyLogo(logoFile);
      }

      final result = await ApiService.saveCompany(companyData);
      return result['id'] as int;
    } catch (e) {
      print('Error saving company via API: $e');
      rethrow;
    }
  }
}
