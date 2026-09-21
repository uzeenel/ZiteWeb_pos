import 'package:zite_web_pos/models/stock_report.dart';
import 'package:zite_web_pos/services/product_service.dart';

class StockReportService {
  final ProductService _productService = ProductService();

  Future<List<StockReport>> getStockReport({int lowStockThreshold = 10}) async {
    final products = await _productService.getAllProducts();

    return products
        .map(
          (product) => StockReport.fromProduct(
            product,
            lowStockThreshold: lowStockThreshold,
          ),
        )
        .toList()
      ..sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));
  }

  Future<StockSummary> getStockSummary({int lowStockThreshold = 10}) async {
    final products = await _productService.getAllProducts();

    int lowStockCount = 0;
    int outOfStockCount = 0;
    double totalInventoryValue = 0;
    double totalPotentialRevenue = 0;
    Map<String, int> categoryCounts = {};
    Map<String, double> categoryValues = {};

    for (var product in products) {
      if (product.stockQuantity <= 0) {
        outOfStockCount++;
      } else if (product.stockQuantity < lowStockThreshold) {
        lowStockCount++;
      }

      final inventoryValue = product.stockQuantity * product.costPrice;
      final potentialRevenue = product.stockQuantity * product.sellingPrice;

      totalInventoryValue += inventoryValue;
      totalPotentialRevenue += potentialRevenue;

      final category = product.categoryName ?? 'Uncategorized';
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      categoryValues[category] =
          (categoryValues[category] ?? 0) + inventoryValue;
    }

    return StockSummary(
      totalProducts: products.length,
      lowStockCount: lowStockCount,
      outOfStockCount: outOfStockCount,
      totalInventoryValue: totalInventoryValue,
      totalPotentialRevenue: totalPotentialRevenue,
      categoryCounts: categoryCounts,
      categoryValues: categoryValues,
    );
  }

  Future<List<StockReport>> getLowStockProducts({int threshold = 10}) async {
    final reports = await getStockReport(lowStockThreshold: threshold);
    return reports.where((r) => r.isLowStock).toList();
  }

  Future<List<StockReport>> getOutOfStockProducts() async {
    final reports = await getStockReport();
    return reports.where((r) => r.stockQuantity <= 0).toList();
  }
}
