import 'package:flutter/material.dart';
import 'package:zite_web_pos/models/stock_report.dart';
import 'package:zite_web_pos/services/stock_report_service.dart';
import 'package:intl/intl.dart';
import 'package:zite_web_pos/services/export_service.dart';

class StockReportScreen extends StatefulWidget {
  const StockReportScreen({super.key});

  @override
  State<StockReportScreen> createState() => _StockReportScreenState();
}

class _StockReportScreenState extends State<StockReportScreen> {
  final StockReportService _service = StockReportService();
  final ExportService _exportService = ExportService();
  List<StockReport> _reports = [];
  StockSummary? _summary;
  bool _isLoading = true;
  bool _isExporting = false;
  String _filter = 'all';
  String _searchQuery = '';
  String _sortBy = 'stock';

  final _formatter = NumberFormat("#,##0.00");

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final reports = await _service.getStockReport();
    final summary = await _service.getStockSummary();
    setState(() {
      _reports = reports;
      _summary = summary;
      _isLoading = false;
    });
  }

  List<StockReport> get _filteredReports {
    var filtered = _reports;

    if (_filter == 'low') {
      filtered = filtered
          .where((r) => r.isLowStock && r.stockQuantity > 0)
          .toList();
    } else if (_filter == 'out') {
      filtered = filtered.where((r) => r.stockQuantity <= 0).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (r) =>
                r.productName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                r.sku.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                r.category.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.productName.compareTo(b.productName));
        break;
      case 'category':
        filtered.sort((a, b) => a.category.compareTo(b.category));
        break;
      case 'value':
        filtered.sort((a, b) => b.inventoryValue.compareTo(a.inventoryValue));
        break;
      default:
        filtered.sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));
        break;
    }
    return filtered;
  }

  Future<void> _exportToExcel() async {
    if (_reports.isEmpty || _summary == null) return;
    setState(() => _isExporting = true);
    try {
      await _exportService.exportStockToExcelWeb(_reports, _summary!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Excel file downloaded'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportToPdf() async {
    if (_reports.isEmpty || _summary == null) return;
    setState(() => _isExporting = true);
    try {
      await _exportService.exportStockToPdfWeb(_reports, _summary!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF file downloaded'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Report', style: TextStyle(fontSize: 18)),
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
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _buildSummaryCard(
                        'Total Products',
                        '${_summary?.totalProducts ?? 0}',
                        Colors.blue,
                        Icons.inventory,
                      ),
                      const SizedBox(width: 8),
                      _buildSummaryCard(
                        'Low Stock',
                        '${_summary?.lowStockCount ?? 0}',
                        Colors.orange,
                        Icons.warning_amber,
                      ),
                      const SizedBox(width: 8),
                      _buildSummaryCard(
                        'Out of Stock',
                        '${_summary?.outOfStockCount ?? 0}',
                        Colors.red,
                        Icons.error,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Inventory Value',
                          '₦${_formatter.format(_summary?.totalInventoryValue ?? 0)}',
                          Colors.green,
                          Icons.account_balance_wallet,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoCard(
                          'Potential Revenue',
                          '₦${_formatter.format(_summary?.totalPotentialRevenue ?? 0)}',
                          Colors.purple,
                          Icons.trending_up,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search products...',
                            prefixIcon: Icon(Icons.search, size: 20),
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _filter,
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('All Products'),
                          ),
                          DropdownMenuItem(
                            value: 'low',
                            child: Text('Low Stock'),
                          ),
                          DropdownMenuItem(
                            value: 'out',
                            child: Text('Out of Stock'),
                          ),
                        ],
                        onChanged: (value) => setState(() => _filter = value!),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _sortBy,
                        items: const [
                          DropdownMenuItem(
                            value: 'stock',
                            child: Text('Sort by Stock'),
                          ),
                          DropdownMenuItem(
                            value: 'name',
                            child: Text('Sort by Name'),
                          ),
                          DropdownMenuItem(
                            value: 'category',
                            child: Text('Sort by Category'),
                          ),
                          DropdownMenuItem(
                            value: 'value',
                            child: Text('Sort by Value'),
                          ),
                        ],
                        onChanged: (value) => setState(() => _sortBy = value!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _filteredReports.isEmpty
                      ? const Center(child: Text('No products found'))
                      : ListView.builder(
                          itemCount: _filteredReports.length,
                          itemBuilder: (context, index) {
                            final report = _filteredReports[index];
                            return _buildProductCard(report);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(StockReport report) {
    final isOutOfStock = report.stockQuantity <= 0;
    final isLowStock = report.isLowStock && !isOutOfStock;

    Color statusColor = isOutOfStock
        ? Colors.red
        : (isLowStock ? Colors.orange : Colors.green);
    IconData statusIcon = isOutOfStock
        ? Icons.error
        : (isLowStock ? Icons.warning : Icons.check_circle);
    Color iconBgColor = statusColor.withValues(alpha: 0.1);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          report.productName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('SKU: ${report.sku} | Category: ${report.category}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Stock: ${report.stockQuantity.toStringAsFixed(0)}',
              style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
            ),
            Text(
              'Value: ₦${_formatter.format(report.inventoryValue)}',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        onTap: () => _showProductDetails(report),
      ),
    );
  }

  void _showProductDetails(StockReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report.productName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('SKU:', report.sku),
            _buildDetailRow('Category:', report.category),
            _buildDetailRow(
              'Current Stock:',
              report.stockQuantity.toStringAsFixed(0),
            ),
            _buildDetailRow(
              'Unit Cost:',
              '₦${_formatter.format(report.unitCost)}',
            ),
            _buildDetailRow(
              'Selling Price:',
              '₦${_formatter.format(report.sellingPrice)}',
            ),
            const Divider(),
            _buildDetailRow(
              'Inventory Value:',
              '₦${_formatter.format(report.inventoryValue)}',
            ),
            _buildDetailRow(
              'Potential Revenue:',
              '₦${_formatter.format(report.potentialRevenue)}',
            ),
            if (report.isLowStock && report.stockQuantity > 0)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                color: Colors.orange.withValues(alpha: 0.1),
                child: const Text(
                  '⚠️ Low Stock Alert - Consider reordering',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
            if (report.stockQuantity <= 0)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                color: Colors.red.withValues(alpha: 0.1),
                child: const Text(
                  '❌ Out of Stock - Immediate reorder required',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
