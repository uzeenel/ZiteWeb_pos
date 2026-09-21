import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:zite_web_pos/models/product.dart';
import 'package:zite_web_pos/services/api_service.dart';
import 'package:cross_file/cross_file.dart';

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

  // In product_service.dart
  Future<Product?> getProductBySku(String code) async {
    try {
      print('🔍 [START] Searching for product with code: "$code"');
      print('🔍 Code length: ${code.length}');
      print('🔍 Code trimmed: "${code.trim()}"');

      final products = await getAllProducts();
      print('📦 Total products loaded: ${products.length}');

      // Print all barcodes for debugging
      for (var p in products) {
        print(
          '   Product: ${p.name}, SKU: ${p.sku}, Barcode: ${p.barcode ?? "NULL"}',
        );
      }

      // Try barcode first
      for (var product in products) {
        if (product.barcode != null) {
          print(
            '   Comparing barcode: "${product.barcode}" with code: "$code"',
          );
          if (product.barcode!.toLowerCase() == code.toLowerCase()) {
            print('✅ Found by barcode: ${product.name}');
            return product;
          }
        }
      }

      // Try SKU next
      for (var product in products) {
        print('   Comparing SKU: "${product.sku}" with code: "$code"');
        if (product.sku.toLowerCase() == code.toLowerCase()) {
          print('✅ Found by SKU: ${product.name}');
          return product;
        }
      }

      print('❌ No product found for code: "$code"');
      return null;
    } catch (e) {
      print('❌ Error searching for product: $e');
      return null;
    }
  }

  // Add new product
   Future<void> addProduct({
    required String name,
    required String sku,
    int? categoryId,
    int? unitId,
    String? barcode,
    required double costPrice,
    required double sellingPrice,
    double stockQuantity = 0,
    double minStockLevel = 0,
    bool isVatExempt = false,
    String? imageUrl,
    double? markupPercent,
    bool markupIsManual = false,
  }) async {
    try {
      final productData = {
        'name': name,
        'sku': sku,
        'category_id': categoryId,
        'unit_id': unitId,
        'barcode': barcode,
        'cost_price': costPrice,
        'selling_price': sellingPrice,
        'stock_quantity': stockQuantity,
        'min_stock_level': minStockLevel,
        'is_vat_exempt': isVatExempt ? 1 : 0,
        'image_url': imageUrl,
        'markup_percent': markupPercent,
        'markup_is_manual': markupIsManual ? 1 : 0,
      };

      await ApiService.addProduct(productData);
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    }
  }


  // Update existing product
    Future<void> updateProduct({
    required int id,
    required String name,
    required String sku,
    int? categoryId,
    int? unitId,
    String? barcode,
    required double costPrice,
    required double sellingPrice,
    double stockQuantity = 0,
    double minStockLevel = 0,
    bool isVatExempt = false,
    String? imageUrl,
    double? markupPercent,
    bool markupIsManual = false,
  }) async {
    try {
      final productData = {
        'name': name,
        'sku': sku,
        'category_id': categoryId,
        'unit_id': unitId,
        'barcode': barcode,
        'cost_price': costPrice,
        'selling_price': sellingPrice,
        'stock_quantity': stockQuantity,
        'min_stock_level': minStockLevel,
        'is_vat_exempt': isVatExempt ? 1 : 0,
        'image_url': imageUrl,
        'markup_percent': markupPercent,
        'markup_is_manual': markupIsManual ? 1 : 0,
      };

      await ApiService.updateProduct(id, productData);
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
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

  Future<void> setStock(int productId, double quantity) async {
    try {
      await ApiService.setStock(productId, quantity);
    } catch (e) {
      print('Error setting stock: $e');
      rethrow;
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

  Future<String?> uploadProductImage(dynamic imageFile) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/products/upload-image');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer ${ApiService.token}';

      if (kIsWeb) {
        // Web: XFile - read as bytes
        final bytes = await (imageFile as XFile).readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: 'product_image.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(await multipartFile);
      } else {
        // Windows: XFile - convert to File and use path
        final file = File((imageFile as XFile).path);
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            file.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final result = jsonDecode(responseData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return result['image_url'];
      }
      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}
