import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zite_web_pos/models/product.dart';
import 'package:zite_web_pos/services/product_service.dart';
import 'package:zite_web_pos/services/api_service.dart';
import 'package:zite_web_pos/screens/unauthorized_screen.dart';
import 'package:zite_web_pos/utils/permissions.dart';

class OpeningBalanceScreen extends StatefulWidget {
  const OpeningBalanceScreen({super.key});

  @override
  State<OpeningBalanceScreen> createState() => _OpeningBalanceScreenState();
}

class _OpeningBalanceScreenState extends State<OpeningBalanceScreen> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  List<Map<String, dynamic>> _selectedProducts = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isProcessing = false;
  bool _isSaving = false;
  String _searchQuery = '';

  final _currencyFormat = NumberFormat("#,##0.00");

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await _productService.getAllProducts();
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    final q = _searchQuery.toLowerCase();
    return _products
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.sku.toLowerCase().contains(q),
        )
        .toList();
  }

  void _addProduct(Product product) {
    if (_selectedProducts.any((p) => p['id'] == product.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product already added'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _selectedProducts.add({
        'id': product.id,
        'name': product.name,
        'sku': product.sku,
        'quantity': 0.0,
        'product': product,
      });
    });
  }

  void _removeProduct(int index) {
    setState(() {
      _selectedProducts.removeAt(index);
    });
  }

  void _updateQuantity(int index, String value) {
    final qty = double.tryParse(value) ?? 0;
    setState(() {
      _selectedProducts[index]['quantity'] = qty;
    });
  }

  Future<void> _saveOpeningBalances() async {
    if (_isProcessing) return;
    _isProcessing = true;
    _isSaving = true;
    _isSubmitting = true;
    setState(() {});

    print('=== SAVE OPENING BALANCES CALLED ===');
    print('Number of products: ${_selectedProducts.length}');

    final hasItems = _selectedProducts.any(
      (p) => (p['quantity'] as double) > 0,
    );
    if (!hasItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one opening balance'),
          backgroundColor: Colors.orange,
        ),
      );
      _isProcessing = false;
      _isSaving = false;
      _isSubmitting = false;
      setState(() {});
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Opening Balances'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will set the opening stock for:'),
            const SizedBox(height: 8),
            ..._selectedProducts
                .where((p) => (p['quantity'] as double) > 0)
                .map((p) => Text('• ${p['name']}: ${p['quantity']}')),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone!',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      _isProcessing = false;
      _isSaving = false;
      _isSubmitting = false;
      setState(() {});
      return;
    }

    try {
      int successCount = 0;
      int failCount = 0;

      print('🔴 LOOP START: ${_selectedProducts.length} items');

      for (var item in _selectedProducts) {
        print('🔴 LOOP ITEM: ${item['name']} - qty: ${item['quantity']}');
        final qty = item['quantity'] as double;
        if (qty <= 0) continue;

        try {
          // SET the stock directly using the new setStock method
          await _productService.setStock(item['id'], qty);
          print('🔴 SET STOCK COMPLETED for ${item['name']}');

          // Record the stock movement
          final reference = 'OPEN-${DateTime.now().millisecondsSinceEpoch}';
          await ApiService.recordStockMovement(
            productId: item['id'],
            reference: reference,
            movementType: 'IN',
            quantity: qty,
            notes: 'Opening balance',
            invoiceNumber: null,
          );

          successCount++;
        } catch (e) {
          print('Failed to update ${item['name']}: $e');
          failCount++;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Opening balances saved! $successCount products updated. ${failCount > 0 ? "$failCount failed." : ""}',
          ),
          backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
        ),
      );

      if (successCount > 0) {
        setState(() {
          _selectedProducts.clear();
          _searchQuery = '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      _isProcessing = false;
      _isSaving = false;
      _isSubmitting = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Permissions.canManageStock) {
      return const UnauthorizedScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Opening Balances', style: TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF1e3a8a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search products...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                        ),
                      ),
                      Expanded(
                        child: _filteredProducts.isEmpty
                            ? const Center(child: Text('No products found'))
                            : ListView.builder(
                                itemCount: _filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = _filteredProducts[index];
                                  final isAdded = _selectedProducts.any(
                                    (p) => p['id'] == product.id,
                                  );
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        product.name,
                                        style: const TextStyle(fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        'SKU: ${product.sku} | Stock: ${product.stockQuantity.toStringAsFixed(0)}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      trailing: isAdded
                                          ? const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                            )
                                          : ElevatedButton(
                                              onPressed: () =>
                                                  _addProduct(product),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                              ),
                                              child: const Text('Add'),
                                            ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 400,
                  color: Colors.grey.shade100,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: const Color(0xFF1e3a8a),
                        child: Row(
                          children: [
                            const Icon(Icons.list, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Opening Balances (${_selectedProducts.length})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _selectedProducts.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    'Select products from the left list\nto set opening balances.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _selectedProducts.length,
                                itemBuilder: (context, index) {
                                  final item = _selectedProducts[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['name'],
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 13,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  'SKU: ${item['sku']}',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'Qty',
                                                border: OutlineInputBorder(),
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (value) =>
                                                  _updateQuantity(index, value),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _removeProduct(index),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade300,
                              blurRadius: 4,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            if (_selectedProducts.isNotEmpty)
                              Text(
                                'Total products: ${_selectedProducts.where((p) => (p['quantity'] as double) > 0).length} with quantity > 0',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : _saveOpeningBalances,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Save Opening Balances'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
