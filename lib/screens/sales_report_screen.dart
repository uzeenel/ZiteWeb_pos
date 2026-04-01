import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/models/sales_report.dart';
import 'package:pos_system/services/sales_report_service.dart';
import 'package:pos_system/services/export_service.dart' as expService;
import 'package:pos_system/screens/unauthorized_screen.dart';
import 'package:pos_system/utils/permissions.dart';
import 'package:pos_system/services/sale_service.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  final SalesReportService _service = SalesReportService();
  final SaleService _saleService = SaleService();
  final expService.ExportService _exportService = expService.ExportService();

  DateTime _selectedDate = DateTime.now();
  SalesReportData? _reportData;
  bool _isLoading = true;
  bool _isExporting = false;
  String _productView = 'top'; // top, all

  final _currencyFormat = NumberFormat("#,##0.00");
  final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final startOfDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      print('=== SALES REPORT DEBUG ===');
      print('Selected date: $_selectedDate');
      print('Start: $startOfDay');
      print('End: $endOfDay');

      final sales = await _saleService.getSalesByDateRange(
        startOfDay,
        endOfDay,
      );

      print('Sales returned: ${sales.length}');
      if (sales.isNotEmpty) {
        print('First sale date: ${sales.first['sale_date']}');
        print('First sale total: ${sales.first['total']}');
      } else {
        print('No sales found for this date range');
      }

      final data = await _service.getDailySalesReport(_selectedDate, sales);

      print('Report data summary: ${data?.summary.totalSales}');
      print('Report has ${data?.categoryReports.length} categories');

      setState(() {
        _reportData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading report: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportToExcel() async {
    if (_reportData == null) return;
    setState(() => _isExporting = true);
    try {
      final file = await _exportService.exportSalesReportToExcel(
        _reportData!,
        _selectedDate,
      );
      if (file != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File saved: ${file.path.split('/').last}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Save cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportToPdf() async {
    if (_reportData == null) return;
    setState(() => _isExporting = true);
    try {
      final file = await _exportService.exportSalesReportToPdf(
        _reportData!,
        _selectedDate,
      );
      if (file != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File saved: ${file.path.split('/').last}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Save cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check permissions - Only Admin and Manager can view sales reports
    if (!Permissions.canViewReports) {
      return const UnauthorizedScreen();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Report', style: TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF1e3a8a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart),
            onPressed: _isExporting ? null : _exportToExcel,
            tooltip: 'Export to Excel',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _isExporting ? null : _exportToPdf,
            tooltip: 'Export to PDF',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                _loadData();
              });
            },
            tooltip: 'Previous Day',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                  _loadData();
                });
              }
            },
            tooltip: 'Select Date',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final nextDay = _selectedDate.add(const Duration(days: 1));
              if (nextDay.isBefore(
                DateTime.now().add(const Duration(days: 1)),
              )) {
                setState(() {
                  _selectedDate = nextDay;
                  _loadData();
                });
              }
            },
            tooltip: 'Next Day',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _reportData == null
              ? const Center(child: Text('No data available'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          _dateFormat.format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Total Sales',
                              '₦${_currencyFormat.format(_reportData!.summary.totalSales)}',
                              Colors.green,
                              Icons.attach_money,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Transactions',
                              _reportData!.summary.totalTransactions.toString(),
                              Colors.blue,
                              Icons.receipt,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Average Ticket',
                              '₦${_currencyFormat.format(_reportData!.summary.averageTicket)}',
                              Colors.purple,
                              Icons.trending_up,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'VAT Collected',
                              '₦${_currencyFormat.format(_reportData!.summary.totalTax)}',
                              Colors.orange,
                              Icons.calculate,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Payment Methods',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: _reportData!
                              .summary
                              .paymentMethodBreakdown
                              .entries
                              .map((entry) {
                                final percentage =
                                    (_reportData!.summary.totalSales > 0)
                                    ? (entry.value /
                                              _reportData!.summary.totalSales) *
                                          100
                                    : 0;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 80,
                                        child: Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: LinearProgressIndicator(
                                          value: percentage / 100,
                                          backgroundColor: Colors.grey.shade200,
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(Colors.green),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '₦${_currencyFormat.format(entry.value)} (${percentage.toStringAsFixed(1)}%)',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Sales by Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _reportData!.categoryReports.length,
                        itemBuilder: (context, index) {
                          final category = _reportData!.categoryReports[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(category.category),
                              subtitle: Text(
                                '${category.quantitySold} units sold',
                              ),
                              trailing: Text(
                                '₦${_currencyFormat.format(category.totalRevenue)} (${category.percentageOfTotal.toStringAsFixed(1)}%)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      // Product Sales Section
                      Row(
                        children: [
                          const Text(
                            'Sales by Product',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                _buildViewToggle('Top 10', 'top'),
                                _buildViewToggle('All Products', 'all'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Summary row for products
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Products Sold: ${_reportData!.allProducts.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Total Units: ${_reportData!.allProducts.fold<int>(0, (sum, p) => sum + p.quantitySold)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Product list header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            SizedBox(
                              width: 40,
                              child: Text(
                                '#',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Product',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(
                              width: 50,
                              child: Text(
                                'Qty',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            SizedBox(
                              width: 90,
                              child: Text(
                                'Unit Price',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: Text(
                                'Total',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: Text(
                                '%',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Product list
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _productView == 'top'
                            ? _reportData!.topProducts.length
                            : _reportData!.allProducts.length,
                        itemBuilder: (context, index) {
                          final product = _productView == 'top'
                              ? _reportData!.topProducts[index]
                              : _reportData!.allProducts[index];
                          final percentage =
                              (product.totalRevenue /
                                  _reportData!.summary.totalSales) *
                              100;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.productName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'SKU: ${product.sku} | Category: ${product.category}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      '${product.quantitySold}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 90,
                                    child: Text(
                                      '₦${_currencyFormat.format(product.unitPrice)}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      '₦${_currencyFormat.format(product.totalRevenue)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      '${percentage.toStringAsFixed(1)}%',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: percentage > 20
                                            ? Colors.green
                                            : Colors.grey.shade700,
                                        fontWeight: percentage > 20
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
          if (_isExporting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Generating file...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(String label, String value) {
    final isSelected = _productView == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _productView = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade700 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
