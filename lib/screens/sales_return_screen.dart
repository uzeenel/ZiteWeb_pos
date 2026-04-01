import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/models/sales_return.dart';
import 'package:pos_system/services/sales_return_service.dart';
import 'package:pos_system/services/sale_service.dart';
import 'package:pos_system/screens/unauthorized_screen.dart';
import 'package:pos_system/utils/permissions.dart';

class SalesReturnScreen extends StatefulWidget {
  const SalesReturnScreen({super.key});

  @override
  State<SalesReturnScreen> createState() => _SalesReturnScreenState();
}

class _SalesReturnScreenState extends State<SalesReturnScreen> {
  final SalesReturnService _service = SalesReturnService();
  final SaleService _saleService = SaleService();
  final TextEditingController _invoiceController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  List<Map<String, dynamic>> _saleItems = [];
  Map<int, int> _selectedQuantities = {};
  bool _isLoading = false;
  String _returnStatus = 'create';
  List<SalesReturn> _returns = [];
  String _filterStatus = 'all';

  List<Map<String, dynamic>> _recentSales = [];
  bool _isLoadingSales = false;
  String _selectedInvoice = '';
  DateTime _selectedDate = DateTime.now();

  final _currencyFormat = NumberFormat("#,##0.00");
  final _dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  final _shortDateFormat = DateFormat('dd/MM/yyyy');

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  void initState() {
    super.initState();
    _loadReturns();
    _loadRecentSales();
  }

  Future<void> _loadRecentSales() async {
    setState(() => _isLoadingSales = true);
    try {
      final startOfDay = DateTime.now().subtract(const Duration(days: 7));
      final endOfDay = DateTime.now();
      final sales = await _saleService.getSalesByDateRange(
        startOfDay,
        endOfDay,
      );
      setState(() {
        _recentSales = sales;
        _isLoadingSales = false;
      });
    } catch (e) {
      print('Error loading recent sales: $e');
      setState(() => _isLoadingSales = false);
    }
  }

  Future<void> _loadReturns() async {
    setState(() => _isLoading = true);
    final returns = await _service.getReturnsByDateRange(
      DateTime.now().subtract(const Duration(days: 30)),
      DateTime.now(),
    );
    setState(() {
      _returns = returns;
      _isLoading = false;
    });
  }

  Future<void> _searchSale() async {
    if (_invoiceController.text.isEmpty && _selectedInvoice.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter or select an invoice number'),
        ),
      );
      return;
    }

    final invoiceNumber = _invoiceController.text.isNotEmpty
        ? _invoiceController.text
        : _selectedInvoice;

    setState(() => _isLoading = true);
    try {
      final items = await _service.getSaleItemsForReturn(invoiceNumber);
      setState(() {
        _saleItems = items;
        _selectedQuantities = {};
        _isLoading = false;
      });

      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No items available for return or sale not found'),
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _submitReturn() async {
    if (_saleItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No items selected')));
      return;
    }

    final itemsToReturn = _saleItems
        .where((item) {
          final quantity = _selectedQuantities[item['sale_item_id']] ?? 0;
          return quantity > 0;
        })
        .map((item) {
          return {
            'sale_item_id': item['sale_item_id'],
            'quantity': _selectedQuantities[item['sale_item_id']],
            'reason': _reasonController.text.isEmpty
                ? 'Customer return'
                : _reasonController.text,
          };
        })
        .toList();

    if (itemsToReturn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select items to return')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final sale = await _service.getSaleByInvoice(
        _invoiceController.text.isNotEmpty
            ? _invoiceController.text
            : _selectedInvoice,
      );
      await _service.createReturn(
        saleId: sale!.id!,
        invoiceNumber: _invoiceController.text.isNotEmpty
            ? _invoiceController.text
            : _selectedInvoice,
        items: itemsToReturn,
        reason: _reasonController.text.isEmpty
            ? 'Customer return'
            : _reasonController.text,
        cashierId: 1,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Return created successfully'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _invoiceController.clear();
        _selectedInvoice = '';
        _reasonController.clear();
        _saleItems = [];
        _selectedQuantities = {};
        _returnStatus = 'view';
      });
      _loadReturns();
      _loadRecentSales();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processReturn(SalesReturn returnData) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Return #${returnData.returnNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice: ${returnData.invoiceNumber}'),
            Text('Amount: ₦${_currencyFormat.format(returnData.totalRefund)}'),
            Text('Reason: ${returnData.reason}'),
            const SizedBox(height: 16),
            const Text('Items:'),
            ...returnData.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text(
                  '• ${item.productName} x${item.quantity} - ₦${_currencyFormat.format(item.total)}',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (returnData.status == ReturnStatus.pending)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  await _service.completeReturn(returnData.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Return completed'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadReturns();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('Complete Return'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Permissions.canProcessReturns) {
      return const UnauthorizedScreen();
    }

    final filteredReturns = _filterStatus == 'all'
        ? _returns
        : _returns
              .where(
                (r) => r.status.toString().split('.').last == _filterStatus,
              )
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Returns', style: TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF1e3a8a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                _returnStatus = 'create';
                _saleItems = [];
                _invoiceController.clear();
                _selectedInvoice = '';
                _reasonController.clear();
              });
            },
            tooltip: 'New Return',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadReturns();
              _loadRecentSales();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _returnStatus == 'create'
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recent Sales (Last 7 Days)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _isLoadingSales
                              ? const Center(child: CircularProgressIndicator())
                              : _recentSales.isEmpty
                              ? const Text('No recent sales')
                              : SizedBox(
                                  height: 120,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _recentSales.length,
                                    itemBuilder: (context, index) {
                                      final sale = _recentSales[index];
                                      final isSelected =
                                          _selectedInvoice ==
                                          sale['invoice_number'];
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedInvoice =
                                                sale['invoice_number'];
                                            _invoiceController.clear();
                                          });
                                          _searchSale();
                                        },
                                        child: Container(
                                          width: 150,
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.blue.shade50
                                                : Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.blue
                                                  : Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                sale['invoice_number'],
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: isSelected
                                                      ? Colors.blue
                                                      : Colors.black,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _shortDateFormat.format(
                                                  DateTime.parse(
                                                    sale['sale_date'],
                                                  ),
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                ),
                                              ),
                                              Text(
                                                '₦${_currencyFormat.format(_toDouble(sale['total']))}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Or Enter Invoice Number',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _invoiceController,
                                  decoration: const InputDecoration(
                                    labelText: 'Invoice Number',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.receipt),
                                  ),
                                  onChanged: (value) {
                                    if (value.isNotEmpty) {
                                      setState(() => _selectedInvoice = '');
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _searchSale,
                                child: const Text('Search'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_saleItems.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Select Items to Return',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            ..._saleItems.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['product_name'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                'SKU: ${item['sku']}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),
                                              Text(
                                                '₦${_currencyFormat.format(_toDouble(item['unit_price']))} each',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Sold: ${item['quantity_sold']}',
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Returned: ${item['quantity_returned']}',
                                          ),
                                        ),
                                        SizedBox(
                                          width: 80,
                                          child: DropdownButton<int>(
                                            value:
                                                _selectedQuantities[item['sale_item_id']],
                                            hint: const Text('Qty'),
                                            items: List.generate(
                                              int.parse(item['quantity_available']) + 1,
                                              (i) => DropdownMenuItem(
                                                value: i,
                                                child: Text(i.toString()),
                                              ),
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                if (value == 0) {
                                                  _selectedQuantities.remove(
                                                    item['sale_item_id'],
                                                  );
                                                } else {
                                                  _selectedQuantities[item['sale_item_id']] =
                                                      value!;
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _reasonController,
                              decoration: const InputDecoration(
                                labelText: 'Return Reason',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _submitReturn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('Submit Return Request'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Text('Filter:'),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _filterStatus,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(
                            value: 'pending',
                            child: Text('Pending'),
                          ),
                          DropdownMenuItem(
                            value: 'completed',
                            child: Text('Completed'),
                          ),
                          DropdownMenuItem(
                            value: 'rejected',
                            child: Text('Rejected'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _filterStatus = value!),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredReturns.isEmpty
                      ? const Center(child: Text('No returns found'))
                      : ListView.builder(
                          itemCount: filteredReturns.length,
                          itemBuilder: (context, index) {
                            final returnData = filteredReturns[index];
                            final statusColor =
                                returnData.status == ReturnStatus.completed
                                ? Colors.green
                                : (returnData.status == ReturnStatus.pending
                                      ? Colors.orange
                                      : Colors.red);

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.assignment_return,
                                    color: statusColor,
                                  ),
                                ),
                                title: Text(returnData.returnNumber),
                                subtitle: Text(
                                  'Invoice: ${returnData.invoiceNumber}\n${_dateFormat.format(returnData.returnDate)}',
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '₦${_currencyFormat.format(returnData.totalRefund)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        returnData.status
                                            .toString()
                                            .split('.')
                                            .last
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => _processReturn(returnData),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
