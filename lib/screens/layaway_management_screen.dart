import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zite_web_pos/models/layaway.dart';
import 'package:zite_web_pos/services/layaway_service.dart';
import 'package:zite_web_pos/services/api_service.dart';
import 'package:zite_web_pos/screens/unauthorized_screen.dart';
import 'package:zite_web_pos/utils/permissions.dart';
import 'package:zite_web_pos/services/company_service.dart';

enum PrintOption { pos, invoice, both }

class LayawayScreen extends StatefulWidget {
  const LayawayScreen({super.key});

  @override
  State<LayawayScreen> createState() => _LayawayScreenState();
}

class _LayawayScreenState extends State<LayawayScreen> {
  final LayawayService _layawayService = LayawayService();
  final CompanyService _companyService = CompanyService();
  List<LayawayOrder> _layawayOrders = [];
  bool _isLoading = false;
  String _filterStatus = 'all';
  Map<int, Map<String, dynamic>> _saleDetails = {};
  Map<int, List<LayawayPayment>> _paymentHistory = {};

  final _currencyFormat = NumberFormat("#,##0.00");
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final _shortDateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _loadLayawayOrders();
  }

  Future<void> _loadLayawayOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _layawayService.getLayawayOrders();
      setState(() {
        _layawayOrders = orders;
        _isLoading = false;
      });

      // Load sale details and payments for each order
      for (final order in orders) {
        await _loadSaleDetails(order.saleId, order.id);
        await _loadPaymentHistory(order.id);
      }
    } catch (e) {
      print('Error loading layaway orders: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSaleDetails(int saleId, int orderId) async {
    try {
      final response = await ApiService.getSaleDetail(saleId);

      final sale = response['sale'];
      final items = response['items'] ?? [];

      setState(() {
        _saleDetails[orderId] = {'sale': sale, 'items': items};
      });
    } catch (e) {
      print('Error loading sale details for order $orderId: $e');
    }
  }

  Future<void> _loadPaymentHistory(int orderId) async {
    try {
      final payments = await _layawayService.getLayawayPayments(orderId);
      setState(() {
        _paymentHistory[orderId] = payments;
      });
    } catch (e) {
      print('Error loading payment history for order $orderId: $e');
    }
  }

  Future<void> _recordPayment(LayawayOrder order) async {
    final amountController = TextEditingController();
    String paymentMethod = 'cash';
    PrintOption _selectedPrintOption = PrintOption.pos; // Add this

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Record Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Balance: ₦${_currencyFormat.format(order.balance)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                // Print Option Dropdown - ADDED
                DropdownButtonFormField<PrintOption>(
                  value: _selectedPrintOption,
                  decoration: const InputDecoration(
                    labelText: 'Print Option',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: PrintOption.pos,
                      child: Text('POS Receipt'),
                    ),
                    DropdownMenuItem(
                      value: PrintOption.invoice,
                      child: Text('Sales Invoice'),
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
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    prefixText: '₦',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'card', child: Text('Card')),
                    DropdownMenuItem(
                      value: 'transfer',
                      child: Text('Transfer'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => paymentMethod = value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text);
                  if (amount != null && amount > 0) {
                    if (amount > order.balance) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Amount cannot exceed balance'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context, {
                      'amount': amount,
                      'paymentMethod': paymentMethod,
                      'printOption': _selectedPrintOption,
                    });
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Record Payment'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      final amount = result['amount'] as double;
      final paymentMethod = result['paymentMethod'] as String;
      final printOption = result['printOption'] as PrintOption;
      await _processPayment(order.id, amount, paymentMethod, printOption);
    }
  }

  Future<void> _processPayment(
    int orderId,
    double amount,
    String paymentMethod,
    PrintOption printOption,
  ) async {
    setState(() => _isLoading = true);
    try {
      await _layawayService.recordPayment(orderId, amount, paymentMethod);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment of ₦${_currencyFormat.format(amount)} recorded',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Get the order details for printing
      final order = _layawayOrders.firstWhere((o) => o.id == orderId);

      // Print based on selected option
      switch (printOption) {
        case PrintOption.pos:
          await _printLayawayReceipt(order, amount, paymentMethod);
          break;
        case PrintOption.invoice:
          await _printLayawayInvoice(order, amount, paymentMethod);
          break;
        case PrintOption.both:
          await _printLayawayReceipt(order, amount, paymentMethod);
          await _printLayawayInvoice(order, amount, paymentMethod);
          break;
      }

      await _loadLayawayOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeLayaway(int orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Layaway'),
        content: const Text('Are you sure you want to complete this layaway?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _layawayService.completeLayaway(orderId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Layaway completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadLayawayOrders();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelLayaway(int orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Layaway'),
        content: const Text('Are you sure you want to cancel this layaway?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _layawayService.cancelLayaway(orderId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Layaway cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadLayawayOrders();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _printLayawayReceipt(
    LayawayOrder order,
    double amount,
    String paymentMethod,
  ) async {
    try {
      final company = await _companyService
          .getCompany(); // You'll need to add CompanyService
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
    <title>Layaway Payment Receipt</title>
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
        .payment-section { margin-top: 8px; padding-top: 8px; border-top: 1px solid #000; }
        .payment-row { display: flex; justify-content: space-between; margin-bottom: 4px; font-size: 10px; }
        .payment-total { display: flex; justify-content: space-between; margin-top: 6px; padding-top: 6px; border-top: 1px dashed #000; font-size: 12px; font-weight: 800; }
        .layaway-section { margin-top: 6px; padding-top: 6px; border-top: 1px dashed #e65100; }
        .layaway-row { display: flex; justify-content: space-between; margin-bottom: 3px; font-size: 10px; }
        .layaway-row.balance { font-weight: 800; font-size: 11px; color: #e65100; }
        .layaway-note { text-align: center; font-size: 8px; color: #e65100; margin-top: 4px; font-weight: 600; }
        .footer { text-align: center; margin-top: 10px; padding-top: 8px; border-top: 1px dashed #aaa; font-size: 8px; color: #666; }
        .footer p { margin: 2px 0; }
        .thankyou { font-weight: 800; font-size: 9px; margin-top: 4px; }
    </style>
</head>
<body>
    <div class="receipt">
        <div class="no-print">
            <button onclick="window.print()">🖨️ PRINT</button>
            <button onclick="window.close()">✖ CLOSE</button>
        </div>
        <div class="header">
''');

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
        <div class="receipt-title">LAYAWAY PAYMENT RECEIPT</div>
        <div class="info-section">
            <div class="info-row"><span class="info-label">INVOICE:</span><span>${_escapeHtml(order.invoiceNumber)}</span></div>
            <div class="info-row"><span class="info-label">DATE:</span><span>${_dateFormat.format(DateTime.now())}</span></div>
            <div class="info-row"><span class="info-label">PAYMENT:</span><span>${_escapeHtml(paymentMethod.toUpperCase())}</span></div>
        </div>
        <div class="payment-section">
            <div class="payment-row"><span>Payment Amount:</span><span>₦${_currencyFormat.format(amount)}</span></div>
            <div class="payment-total"><span>TOTAL PAID:</span><span>₦${_currencyFormat.format(order.paidAmount + amount)}</span></div>
        </div>
        <div class="layaway-section">
            <div class="layaway-row"><span>Total Amount:</span><span>₦${_currencyFormat.format(order.totalAmount)}</span></div>
            <div class="layaway-row balance"><span>Remaining Balance:</span><span>₦${_currencyFormat.format(order.balance - amount)}</span></div>
            <div class="layaway-note">📦 Layaway - Pay balance before collection</div>
        </div>
        <div class="footer">
            <p>Thank you for your payment!</p>
            <p>Balance must be cleared before pickup</p>
            <p class="thankyou">★★★★★ COME AGAIN ★★★★★</p>
        </div>
    </div>
</body>
</html>
''');

      // Open in browser
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'Layaway_Payment_${order.invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.html';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(receiptHtml.toString());
      await Process.run('start', [file.path], runInShell: true);
    } catch (e) {
      print('Error printing layaway receipt: $e');
    }
  }

  Future<void> _printLayawayInvoice(
    LayawayOrder order,
    double amount,
    String paymentMethod,
  ) async {
    try {
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
    <title>Layaway Payment Invoice</title>
    <style>
      body { font-family: Arial, sans-serif; margin: 40px; }
      .no-print { text-align: center; margin-bottom: 20px; }
      .no-print button { padding: 10px 20px; font-size: 14px; margin: 0 5px; cursor: pointer; }
      .company { text-align: center; margin-bottom: 20px; }
      .company-logo { max-width: 100px; max-height: 80px; margin-bottom: 8px; }
      .company h2 { margin: 0; }
      .info { margin-bottom: 20px; }
      .payment-section { margin-top: 20px; padding-top: 20px; border-top: 1px solid #000; }
      .payment-row { display: flex; justify-content: space-between; margin-bottom: 8px; font-size: 14px; }
      .payment-total { display: flex; justify-content: space-between; margin-top: 10px; padding-top: 10px; border-top: 2px solid #000; font-size: 16px; font-weight: bold; }
      .layaway-section { margin-top: 20px; padding: 15px; background: #fff3e0; border-radius: 8px; }
      .layaway-row { display: flex; justify-content: space-between; margin-bottom: 4px; font-size: 13px; }
      .layaway-row.balance { font-weight: 800; font-size: 15px; color: #e65100; }
      .footer { margin-top: 40px; font-size: 12px; color: #555; }
      .signature { margin-top: 60px; text-align: right; }
      .signature-line { border-top: 1px solid #000; width: 200px; margin-left: auto; }
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
    <h1>Layaway Payment Invoice</h1>
    <div class="info">
      <p><strong>Invoice No:</strong> ${_escapeHtml(order.invoiceNumber)}</p>
      <p><strong>Date:</strong> ${_dateFormat.format(DateTime.now())}</p>
      <p><strong>Payment Method:</strong> ${_escapeHtml(paymentMethod.toUpperCase())}</p>
    </div>
    <div class="payment-section">
      <div class="payment-row"><span>Payment Amount:</span><span>₦${_currencyFormat.format(amount)}</span></div>
      <div class="payment-total"><span>Total Paid to Date:</span><span>₦${_currencyFormat.format(order.paidAmount + amount)}</span></div>
    </div>
    <div class="layaway-section">
      <h3>📦 Layaway Summary</h3>
      <div class="layaway-row"><span>Total Amount:</span><span>₦${_currencyFormat.format(order.totalAmount)}</span></div>
      <div class="layaway-row"><span>Deposit Paid:</span><span>₦${_currencyFormat.format(order.depositAmount)}</span></div>
      <div class="layaway-row"><span>Previous Payments:</span><span>₦${_currencyFormat.format(order.paidAmount)}</span></div>
      <div class="layaway-row balance"><span>Remaining Balance:</span><span>₦${_currencyFormat.format(order.balance - amount)}</span></div>
    </div>
    <div class="footer">
      <p>Thank you for your payment!</p>
      <p>Balance must be cleared before pickup.</p>
    </div>
    <div class="signature">
      <div class="signature-line"></div>
      <p>Authorized Signature</p>
    </div>
  </body>
  </html>
''');

      // Open in browser
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'Layaway_Invoice_${order.invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.html';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(invoiceHtml.toString());
      await Process.run('start', [file.path], runInShell: true);
    } catch (e) {
      print('Error printing layaway invoice: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Permissions.canManageLayaway) {
      return const UnauthorizedScreen();
    }

    final filteredOrders = _filterStatus == 'all'
        ? _layawayOrders
        : _layawayOrders
              .where((order) => order.status == _filterStatus)
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Layaway Orders', style: TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF1e3a8a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLayawayOrders,
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
                      const Text('Filter:'),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _filterStatus,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(
                            value: 'deposit_paid',
                            child: Text('Deposit Paid'),
                          ),
                          DropdownMenuItem(
                            value: 'partial',
                            child: Text('Partial'),
                          ),
                          DropdownMenuItem(
                            value: 'completed',
                            child: Text('Completed'),
                          ),
                          DropdownMenuItem(
                            value: 'cancelled',
                            child: Text('Cancelled'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _filterStatus = value!),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredOrders.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text('No layaway orders found'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = filteredOrders[index];
                            final statusColor = _getStatusColor(order.status);
                            final statusText = _getStatusText(order.status);

                            // Get sale details
                            final saleDetail = _saleDetails[order.id];
                            final sale = saleDetail?['sale'];
                            final items = saleDetail?['items'] ?? [];
                            final payments = _paymentHistory[order.id] ?? [];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              child: ExpansionTile(
                                leading: Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getStatusIcon(order.status),
                                    color: statusColor,
                                  ),
                                ),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.invoiceNumber,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      'Total: ₦${_currencyFormat.format(order.totalAmount)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  'Deposit: ₦${_currencyFormat.format(order.depositAmount)} | '
                                  'Paid: ₦${_currencyFormat.format(order.paidAmount)} | '
                                  'Balance: ₦${_currencyFormat.format(order.balance)}\n'
                                  '${_shortDateFormat.format(order.createdAt)}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₦${_currencyFormat.format(order.balance)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: order.balance > 0
                                            ? Colors.orange
                                            : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                children: [
                                  // Sale Details Section
                                  if (sale != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.blue.shade200,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Sale Details',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Date: ${_dateFormat.format(DateTime.parse(sale['sale_date'] ?? order.createdAt.toIso8601String()))}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  'Subtotal: ₦${_currencyFormat.format(_toDouble(sale['subtotal']))}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Tax: ₦${_currencyFormat.format(_toDouble(sale['tax']))}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  'Total: ₦${_currencyFormat.format(_toDouble(sale['total']))}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          // Items list with improved contrast
                                          if (items.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            const Text(
                                              'Items:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            ...items
                                                .map(
                                                  (item) => Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 4,
                                                        ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            10,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                        border: Border.all(
                                                          color: Colors
                                                              .grey
                                                              .shade300,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            flex: 3,
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  item['product_name'] ??
                                                                      'Unknown Product',
                                                                  style: const TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: Colors
                                                                        .black87,
                                                                  ),
                                                                ),
                                                                if (item['sku'] !=
                                                                        null &&
                                                                    item['sku']
                                                                        .toString()
                                                                        .isNotEmpty)
                                                                  Text(
                                                                    'SKU: ${item['sku']}',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          11,
                                                                      color: Colors
                                                                          .grey[700],
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              '×${item['quantity'] ?? 0}',
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    color: Colors
                                                                        .black87,
                                                                  ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              '₦${_currencyFormat.format(_toDouble(item['total']))}',
                                                              style: const TextStyle(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .green,
                                                              ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .right,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],

                                  // Payment History Section
                                  if (payments.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Payment History',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          ...payments
                                              .map(
                                                (payment) => Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 2,
                                                      ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          _dateFormat.format(
                                                            payment.createdAt,
                                                          ),
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 11,
                                                                color: Colors
                                                                    .black87,
                                                              ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Text(
                                                          payment.paymentMethod
                                                              .toUpperCase(),
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 11,
                                                                color: Colors
                                                                    .black87,
                                                              ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Text(
                                                          '₦${_currencyFormat.format(payment.amount)}',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: Colors
                                                                    .green,
                                                              ),
                                                          textAlign:
                                                              TextAlign.right,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],

                                  // Action Buttons
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        if (order.status != 'completed' &&
                                            order.status != 'cancelled' &&
                                            order.balance > 0)
                                          ElevatedButton.icon(
                                            onPressed: () =>
                                                _recordPayment(order),
                                            icon: const Icon(
                                              Icons.payment,
                                              size: 18,
                                            ),
                                            label: const Text('Record Payment'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        if (order.status != 'completed' &&
                                            order.status != 'cancelled' &&
                                            order.balance <= 0)
                                          ElevatedButton.icon(
                                            onPressed: () =>
                                                _completeLayaway(order.id),
                                            icon: const Icon(
                                              Icons.check_circle,
                                              size: 18,
                                            ),
                                            label: const Text('Complete'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        if (order.status != 'completed' &&
                                            order.status != 'cancelled')
                                          ElevatedButton.icon(
                                            onPressed: () =>
                                                _cancelLayaway(order.id),
                                            icon: const Icon(
                                              Icons.cancel,
                                              size: 18,
                                            ),
                                            label: const Text('Cancel'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'deposit_paid':
        return Colors.blue;
      case 'partial':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'deposit_paid':
        return 'DEPOSIT';
      case 'partial':
        return 'PARTIAL';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return status.toUpperCase();
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'deposit_paid':
        return Icons.payments;
      case 'partial':
        return Icons.payment;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.shopping_bag;
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
}
