class DailySalesSummary {
  final DateTime date;
  final int totalTransactions;
  final double totalSales;
  final double totalTax;
  final double totalDiscount;
  final double netSales;
  final Map<String, double> paymentMethodBreakdown;

  DailySalesSummary({
    required this.date,
    required this.totalTransactions,
    required this.totalSales,
    required this.totalTax,
    required this.totalDiscount,
    required this.netSales,
    required this.paymentMethodBreakdown,
  });

  double get averageTicket =>
      totalTransactions > 0 ? totalSales / totalTransactions : 0;
}

class CategorySalesReport {
  final String category;
  final int quantitySold;
  final double totalRevenue;
  final double percentageOfTotal;

  CategorySalesReport({
    required this.category,
    required this.quantitySold,
    required this.totalRevenue,
    required this.percentageOfTotal,
  });
}

class ProductSalesReport {
  final String productName;
  final String sku;
  final String category;
  final int quantitySold;
  final double totalRevenue;
  final double unitPrice;

  ProductSalesReport({
    required this.productName,
    required this.sku,
    required this.category,
    required this.quantitySold,
    required this.totalRevenue,
    required this.unitPrice,
  });
}

class SalesReportData {
  final DailySalesSummary summary;
  final List<CategorySalesReport> categoryReports;
  final List<ProductSalesReport> topProducts;
  final List<ProductSalesReport> allProducts;

  SalesReportData({
    required this.summary,
    required this.categoryReports,
    required this.topProducts,
    required this.allProducts,
  });
}
