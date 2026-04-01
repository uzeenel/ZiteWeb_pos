import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pos_system/services/product_service.dart';
// import 'package:pos_system/services/sale_service.dart';
import 'package:pos_system/services/company_service.dart';
import 'package:pos_system/models/product.dart';
import 'package:pos_system/models/cart_item.dart';
import 'package:pos_system/screens/login_screen.dart';
import 'package:pos_system/services/auth_service.dart';
import 'package:pos_system/services/api_service.dart';
import 'package:window_manager/window_manager.dart';


class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final ProductService _productService = ProductService();
  final CompanyService _companyService = CompanyService();
  final AuthService _authService = AuthService();

  List<Product> _products = [];
  final List<CartItem> _cart = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );

  String get _currentCashierName =>
      _authService.currentUser?.fullName ?? 'CASHIER-01';

  @override
  void initState() {
    super.initState();
    print('Current user in POSScreen: ${_authService.currentUser?.username}');
    _loadData();
    _maximizeWindow();
  }

  Future<void> _maximizeWindow() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await windowManager.ensureInitialized();
      await windowManager.setTitle('POS System');
      await windowManager.setMinimumSize(const Size(1024, 768));
      await windowManager.maximize();
    });
  }

  Future<void> _loadData() async {
    final products = await _productService.getAllProducts();
    final categories = products
        .map((p) => p.categoryName ?? 'Uncategorized')
        .toSet()
        .toList();
    categories.sort();
    setState(() {
      _products = products;
      _categories = ['All', ...categories];
      _isLoading = false;
    });
  }

  Future<void> _refreshProducts() async {
    final products = await _productService.getAllProducts();
    setState(() {
      _products = products;
    });
    _loadCategories();
  }

  void _loadCategories() {
    final categories = _products
        .map((p) => p.categoryName ?? 'Uncategorized')
        .toSet()
        .toList();
    categories.sort();
    setState(() {
      _categories = ['All', ...categories];
    });
  }

  void _addToCart(Product product, {int quantity = 1}) {
    if (quantity < 1) quantity = 1;

    final cartItem = _cart.firstWhere(
      (item) => item.product.id == product.id,
      orElse: () => CartItem(product: product, quantity: 0),
    );
    final totalNeeded = cartItem.quantity + quantity;

    if (totalNeeded > product.stockQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only ${product.stockQuantity} left in stock!'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      final existingIndex = _cart.indexWhere(
        (item) => item.product.id == product.id,
      );
      if (existingIndex >= 0) {
        _cart[existingIndex].quantity += quantity;
      } else {
        _cart.add(CartItem(product: product, quantity: quantity));
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+$quantity ${product.name}',
              style: const TextStyle(fontSize: 12),
            ),
            if (product.isVatExempt)
              const Text(
                '✓ VAT Exempt',
                style: TextStyle(fontSize: 10, color: Colors.green),
              ),
          ],
        ),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        width: 250,
      ),
    );
  }

  void _addBySku() async {
    if (_skuController.text.isEmpty) return;

    int quantity = int.tryParse(_quantityController.text) ?? 1;
    if (quantity < 1) quantity = 1;

    final product = await _productService.getProductBySku(_skuController.text);
    if (product != null) {
      _addToCart(product, quantity: quantity);
      _skuController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product not found!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _removeFromCart(CartItem item) {
    setState(() {
      _cart.remove(item);
    });
  }

  void _updateCartQuantity(CartItem item, int newQuantity) {
    if (newQuantity > item.product.stockQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only ${item.product.stockQuantity} left in stock!'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() {
      if (newQuantity <= 0) {
        _cart.remove(item);
      } else {
        item.quantity = newQuantity;
      }
    });
  }

  double get _subtotal => _cart.fold(0, (sum, item) => sum + item.subtotal);

  double get _tax {
    double tax = 0;
    for (var item in _cart) {
      if (!item.product.isVatExempt) {
        tax += item.subtotal * 0.075;
      }
    }
    return tax;
  }

  double get _total => _subtotal + _tax;

  List<Product> get _filteredProducts {
    var filtered = _products;
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((p) => p.categoryName == _selectedCategory)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (p) =>
                p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                p.sku.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    return filtered;
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
    });
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  Future<void> _printReceiptWithData(
    String invoiceNumber,
    List<CartItem> cart,
    double subtotal,
    double tax,
    double total,
  ) async {
    final company = await _companyService.getCompany();
    final companyName = company?.name ?? 'Your Company Name';
    final companyAddress = company?.address ?? '';
    final companyPhone = company?.phone ?? '';

    final StringBuffer html = StringBuffer();

    html.writeln('''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Receipt $invoiceNumber</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Courier New', monospace;
            background: white;
            margin: 0;
            padding: 0;
        }
        
        .receipt {
            width: 280px;
            margin: 0 auto;
            padding: 12px;
            background: white;
        }
        
        @media print {
            body {
                background: white;
                margin: 0;
                padding: 0;
            }
            .receipt {
                margin: 0;
                padding: 8px;
            }
            .no-print {
                display: none !important;
            }
        }
        
        .no-print {
            text-align: center;
            margin-bottom: 12px;
            padding-bottom: 8px;
            border-bottom: 1px solid #ddd;
        }
        
        .no-print button {
            padding: 6px 16px;
            margin: 0 5px;
            cursor: pointer;
            font-family: monospace;
            font-weight: bold;
            border: none;
            border-radius: 4px;
            font-size: 12px;
        }
        
        .no-print button:first-child {
            background: #4caf50;
            color: white;
        }
        
        .no-print button:last-child {
            background: #f44336;
            color: white;
        }
        
        .header {
            text-align: center;
            border-bottom: 1px dashed #aaa;
            padding-bottom: 8px;
            margin-bottom: 8px;
        }
        
        .company-name {
            font-size: 14px;
            font-weight: 800;
            text-transform: uppercase;
        }
        
        .company-address {
            font-size: 9px;
            color: #444;
            margin-top: 2px;
        }
        
        .company-phone {
            font-size: 9px;
            color: #444;
        }
        
        .receipt-title {
            text-align: center;
            font-size: 11px;
            font-weight: 800;
            margin: 8px 0;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .info-section {
            margin-bottom: 10px;
            font-size: 10px;
            border-bottom: 1px dashed #aaa;
            padding-bottom: 6px;
        }
        
        .info-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 4px;
        }
        
        .info-label {
            font-weight: 600;
        }
        
        .items-table {
            width: 100%;
            margin: 8px 0;
            border-collapse: collapse;
            font-size: 10px;
        }
        
        .items-table th {
            text-align: left;
            font-weight: 800;
            padding: 4px 0;
            border-bottom: 1px solid #000;
        }
        
        .items-table td {
            padding: 4px 0;
            border-bottom: 1px dotted #ccc;
        }
        
        .items-table th:first-child,
        .items-table td:first-child {
            text-align: left;
            width: 45%;
        }
        
        .items-table th:nth-child(2),
        .items-table td:nth-child(2) {
            text-align: center;
            width: 15%;
        }
        
        .items-table th:nth-child(3),
        .items-table td:nth-child(3) {
            text-align: right;
            width: 20%;
        }
        
        .items-table th:last-child,
        .items-table td:last-child {
            text-align: right;
            width: 20%;
        }
        
        .totals {
            margin-top: 8px;
            padding-top: 8px;
            border-top: 1px solid #000;
        }
        
        .total-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 4px;
            font-size: 10px;
        }
        
        .grand-total {
            display: flex;
            justify-content: space-between;
            margin-top: 6px;
            padding-top: 6px;
            border-top: 1px dashed #000;
            font-size: 12px;
            font-weight: 800;
        }
        
        .footer {
            text-align: center;
            margin-top: 10px;
            padding-top: 8px;
            border-top: 1px dashed #aaa;
            font-size: 8px;
            color: #666;
        }
        
        .footer p {
            margin: 2px 0;
        }
        
        .thankyou {
            font-weight: 800;
            font-size: 9px;
            margin-top: 4px;
        }
        
        .barcode-section {
            text-align: center;
            margin-top: 8px;
            padding-top: 6px;
            border-top: 1px dashed #aaa;
        }
        
        .barcode {
            font-family: 'Libre Barcode 39', 'Code 39', 'Courier New', monospace;
            font-size: 36px;
            font-weight: normal;
            letter-spacing: 1px;
            margin: 4px 0;
        }
        
        .barcode-number {
            font-size: 8px;
            color: #666;
            margin-top: 2px;
        }
    </style>
    <link href="https://fonts.googleapis.com/css2?family=Libre+Barcode+39&display=swap" rel="stylesheet">
</head>
<body>
    <div class="receipt">
        <div class="no-print">
            <button onclick="window.print()">🖨️ PRINT</button>
            <button onclick="window.close()">✖ CLOSE</button>
        </div>
        
        <div class="header">
            <div class="company-name">${_escapeHtml(companyName)}</div>
            ${companyAddress.isNotEmpty ? '<div class="company-address">${_escapeHtml(companyAddress)}</div>' : ''}
            ${companyPhone.isNotEmpty ? '<div class="company-phone">Tel: ${_escapeHtml(companyPhone)}</div>' : ''}
        </div>
        
        <div class="receipt-title">SALES RECEIPT</div>
        
        <div class="info-section">
            <div class="info-row">
                <span class="info-label">INVOICE NO:</span>
                <span>${_escapeHtml(invoiceNumber)}</span>
            </div>
            <div class="info-row">
                <span class="info-label">DATE:</span>
                <span>${DateTime.now().toString().substring(0, 16).replaceAll('T', ' ')}</span>
            </div>
            <div class="info-row">
                <span class="info-label">CASHIER:</span>
                <span>${_escapeHtml(_currentCashierName)}</span>
            </div>
        </div>
        
        <table class="items-table">
            <thead>
                <tr>
                    <th>ITEM</th>
                    <th>QTY</th>
                    <th>PRICE</th>
                    <th>TOTAL</th>
                </tr>
            </thead>
            <tbody>
''');

    for (var item in cart) {
      final itemTotal = item.product.sellingPrice * item.quantity;
      html.writeln('''
                <tr>
                    <td class="item-name">${_escapeHtml(item.product.name)}</td>
                    <td style="text-align: center;">${item.quantity}</td>
                    <td style="text-align: right;">₦${item.product.sellingPrice.toStringAsFixed(2)}</td>
                    <td style="text-align: right;">₦${itemTotal.toStringAsFixed(2)}</td>
                 </tr>
''');
    }

    html.writeln('''
            </tbody>
         </table>
        
        <div class="totals">
            <div class="total-row">
                <span>SUBTOTAL:</span>
                <span>₦${subtotal.toStringAsFixed(2)}</span>
            </div>
            <div class="total-row">
                <span>VAT (7.5%):</span>
                <span>₦${tax.toStringAsFixed(2)}</span>
            </div>
            <div class="grand-total">
                <span>TOTAL:</span>
                <span>₦${total.toStringAsFixed(2)}</span>
            </div>
        </div>
        
        <div class="footer">
            <p>Thank you for your patronage!</p>
            <p>Goods sold are not returnable</p>
            <p class="thankyou">★★★★★ COME AGAIN ★★★★★</p>
        </div>
        
        <div class="barcode-section">
            <div class="barcode">*${_escapeHtml(invoiceNumber)}*</div>
            <div class="barcode-number">${_escapeHtml(invoiceNumber)}</div>
        </div>
    </div>
</body>
</html>
''');

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Receipt_${invoiceNumber.replaceAll('-', '_')}.html';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(html.toString());
    await Process.run('start', [file.path], runInShell: true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Receipt opened in browser',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sale', style: TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF1e3a8a),
        foregroundColor: Colors.white,
        toolbarHeight: 56,
        actions: [
          // User info and logout
          if (_authService.currentUser != null)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'logout') {
                  await _authService.logout();
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
              child: Row(
                children: [
                  const Icon(Icons.person),
                  const SizedBox(width: 4),
                  Text(
                    _authService.currentUser!.fullName.split(' ').first,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),

          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProducts,
            tooltip: 'Refresh Stock',
          ),

          // Cart button with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, size: 24),
                onPressed: () => _showCartDialog(),
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_cart.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Search and SKU input row
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search by name...',
                            prefixIcon: Icon(Icons.search, size: 20),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            isDense: true,
                          ),
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 70,
                        child: TextField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            hintText: 'Qty',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _skuController,
                          decoration: const InputDecoration(
                            hintText: 'SKU',
                            prefixIcon: Icon(Icons.qr_code, size: 20),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _addBySku(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addBySku,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

                // Category filter chips - Styled
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    height: 42,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              category,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (_) =>
                                setState(() => _selectedCategory = category),
                            backgroundColor: Colors.grey[100],
                            selectedColor: const Color(0xFF1e3a8a),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.transparent
                                    : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // Products grid
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredProducts.isEmpty
                      ? const Center(child: Text('No products found'))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = (constraints.maxWidth / 110)
                                .floor();
                            if (crossAxisCount < 5) crossAxisCount = 5;
                            if (crossAxisCount > 9) crossAxisCount = 9;
                            return GridView.builder(
                              padding: const EdgeInsets.all(8),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    childAspectRatio:
                                        0.75, // Change from 0.85 to 0.75
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                final isLowStock = product.stockQuantity < 10;
                                final isOutOfStock = product.stockQuantity <= 0;
                                final cartItem = _cart.firstWhere(
                                  (item) => item.product.id == product.id,
                                  orElse: () =>
                                      CartItem(product: product, quantity: 0),
                                );

                                return Card(
                                  elevation: 1,
                                  color: isOutOfStock
                                      ? Colors.grey.shade100
                                      : Colors.white,
                                  child: InkWell(
                                    onTap: isOutOfStock
                                        ? null
                                        : () {
                                            int qty =
                                                int.tryParse(
                                                  _quantityController.text,
                                                ) ??
                                                1;
                                            _addToCart(product, quantity: qty);
                                          },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.shopping_cart,
                                            size: 20,
                                            color: isOutOfStock
                                                ? Colors.grey
                                                : Colors.blue.shade600,
                                          ),
                                          const SizedBox(height: 4),
                                          Flexible(
                                            child: Text(
                                              product.name,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 9,
                                                color: isOutOfStock
                                                    ? Colors.grey
                                                    : Colors.black87,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isOutOfStock
                                                  ? Colors.grey.shade200
                                                  : Colors.green.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '₦${product.sellingPrice.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                color: isOutOfStock
                                                    ? Colors.grey
                                                    : Colors.green.shade700,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 9,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Flexible(
                                            child: Text(
                                              isOutOfStock
                                                  ? 'OUT'
                                                  : 'Stock: ${product.stockQuantity.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontSize: 8,
                                                color: isOutOfStock
                                                    ? Colors.red.shade700
                                                    : (isLowStock
                                                          ? Colors
                                                                .orange
                                                                .shade700
                                                          : Colors
                                                                .grey
                                                                .shade600),
                                                fontWeight: isOutOfStock
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (cartItem.quantity > 0 &&
                                              !isOutOfStock)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                top: 2,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: 1,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${cartItem.quantity}',
                                                style: TextStyle(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue.shade800,
                                                ),
                                              ),
                                            ),
                                          if (product.isVatExempt &&
                                              !isOutOfStock)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 1,
                                              ),
                                              child: Text(
                                                '✓',
                                                style: TextStyle(
                                                  fontSize: 7,
                                                  color: Colors.green.shade600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // Cart sidebar
          Container(
            width: 300,
            color: Colors.grey.shade100,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.blue.shade800,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Cart (${_cart.length} items)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _cart.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Cart is empty',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _cart.length,
                          itemBuilder: (context, index) {
                            final item = _cart[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.product.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 18,
                                          ),
                                          onPressed: () =>
                                              _removeFromCart(item),
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '₦${item.product.sellingPrice.toStringAsFixed(0)} each',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.remove,
                                                size: 18,
                                              ),
                                              onPressed: () =>
                                                  _updateCartQuantity(
                                                    item,
                                                    item.quantity - 1,
                                                  ),
                                              constraints:
                                                  const BoxConstraints(),
                                              padding: EdgeInsets.zero,
                                            ),
                                            Container(
                                              width: 30,
                                              alignment: Alignment.center,
                                              child: Text(
                                                item.quantity.toString(),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.add,
                                                size: 18,
                                              ),
                                              onPressed: () =>
                                                  _updateCartQuantity(
                                                    item,
                                                    item.quantity + 1,
                                                  ),
                                              constraints:
                                                  const BoxConstraints(),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '₦${item.subtotal.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
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
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Subtotal:',
                            style: TextStyle(fontSize: 13),
                          ),
                          Text(
                            '₦${_subtotal.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'VAT (7.5%):',
                            style: TextStyle(fontSize: 13),
                          ),
                          Text(
                            '₦${_tax.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      const Divider(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '₦${_total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _cart.isEmpty ? null : _showCheckoutDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Checkout',
                            style: TextStyle(fontSize: 14),
                          ),
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

  void _showCartDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        height: 400,
        child: Column(
          children: [
            const Text(
              'Shopping Cart',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: _cart.isEmpty
                  ? const Center(child: Text('Cart is empty'))
                  : ListView.builder(
                      itemCount: _cart.length,
                      itemBuilder: (context, index) {
                        final item = _cart[index];
                        return ListTile(
                          title: Text(
                            item.product.name,
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: Text(
                            '₦${item.product.sellingPrice.toStringAsFixed(0)} x ${item.quantity}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Text(
                            '₦${item.subtotal.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontSize: 14)),
                Text(
                  '₦${_total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckoutDialog() {
    final TextEditingController cashController = TextEditingController();
    String paymentMethod = 'Cash';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Checkout', style: TextStyle(fontSize: 16)),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subtotal: ₦${_subtotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    Text(
                      'VAT: ₦${_tax.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const Divider(),
                    Text(
                      'Total: ₦${_total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Payment Method:',
                      style: TextStyle(fontSize: 13),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile(
                            title: const Text(
                              'Cash',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: 'Cash',
                            groupValue: paymentMethod,
                            onChanged: (value) => setState(
                              () => paymentMethod = value.toString(),
                            ),
                            contentPadding: EdgeInsets.zero,
                            visualDensity: const VisualDensity(horizontal: -2),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile(
                            title: const Text(
                              'Card',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: 'Card',
                            groupValue: paymentMethod,
                            onChanged: (value) => setState(
                              () => paymentMethod = value.toString(),
                            ),
                            contentPadding: EdgeInsets.zero,
                            visualDensity: const VisualDensity(horizontal: -2),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile(
                            title: const Text(
                              'Transfer',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: 'Transfer',
                            groupValue: paymentMethod,
                            onChanged: (value) => setState(
                              () => paymentMethod = value.toString(),
                            ),
                            contentPadding: EdgeInsets.zero,
                            visualDensity: const VisualDensity(horizontal: -2),
                          ),
                        ),
                      ],
                    ),
                    if (paymentMethod == 'Cash') const SizedBox(height: 8),
                    if (paymentMethod == 'Cash')
                      TextField(
                        controller: cashController,
                        decoration: const InputDecoration(
                          labelText: 'Amount Paid',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 13),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    double paidAmount = _total;
                    if (paymentMethod == 'Cash' &&
                        cashController.text.isNotEmpty) {
                      paidAmount =
                          double.tryParse(cashController.text) ?? _total;
                    }

                    final capturedCart = List<CartItem>.from(_cart);
                    final capturedSubtotal = _subtotal;
                    final capturedTax = _tax;
                    final capturedTotal = _total;

                    showDialog(
                      context: dialogContext,
                      barrierDismissible: false,
                      builder: (loadingContext) {
                        return const Center(child: CircularProgressIndicator());
                      },
                    );

                    print('=== SAVING SALE ===');
                    print('Cart: ${capturedCart.length} items');
                    print('Total: $capturedTotal');

                    final result = await ApiService.saveSale(
                      cart: capturedCart,
                      subtotal: capturedSubtotal,
                      tax: capturedTax,
                      total: capturedTotal,
                      paymentMethod: paymentMethod,
                      paidAmount: paidAmount,
                      cashierId: _authService.currentUser?.id,
                    );
                    print('Save sale result: $result');

                    _clearCart();
                    await _refreshProducts();

                    if (mounted) {
                      try {
                        Navigator.pop(dialogContext);
                      } catch (e) {}
                    }

                    if (mounted) {
                      try {
                        Navigator.pop(dialogContext);
                      } catch (e) {}
                    }

                    if (mounted) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (successContext) {
                          return AlertDialog(
                            title: const Text(
                              'Sale Complete!',
                              style: TextStyle(fontSize: 14),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Invoice: ${result['invoiceNumber']}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  'Total: ₦${capturedTotal.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (result['change'] > 0)
                                  Text(
                                    'Change: ₦${result['change'].toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(successContext);
                                },
                                child: const Text(
                                  'OK',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(successContext);
                                  _printReceiptWithData(
                                    result['invoiceNumber'],
                                    capturedCart,
                                    capturedSubtotal,
                                    capturedTax,
                                    capturedTotal,
                                  );
                                },
                                child: const Text('Print Receipt'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: const Text(
                    'Complete Sale',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
