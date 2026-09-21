import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zite_web_pos/models/stock_movement.dart';
import 'package:zite_web_pos/services/stock_movement_service.dart';
import 'package:zite_web_pos/services/product_service.dart';
import 'package:zite_web_pos/services/export_service.dart';
import 'package:zite_web_pos/models/product.dart';
import 'package:zite_web_pos/screens/unauthorized_screen.dart';
import 'package:zite_web_pos/utils/permissions.dart';

class StockMovementScreen extends StatefulWidget {
  const StockMovementScreen({super.key});

  @override
  State<StockMovementScreen> createState() => _StockMovementScreenState();
}

class _StockMovementScreenState extends State<StockMovementScreen> {
  final StockMovementService _movementService = StockMovementService();
  final ProductService _productService = ProductService();
  final ExportService _exportService = ExportService();

  List<StockMovement> _movements = [];
  List<Product> _products = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int? _selectedProductId;
  String? _selectedMovementType; // 'IN', 'OUT', or null for all
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  final _currencyFormat = NumberFormat("#,##0.00");
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    print('=== LOADING STOCK MOVEMENTS ===');

    final movements = await _movementService.getMovementsByDateRange(
      _dateRange.start,
      _dateRange.end,
    );

    print('Movements found: ${movements.length}');
    for (var m in movements) {
      print('  - ${m.productName}: ${m.movementType} ${m.quantity}');
    }

    final products = await _productService.getAllProducts();
    setState(() {
      _movements = movements;
      _products = products;
      _isLoading = false;
    });
  }

  List<StockMovement> get _filteredMovements {
    var filtered = _movements;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (m) =>
                m.productName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                m.sku.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                m.reference.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (m.invoiceNumber?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    }

    // Filter by product
    if (_selectedProductId != null) {
      filtered = filtered
          .where((m) => m.productId == _selectedProductId)
          .toList();
    }

    // Filter by movement type
    if (_selectedMovementType != null) {
      filtered = filtered
          .where((m) => m.movementType == _selectedMovementType)
          .toList();
    }

    return filtered;
  }

  double get _totalStockIn {
    return _filteredMovements
        .where((m) => m.movementType == 'IN')
        .fold(0.0, (sum, m) => sum + m.quantity);
  }

  double get _totalStockOut {
    return _filteredMovements
        .where((m) => m.movementType == 'OUT')
        .fold(0.0, (sum, m) => sum + m.quantity);
  }

  void _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      _loadData();
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Filter Movements'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product filter
                    DropdownButtonFormField<int?>(
                      decoration: const InputDecoration(
                        labelText: 'Product',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _selectedProductId,
                      hint: const Text('All Products'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All Products'),
                        ),
                        ..._products.map((p) {
                          return DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              '${p.name} (${p.sku})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setStateDialog(() {
                          _selectedProductId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Movement type filter
                    DropdownButtonFormField<String?>(
                      decoration: const InputDecoration(
                        labelText: 'Movement Type',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _selectedMovementType,
                      hint: const Text('All Types'),
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Types'),
                        ),
                        DropdownMenuItem(
                          value: 'IN',
                          child: Text('Stock In (Receipts)'),
                        ),
                        DropdownMenuItem(
                          value: 'OUT',
                          child: Text('Stock Out (Sales)'),
                        ),
                      ],
                      onChanged: (value) {
                        setStateDialog(() {
                          _selectedMovementType = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setStateDialog(() {
                      _selectedProductId = null;
                      _selectedMovementType = null;
                    });
                  },
                  child: const Text('Clear'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedProductId = _selectedProductId;
                      _selectedMovementType = _selectedMovementType;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

    // Export to Excel
  Future<void> _exportToExcel() async {
    if (_filteredMovements.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _exportService.exportStockMovementsToExcel(
        _filteredMovements,
        _dateRange.start,
        _dateRange.end,
      );

      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Excel file downloaded')));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // Export to PDF
  Future<void> _exportToPDF() async {
    if (_filteredMovements.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _exportService.exportStockMovementsToPDF(
        _filteredMovements,
        _dateRange.start,
        _dateRange.end,
      );

      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PDF file downloaded')));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (!Permissions.canViewReports) {
      return const UnauthorizedScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Movements', style: TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF1e3a8a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_copy),
            onPressed: _exportToExcel,
            tooltip: 'Export to Excel',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPDF,
            tooltip: 'Export to PDF',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _showDateRangePicker,
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Stock In',
                    '+${_totalStockIn.toStringAsFixed(0)}',
                    Colors.green,
                    Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Stock Out',
                    '-${_totalStockOut.toStringAsFixed(0)}',
                    Colors.red,
                    Icons.arrow_upward,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Net Movement',
                    (_totalStockIn - _totalStockOut).toStringAsFixed(0),
                    Colors.blue,
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by product, SKU, reference, or invoice...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Active filters display
          if (_selectedProductId != null || _selectedMovementType != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_selectedProductId != null)
                      Chip(
                        label: Text(
                          'Product: ${_products.firstWhere((p) => p.id == _selectedProductId).name}',
                        ),
                        onDeleted: () {
                          setState(() {
                            _selectedProductId = null;
                          });
                          _loadData();
                        },
                      ),
                    if (_selectedMovementType != null)
                      Chip(
                        label: Text(
                          _selectedMovementType == 'IN'
                              ? 'Stock In'
                              : 'Stock Out',
                        ),
                        onDeleted: () {
                          setState(() {
                            _selectedMovementType = null;
                          });
                          _loadData();
                        },
                      ),
                  ],
                ),
              ),
            ),

          // Date range display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${_dateFormat.format(_dateRange.start)} - ${_dateFormat.format(_dateRange.end)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Movements list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMovements.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No stock movements found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filteredMovements.length,
                    itemBuilder: (context, index) {
                      final m = _filteredMovements[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: InkWell(
                          onTap: () {
                            _showMovementDetails(m);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: m.movementType == 'IN'
                                          ? Colors.green.shade100
                                          : Colors.red.shade100,
                                      radius: 20,
                                      child: Icon(
                                        m.movementType == 'IN'
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        color: m.movementType == 'IN'
                                            ? Colors.green
                                            : Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            m.productName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            'SKU: ${m.sku}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${m.movementType == 'IN' ? '+' : '-'} ${m.quantity.toStringAsFixed(0)} ${m.unitSymbol ?? ''}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: m.movementType == 'IN'
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                        Text(
                                          'Balance: ${m.balanceAfter.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.receipt,
                                      size: 14,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      m.reference,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _dateFormat.format(m.date),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                if (m.invoiceNumber != null &&
                                    m.invoiceNumber!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.receipt_outlined,
                                          size: 12,
                                          color: Colors.blue[400],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Invoice: ${m.invoiceNumber}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (m.notes != null && m.notes!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      m.notes!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Permissions.canManageInventory
          ? FloatingActionButton(
              onPressed: _showManualAdjustmentDialog,
              backgroundColor: const Color(0xFF1e3a8a),
              tooltip: 'Manual Adjustment',
              child: const Icon(Icons.add),
            )
          : null,
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showMovementDetails(StockMovement movement) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: movement.movementType == 'IN'
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    radius: 25,
                    child: Icon(
                      movement.movementType == 'IN'
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: movement.movementType == 'IN'
                          ? Colors.green
                          : Colors.red,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movement.productName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'SKU: ${movement.sku}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              _buildDetailRow('Reference', movement.reference),
              if (movement.invoiceNumber != null &&
                  movement.invoiceNumber!.isNotEmpty)
                _buildDetailRow('Invoice Number', movement.invoiceNumber!),
              _buildDetailRow(
                'Movement Type',
                movement.movementType == 'IN' ? 'Stock In' : 'Stock Out',
              ),
              _buildDetailRow(
                'Quantity',
                '${movement.quantity.toStringAsFixed(0)} ${movement.unitSymbol ?? ''}',
              ),
              _buildDetailRow(
                'Balance Before',
                movement.balanceBefore.toStringAsFixed(0),
              ),
              _buildDetailRow(
                'Balance After',
                movement.balanceAfter.toStringAsFixed(0),
              ),
              _buildDetailRow('Date', _dateFormat.format(movement.date)),
              if (movement.notes != null && movement.notes!.isNotEmpty)
                _buildDetailRow('Notes', movement.notes!),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualAdjustmentDialog() {
    final quantityController = TextEditingController();
    final reasonController = TextEditingController();
    final invoiceController = TextEditingController();
    Product? selectedProduct;
    String movementType = 'IN';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Manual Stock Adjustment'),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Product dropdown
                      Container(
                        constraints: const BoxConstraints(
                          maxWidth: double.infinity,
                        ),
                        child: DropdownButtonFormField<Product>(
                          decoration: const InputDecoration(
                            labelText: 'Product *',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          isExpanded: true,
                          initialValue: selectedProduct,
                          hint: const Text('Select Product'),
                          items: _products.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text(
                                '${p.name} (${p.sku})',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setStateDialog(() {
                              selectedProduct = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Movement type and quantity row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              constraints: const BoxConstraints(
                                maxWidth: double.infinity,
                              ),
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Type *',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                isExpanded: true,
                                initialValue: movementType,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'IN',
                                    child: Text('Stock In (Add)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'OUT',
                                    child: Text('Stock Out (Remove)'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setStateDialog(() {
                                    movementType = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: quantityController,
                              decoration: const InputDecoration(
                                labelText: 'Quantity *',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: invoiceController,
                        decoration: const InputDecoration(
                          labelText: 'Invoice Number (Optional)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Reason *',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedProduct == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a product'),
                        ),
                      );
                      return;
                    }
                    final quantity =
                        double.tryParse(quantityController.text) ?? 0;
                    if (quantity <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid quantity'),
                        ),
                      );
                      return;
                    }
                    if (reasonController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a reason')),
                      );
                      return;
                    }

                    final adjustedQuantity = movementType == 'IN'
                        ? quantity
                        : -quantity;

                    await _movementService.recordManualAdjustment(
                      productId: selectedProduct!.id,
                      quantity: adjustedQuantity,
                      reason: reasonController.text,
                      invoiceNumber: invoiceController.text.isNotEmpty
                          ? invoiceController.text
                          : null,
                    );

                    Navigator.pop(context);
                    _loadData();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Stock adjusted: ${movementType == 'IN' ? '+' : '-'} ${quantity.toStringAsFixed(0)} ${selectedProduct!.name}',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
