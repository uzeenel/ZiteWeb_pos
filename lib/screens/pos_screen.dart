import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:zite_web_pos/models/customer.dart';
import 'package:zite_web_pos/screens/credit_sales_approval_screen.dart';
import 'package:zite_web_pos/services/product_service.dart';
import 'package:zite_web_pos/services/customer_service.dart';
import 'package:zite_web_pos/services/company_service.dart';
import 'package:zite_web_pos/models/product.dart';
import 'package:zite_web_pos/models/cart_item.dart';
import 'package:zite_web_pos/screens/login_screen.dart';
import 'package:zite_web_pos/services/auth_service.dart';
import 'package:zite_web_pos/services/api_service.dart';
import 'package:window_manager/window_manager.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:zite_web_pos/utils/receipt_printer.dart';
import 'package:zite_web_pos/services/category_service.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

enum PrintOption { pos, invoice, both }

PrintOption _selectedPrintOption = PrintOption.pos;

class _POSScreenState extends State<POSScreen> {
  final ProductService _productService = ProductService();
  final CustomerService _customerService = CustomerService();
  final CompanyService _companyService = CompanyService();
  final AuthService _authService = AuthService();
  final FocusNode _skuFocusNode = FocusNode();

  Timer? _notificationTimer;

  List<Product> _products = [];
  final List<CartItem> _cart = [];
  List<Customer> _customers = [];
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  bool _vatEnabled = false;
  double _vatRate = 0;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];
  String _discountType = 'percent';
  final _discountController = TextEditingController();
  double _discountAmount = 0;

  double get _discountedTotal => _total - _discountAmount;

  final TextEditingController _skuController = TextEditingController();

  String get _currentCashierName =>
      _authService.currentUser?.fullName ?? 'CASHIER-01';

  @override
  void initState() {
    super.initState();
    print('Current user in POSScreen: ${_authService.currentUser?.username}');
    _loadData();
    _loadCustomers();
    _loadNotifications();
    _maximizeWindow();

    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadNotifications();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_skuFocusNode);
    });
  }

  @override
  void dispose() {
    _skuFocusNode.dispose();
    _skuController.dispose();
    _notificationTimer?.cancel();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _maximizeWindow() async {
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await windowManager.ensureInitialized();
        await windowManager.setTitle('ZiteMart POS System');
        await windowManager.setMinimumSize(const Size(1024, 768));
        await windowManager.maximize();
      });
    }
  }

  void _recalculateDiscount() {
    final value = double.tryParse(_discountController.text) ?? 0;
    setState(() {
      if (_discountType == 'percent') {
        _discountAmount = _subtotal * (value / 100);
      } else {
        _discountAmount = value;
      }
      if (_discountAmount > _subtotal) {
        _discountAmount = _subtotal;
      }
      if (_discountAmount < 0) {
        _discountAmount = 0;
      }
    });
  }

  Future<void> _printInvoiceA4(
    String invoiceNumber,
    List<CartItem> cart,
    double subtotal,
    double tax,
    double total, {
    Customer? customer,
    DateTime? dueDate,
    String paymentMethod = 'Cash',
    double depositAmount = 0,
    double discountAmount = 0,
  }) async {
    final company = await _companyService.getCompany();
    final companyName = company?.name ?? 'Your Company Name';
    final companyAddress = company?.address ?? '';
    final companyPhone = company?.phone ?? '';
    final companyLogo = company?.logoPath ?? '';

    final StringBuffer invoiceHtml = StringBuffer();
    invoiceHtml.writeln('''
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="UTF-8">
    <title>Invoice $invoiceNumber</title>
    <style>
      body { font-family: Arial, sans-serif; margin: 40px; }
      .no-print { text-align: center; margin-bottom: 20px; }
      .no-print button { padding: 10px 20px; font-size: 14px; margin: 0 5px; cursor: pointer; }
      h1 { text-align: center; }
      .company { text-align: center; margin-bottom: 20px; }
      .company-logo { max-width: 100px; max-height: 80px; margin-bottom: 8px; }
      .company h2 { margin: 0; }
      .info { margin-bottom: 20px; }
      table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
      th, td { border: 1px solid #000; padding: 8px; text-align: left; }
      th { background: #f0f0f0; }
      .totals { text-align: right; margin-top: 20px; }
      .footer { margin-top: 40px; font-size: 12px; color: #555; }
      .signature { margin-top: 60px; text-align: right; }
      .signature-line { border-top: 1px solid #000; width: 200px; margin-left: auto; }
      .terms { margin-top: 20px; font-size: 12px; }
      @media print {
        .no-print { display: none; }
      }
    </style>
  </head>
  <body>
    <div class="no-print">
      <button onclick="window.print()">🖨️ Print / Save as PDF</button>
      <button onclick="window.close()">❌ Close</button>
    </div>
    <div class="company">
''');

    // Add logo if exists
    if (companyLogo.isNotEmpty) {
      invoiceHtml.writeln('''
      <img src="http://localhost:3000$companyLogo" class="company-logo" alt="Company Logo" onerror="this.style.display='none'" />
''');
    }

    invoiceHtml.writeln('''
      <h2>${_escapeHtml(companyName)}</h2>
      <p>${_escapeHtml(companyAddress)}</p>
      <p>${_escapeHtml(companyPhone)}</p>
    </div>
    <h1>Sales Invoice</h1>
    <div class="info">
      <p><strong>Invoice No:</strong> ${_escapeHtml(invoiceNumber)}</p>
      <p><strong>Date:</strong> ${DateFormat('dd/MM/yyyy').format(DateTime.now())}</p>
      <p><strong>Cashier:</strong> ${_escapeHtml(_currentCashierName)}</p>
      <p><strong>Payment Method:</strong> ${_escapeHtml(paymentMethod)}</p>
      ${customer != null ? '''
        <p><strong>Customer:</strong> ${_escapeHtml(customer.name)}</p>
        ${customer.address != null ? '<p><strong>Address:</strong> ${_escapeHtml(customer.address!)}</p>' : ''}
        ${customer.phone != null ? '<p><strong>Phone:</strong> ${_escapeHtml(customer.phone!)}</p>' : ''}
        ${customer.email != null ? '<p><strong>Email:</strong> ${_escapeHtml(customer.email!)}</p>' : ''}
        ${customer.stateName != null ? '<p><strong>State:</strong> ${_escapeHtml(customer.stateName!)}</p>' : ''}
        ${customer.taxId != null ? '<p><strong>Tax ID:</strong> ${_escapeHtml(customer.taxId!)}</p>' : ''}
      ''' : ''}
    </div>
    <table>
      <thead>
        <tr><th>Item</th><th>Qty</th><th>Unit Price</th><th>Total</th></tr>
      </thead>
      <tbody>
  ''');

    for (var item in cart) {
      final itemTotal = item.product.sellingPrice * item.quantity;
      invoiceHtml.writeln(
        '<tr><td>${_escapeHtml(item.product.name)}</td><td>${item.quantity}</td><td>₦${item.product.sellingPrice.toStringAsFixed(2)}</td><td>₦${itemTotal.toStringAsFixed(2)}</td></tr>',
      );
    }

    invoiceHtml.writeln('''
      </tbody>
    </table>
    <div class="totals">
      <p><strong>Subtotal:</strong> ₦${subtotal.toStringAsFixed(2)}</p>
      ${tax > 0 ? '<p><strong>VAT (${_vatRate.toStringAsFixed(2)}%):</strong> ₦${tax.toStringAsFixed(2)}</p>' : ''}
      <p><strong>Grand Total:</strong> ₦${total.toStringAsFixed(2)}</p>
    </div>
    ${dueDate != null ? '''
      <div class="terms">
        <p><strong>Payment Terms:</strong> Payment due by ${DateFormat('dd/MM/yyyy').format(dueDate)}.</p>
        <p>Credit Days Allowed: ${customer?.creditDays ?? 0} days</p>
      </div>
    ''' : ''}
    <div class="footer">
      <p>Thank you for your business!</p>
      <p>Goods sold are not returnable.</p>
    </div>
    <div class="signature">
      <div class="signature-line"></div>
      <p>Authorized Signature</p>
    </div>
  </body>
  </html>
  ''');

    // Platform-specific output
    if (kIsWeb) {
      printReceiptWeb(invoiceHtml.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice opened in new tab'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'Invoice_${invoiceNumber.replaceAll('-', '_')}.html';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(invoiceHtml.toString());
      await Process.run('start', [file.path], runInShell: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice opened in browser'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _loadData() async {
    final products = await _productService.getAllProducts();

    // Fetch categories from API directly
    final categoryService = CategoryService();
    final categoriesList = await categoryService.getAllCategories();

    // Only show categories that have products
    final productCategoryIds = products.map((p) => p.categoryId).toSet();
    final categories = categoriesList
        .where((c) => productCategoryIds.contains(c.id))
        .map((c) => c.name)
        .toList();
    categories.sort();

    // Load company VAT settings
    final company = await _companyService.getCompany();

    setState(() {
      _products = products;
      _categories = ['All', ...categories];
      _vatEnabled = company?.vatEnabled ?? false;
      _vatRate = company?.vatRate ?? 0;
      _isLoading = false;
    });
  }

  Future<void> _loadCustomers() async {
    final customers = await _customerService.getAllCustomers();
    setState(() {
      _customers = customers.where((c) => c.isActive).toList();
    });
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await ApiService.getNotifications();
      final unreadCount = notifications
          .where((n) => n['is_read'] == 0 || n['is_read'] == false)
          .length;

      setState(() {
        _notifications = notifications;
        _unreadCount = unreadCount;
      });
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  Future<void> _refreshProducts() async {
    final products = await _productService.getAllProducts();
    final categoryService = CategoryService();
    final categoriesList = await categoryService.getAllCategories();

    final productCategoryIds = products.map((p) => p.categoryId).toSet();
    final categories = categoriesList
        .where((c) => productCategoryIds.contains(c.id))
        .map((c) => c.name)
        .toList();
    categories.sort();

    setState(() {
      _products = products;
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

    FocusScope.of(context).requestFocus(_skuFocusNode);
  }

  void _addBySku() async {
    if (_skuController.text.isEmpty) return;

    String input = _skuController.text.trim();
    int quantity = 1;
    String code = input;

    if (input.contains('*')) {
      final parts = input.split('*');
      if (parts.length == 2) {
        quantity = int.tryParse(parts[0]) ?? 1;
        code = parts[1];
      }
    }

    if (quantity < 1) quantity = 1;

    final product = await _productService.getProductBySku(code);

    if (product != null) {
      _addToCart(product, quantity: quantity);
      _skuController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product not found: "$code"'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }

    FocusScope.of(context).requestFocus(_skuFocusNode);
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
    if (!_vatEnabled || _vatRate <= 0) return 0;
    double tax = 0;
    for (var item in _cart) {
      if (!item.product.isVatExempt) {
        tax += item.subtotal * (_vatRate / 100);
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
      _discountController.clear();
      _discountAmount = 0;
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

  void _showNotificationsDialog() async {
    await _loadNotifications();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, localSetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder: (context, scrollController) => Container(
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
                    'Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Expanded(
                    child:
                        _notifications.where((n) => n['is_read'] == 0).isEmpty
                        ? const Center(child: Text('No unread notifications'))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _notifications
                                .where((n) => n['is_read'] == 0)
                                .length,
                            itemBuilder: (context, index) {
                              final unreadNotifications = _notifications
                                  .where((n) => n['is_read'] == 0)
                                  .toList();
                              final notification = unreadNotifications[index];
                              final isCreditApproved =
                                  notification['type'] == 'credit_approved';
                              final isCreditRejected =
                                  notification['type'] == 'credit_rejected';
                              final isCreditPending =
                                  notification['type'] == 'credit_pending';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: Colors.blue.shade50,
                                child: ListTile(
                                  leading: Icon(
                                    isCreditApproved
                                        ? Icons.check_circle
                                        : (isCreditRejected
                                              ? Icons.cancel
                                              : (isCreditPending
                                                    ? Icons.hourglass_empty
                                                    : Icons.info)),
                                    color: isCreditApproved
                                        ? Colors.green
                                        : (isCreditRejected
                                              ? Colors.red
                                              : (isCreditPending
                                                    ? Colors.orange
                                                    : Colors.blue)),
                                  ),
                                  title: Text(
                                    notification['title'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(notification['message']),
                                  trailing:
                                      (isCreditApproved ||
                                          isCreditRejected ||
                                          isCreditPending)
                                      ? ElevatedButton(
                                          onPressed: () async {
                                            await ApiService.markNotificationRead(
                                              notification['id'],
                                            );

                                            if (isCreditApproved) {
                                              try {
                                                final saleId = int.parse(
                                                  notification['reference_id']
                                                      .toString(),
                                                );
                                                await ApiService.completeCreditSale(
                                                  saleId,
                                                );
                                                await _loadNotifications();
                                                localSetState(() {});
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Credit sale completed! Stock deducted.',
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error: $e'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            } else if (isCreditPending) {
                                              Navigator.pop(context);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const CreditSalesApprovalScreen(),
                                                ),
                                              );
                                              return;
                                            }
                                            await _loadNotifications();
                                            if (mounted) {
                                              Navigator.pop(context);
                                              setState(() {});
                                            }
                                          },
                                          child: Text(
                                            isCreditApproved
                                                ? 'Release Products'
                                                : (isCreditPending
                                                      ? 'Review'
                                                      : 'OK'),
                                          ),
                                        )
                                      : null,
                                  onTap: () async {
                                    await ApiService.markNotificationRead(
                                      notification['id'],
                                    );
                                    await _loadNotifications();
                                    localSetState(() {});
                                    setState(() {});
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _printReceiptWithData(
    String invoiceNumber,
    List<CartItem> cart,
    double subtotal,
    double tax,
    double total, {
    String paymentMethod = 'Cash',
    double depositAmount = 0,
    double discountAmount = 0,
  }) async {
    final company = await _companyService.getCompany();
    final companyName = company?.name ?? 'Your Company Name';
    final companyAddress = company?.address ?? '';
    final companyPhone = company?.phone ?? '';
    final companyLogo = company?.logoPath ?? '';

    final StringBuffer receiptHtml = StringBuffer();
    receiptHtml.writeln('''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Receipt $invoiceNumber</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Courier New', monospace; background: white; margin: 0; padding: 0; }
        .receipt { width: 280px; margin: 0 auto; padding: 12px; background: white; }
        @media print { body { background: white; margin: 0; padding: 0; } .receipt { margin: 0; padding: 8px; } .no-print { display: none !important; } }
        .no-print { text-align: center; margin-bottom: 12px; padding-bottom: 8px; border-bottom: 1px solid #ddd; }
        .no-print button { padding: 6px 16px; margin: 0 5px; cursor: pointer; font-family: monospace; font-weight: bold; border: none; border-radius: 4px; font-size: 12px; }
        .no-print button:first-child { background: #4caf50; color: white; }
        .no-print button:last-child { background: #f44336; color: white; }
        .header { text-align: center; border-bottom: 1px dashed #aaa; padding-bottom: 8px; margin-bottom: 8px; }
        .company-logo { max-width: 80px; max-height: 60px; margin-bottom: 4px; }
        .company-name { font-size: 14px; font-weight: 800; text-transform: uppercase; }
        .company-address { font-size: 9px; color: #444; margin-top: 2px; }
        .company-phone { font-size: 9px; color: #444; }
        .receipt-title { text-align: center; font-size: 11px; font-weight: 800; margin: 8px 0; text-transform: uppercase; letter-spacing: 1px; }
        .info-section { margin-bottom: 10px; font-size: 10px; border-bottom: 1px dashed #aaa; padding-bottom: 6px; }
        .info-row { display: flex; justify-content: space-between; margin-bottom: 4px; }
        .info-label { font-weight: 600; }
        .items-table { width: 100%; margin: 8px 0; border-collapse: collapse; font-size: 10px; }
        .items-table th { text-align: left; font-weight: 800; padding: 4px 0; border-bottom: 1px solid #000; }
        .items-table td { padding: 4px 0; border-bottom: 1px dotted #ccc; }
        .items-table th:first-child, .items-table td:first-child { text-align: left; width: 45%; }
        .items-table th:nth-child(2), .items-table td:nth-child(2) { text-align: center; width: 15%; }
        .items-table th:nth-child(3), .items-table td:nth-child(3) { text-align: right; width: 20%; }
        .items-table th:last-child, .items-table td:last-child { text-align: right; width: 20%; }
        .totals { margin-top: 8px; padding-top: 8px; border-top: 1px solid #000; }
        .total-row { display: flex; justify-content: space-between; margin-bottom: 4px; font-size: 10px; }
        .grand-total { display: flex; justify-content: space-between; margin-top: 6px; padding-top: 6px; border-top: 1px dashed #000; font-size: 12px; font-weight: 800; }
        .layaway-section { margin-top: 6px; padding-top: 6px; border-top: 1px dashed #e65100; }
        .layaway-row { display: flex; justify-content: space-between; margin-bottom: 3px; font-size: 10px; }
        .layaway-row.balance { font-weight: 800; font-size: 11px; color: #e65100; }
        .layaway-note { text-align: center; font-size: 8px; color: #e65100; margin-top: 4px; font-weight: 600; }
        .footer { text-align: center; margin-top: 10px; padding-top: 8px; border-top: 1px dashed #aaa; font-size: 8px; color: #666; }
        .footer p { margin: 2px 0; }
        .thankyou { font-weight: 800; font-size: 9px; margin-top: 4px; }
        .barcode-section { text-align: center; margin-top: 8px; padding-top: 6px; border-top: 1px dashed #aaa; }
        .barcode { font-family: 'Libre Barcode 39', 'Code 39', 'Courier New', monospace; font-size: 36px; font-weight: normal; letter-spacing: 1px; margin: 4px 0; }
        .barcode-number { font-size: 8px; color: #666; margin-top: 2px; }
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
''');

    // Add logo if exists
    if (companyLogo.isNotEmpty) {
      receiptHtml.writeln('''
            <img src="http://localhost:3000$companyLogo" class="company-logo" alt="Company Logo" onerror="this.style.display='none'" />
''');
    }

    receiptHtml.writeln('''
            <div class="company-name">${_escapeHtml(companyName)}</div>
            ${companyAddress.isNotEmpty ? '<div class="company-address">${_escapeHtml(companyAddress)}</div>' : ''}
            ${companyPhone.isNotEmpty ? '<div class="company-phone">Tel: ${_escapeHtml(companyPhone)}</div>' : ''}
        </div>
        <div class="receipt-title">SALES RECEIPT</div>
        <div class="info-section">
            <div class="info-row"><span class="info-label">INVOICE NO:</span><span>${_escapeHtml(invoiceNumber)}</span></div>
            <div class="info-row"><span class="info-label">DATE:</span><span>${DateTime.now().toString().substring(0, 16).replaceAll('T', ' ')}</span></div>
            <div class="info-row"><span class="info-label">CASHIER:</span><span>${_escapeHtml(_currentCashierName)}</span></div>
            <div class="info-row"><span class="info-label">PAYMENT:</span><span>${_escapeHtml(paymentMethod)}</span></div>
        </div>
        <table class="items-table">
            <thead><tr><th>ITEM</th><th>QTY</th><th>PRICE</th><th>TOTAL</th></tr></thead>
            <tbody>
''');
    for (var item in cart) {
      final itemTotal = item.product.sellingPrice * item.quantity;
      receiptHtml.writeln(
        '<tr><td class="item-name">${_escapeHtml(item.product.name)}</td><td style="text-align: center;">${item.quantity}</td><td style="text-align: right;">₦${item.product.sellingPrice.toStringAsFixed(2)}</td><td style="text-align: right;">₦${itemTotal.toStringAsFixed(2)}</td></tr>',
      );
    }
    receiptHtml.writeln('''
            </tbody>
        </table>
            <div class="totals">
            <div class="total-row"><span>SUBTOTAL:</span><span>₦${subtotal.toStringAsFixed(2)}</span></div>
            ${discountAmount > 0 ? '<div class="total-row" style="color:#c00;"><span>DISCOUNT:</span><span>-₦${discountAmount.toStringAsFixed(2)}</span></div>' : ''}
            ${tax > 0 ? '<div class="total-row"><span>VAT (${_vatRate.toStringAsFixed(2)}%):</span><span>₦${tax.toStringAsFixed(2)}</span></div>' : ''}
            <div class="grand-total"><span>TOTAL:</span><span>₦${total.toStringAsFixed(2)}</span></div>
''');

    if (paymentMethod == 'Layaway' && depositAmount > 0) {
      final balance = total - depositAmount;
      receiptHtml.writeln('''
        </div>
        <div class="layaway-section">
            <div class="layaway-row"><span>DEPOSIT PAID:</span><span>₦${depositAmount.toStringAsFixed(2)}</span></div>
            <div class="layaway-row balance"><span>BALANCE DUE:</span><span>₦${balance.toStringAsFixed(2)}</span></div>
            <div class="layaway-note">📦 Layaway - Pay balance before collection</div>
        </div>
''');
    } else {
      receiptHtml.writeln('''
        </div>
''');
    }

    receiptHtml.writeln('''
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

    // Platform-specific output
    if (kIsWeb) {
      printReceiptWeb(receiptHtml.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt opened in new tab'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'Receipt_${invoiceNumber.replaceAll('-', '_')}.html';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(receiptHtml.toString());
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
    final TextEditingController depositController = TextEditingController();
    final TextEditingController pinController = TextEditingController();
    String paymentMethod = 'Cash';
    Customer? selectedCustomer;
    DateTime dueDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              constraints: BoxConstraints(maxWidth: 600),
              title: const Text('Checkout', style: TextStyle(fontSize: 16)),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<PrintOption>(
                        initialValue: _selectedPrintOption,
                        decoration: const InputDecoration(
                          labelText: "Print Option",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: PrintOption.pos,
                            child: Text('POS Receipt'),
                          ),
                          DropdownMenuItem(
                            value: PrintOption.invoice,
                            child: Text("Sales Invoice"),
                          ),
                          DropdownMenuItem(
                            value: PrintOption.both,
                            child: Text('Both'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedPrintOption = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      if (paymentMethod == 'Credit')
                        DropdownButtonFormField<Customer>(
                          decoration: const InputDecoration(
                            labelText: 'Customer *',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          initialValue: selectedCustomer,
                          hint: const Text('Select Customer'),
                          isExpanded: true,
                          items: _customers.map((c) {
                            final availableCredit =
                                c.creditLimit - c.currentBalance;
                            return DropdownMenuItem(
                              value: c,
                              child: Text(
                                '${c.name} (Limit: ₦${c.creditLimit.toStringAsFixed(0)} | Avail: ₦${availableCredit.toStringAsFixed(0)})',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => selectedCustomer = value),
                        ),
                      if (paymentMethod == 'Credit' && selectedCustomer != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: dueDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (date != null) setState(() => dueDate = date);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Due Date',
                                border: OutlineInputBorder(),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(dueDate),
                                  ),
                                  const Icon(Icons.calendar_today, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        'Subtotal: ₦${_subtotal.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        'VAT: ₦${_tax.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (_discountAmount > 0) ...[
                        Text(
                          'Dicount: -₦${_discountAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 0),
                        TextField(
                          controller: pinController,
                          decoration: const InputDecoration(
                            labelText: 'Discount PIN *',
                            helperText:
                                'Enter the PIN issued by the manager for this discount',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.vpn_key),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                        ),
                      ],
                      const Divider(),
                      Text(
                        'Total: ₦${_discountedTotal.toStringAsFixed(0)}',
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
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 0,
                        runSpacing: 0,
                        children: [
                          SizedBox(
                            width: 95, // Changed from 80 to 95
                            child: RadioListTile(
                              title: const Text(
                                'Cash',
                                style: TextStyle(fontSize: 11),
                              ),
                              value: 'Cash',
                              groupValue: paymentMethod,
                              onChanged: (value) => setState(() {
                                paymentMethod = value.toString();
                                selectedCustomer = null;
                              }),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              visualDensity: const VisualDensity(
                                horizontal: -4,
                                vertical: -4,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 95, // Changed from 80 to 95
                            child: RadioListTile(
                              title: const Text(
                                'Card',
                                style: TextStyle(fontSize: 11),
                              ),
                              value: 'Card',
                              groupValue: paymentMethod,
                              onChanged: (value) => setState(() {
                                paymentMethod = value.toString();
                                selectedCustomer = null;
                              }),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              visualDensity: const VisualDensity(
                                horizontal: -4,
                                vertical: -4,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 95, // Changed from 80 to 95
                            child: RadioListTile(
                              title: const Text(
                                'Transfer',
                                style: TextStyle(fontSize: 11),
                              ),
                              value: 'Transfer',
                              groupValue: paymentMethod,
                              onChanged: (value) => setState(() {
                                paymentMethod = value.toString();
                                selectedCustomer = null;
                              }),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              visualDensity: const VisualDensity(
                                horizontal: -4,
                                vertical: -4,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 95, // Changed from 80 to 95
                            child: RadioListTile(
                              title: const Text(
                                'Credit',
                                style: TextStyle(fontSize: 11),
                              ),
                              value: 'Credit',
                              groupValue: paymentMethod,
                              onChanged: (value) => setState(() {
                                paymentMethod = value.toString();
                              }),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              visualDensity: const VisualDensity(
                                horizontal: -4,
                                vertical: -4,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 95, // Changed from 80 to 95
                            child: RadioListTile(
                              title: const Text(
                                'Layaway',
                                style: TextStyle(fontSize: 11),
                              ),
                              value: 'Layaway',
                              groupValue: paymentMethod,
                              onChanged: (value) => setState(() {
                                paymentMethod = value.toString();
                                selectedCustomer = null;
                              }),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              visualDensity: const VisualDensity(
                                horizontal: -4,
                                vertical: -4,
                              ),
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
                      if (paymentMethod == 'Layaway') ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: depositController,
                          decoration: const InputDecoration(
                            labelText: 'Deposit Amount ₦',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '📦 Layaway',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Balance after deposit: ₦${(_total - (double.tryParse(depositController.text) ?? 0)).toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              Text(
                                'Goods will be released when fully paid.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (paymentMethod == 'Credit' && selectedCustomer != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '⚠️ Credit Sale',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Available Credit: ₦${((selectedCustomer!.creditLimit - selectedCustomer!.currentBalance)).toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                Text(
                                  'This sale requires manager/Admin approval',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange.shade700,
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Checkout logic
                    if (paymentMethod == 'Credit') {
                      if (selectedCustomer == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please select a customer for credit sale',
                            ),
                          ),
                        );
                        return;
                      }
                      final availableCredit =
                          selectedCustomer!.creditLimit -
                          selectedCustomer!.currentBalance;
                      if (_total > availableCredit) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Credit limit exceeded! Available credit: ₦${availableCredit.toStringAsFixed(2)}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                    }

                    if (_discountAmount > 0 &&
                        pinController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter the discount PIN'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (paymentMethod == 'Layaway') {
                      final deposit =
                          double.tryParse(depositController.text) ?? 0;
                      if (deposit <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a deposit amount'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (deposit > _total) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Deposit cannot exceed total amount'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                    }

                    double paidAmount = _discountedTotal;
                    if (paymentMethod == 'Cash' &&
                        cashController.text.isNotEmpty) {
                      paidAmount =
                          double.tryParse(cashController.text) ??
                          _discountedTotal;
                    }

                    final capturedCart = List<CartItem>.from(_cart);
                    final capturedSubtotal = _subtotal;
                    final capturedTax = _tax;
                    final capturedTotal = _discountedTotal;
                    final capturedPaymentMethod = paymentMethod;
                    final capturedCustomer = selectedCustomer;
                    final capturedDueDate = dueDate;
                    final capturedDeposit =
                        double.tryParse(depositController.text) ?? 0;
                    final capturedDiscountType = _discountAmount > 0
                        ? _discountType
                        : null;
                    final capturedDiscountValue = _discountAmount > 0
                        ? double.tryParse(_discountController.text)
                        : null;
                    final capturedDiscountPin = _discountAmount > 0
                        ? pinController.text.trim()
                        : null;
                    final capturedDiscountAmount = _discountAmount;

                    showDialog(
                      context: dialogContext,
                      barrierDismissible: false,
                      builder: (loadingContext) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      final result = await ApiService.saveSale(
                        cart: capturedCart,
                        subtotal: capturedSubtotal,
                        tax: capturedTax,
                        total: capturedTotal,
                        paymentMethod: capturedPaymentMethod == 'Layaway'
                            ? 'Layaway'
                            : capturedPaymentMethod,
                        paidAmount: capturedPaymentMethod == 'Layaway'
                            ? capturedDeposit
                            : paidAmount,
                        cashierId: _authService.currentUser?.id,
                        customerId: capturedPaymentMethod == 'Credit'
                            ? capturedCustomer?.id
                            : null,
                        discountType: capturedDiscountType,
                        discountValue: capturedDiscountValue,
                        discountPin: capturedDiscountPin,
                      );

                      if (capturedPaymentMethod == 'Credit' &&
                          capturedCustomer != null) {
                        final saleId = result['saleId'];
                        if (saleId == null) {
                          throw Exception(
                            'Sale ID is null - cannot create credit sale',
                          );
                        }

                        final itemsWithDetails = capturedCart
                            .map(
                              (item) => ({
                                'product_id': item.product.id,
                                'product_name': item.product.name,
                                'quantity': item.quantity,
                                'unit_price': item.product.sellingPrice,
                              }),
                            )
                            .toList();

                        await ApiService.createCreditSale({
                          'sale_id': saleId,
                          'customer_id': capturedCustomer.id,
                          'invoice_number': result['invoiceNumber'],
                          'total': capturedTotal,
                          'due_date': capturedDueDate.toIso8601String().split(
                            'T',
                          )[0],
                          'items': jsonEncode(itemsWithDetails),
                        });
                      }

                      if (capturedPaymentMethod == 'Layaway') {
                        // Create layaway record
                        await ApiService.createLayaway({
                          'saleId': result['saleId'],
                          'customerId': capturedCustomer?.id,
                          'invoiceNumber': result['invoiceNumber'],
                          'totalAmount': capturedTotal,
                          'depositAmount': capturedDeposit,
                          'items': jsonEncode(
                            capturedCart
                                .map(
                                  (item) => ({
                                    'product_id': item.product.id,
                                    'product_name': item.product.name,
                                    'quantity': item.quantity,
                                    'unit_price': item.product.sellingPrice,
                                  }),
                                )
                                .toList(),
                          ),
                        });
                      }

                      _clearCart();
                      await _refreshProducts();

                      if (mounted) {
                        try {
                          Navigator.pop(dialogContext);
                        } catch (e) {}
                        try {
                          Navigator.pop(dialogContext);
                        } catch (e) {}
                      }

                      if (mounted) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (successContext) => AlertDialog(
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
                                if (capturedPaymentMethod == 'Credit')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      '⚠️ Credit sale pending approval',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ),
                                if (capturedPaymentMethod == 'Layaway')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      '📦 Layaway created! Deposit: ₦${capturedDeposit.toStringAsFixed(0)}. Balance: ₦${(capturedTotal - capturedDeposit).toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(successContext),
                                child: const Text(
                                  'OK',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              if (capturedPaymentMethod != 'Credit') ...[
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(successContext);

                                    switch (_selectedPrintOption) {
                                      case PrintOption.pos:
                                        _printReceiptWithData(
                                          result['invoiceNumber'],
                                          capturedCart,
                                          capturedSubtotal,
                                          capturedTax,
                                          capturedTotal,
                                          paymentMethod: capturedPaymentMethod,
                                          depositAmount: capturedDeposit,
                                          discountAmount:
                                              capturedDiscountAmount,
                                        );
                                        break;
                                      case PrintOption.invoice:
                                        _printInvoiceA4(
                                          result['invoiceNumber'],
                                          capturedCart,
                                          capturedSubtotal,
                                          capturedTax,
                                          capturedTotal,
                                          paymentMethod: capturedPaymentMethod,
                                          depositAmount: capturedDeposit,
                                          discountAmount:
                                              capturedDiscountAmount,
                                        );
                                        break;
                                      case PrintOption.both:
                                        _printReceiptWithData(
                                          result['invoiceNumber'],
                                          capturedCart,
                                          capturedSubtotal,
                                          capturedTax,
                                          capturedTotal,
                                          paymentMethod: capturedPaymentMethod,
                                          depositAmount: capturedDeposit,
                                          discountAmount:
                                              capturedDiscountAmount,
                                        );
                                        _printInvoiceA4(
                                          result['invoiceNumber'],
                                          capturedCart,
                                          capturedSubtotal,
                                          capturedTax,
                                          capturedTotal,
                                          discountAmount:
                                              capturedDiscountAmount,
                                        );
                                        break;
                                    }
                                  },
                                  child: const Text('Print'),
                                ),
                              ],
                            ],
                          ),
                        );
                      }
                    } catch (e) {
                      print('Error saving sale: $e');
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sale', style: TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF1e3a8a),
        foregroundColor: Colors.white,
        toolbarHeight: 56,
        actions: [
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
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications, color: Colors.white),
                if (_unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '$_unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showNotificationsDialog,
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProducts,
            tooltip: 'Refresh Stock',
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, size: 24),
                onPressed: _showCartDialog,
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
      body: Container(
        color: Colors.grey.shade100,
        child: Column(
          children: [
            // Categories Section
            Container(
              color: Colors.grey.shade200,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category label
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1e3a8a),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1e3a8a),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_categories.length - 1}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Category chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return FilterChip(
                        label: Text(
                          category,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = category),
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFF1e3a8a),
                        checkmarkColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF1e3a8a)
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            // Main Content with Dark Overlay
            Expanded(
              child: Stack(
                children: [
                  // Main content Row
                  Row(
                    children: [
                      // Products Section
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            // Search row
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        hintText: 'Search by name...',
                                        prefixIcon: Icon(
                                          Icons.search,
                                          size: 20,
                                        ),
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        isDense: true,
                                        fillColor: Colors.white,
                                        filled: true,
                                      ),
                                      onChanged: (value) =>
                                          setState(() => _searchQuery = value),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: _skuController,
                                      focusNode: _skuFocusNode,
                                      decoration: const InputDecoration(
                                        hintText: 'QTY*SKU or BARCODE',
                                        prefixIcon: Icon(
                                          Icons.qr_code,
                                          size: 20,
                                        ),
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        isDense: true,
                                        fillColor: Colors.white,
                                        filled: true,
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
                                    child: const Text('Add'),
                                  ),
                                ],
                              ),
                            ),
                            // Products grid
                            Expanded(
                              child: _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : _filteredProducts.isEmpty
                                  ? const Center(
                                      child: Text('No products found'),
                                    )
                                  : GridView.builder(
                                      padding: const EdgeInsets.all(8),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 6,
                                            childAspectRatio: 0.75,
                                            crossAxisSpacing: 8,
                                            mainAxisSpacing: 8,
                                          ),
                                      itemCount: _filteredProducts.length,
                                      itemBuilder: (context, index) {
                                        final product =
                                            _filteredProducts[index];
                                        final isLowStock =
                                            product.stockQuantity < 10;
                                        final isOutOfStock =
                                            product.stockQuantity <= 0;
                                        final cartItem = _cart.firstWhere(
                                          (item) =>
                                              item.product.id == product.id,
                                          orElse: () => CartItem(
                                            product: product,
                                            quantity: 0,
                                          ),
                                        );
                                        return Card(
                                          elevation: 4,
                                          color: isOutOfStock
                                              ? Colors.grey.shade300
                                              : Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            side: isOutOfStock
                                                ? BorderSide(
                                                    color: Colors.grey.shade400,
                                                    width: 1,
                                                  )
                                                : BorderSide(
                                                    color: Colors.grey.shade200,
                                                    width: 1,
                                                  ),
                                          ),
                                          child: InkWell(
                                            onTap: isOutOfStock
                                                ? null
                                                : () => _addToCart(product),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            splashColor: Colors.blue.shade100,
                                            highlightColor: Colors.blue.shade50,
                                            child: Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  // Product image or fallback icon
                                                  product.imageUrl != null &&
                                                          product
                                                              .imageUrl!
                                                              .isNotEmpty
                                                      ? ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          child: Image.network(
                                                            product.imageUrl!,
                                                            width: 50,
                                                            height: 50,
                                                            fit: BoxFit.cover,
                                                            errorBuilder: (_, __, ___) => Icon(
                                                              Icons
                                                                  .shopping_cart,
                                                              size: 40,
                                                              color:
                                                                  isOutOfStock
                                                                  ? Colors
                                                                        .grey
                                                                        .shade500
                                                                  : Colors
                                                                        .blue
                                                                        .shade700,
                                                            ),
                                                          ),
                                                        )
                                                      : Icon(
                                                          Icons.shopping_cart,
                                                          size: 40,
                                                          color: isOutOfStock
                                                              ? Colors
                                                                    .grey
                                                                    .shade500
                                                              : Colors
                                                                    .blue
                                                                    .shade700,
                                                        ),
                                                  const SizedBox(height: 6),
                                                  Flexible(
                                                    child: Text(
                                                      product.name,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 11,
                                                        color: isOutOfStock
                                                            ? Colors
                                                                  .grey
                                                                  .shade600
                                                            : Colors.black87,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: isOutOfStock
                                                          ? Colors.grey.shade300
                                                          : Colors
                                                                .green
                                                                .shade700,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '₦${product.sellingPrice.toStringAsFixed(0)}',
                                                      style: TextStyle(
                                                        color: isOutOfStock
                                                            ? Colors
                                                                  .grey
                                                                  .shade600
                                                            : Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  if (isOutOfStock)
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.red.shade600,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: const Text(
                                                        'OUT OF STOCK',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    )
                                                  else if (isLowStock)
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .orange
                                                            .shade600,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        'Stock: ${product.stockQuantity.toStringAsFixed(0)}',
                                                        style: const TextStyle(
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    )
                                                  else
                                                    Text(
                                                      'Stock: ${product.stockQuantity.toStringAsFixed(0)}',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                    ),
                                                  if (cartItem.quantity > 0 &&
                                                      !isOutOfStock)
                                                    Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                            top: 4,
                                                          ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .blue
                                                            .shade700,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        '${cartItem.quantity} in cart',
                                                        style: const TextStyle(
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
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
                      ),
                      // Cart Sidebar
                      Container(
                        width: 320,
                        color: Colors.grey.shade200,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              color: const Color(0xFF1e3a8a),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.shopping_cart,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Shopping Cart (${_cart.length})',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: _cart.isEmpty
                                  ? const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.shopping_cart,
                                            size: 64,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'Cart is empty',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
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
                                          child: ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor:
                                                  Colors.blue.shade100,
                                              child: Text(
                                                '${item.quantity}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              item.product.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            subtitle: Text(
                                              '₦${item.product.sellingPrice.toStringAsFixed(0)} each',
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.remove_circle_outline,
                                                  ),
                                                  onPressed: () =>
                                                      _updateCartQuantity(
                                                        item,
                                                        item.quantity - 1,
                                                      ),
                                                ),
                                                Text(
                                                  '₦${item.subtotal.toStringAsFixed(0)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () =>
                                                      _removeFromCart(item),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(16),
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
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Subtotal:'),
                                      Text(
                                        '₦${_subtotal.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('VAT (7.5%):'),
                                      Text('₦${_tax.toStringAsFixed(0)}'),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 90,
                                        child: DropdownButtonFormField<String>(
                                          value: _discountType,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 8,
                                                ),
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'percent',
                                              child: Text(
                                                '%',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                            DropdownMenuItem(
                                              value: 'amount',
                                              child: Text(
                                                '₦',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          ],
                                          onChanged: (v) {
                                            setState(
                                              () => _discountType =
                                                  v ?? 'percent',
                                            );
                                            _recalculateDiscount();
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: TextField(
                                          controller: _discountController,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            hintText: 'Discount',
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 10,
                                                ),
                                          ),
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          onChanged: (_) =>
                                              _recalculateDiscount(),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_discountAmount > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Discount:',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                          Text(
                                            '-₦${_discountAmount.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        '₦${_total.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _cart.isEmpty
                                          ? null
                                          : _showCheckoutDialog,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      child: const Text('Checkout'),
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
                  // Dark overlay when cart has items
                  if (_cart.isNotEmpty)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
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
