import 'package:flutter/material.dart';
import 'package:zite_web_pos/models/product.dart';
import 'package:zite_web_pos/services/product_service.dart';
import 'package:zite_web_pos/services/api_service.dart';
import 'package:intl/intl.dart';

class StockAdjustmentScreen extends StatefulWidget {
  const StockAdjustmentScreen({super.key});

  @override
  State<StockAdjustmentScreen> createState() => _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends State<StockAdjustmentScreen> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  Product? _selectedProduct;
  final TextEditingController _quantityController = TextEditingController();
  String _adjustmentType = 'add'; // 'add', 'remove', 'set'
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _searchQuery = '';
  String _notes = '';

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
    return _products.where((p) =>
      p.name.toLowerCase().contains(q) ||
      p.sku.toLowerCase().contains(q)
    ).toList();
  }

  Future<void> _submitAdjustment() async {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product'), backgroundColor: Colors.red),
      );
      return;
    }

    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      double newQuantity = _selectedProduct!.stockQuantity;
      String movementType = 'IN';
      String notes = '';

      switch (_adjustmentType) {
        case 'add':
          newQuantity = _selectedProduct!.stockQuantity + quantity;
          movementType = 'IN';
          notes = 'Manual stock increase by ${quantity.toStringAsFixed(2)}';
          break;
        case 'remove':
          if (quantity > _selectedProduct!.stockQuantity) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cannot remove more than current stock (${_selectedProduct!.stockQuantity.toStringAsFixed(2)})'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => _isSubmitting = false);
            return;
          }
          newQuantity = _selectedProduct!.stockQuantity - quantity;
          movementType = 'OUT';
          notes = 'Manual stock removal of ${quantity.toStringAsFixed(2)}';
          break;
        case 'set':
          newQuantity = quantity;
          movementType = 'IN';
          notes = 'Stock adjusted to ${quantity.toStringAsFixed(2)}';
          break;
      }

      // Update product stock
      final adjustment = newQuantity - _selectedProduct!.stockQuantity;
      await _productService.updateStock(_selectedProduct!.id, adjustment);

      // Record stock movement
      final reference = 'ADJ-${DateTime.now().millisecondsSinceEpoch}';
      print(
        '📤 Calling recordStockMovement with: productId=${_selectedProduct!.id}, movementType=$movementType, quantity=$quantity',
      );
      await ApiService.recordStockMovement(
        productId: _selectedProduct!.id,
        reference: reference,
        movementType: movementType,
        quantity: quantity,
        notes: '$_notes\n$notes',
        invoiceNumber: null,
      );

      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock adjusted successfully! New stock: ${newQuantity.toStringAsFixed(2)}'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      setState(() {
        _selectedProduct = null;
        _quantityController.clear();
        _notes = '';
        _searchQuery = '';
      });

      // Reload products
      await _loadProducts();

    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Adjustment', style: TextStyle(fontSize: 18)),
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
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product search
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search product by name or SKU...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                  const SizedBox(height: 12),

                  // Product dropdown
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<Product>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Product *',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedProduct,
                      hint: const Text('Select a product'),
                      items: _filteredProducts.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text(
                            '${p.name} (${p.sku}) - Stock: ${p.stockQuantity.toStringAsFixed(0)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedProduct = value),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Current stock display
                  if (_selectedProduct != null)
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
                          const Text(
                            'Current Stock:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _selectedProduct!.stockQuantity.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Adjustment type
                  const Text(
                    'Adjustment Type',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile(
                          title: const Text('Add'),
                          value: 'add',
                          groupValue: _adjustmentType,
                          onChanged: (value) => setState(() => _adjustmentType = value.toString()),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile(
                          title: const Text('Remove'),
                          value: 'remove',
                          groupValue: _adjustmentType,
                          onChanged: (value) => setState(() => _adjustmentType = value.toString()),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile(
                          title: const Text('Set to'),
                          value: 'set',
                          groupValue: _adjustmentType,
                          onChanged: (value) => setState(() => _adjustmentType = value.toString()),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Quantity
                  TextField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: _adjustmentType == 'add'
                          ? 'Quantity to Add'
                          : (_adjustmentType == 'remove'
                              ? 'Quantity to Remove'
                              : 'Set Quantity'),
                      border: const OutlineInputBorder(),
                      helperText: _adjustmentType == 'set'
                          ? 'This will replace the current stock quantity'
                          : null,
                    ),
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 12),

                  // Notes
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (value) => setState(() => _notes = value),
                  ),

                  const SizedBox(height: 16),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitAdjustment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Apply Adjustment',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'How it works:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Add: Increases stock by the quantity entered',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '• Remove: Decreases stock by the quantity entered',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '• Set to: Replaces stock with the exact quantity entered',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber,
                                color: Colors.red.shade700,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '⚠️ This action cannot be undone!',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
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
            ),
    );
  }
}
