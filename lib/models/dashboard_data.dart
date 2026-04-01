class DashboardData {
  final double totalSalesToday;
  final double totalSalesThisWeek;
  final double totalSalesThisMonth;
  final int totalTransactionsToday;
  final double averageTicketToday;
  final int lowStockCount;
  final int outOfStockCount;
  final Map<String, double> salesByCategory;
  final List<DailySales> last7DaysSales;
  final List<TopProduct> topProducts;

  DashboardData({
    required this.totalSalesToday,
    required this.totalSalesThisWeek,
    required this.totalSalesThisMonth,
    required this.totalTransactionsToday,
    required this.averageTicketToday,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.salesByCategory,
    required this.last7DaysSales,
    required this.topProducts,
  });
}

class DailySales {
  final DateTime date;
  final double total;
  final int transactions;

  DailySales({
    required this.date,
    required this.total,
    required this.transactions,
  });
}

class TopProduct {
  final String productName;
  final int quantitySold;
  final double revenue;
  final String sku;

  TopProduct({
    required this.productName,
    required this.quantitySold,
    required this.revenue,
    required this.sku,
  });
}
