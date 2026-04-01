import 'package:pos_system/models/product.dart';
import 'package:pos_system/services/api_service.dart';

class ProductService {
  // Get all active products
  Future<List<Product>> getAllProducts() async {
    try {
      final products = await ApiService.getProducts();
      return products;
    } catch (e) {
      print('Error fetching products from API: $e');
      return [];
    }
  }

  // Get product by ID
  Future<Product?> getProductById(int id) async {
    try {
      final product = await ApiService.getProduct(id);
      return product;
    } catch (e) {
      print('Error fetching product by ID from API: $e');
      return null;
    }
  }

  // Get product by SKU
  Future<Product?> getProductBySku(String sku) async {
    try {
      final products = await ApiService.getProducts();
      return products.firstWhere(
        (p) => p.sku == sku,
        orElse: () => throw Exception('Product not found'),
      );
    } catch (e) {
      print('Error fetching product by SKU from API: $e');
      return null;
    }
  }

  // Add new product
  Future<int> addProduct({
    required String name,
    required String sku,
    int? categoryId,
    int? unitId,
    String? barcode,
    required double costPrice,
    required double sellingPrice,
    double stockQuantity = 0,
    double minStockLevel = 0,
    bool? isVatExempt,
  }) async {
    try {
      final productData = {
        'name': name,
        'sku': sku,
        'categoryId': categoryId,
        'unitId': unitId,
        'barcode': barcode,
        'costPrice': costPrice,
        'sellingPrice': sellingPrice,
        'stockQuantity': stockQuantity,
        'minStockLevel': minStockLevel,
        'isVatExempt': isVatExempt ?? false,
      };

      final result = await ApiService.addProduct(productData);
      return result['id'] as int;
    } catch (e) {
      print('Error adding product via API: $e');
      rethrow;
    }
  }

  // Update existing product
  Future<int> updateProduct({
    required int id,
    required String name,
    required String sku,
    int? categoryId,
    int? unitId,
    String? barcode,
    required double costPrice,
    required double sellingPrice,
    double? stockQuantity,
    double? minStockLevel,
    bool? isVatExempt,
  }) async {
    try {
      final productData = {
        'name': name,
        'sku': sku,
        'categoryId': categoryId,
        'unitId': unitId,
        'barcode': barcode,
        'costPrice': costPrice,
        'sellingPrice': sellingPrice,
        'isVatExempt': isVatExempt ?? false,
      };

      if (stockQuantity != null) {
        productData['stockQuantity'] = stockQuantity;
      }
      if (minStockLevel != null) {
        productData['minStockLevel'] = minStockLevel;
      }

      // Note: We're not sending isActive - the API will preserve the current value
      await ApiService.updateProduct(id, productData);
      return 1;
    } catch (e) {
      print('Error updating product via API: $e');
      return 0;
    }
  }

  // Update stock quantity (add or remove)
  Future<int> updateStock(int productId, double quantityToAdd) async {
    try {
      await ApiService.updateStock(productId, quantityToAdd);
      return 1; // Return 1 to indicate success
    } catch (e) {
      print('Error updating stock via API: $e');
      return 0;
    }
  }

  // Delete product (soft delete)
  Future<int> deleteProduct(int productId) async {
    try {
      await ApiService.deleteProduct(productId);
      return 1;
    } catch (e) {
      print('Error deleting product via API: $e');
      return 0;
    }
  }
}
