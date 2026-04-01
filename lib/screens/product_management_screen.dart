import 'package:flutter/material.dart';
import 'package:pos_system/services/product_service.dart';
import 'package:pos_system/services/category_service.dart';
import 'package:pos_system/services/unit_service.dart';
import 'package:pos_system/models/product.dart';
import 'package:pos_system/models/category.dart';
import 'package:pos_system/models/unit.dart';
import 'package:pos_system/utils/permissions.dart';
import 'package:pos_system/screens/unauthorized_screen.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  final UnitService _unitService = UnitService();

  List<Product> _products = [];
  List<Category> _categories = [];
  List<Unit> _units = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    final products = await _productService.getAllProducts();
    final categories = await _categoryService.getAllCategories();
    final units = await _unitService.getAllUnits();
    setState(() {
      _products = products;
      _categories = categories;
      _units = units;
      _isLoading = false;
    });
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products
        .where(
          (p) =>
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.sku.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final skuController = TextEditingController();
    final barcodeController = TextEditingController();
    final costPriceController = TextEditingController();
    final sellingPriceController = TextEditingController();
    final stockController = TextEditingController();
    final minStockController = TextEditingController();
    Category? selectedCategory;
    Unit? selectedUnit;
    bool isVatExempt = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Product'),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category dropdown - Fixed
                      Container(
                        constraints: const BoxConstraints(
                          maxWidth: double.infinity,
                        ),
                        child: DropdownButtonFormField<Category>(
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          isExpanded: true,
                          hint: const Text('Select Category'),
                          items: _categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(
                                cat.name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Unit dropdown - Fixed
                      Container(
                        constraints: const BoxConstraints(
                          maxWidth: double.infinity,
                        ),
                        child: DropdownButtonFormField<Unit>(
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          isExpanded: true,
                          hint: const Text('Select Unit'),
                          items: _units.map((unit) {
                            return DropdownMenuItem(
                              value: unit,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    unit.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${unit.symbol} = ${unit.conversionFactor} ${unit.baseUnitName}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedUnit = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Product name
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // SKU
                      TextField(
                        controller: skuController,
                        decoration: const InputDecoration(
                          labelText: 'SKU *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Barcode
                      TextField(
                        controller: barcodeController,
                        decoration: const InputDecoration(
                          labelText: 'Barcode',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Cost Price
                      TextField(
                        controller: costPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Cost Price (₦) *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),

                      // Selling Price
                      TextField(
                        controller: sellingPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Selling Price (₦) *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),

                      // Initial Stock
                      TextField(
                        controller: stockController,
                        decoration: const InputDecoration(
                          labelText: 'Initial Stock',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),

                      // Min Stock Alert
                      TextField(
                        controller: minStockController,
                        decoration: const InputDecoration(
                          labelText: 'Min Stock Alert',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),

                      // VAT Exempt checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: isVatExempt,
                            onChanged: (value) {
                              setState(() {
                                isVatExempt = value!;
                              });
                            },
                          ),
                          const Text('VAT Exempt'),
                        ],
                      ),

                      // Category VAT note
                      if (selectedCategory != null &&
                          selectedCategory!.isVatExempt)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Note: Category "${selectedCategory!.name}" is VAT exempt',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade700,
                            ),
                          ),
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
                    if (nameController.text.isEmpty ||
                        skuController.text.isEmpty ||
                        costPriceController.text.isEmpty ||
                        sellingPriceController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all required fields'),
                        ),
                      );
                      return;
                    }
                    await _productService.addProduct(
                      name: nameController.text,
                      sku: skuController.text,
                      categoryId: selectedCategory?.id,
                      unitId: selectedUnit?.id,
                      barcode: barcodeController.text.isEmpty
                          ? null
                          : barcodeController.text,
                      costPrice: double.parse(costPriceController.text),
                      sellingPrice: double.parse(sellingPriceController.text),
                      stockQuantity: double.tryParse(stockController.text) ?? 0,
                      minStockLevel:
                          double.tryParse(minStockController.text) ?? 0,
                      isVatExempt: isVatExempt,
                    );
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Product added successfully'),
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

  void _showEditProductDialog(Product product) {
    final nameController = TextEditingController(text: product.name);
    final skuController = TextEditingController(text: product.sku);
    final barcodeController = TextEditingController(
      text: product.barcode ?? '',
    );
    final costPriceController = TextEditingController(
      text: product.costPrice.toString(),
    );
    final sellingPriceController = TextEditingController(
      text: product.sellingPrice.toString(),
    );
    final stockController = TextEditingController(
      text: product.stockQuantity.toString(),
    );
    final minStockController = TextEditingController(
      text: product.minStockLevel.toString(),
    );
    bool isVatExempt = product.isVatExempt;

    // Find selected category
    Category? selectedCategory;
    if (product.categoryId != null) {
      try {
        selectedCategory = _categories.firstWhere(
          (c) => c.id == product.categoryId,
        );
      } catch (e) {
        selectedCategory = null;
      }
    }

    // Find selected unit
    Unit? selectedUnit;
    if (product.unitId != null) {
      try {
        selectedUnit = _units.firstWhere((u) => u.id == product.unitId);
      } catch (e) {
        selectedUnit = null;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Product'),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category dropdown - Fixed
                      Container(
                        constraints: const BoxConstraints(
                          maxWidth: double.infinity,
                        ),
                        child: DropdownButtonFormField<Category>(
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          isExpanded: true,
                          value: selectedCategory,
                          items: _categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(
                                cat.name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Unit dropdown - Fixed
                      Container(
                        constraints: const BoxConstraints(
                          maxWidth: double.infinity,
                        ),
                        child: DropdownButtonFormField<Unit>(
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          isExpanded: true,
                          value: selectedUnit,
                          items: _units.map((unit) {
                            return DropdownMenuItem(
                              value: unit,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    unit.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${unit.symbol} = ${unit.conversionFactor} ${unit.baseUnitName}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedUnit = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Product name
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // SKU
                      TextField(
                        controller: skuController,
                        decoration: const InputDecoration(
                          labelText: 'SKU *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Barcode
                      TextField(
                        controller: barcodeController,
                        decoration: const InputDecoration(
                          labelText: 'Barcode',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Cost Price
                      TextField(
                        controller: costPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Cost Price (₦) *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),

                      // Selling Price
                      TextField(
                        controller: sellingPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Selling Price (₦) *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),

                      // Stock Quantity
                      TextField(
                        controller: stockController,
                        decoration: const InputDecoration(
                          labelText: 'Stock Quantity',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),

                      // Min Stock Alert
                      TextField(
                        controller: minStockController,
                        decoration: const InputDecoration(
                          labelText: 'Min Stock Alert',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),

                      // VAT Exempt checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: isVatExempt,
                            onChanged: (value) {
                              setState(() {
                                isVatExempt = value!;
                              });
                            },
                          ),
                          const Text('VAT Exempt'),
                        ],
                      ),

                      // Category VAT note
                      if (selectedCategory != null &&
                          selectedCategory!.isVatExempt)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Note: Category "${selectedCategory!.name}" is VAT exempt',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),

                      // Override note
                      if (isVatExempt != product.isVatExempt)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            isVatExempt
                                ? 'Product will be VAT exempt (overrides category)'
                                : 'Product will be VATable',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.shade700,
                            ),
                          ),
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
                    if (nameController.text.isEmpty ||
                        skuController.text.isEmpty ||
                        costPriceController.text.isEmpty ||
                        sellingPriceController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all required fields'),
                        ),
                      );
                      return;
                    }
                    await _productService.updateProduct(
                      id: product.id,
                      name: nameController.text,
                      sku: skuController.text,
                      categoryId: selectedCategory?.id,
                      unitId: selectedUnit?.id,
                      barcode: barcodeController.text.isEmpty
                          ? null
                          : barcodeController.text,
                      costPrice: double.parse(costPriceController.text),
                      sellingPrice: double.parse(sellingPriceController.text),
                      stockQuantity:
                          double.tryParse(stockController.text) ??
                          product.stockQuantity,
                      minStockLevel:
                          double.tryParse(minStockController.text) ??
                          product.minStockLevel,
                      isVatExempt: isVatExempt,
                    );
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Product updated successfully'),
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

  void _showAdjustStockDialog(Product product) {
    final stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Adjust Stock: ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current Stock: ${product.stockQuantity.toStringAsFixed(0)}',
              ),
              const SizedBox(height: 8),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(
                  labelText: 'Quantity to Add',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final qty = double.tryParse(stockController.text) ?? 0;
                if (qty <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid quantity'),
                    ),
                  );
                  return;
                }
                await _productService.updateStock(product.id, qty);
                Navigator.pop(context);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Added ${qty.toStringAsFixed(0)} to ${product.name}',
                    ),
                  ),
                );
              },
              child: const Text('Add Stock'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check permission - Only Admin and Manager can access product management
    if (!Permissions.canManageProducts) {
      return const UnauthorizedScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products', style: TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF1e3a8a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        backgroundColor: const Color(0xFF1e3a8a),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or SKU...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Product list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                ? const Center(child: Text('No products found'))
                : ListView.builder(
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      final isLowStock =
                          product.stockQuantity < product.minStockLevel;

                      // Find unit name for display
                      String unitDisplay = '';
                      if (product.unitId != null) {
                        final unit = _units.firstWhere(
                          (u) => u.id == product.unitId,
                          orElse: () => Unit(
                            id: 0,
                            baseUnitId: 0,
                            baseUnitName: '',
                            name: '',
                            symbol: '',
                            conversionFactor: 1,
                            isBaseUnit: false,
                          ),
                        );
                        if (unit.symbol.isNotEmpty) {
                          unitDisplay = ' | Unit: ${unit.symbol}';
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              product.sku.substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.blue),
                            ),
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SKU: ${product.sku} | Price: ₦${product.sellingPrice.toStringAsFixed(0)}$unitDisplay | Stock: ${product.stockQuantity.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isLowStock
                                      ? Colors.red.shade700
                                      : Colors.grey.shade600,
                                ),
                              ),
                              if (product.isVatExempt)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'VAT Exempt',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.inventory, size: 20),
                                onPressed: () =>
                                    _showAdjustStockDialog(product),
                                tooltip: 'Adjust Stock',
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () =>
                                    _showEditProductDialog(product),
                              ),
                            ],
                          ),
                          onTap: () => _showEditProductDialog(product),
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
