import 'package:flutter/material.dart';
import 'package:pos_system/services/purchase_order_service.dart';
import 'package:pos_system/services/vendor_service.dart';
import 'package:pos_system/services/product_service.dart';
import 'package:pos_system/services/unit_service.dart';
import 'package:pos_system/models/vendor.dart';
import 'package:pos_system/models/product.dart';
import 'package:pos_system/models/unit.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/screens/unauthorized_screen.dart';
import 'package:pos_system/utils/permissions.dart';

class ReceiveStockScreen extends StatefulWidget {
  const ReceiveStockScreen({super.key});

  @override
  State<ReceiveStockScreen> createState() => _ReceiveStockScreenState();
}

class _ReceiveStockScreenState extends State<ReceiveStockScreen>
    with SingleTickerProviderStateMixin {
  final PurchaseOrderService _poService = PurchaseOrderService();
  final VendorService _vendorService = VendorService();
  final ProductService _productService = ProductService();
  final UnitService _unitService = UnitService();

  List<Map<String, dynamic>> _pendingOrders = [];
  List<Vendor> _vendors = [];
  List<Product> _products = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Vendor filter for PO tab
  Vendor? _selectedFilterVendor;

  late TabController _tabController;

  // For invoice receiving
  List<Map<String, dynamic>> _invoiceItems = [];
  Vendor? _selectedInvoiceVendor;
  TextEditingController _invoiceNumberController = TextEditingController();
  DateTime _selectedInvoiceDate = DateTime.now();

  // Helper methods for safe type conversion
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0.0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _formatQuantity(dynamic value) {
    if (value == null) return '0';
    if (value is int) return value.toString();
    if (value is double) {
      if (value == value.toInt()) {
        return value.toInt().toString();
      }
      return value.toString();
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        if (parsed == parsed.toInt()) {
          return parsed.toInt().toString();
        }
        return parsed.toString();
      }
      return value;
    }
    return value.toString();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _invoiceNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final orders = await _poService.getAllPurchaseOrders();
      final vendors = await _vendorService.getAllVendors();
      final products = await _productService.getAllProducts();
      setState(() {
        _pendingOrders = orders.where((o) => o['status'] == 'pending').toList();
        _vendors = vendors;
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Filtered orders with vendor filter and search
  List<Map<String, dynamic>> get _filteredOrders {
    List<Map<String, dynamic>> filtered = _pendingOrders;

    // Apply vendor filter if selected
    if (_selectedFilterVendor != null) {
      filtered = filtered
          .where((order) => order['vendor_id'] == _selectedFilterVendor!.id)
          .toList();
    }

    // Apply search query filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (order) =>
                order['po_number'].toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (order['vendor_name']?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    }

    return filtered;
  }

  double _calculateSubtotal(List<Map<String, dynamic>> items) {
    double sum = 0;
    for (var item in items) {
      sum += _toDouble(item['total']);
    }
    return sum;
  }

  double _calculateVat(List<Map<String, dynamic>> items) {
    return _calculateSubtotal(items) * 0.075;
  }

  double _calculateTotal(List<Map<String, dynamic>> items) {
    return _calculateSubtotal(items) + _calculateVat(items);
  }

  void _showAddDirectItemDialog(
    List<Map<String, dynamic>> items,
    Function setState,
  ) {
    Product? selectedProduct;
    TextEditingController quantityController = TextEditingController(text: '1');
    TextEditingController priceController = TextEditingController();
    Unit? selectedUnit;
    List<Unit> availableUnits = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Item',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Product dropdown
                    DropdownButtonFormField<Product>(
                      decoration: const InputDecoration(
                        labelText: 'Product *',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      isExpanded: true,
                      menuMaxHeight: 300,
                      items: _products.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                p.sku,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        setStateDialog(() {
                          selectedProduct = value;
                          selectedUnit = null;
                          availableUnits = [];
                          priceController.clear();
                        });

                        if (value != null) {
                          final units = await _unitService.getUnitsForProduct(
                            value.id,
                          );
                          setStateDialog(() {
                            availableUnits = units;
                            if (availableUnits.isNotEmpty) {
                              selectedUnit = availableUnits.first;
                              priceController.text = value.costPrice.toString();
                            }
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    // Unit dropdown
                    if (selectedProduct != null && availableUnits.isNotEmpty)
                      DropdownButtonFormField<Unit>(
                        decoration: const InputDecoration(
                          labelText: 'Unit *',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        isExpanded: true,
                        value: selectedUnit,
                        items: availableUnits.map((u) {
                          return DropdownMenuItem(
                            value: u,
                            child: Text(u.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            selectedUnit = value;
                          });
                        },
                      ),

                    const SizedBox(height: 12),

                    // Quantity field
                    TextField(
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

                    const SizedBox(height: 12),

                    // Price field
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Unit Price (₦) *',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        prefixText: '₦ ',
                      ),
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
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
                            if (selectedUnit == null &&
                                availableUnits.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select a unit'),
                                ),
                              );
                              return;
                            }
                            final qty =
                                double.tryParse(quantityController.text) ?? 0;
                            final price =
                                double.tryParse(priceController.text) ?? 0;
                            if (qty <= 0 || price <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please enter valid quantity and price',
                                  ),
                                ),
                              );
                              return;
                            }

                            final total = qty * price;

                            items.add({
                              'productId': selectedProduct!.id,
                              'productName': selectedProduct!.name,
                              'productSku': selectedProduct!.sku,
                              'quantity': qty,
                              'unitPrice': price,
                              'total': total,
                              'unitId': selectedUnit?.id,
                              'unitName': selectedUnit?.name,
                            });

                            Navigator.pop(context);
                            setState(() {});
                          },
                          child: const Text('Add Item'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddVendorDialog(Function setState, Vendor? selectedVendor) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    final contactController = TextEditingController();
    bool isVatRegistered = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Add New Vendor'),
              content: SizedBox(
                width: 350,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Company Name *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: contactController,
                        decoration: const InputDecoration(
                          labelText: 'Contact Person',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text('VAT Registered'),
                        value: isVatRegistered,
                        onChanged: (value) {
                          setStateDialog(() {
                            isVatRegistered = value!;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
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
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter vendor name'),
                        ),
                      );
                      return;
                    }

                    final newVendorId = await _vendorService.addVendor(
                      name: nameController.text,
                      phone: phoneController.text.isEmpty
                          ? null
                          : phoneController.text,
                      email: emailController.text.isEmpty
                          ? null
                          : emailController.text,
                      address: addressController.text.isEmpty
                          ? null
                          : addressController.text,
                      contactPerson: contactController.text.isEmpty
                          ? null
                          : contactController.text,
                      isVatRegistered: isVatRegistered,
                    );

                    final updatedVendors = await _vendorService.getAllVendors();
                    setState(() {
                      _vendors = updatedVendors;
                    });

                    Navigator.pop(context);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Vendor "${nameController.text}" added',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Add Vendor'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _resetInvoiceForm() {
    _invoiceItems.clear();
    _selectedInvoiceVendor = null;
    _invoiceNumberController.clear();
    _selectedInvoiceDate = DateTime.now();
    setState(() {});
  }

  Future<void> _saveInvoiceReceipt() async {
    if (_selectedInvoiceVendor == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a vendor')));
      return;
    }
    if (_invoiceNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter invoice number')),
      );
      return;
    }
    if (_invoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    try {
      final poId = await _poService.createDirectPurchaseOrder(
        vendorId: _selectedInvoiceVendor!.id,
        items: _invoiceItems,
        notes: 'Date: ${DateFormat('dd/MM/yyyy').format(_selectedInvoiceDate)}',
        invoiceNumber: _invoiceNumberController.text, // Pass invoice number
      );

      if (poId > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stock received! Invoice: ${_invoiceNumberController.text}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _resetInvoiceForm();
        _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save stock receipt')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  final _dateFormat = DateFormat('dd/MM/yyyy');

  void _showDirectPurchaseDialog() {
    List<Map<String, dynamic>> items = [];
    Vendor? selectedVendor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.95,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
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
                      const SizedBox(height: 16),
                      const Text(
                        'Direct Purchase',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Vendor selection with add button
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<Vendor>(
                              decoration: const InputDecoration(
                                labelText: 'Vendor',
                                border: OutlineInputBorder(),
                              ),
                              hint: const Text('Select Vendor'),
                              value: selectedVendor,
                              items: _vendors.map((v) {
                                return DropdownMenuItem(
                                  value: v,
                                  child: Text(v.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedVendor = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: Colors.blue,
                            ),
                            onPressed: () {
                              _showAddVendorDialog(setState, selectedVendor);
                            },
                            tooltip: 'Add New Vendor',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Items list header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Items',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              _showAddDirectItemDialog(items, setState);
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Item'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Items list
                      Expanded(
                        child: items.isEmpty
                            ? const Center(child: Text('No items added'))
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      title: Text(item['productName']),
                                      subtitle: Text(
                                        'Qty: ${_formatQuantity(item['quantity'])} × ₦${_toDouble(item['unitPrice']).toStringAsFixed(2)} = ₦${_toDouble(item['total']).toStringAsFixed(2)}',
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            items.removeAt(index);
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                      const Divider(),

                      // Totals
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Subtotal:',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            '₦${_calculateSubtotal(items).toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'VAT (7.5%):',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text('₦${_calculateVat(items).toStringAsFixed(2)}'),
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
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '₦${_calculateTotal(items).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: items.isEmpty || selectedVendor == null
                                ? null
                                : () async {
                                    try {
                                      final poId = await _poService
                                          .createDirectPurchaseOrder(
                                            vendorId: selectedVendor!.id,
                                            items: items,
                                            notes: 'Direct Purchase',
                                          );
                                      if (poId > 0 && mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Direct purchase saved!',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                      if (mounted) {
                                        Navigator.pop(context);
                                        _loadData();
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error: ${e.toString()}',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: const Text('Save & Receive Stock'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showReceiveDialog(Map<String, dynamic> order) async {
    try {
      final details = await _poService.getPurchaseOrderDetails(order['id']);
      if (details['items'].isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order not found or already received'),
            ),
          );
        }
        return;
      }

      final orderData = details['order'];
      final items = List<Map<String, dynamic>>.from(details['items']);

      // Controller for supplier invoice number
      final invoiceNumberController = TextEditingController();

      List<Map<String, dynamic>> modifiableItems = [];
      for (var item in items) {
        modifiableItems.add({
          ...item,
          'receivedQuantity': _toDouble(item['received_quantity']),
          'productId': item['product_id'],
        });
      }

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return DraggableScrollableSheet(
                initialChildSize: 0.9,
                maxChildSize: 0.95,
                minChildSize: 0.5,
                expand: false,
                builder: (context, scrollController) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
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
                        const SizedBox(height: 16),
                        Text(
                          'Receive Stock',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // PO Information Card
                        Card(
                          color: Colors.blue.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PO: ${orderData['po_number']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('Vendor: ${orderData['vendor_name']}'),
                                Text(
                                  'Date: ${orderData['order_date'].toString().substring(0, 16)}',
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Supplier Invoice Number Field (Optional)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Supplier Information',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: invoiceNumberController,
                                  decoration: const InputDecoration(
                                    labelText: 'Supplier Invoice Number',
                                    hintText: 'Optional - for reference',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.receipt_outlined),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Items Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Items to Receive',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${modifiableItems.length} item(s)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // Items List
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: modifiableItems.length,
                            itemBuilder: (context, index) {
                              final item = modifiableItems[index];
                              final orderedQty = _toDouble(item['quantity']);
                              final receivedQty = _toDouble(
                                item['received_quantity'],
                              );
                              final remaining = orderedQty - receivedQty;
                              final currentReceive = _toDouble(
                                item['receivedQuantity'],
                              );

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['product_name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'SKU: ${item['sku']}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Ordered',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                Text(
                                                  _formatQuantity(
                                                    item['quantity'],
                                                  ),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Received',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                Text(
                                                  _formatQuantity(
                                                    item['received_quantity'],
                                                  ),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Remaining',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                Text(
                                                  _formatQuantity(remaining),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: remaining > 0
                                                        ? Colors.orange
                                                        : Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (remaining > 0) ...[
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                decoration:
                                                    const InputDecoration(
                                                      labelText:
                                                          'Quantity to Receive',
                                                      border:
                                                          OutlineInputBorder(),
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 8,
                                                          ),
                                                    ),
                                                keyboardType:
                                                    TextInputType.number,
                                                onChanged: (value) {
                                                  final qty =
                                                      double.tryParse(value) ??
                                                      0;
                                                  if (qty <= remaining) {
                                                    setState(() {
                                                      modifiableItems[index]['receivedQuantity'] =
                                                          qty;
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  modifiableItems[index]['receivedQuantity'] =
                                                      remaining;
                                                });
                                              },
                                              child: const Text('Receive All'),
                                            ),
                                          ],
                                        ),
                                        if (currentReceive > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              'Will receive: ${_formatQuantity(currentReceive)}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.blue,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                      ] else
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Fully Received',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.green,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final itemsToReceive = modifiableItems
                                    .where(
                                      (item) =>
                                          _toDouble(item['receivedQuantity']) >
                                          0,
                                    )
                                    .map(
                                      (item) => {
                                        'id': item['id'],
                                        'productId': item['productId'],
                                        'receivedQuantity': _toDouble(
                                          item['receivedQuantity'],
                                        ),
                                      },
                                    )
                                    .toList();

                                if (itemsToReceive.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter quantities to receive',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );

                                // Pass the invoice number to the service
                                final success = await _poService
                                    .receivePurchaseOrder(
                                      order['id'],
                                      itemsToReceive,
                                      invoiceNumber:
                                          invoiceNumberController
                                              .text
                                              .isNotEmpty
                                          ? invoiceNumberController.text
                                          : null,
                                    );

                                if (mounted) {
                                  Navigator.pop(
                                    context,
                                  ); // Close loading dialog
                                  Navigator.pop(context); // Close bottom sheet
                                }

                                if (success && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        invoiceNumberController.text.isNotEmpty
                                            ? 'Stock received! Invoice: ${invoiceNumberController.text}'
                                            : 'Stock received successfully',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  _loadData(); // Refresh the list
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to receive stock'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: const Text('Receive Stock'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Permissions.canReceiveStock) {
      return const UnauthorizedScreen();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive Stock', style: TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF1e3a8a),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '📦 Purchase Orders'),
            Tab(text: '📄 Receive by Invoice'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Purchase Orders with Vendor Filter
          Column(
            children: [
              // Vendor filter row
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Vendor>(
                        decoration: InputDecoration(
                          labelText: 'Filter by Vendor',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.filter_list),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        value: _selectedFilterVendor,
                        hint: const Text('All Vendors'),
                        items: [
                          const DropdownMenuItem<Vendor>(
                            value: null,
                            child: Text('All Vendors'),
                          ),
                          ..._vendors.map((v) {
                            return DropdownMenuItem(
                              value: v,
                              child: Text(v.name),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedFilterVendor = value;
                            _searchQuery = '';
                          });
                        },
                      ),
                    ),
                    if (_selectedFilterVendor != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _selectedFilterVendor = null;
                          });
                        },
                        tooltip: 'Clear filter',
                      ),
                  ],
                ),
              ),
              // Search field
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: _selectedFilterVendor != null
                        ? 'Search by PO number...'
                        : 'Search by PO number or vendor...',
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
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedFilterVendor != null
                                  ? 'No pending POs for ${_selectedFilterVendor!.name}'
                                  : 'No pending purchase orders',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_selectedFilterVendor != null)
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _selectedFilterVendor = null;
                                  });
                                },
                                icon: const Icon(Icons.clear),
                                label: const Text('Clear filter'),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = _filteredOrders[index];
                          final date = DateTime.parse(order['order_date']);
                          final formattedDate = DateFormat(
                            'dd/MM/yyyy',
                          ).format(date);

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange.shade100,
                                child: const Icon(
                                  Icons.pending,
                                  color: Colors.orange,
                                ),
                              ),
                              title: Text(
                                order['po_number'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${order['vendor_name']}\n$formattedDate | ${_toInt(order['item_count'])} items | ₦${_toDouble(order['total']).toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              onTap: () => _showReceiveDialog(order),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          // Tab 2: Receive by Invoice
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Invoice Information Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Invoice Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _invoiceNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Invoice Number *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.receipt),
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedInvoiceDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _selectedInvoiceDate = date;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Invoice Date',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_dateFormat.format(_selectedInvoiceDate)),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Vendor Selection
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Vendor Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<Vendor>(
                          decoration: const InputDecoration(
                            labelText: 'Select Vendor *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.business),
                          ),
                          value: _selectedInvoiceVendor,
                          items: _vendors.map((v) {
                            return DropdownMenuItem(
                              value: v,
                              child: Text(v.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedInvoiceVendor = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Items Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Items',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                _showAddDirectItemDialog(
                                  _invoiceItems,
                                  setState,
                                );
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Item'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_invoiceItems.isEmpty)
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
                            itemCount: _invoiceItems.length,
                            itemBuilder: (context, index) {
                              final item = _invoiceItems[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(item['productName']),
                                  subtitle: Text(
                                    'Qty: ${_formatQuantity(item['quantity'])} × ₦${_toDouble(item['unitPrice']).toStringAsFixed(2)}',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _invoiceItems.removeAt(index);
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Subtotal:',
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              '₦${_calculateSubtotal(_invoiceItems).toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'VAT (7.5%):',
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              '₦${_calculateVat(_invoiceItems).toStringAsFixed(2)}',
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
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '₦${_calculateTotal(_invoiceItems).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveInvoiceReceipt,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Save & Receive Stock',
                      style: TextStyle(fontSize: 16),
                    ),
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
