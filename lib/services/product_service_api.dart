import 'package:zite_web_pos/models/product.dart';
import 'package:zite_web_pos/services/api_service.dart';

class ProductService {
  Future<List<Product>> getAllProducts() async {
    return await ApiService.getProducts();
  }

  Future<Product?> getProductBySku(String sku) async {
    final products = await getAllProducts();
    try {
      return products.firstWhere((p) => p.sku == sku);
    } catch (e) {
      return null;
    }
  }

  Future<void> addProduct({
    required String name,
    required String sku,
    int? categoryId,
    int? unitId,
    String? barcode,
    required double costPrice,
    required double sellingPrice,
    required double stockQuantity,
    required double minStockLevel,
    required bool isVatExempt,
  }) async {
    // TODO: Implement add product API call
    // We'll add this endpoint to the server next
    throw UnimplementedError('Add product API not implemented yet');
  }

  Future<void> updateProduct({
    required int id,
    required String name,
    required String sku,
    int? categoryId,
    int? unitId,
    String? barcode,
    required double costPrice,
    required double sellingPrice,
    required double stockQuantity,
    required double minStockLevel,
    required bool isVatExempt,
  }) async {
    // TODO: Implement update product API call
    throw UnimplementedError('Update product API not implemented yet');
  }

  Future<void> updateStock(int productId, double quantity) async {
    // TODO: Implement update stock API call
    throw UnimplementedError('Update stock API not implemented yet');
  }
}
