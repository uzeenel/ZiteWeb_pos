import 'package:zite_web_pos/models/product.dart';

class StockReport {
  final String productName;
  final String sku;
  final String category;
  final double stockQuantity;
  final double unitCost;
  final double sellingPrice;
  final double inventoryValue;
  final double potentialRevenue;
  final bool isLowStock;
  final int lowStockThreshold;

  StockReport({
    required this.productName,
    required this.sku,
    required this.category,
    required this.stockQuantity,
    required this.unitCost,
    required this.sellingPrice,
    required this.inventoryValue,
    required this.potentialRevenue,
    required this.isLowStock,
    this.lowStockThreshold = 10,
  });

  factory StockReport.fromProduct(
    Product product, {
    int lowStockThreshold = 10,
  }) {
    final inventoryValue = product.stockQuantity * product.costPrice;
    final potentialRevenue = product.stockQuantity * product.sellingPrice;

    return StockReport(
      productName: product.name,
      sku: product.sku,
      category: product.categoryName ?? 'Uncategorized',
      stockQuantity: product.stockQuantity,
      unitCost: product.costPrice,
      sellingPrice: product.sellingPrice,
      inventoryValue: inventoryValue,
      potentialRevenue: potentialRevenue,
      isLowStock: product.stockQuantity < lowStockThreshold,
    );
  }
}

class StockSummary {
  final int totalProducts;
  final int lowStockCount;
  final int outOfStockCount;
  final double totalInventoryValue;
  final double totalPotentialRevenue;
  final Map<String, int> categoryCounts;
  final Map<String, double> categoryValues;

  StockSummary({
    required this.totalProducts,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.totalInventoryValue,
    required this.totalPotentialRevenue,
    required this.categoryCounts,
    required this.categoryValues,
  });
}
