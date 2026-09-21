import 'package:zite_web_pos/models/dashboard_data.dart';
import 'package:zite_web_pos/services/api_service.dart';

class DashboardService {
  Future<DashboardData> getDashboardData() async {
    try {
      print('📊 Fetching dashboard data...');
      final data = await ApiService.getDashboard();
      print('📊 Dashboard data received: $data');

      return DashboardData(
        totalSalesToday: _toDouble(data['totalSalesToday']),
        totalSalesThisWeek: _toDouble(data['totalSalesThisWeek']),
        totalSalesThisMonth: _toDouble(data['totalSalesThisMonth']),
        totalTransactionsToday: _toInt(data['totalTransactionsToday']),
        averageTicketToday: _toDouble(data['averageTicketToday']),
        lowStockCount: _toInt(data['lowStockCount']),
        outOfStockCount: _toInt(data['outOfStockCount']),
        totalCustomers: _toInt(data['totalCustomers']),
        salesByCategory: _parseSalesByCategory(data['salesByCategory']),
        last7DaysSales: _parseLast7DaysSales(data['last7DaysSales']),
        topProducts: _parseTopProducts(data['topProducts']),
      );
    } catch (e) {
      print('❌ Error fetching dashboard: $e');
      return _emptyDashboardData();
    }
  }

  Map<String, double> _parseSalesByCategory(List? categories) {
    if (categories == null) return {};

    final Map<String, double> result = {};
    for (var item in categories) {
      final category = item['category_name'] ?? 'Uncategorized';
      final revenue = _toDouble(item['revenue']);
      result[category] = revenue;
    }
    return result;
  }

  List<DailySales> _parseLast7DaysSales(List? days) {
    if (days == null) return [];

    final parsed = days.map((item) {
      // Parse the ISO date string
      DateTime date;
      try {
        date = DateTime.parse(item['date']);
      } catch (e) {
        date = DateTime.now();
      }

      return DailySales(
        date: date,
        total: _toDouble(item['total']),
        transactions: _toInt(item['transactions']),
      );
    }).toList();

    return parsed;
  }

  List<TopProduct> _parseTopProducts(List? products) {
    if (products == null) return [];

    return products
        .map(
          (item) => TopProduct(
            productName: item['name'] ?? '',
            quantitySold: _toInt(item['quantity_sold']),
            revenue: _toDouble(item['revenue']),
            sku: item['sku'] ?? '',
          ),
        )
        .toList();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  DashboardData _emptyDashboardData() {
    return DashboardData(
      totalSalesToday: 0,
      totalSalesThisWeek: 0,
      totalSalesThisMonth: 0,
      totalTransactionsToday: 0,
      averageTicketToday: 0,
      lowStockCount: 0,
      outOfStockCount: 0,
      totalCustomers: 0,
      salesByCategory: {},
      last7DaysSales: [],
      topProducts: [],
    );
  }
}
