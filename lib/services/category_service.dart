import 'package:zite_web_pos/models/category.dart';
import 'package:zite_web_pos/services/api_service.dart';

class CategoryService {
  /// Get all active categories
  Future<List<Category>> getAllCategories() async {
    try {
      final categories = await ApiService.getCategories();
      return categories;
    } catch (e) {
      print('Error fetching categories from API: $e');
      return [];
    }
  }

  /// Get a single category by ID
  Future<Category?> getCategoryById(int id) async {
    try {
      final categories = await ApiService.getCategories();
      return categories.firstWhere(
        (c) => c.id == id,
        orElse: () => throw Exception('Category not found'),
      );
    } catch (e) {
      print('Error fetching category by ID from API: $e');
      return null;
    }
  }

  /// Add a new category
    /// Add a new category
  Future<int> addCategory({
    required String name,
    String? description,
    bool isVatExempt = false,
    double? markupPercent,
  }) async {
    try {
      final categoryData = {
        'name': name,
        'description': description,
        'isVatExempt': isVatExempt,
        'markupPercent': markupPercent,
      };

      final result = await ApiService.addCategory(categoryData);
      return result['id'] as int;
    } catch (e) {
      print('Error adding category via API: $e');
      rethrow;
    }
  }

  /// Update an existing category
  Future<int> updateCategory({
    required int id,
    required String name,
    String? description,
    bool? isVatExempt,
    double? markupPercent,
  }) async {
    try {
      final Map<String, dynamic> categoryData = {'name': name};

      if (description != null) {
        categoryData['description'] = description;
      }

      if (isVatExempt != null) {
        categoryData['isVatExempt'] = isVatExempt;
      }

      categoryData['markupPercent'] = markupPercent;

      await ApiService.updateCategory(id, categoryData);
      return 1;
    } catch (e) {
      print('Error updating category via API: $e');
      return 0;
    }
  }

  /// Delete a category
  Future<int> deleteCategory(int id) async {
    try {
      await ApiService.deleteCategory(id);
      return 1;
    } catch (e) {
      print('Error deleting category via API: $e');
      return 0;
    }
  }

  /// Check if a category is VAT exempt
  Future<bool> isCategoryVatExempt(int categoryId) async {
    try {
      final categories = await ApiService.getCategories();
      final category = categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => throw Exception('Category not found'),
      );
      return category.isVatExempt;
    } catch (e) {
      print('Error checking category VAT exempt from API: $e');
      return false;
    }
  }
}
