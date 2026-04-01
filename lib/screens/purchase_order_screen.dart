import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pos_system/services/vendor_service.dart';
import 'package:pos_system/services/product_service.dart';
import 'package:pos_system/services/purchase_order_service.dart';
import 'package:pos_system/services/unit_service.dart';
import 'package:pos_system/services/company_service.dart';
import 'package:pos_system/models/vendor.dart';
import 'package:pos_system/models/product.dart';
import 'package:pos_system/models/unit.dart';
import 'package:pos_system/screens/unauthorized_screen.dart';
import 'package:pos_system/utils/permissions.dart';

class PurchaseOrderScreen extends StatefulWidget {
  const PurchaseOrderScreen({super.key});

  @override
  State<PurchaseOrderScreen> createState() => _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState extends State<PurchaseOrderScreen> {
  final VendorService _vendorService = VendorService();
  final ProductService _productService = ProductService();
  final PurchaseOrderService _poService = PurchaseOrderService();
  final UnitService _unitService = UnitService();
  final CompanyService _companyService = CompanyService();

  List<Vendor> _vendors = [];
  List<Product> _products = [];
  final List<Map<String, dynamic>> _orderItems = [];
  Vendor? _selectedVendor;
  String? _selectedVendorId;
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    final vendors = await _vendorService.getAllVendors();
    final products = await _productService.getAllProducts();

    setState(() {
      _vendors = vendors;
      _products = products;
      _isLoading = false;
    });
  }

  bool _isProductVatExempt(Product product) {
    return product.isVatExempt;
  }

  double _calculateItemVat(Product product, double subtotal) {
    if (_selectedVendor?.isVatRegistered != true) return 0;
    if (_isProductVatExempt(product)) return 0;
    return subtotal * 0.075;
  }

  double get _subtotal {
    return _orderItems.fold(0, (sum, item) => sum + (item['total'] as double));
  }

  double get _tax {
    double tax = 0;
    for (var item in _orderItems) {
      final product = _getProductById(item['productId']);
      if (product != null) {
        tax += _calculateItemVat(product, item['total']);
      }
    }
    return tax;
  }

  Product? _getProductById(int productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  double get _total {
    return _subtotal + _tax;
  }

  void _showAddItemDialog(Function() onItemAdded) {
    Product? selectedProduct;
    Unit? selectedUnit;
    List<Unit> availableUnits = [];
    TextEditingController quantityController = TextEditingController(text: '1');
    TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Item'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedVendor != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vendor: ${_selectedVendor!.name}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_selectedVendor!.isVatRegistered)
                                const Text(
                                  'VAT Registered',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),

                      DropdownButtonFormField<Product>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Product',
                          border: OutlineInputBorder(),
                        ),
                        items: _products.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text(
                              '${p.name} (${p.sku}) - Base unit: ${p.unitSymbol ?? "pcs"}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          setState(() {
                            selectedProduct = value;
                            selectedUnit = null;
                            availableUnits = [];
                            priceController.clear();
                          });

                          if (value != null) {
                            final units = await _unitService.getUnitsForProduct(
                              value.id,
                            );
                            setState(() {
                              availableUnits = units;
                              if (availableUnits.isNotEmpty) {
                                selectedUnit = availableUnits.first;
                                priceController.text = value.costPrice
                                    .toString();
                              }
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      if (selectedProduct != null && availableUnits.isNotEmpty)
                        DropdownButtonFormField<Unit>(
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(),
                          ),
                          initialValue: selectedUnit,
                          items: availableUnits.map((u) {
                            String unitText = u.name;
                            if (u.conversionFactor != 1) {
                              unitText =
                                  '${u.name} (1 ${u.symbol} = ${u.conversionFactor} ${u.baseUnitName})';
                            }
                            return DropdownMenuItem(
                              value: u,
                              child: Text(
                                unitText,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedUnit = value;
                            });
                          },
                        ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: quantityController,
                        decoration: InputDecoration(
                          labelText: selectedUnit != null
                              ? 'Quantity (${selectedUnit!.symbol})'
                              : 'Quantity',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: priceController,
                        decoration: InputDecoration(
                          labelText: selectedProduct != null
                              ? 'Cost Price per ${selectedProduct!.unitSymbol ?? "base unit"} (₦)'
                              : 'Cost Price (₦)',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),

                      if (selectedProduct != null &&
                          selectedUnit != null &&
                          priceController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Price per ${selectedUnit!.symbol}: ₦${((double.tryParse(priceController.text) ?? 0) * selectedUnit!.conversionFactor).toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                Text(
                                  'Total: ₦${((double.tryParse(quantityController.text) ?? 0) * (double.tryParse(priceController.text) ?? 0) * selectedUnit!.conversionFactor).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      if (selectedProduct != null && _selectedVendor != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'VAT Info:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Vendor: ${_selectedVendor!.isVatRegistered ? "VAT Registered" : "Not Registered"}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                Text(
                                  'Product: ${selectedProduct!.isVatExempt ? "VAT Exempt" : "VAT Applicable"}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                if (_selectedVendor!.isVatRegistered &&
                                    !selectedProduct!.isVatExempt)
                                  const Text(
                                    '→ VAT (7.5%) will be applied',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange,
                                    ),
                                  ),
                              ],
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
                  onPressed: () {
                    if (selectedProduct == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a product'),
                        ),
                      );
                      return;
                    }
                    if (selectedUnit == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a unit')),
                      );
                      return;
                    }
                    final qty = double.tryParse(quantityController.text) ?? 0;
                    final pricePerBaseUnit =
                        double.tryParse(priceController.text) ?? 0;
                    if (qty <= 0 || pricePerBaseUnit <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter valid quantity and price',
                          ),
                        ),
                      );
                      return;
                    }

                    final pricePerSellingUnit =
                        pricePerBaseUnit * selectedUnit!.conversionFactor;
                    final total = qty * pricePerSellingUnit;
                    final baseQuantity = qty * selectedUnit!.conversionFactor;

                    _orderItems.add({
                      'productId': selectedProduct!.id,
                      'productName': selectedProduct!.name,
                      'productSku': selectedProduct!.sku,
                      'unitId': selectedUnit!.id,
                      'unitName': selectedUnit!.name,
                      'unitSymbol': selectedUnit!.symbol,
                      'conversionFactor': selectedUnit!.conversionFactor,
                      'quantity': qty,
                      'baseQuantity': baseQuantity,
                      'unitPrice': pricePerSellingUnit,
                      'total': total,
                      'isVatExempt': selectedProduct!.isVatExempt,
                    });

                    Navigator.pop(context);
                    onItemAdded();
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeItem(int index) {
    setState(() {
      _orderItems.removeAt(index);
    });
  }

  Future<void> _createPurchaseOrder() async {
    if (_selectedVendor == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a vendor')));
      return;
    }
    if (_orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    final items = _orderItems
        .map(
          (item) => ({
            'productId': item['productId'],
            'quantity': item['baseQuantity'],
            'unitPrice': item['unitPrice'],
          }),
        )
        .toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await _poService.createPurchaseOrder(
      vendorId: _selectedVendor!.id,
      items: items,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Purchase Order Created',
          style: TextStyle(fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PO Number: ${result['poNumber']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Vendor: ${_selectedVendor!.name}'),
            Text('Date: ${DateTime.now().toString().substring(0, 16)}'),
            const Divider(),
            Text('Subtotal: ₦${_subtotal.toStringAsFixed(2)}'),
            Text('VAT (7.5%): ₦${_tax.toStringAsFixed(2)}'),
            const Divider(),
            Text(
              'Total: ₦${_total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _orderItems.clear();
                _selectedVendor = null;
                _selectedVendorId = null;
                _notesController.clear();
              });
            },
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _printPurchaseOrder(result['poNumber']);
            },
            child: const Text('Print'),
          ),
        ],
      ),
    );
  }

  Future<void> _printPurchaseOrder(String poNumber) async {
    final company = await _companyService.getCompany();
    final companyName = company?.name ?? 'Your Company Name';
    final companyAddress = company?.address ?? '';
    final companyPhone = company?.phone ?? '';
    final companyEmail = company?.email ?? '';
    final companyTaxId = company?.taxId ?? '';

    // Build HTML content
    final StringBuffer html = StringBuffer();

    html.writeln('''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Purchase Order $poNumber</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            font-size: 12px;
        }
        .print-container {
            max-width: 800px;
            margin: 0 auto;
        }
        .header {
            text-align: center;
            border: 1px solid #ccc;
            padding: 20px;
            margin-bottom: 20px;
        }
        .company-name {
            font-size: 20px;
            font-weight: bold;
        }
        .po-title {
            text-align: center;
            font-size: 18px;
            font-weight: bold;
            margin: 20px 0;
        }
        .info-box {
            border: 1px solid #ccc;
            padding: 10px;
            margin-bottom: 20px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            border: 1px solid #ccc;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f5f5f5;
            font-weight: bold;
        }
        .totals {
            text-align: right;
            margin-top: 20px;
        }
        .signature {
            margin-top: 40px;
            display: flex;
            justify-content: space-between;
        }
        .footer {
            text-align: center;
            margin-top: 40px;
            font-size: 10px;
            color: #666;
        }
        .no-print {
            text-align: center;
            margin-bottom: 20px;
        }
        .no-print button {
            padding: 10px 20px;
            font-size: 14px;
            margin: 0 5px;
            cursor: pointer;
        }
        @media print {
            .no-print {
                display: none;
            }
            body {
                padding: 0;
                margin: 0;
            }
            .print-container {
                max-width: 100%;
            }
        }
    </style>
</head>
<body>
    <div class="print-container">
        <div class="no-print">
            <button onclick="window.print()">🖨️ Print / Save as PDF</button>
            <button onclick="window.close()">❌ Close</button>
        </div>
        
        <div class="header">
            <div class="company-name">${_escapeHtml(companyName.toUpperCase())}</div>
            ${companyAddress.isNotEmpty ? '<div>${_escapeHtml(companyAddress)}</div>' : ''}
            ${companyPhone.isNotEmpty ? '<div>Tel: ${_escapeHtml(companyPhone)}</div>' : ''}
            ${companyEmail.isNotEmpty ? '<div>Email: ${_escapeHtml(companyEmail)}</div>' : ''}
            ${companyTaxId.isNotEmpty ? '<div>RC No: ${_escapeHtml(companyTaxId)}</div>' : ''}
        </div>
        
        <div class="po-title">PURCHASE ORDER</div>
        
        <div class="info-box">
            <strong>PO Number:</strong> ${_escapeHtml(poNumber)}<br>
            <strong>Date:</strong> ${DateTime.now().toString().substring(0, 16)}<br><br>
            <strong>VENDOR:</strong><br>
            ${_escapeHtml(_selectedVendor!.name)}<br>
            ${_selectedVendor!.address != null ? '${_escapeHtml(_selectedVendor!.address!)}<br>' : ''}
            ${_selectedVendor!.phone != null ? 'Tel: ${_escapeHtml(_selectedVendor!.phone!)}<br>' : ''}
        </div>
        
        <table>
            <thead>
                <tr>
                    <th>Qty</th>
                    <th>Unit</th>
                    <th>Description</th>
                    <th>Unit Price</th>
                    <th>Amount</th>
                </tr>
            </thead>
            <tbody>
    ''');

    for (var item in _orderItems) {
      html.writeln('''
                <tr>
                    <td>${item['quantity']}</td>
                    <td>${_escapeHtml(item['unitSymbol'])}</td>
                    <td>${_escapeHtml(item['productName'])}</td>
                    <td>₦${item['unitPrice'].toStringAsFixed(2)}</td>
                    <td>₦${item['total'].toStringAsFixed(2)}</td>
                </tr>
      ''');
    }

    html.writeln('''
            </tbody>
        </table>
        
        <div class="totals">
            <div>Subtotal: ₦${_subtotal.toStringAsFixed(2)}</div>
            <div>VAT (7.5%): ₦${_tax.toStringAsFixed(2)}</div>
            <div><strong>Total: ₦${_total.toStringAsFixed(2)}</strong></div>
        </div>
    ''');

    if (_notesController.text.isNotEmpty) {
      html.writeln('''
        <div class="info-box">
            <strong>NOTES:</strong><br>
            ${_escapeHtml(_notesController.text)}
        </div>
      ''');
    }

    html.writeln('''
        <div class="signature">
            <div>
                Authorized Signature: _________________<br>
                Date: _________________
            </div>
        </div>
        
        <div class="footer">
            Thank you for your business!
        </div>
    </div>
</body>
</html>
    ''');

    // Save to file and open in browser
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'PO_${poNumber.replaceAll('-', '_')}.html';
    final file = File('${directory.path}/$fileName');

    await file.writeAsString(html.toString());

    // Open in default browser
    await Process.run('start', [file.path], runInShell: true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening print preview in browser...')),
      );
    }
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  @override
  Widget build(BuildContext context) {
    // Check permissions - Only Admin and Manager can manage users
    if (!Permissions.canManagePurchaseOrders) {
      return const UnauthorizedScreen();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Order', style: TextStyle(fontSize: 18)),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vendor Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vendor Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Select Vendor',
                              border: OutlineInputBorder(),
                            ),
                            initialValue: _selectedVendorId,
                            items: _vendors.map((v) {
                              String displayName = v.name;
                              if (v.isVatRegistered) {
                                displayName = '$displayName (VAT Reg)';
                              }
                              return DropdownMenuItem(
                                value: v.id.toString(),
                                child: Text(
                                  displayName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedVendorId = value;
                                _selectedVendor = _vendors.firstWhere(
                                  (v) => v.id.toString() == value,
                                );
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Notes',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Order Items
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Order Items',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _selectedVendor == null
                                    ? null
                                    : () => _showAddItemDialog(
                                        () => setState(() {}),
                                      ),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Item'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (_selectedVendor == null)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('Please select a vendor first'),
                              ),
                            )
                          else if (_orderItems.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text(
                                  'No items added. Click "Add Item" to start.',
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _orderItems.length,
                              itemBuilder: (context, index) {
                                final item = _orderItems[index];
                                final product = _getProductById(
                                  item['productId'],
                                );
                                final itemVat = product != null
                                    ? _calculateItemVat(product, item['total'])
                                    : 0;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['productName'],
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  Text(
                                                    'SKU: ${item['productSku']} | Unit: ${item['unitSymbol']}',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              onPressed: () =>
                                                  _removeItem(index),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Qty: ${item['quantity']} ${item['unitSymbol']} × ₦${item['unitPrice'].toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                            ),
                                            Text(
                                              '₦${item['total'].toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (itemVat > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '+ VAT: ₦${itemVat.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                          if (_orderItems.isNotEmpty) ...[
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Subtotal:',
                                  style: TextStyle(fontSize: 13),
                                ),
                                Text(
                                  '₦${_subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'VAT (7.5%):',
                                  style: TextStyle(fontSize: 13),
                                ),
                                Text(
                                  '₦${_tax.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  '₦${_total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  if (_orderItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _createPurchaseOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Create Purchase Order',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
