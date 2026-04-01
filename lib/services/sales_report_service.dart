import 'package:pos_system/models/sales_report.dart';

class SalesReportService {
  // Helper to safely convert to double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Helper to safely convert to int
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<SalesReportData> getDailySalesReport(
    DateTime date,
    List<Map<String, dynamic>> sales,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final filteredSales = sales.where((sale) {
      final saleDate = DateTime.parse(sale['sale_date']);
      return saleDate.isAfter(startOfDay) && saleDate.isBefore(endOfDay);
    }).toList();

    print('Filtered sales count: ${filteredSales.length}');

    // Calculate summary
    int totalTransactions = filteredSales.length;
    double totalSales = 0;
    double totalTax = 0;
    Map<String, double> paymentMethodBreakdown = {};

    for (var sale in filteredSales) {
      totalSales += _toDouble(sale['total']);
      totalTax += _toDouble(sale['tax']);

      final method = sale['payment_method'] ?? 'Cash';
      paymentMethodBreakdown[method] =
          (paymentMethodBreakdown[method] ?? 0) + _toDouble(sale['total']);
    }

    final summary = DailySalesSummary(
      date: date,
      totalTransactions: totalTransactions,
      totalSales: totalSales,
      totalTax: totalTax,
      totalDiscount: 0,
      netSales: totalSales - totalTax,
      paymentMethodBreakdown: paymentMethodBreakdown,
    );

    // Calculate category breakdown
    Map<String, CategorySalesReport> categoryMap = {};
    Map<String, ProductSalesReport> productMap = {};

    for (var sale in filteredSales) {
      // Get items safely - handle different possible types
      dynamic itemsData = sale['items'];
      List<Map<String, dynamic>> items = [];

      if (itemsData != null && itemsData is List) {
        for (var item in itemsData) {
          if (item is Map) {
            items.add(Map<String, dynamic>.from(item));
          }
        }
      }

      print('Sale ${sale['invoice_number']} has ${items.length} items');

      for (var item in items) {
        final category = item['category_name']?.toString() ?? 'Uncategorized';
        final quantity = _toInt(item['quantity']);
        final total = _toDouble(item['total']);

        // Update category map
        final existingCategory = categoryMap[category];
        if (existingCategory != null) {
          categoryMap[category] = CategorySalesReport(
            category: category,
            quantitySold: existingCategory.quantitySold + quantity,
            totalRevenue: existingCategory.totalRevenue + total,
            percentageOfTotal: 0,
          );
        } else {
          categoryMap[category] = CategorySalesReport(
            category: category,
            quantitySold: quantity,
            totalRevenue: total,
            percentageOfTotal: 0,
          );
        }

        // Update product map
        final productKey = (item['product_id'] ?? 0).toString();
        final existingProduct = productMap[productKey];
        if (existingProduct != null) {
          productMap[productKey] = ProductSalesReport(
            productName: item['product_name']?.toString() ?? 'Unknown',
            sku: item['sku']?.toString() ?? '',
            category: category,
            quantitySold: existingProduct.quantitySold + quantity,
            totalRevenue: existingProduct.totalRevenue + total,
            unitPrice: _toDouble(item['unit_price']),
          );
        } else {
          productMap[productKey] = ProductSalesReport(
            productName: item['product_name']?.toString() ?? 'Unknown',
            sku: item['sku']?.toString() ?? '',
            category: category,
            quantitySold: quantity,
            totalRevenue: total,
            unitPrice: _toDouble(item['unit_price']),
          );
        }
      }
    }

    // Calculate percentages for categories
    List<CategorySalesReport> categoryReports = [];
    for (var category in categoryMap.values) {
      categoryReports.add(
        CategorySalesReport(
          category: category.category,
          quantitySold: category.quantitySold,
          totalRevenue: category.totalRevenue,
          percentageOfTotal: totalSales > 0
              ? (category.totalRevenue / totalSales) * 100
              : 0,
        ),
      );
    }
    categoryReports.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

    // Get top products (by revenue)
    List<ProductSalesReport> allProducts = productMap.values.toList();
    allProducts.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
    List<ProductSalesReport> topProducts = allProducts.length > 10
        ? allProducts.sublist(0, 10)
        : allProducts;

    return SalesReportData(
      summary: summary,
      categoryReports: categoryReports,
      topProducts: topProducts,
      allProducts: allProducts,
    );
  }
}
