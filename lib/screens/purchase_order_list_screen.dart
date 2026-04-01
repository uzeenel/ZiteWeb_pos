import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/services/purchase_order_service.dart';
import 'package:pos_system/services/company_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PurchaseOrderListScreen extends StatefulWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  State<PurchaseOrderListScreen> createState() =>
      _PurchaseOrderListScreenState();
}

class _PurchaseOrderListScreenState extends State<PurchaseOrderListScreen> {
  final PurchaseOrderService _poService = PurchaseOrderService();
  final CompanyService _companyService = CompanyService();
  List<Map<String, dynamic>> _purchaseOrders = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Helper methods for safe type conversion
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _loadPurchaseOrders();
  }

  Future<void> _loadPurchaseOrders() async {
    setState(() {
      _isLoading = true;
    });
    final orders = await _poService.getAllPurchaseOrders();
    setState(() {
      _purchaseOrders = orders;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_searchQuery.isEmpty) return _purchaseOrders;
    return _purchaseOrders
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

  Future<void> _printPurchaseOrder(
    Map<String, dynamic> order,
    List<Map<String, dynamic>> items,
  ) async {
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
    <title>Purchase Order ${order['po_number']}</title>
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
            <strong>PO Number:</strong> ${_escapeHtml(order['po_number'])}<br>
            <strong>Date:</strong> ${order['order_date'].toString().substring(0, 16)}<br>
            <strong>Status:</strong> ${order['status'].toUpperCase()}<br><br>
            <strong>VENDOR:</strong><br>
            ${_escapeHtml(order['vendor_name'])}<br>
            ${order['vendor_address'] != null ? '${_escapeHtml(order['vendor_address'])}<br>' : ''}
            ${order['vendor_phone'] != null ? 'Tel: ${_escapeHtml(order['vendor_phone'])}<br>' : ''}
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

    for (var item in items) {
      html.writeln('''
                <tr>
                    <td>${_toInt(item['quantity'])}</td>
                    <td>${_escapeHtml(item['unit'] ?? 'pcs')}</td>
                    <td>${_escapeHtml(item['product_name'])}</td>
                    <td>₦${_toDouble(item['unit_price']).toStringAsFixed(2)}</td>
                    <td>₦${_toDouble(item['total']).toStringAsFixed(2)}</td>
                </tr>
      ''');
    }

    html.writeln('''
            </tbody>
        </table>
        
        <div class="totals">
            <div>Subtotal: ₦${_toDouble(order['subtotal']).toStringAsFixed(2)}</div>
            <div>VAT (7.5%): ₦${_toDouble(order['tax']).toStringAsFixed(2)}</div>
            <div><strong>Total: ₦${_toDouble(order['total']).toStringAsFixed(2)}</strong></div>
        </div>
    ''');

    if (order['notes'] != null && order['notes'].toString().isNotEmpty) {
      html.writeln('''
        <div class="info-box">
            <strong>NOTES:</strong><br>
            ${_escapeHtml(order['notes'])}
        </div>
      ''');
    }

    html.writeln('''
    <div style="display: flex; justify-content: space-between; margin-top: 60px;">
        <div>
            Authorized Signature: _________________<br>
            <br>
        </div>
        <div>
            Date: _________________<br>
            <br>
        </div>
    </div>
    </div>
</body>
</html>
''');

    // Save to file and open in browser
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'PO_${order['po_number'].replaceAll('-', '_')}.html';
    final file = File('${directory.path}/$fileName');

    await file.writeAsString(html.toString());

    await Process.run('start', [file.path], runInShell: true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening PO ${order['po_number']}...')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders', style: TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF1e3a8a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPurchaseOrders,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by PO number or vendor...',
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
                ? const Center(child: Text('No purchase orders found'))
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
                            backgroundColor: order['status'] == 'received'
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                            child: Icon(
                              order['status'] == 'received'
                                  ? Icons.check_circle
                                  : Icons.pending,
                              color: order['status'] == 'received'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                          title: Text(
                            order['po_number'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${order['vendor_name']}\n$formattedDate | ${_toInt(order['item_count'])} items | ₦${_toDouble(order['total']).toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.print),
                                onPressed: () async {
                                  final details = await _poService
                                      .getPurchaseOrderDetails(order['id']);
                                  if (details.isNotEmpty &&
                                      details['order'] != null) {
                                    final items = details['items'] != null
                                        ? List<Map<String, dynamic>>.from(
                                            details['items'],
                                          )
                                        : <Map<String, dynamic>>[];
                                    _printPurchaseOrder(
                                      details['order'],
                                      items,
                                    );
                                  }
                                },
                                tooltip: 'Print',
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () async {
                            final details = await _poService
                                .getPurchaseOrderDetails(order['id']);
                            if (details.isNotEmpty &&
                                details['order'] != null) {
                              final items = details['items'] != null
                                  ? List<Map<String, dynamic>>.from(
                                      details['items'],
                                    )
                                  : <Map<String, dynamic>>[];
                              _showOrderDetails(details['order'], items);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(
    Map<String, dynamic> order,
    List<Map<String, dynamic>> items,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
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
                    order['po_number'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vendor: ${order['vendor_name']}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Date: ${order['order_date'].toString().substring(0, 16)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    'Status: ${order['status'].toUpperCase()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: order['status'] == 'received'
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 24),
                  Text(
                    'Items (${items.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item['product_name'],
                                  style: const TextStyle(fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: 50,
                                child: Text(
                                  '${_toInt(item['quantity'])}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  '₦${_toDouble(item['unit_price']).toStringAsFixed(0)}',
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  '₦${_toDouble(item['total']).toStringAsFixed(0)}',
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:', style: TextStyle(fontSize: 13)),
                      Text(
                        '₦${_toDouble(order['subtotal']).toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('VAT (7.5%):', style: TextStyle(fontSize: 13)),
                      Text(
                        '₦${_toDouble(order['tax']).toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                        '₦${_toDouble(order['total']).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  if (order['notes'] != null &&
                      order['notes'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Notes:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(order['notes'], style: const TextStyle(fontSize: 12)),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _printPurchaseOrder(order, items);
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Print / Reprint'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
