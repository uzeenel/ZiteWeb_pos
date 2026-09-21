import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:zite_web_pos/models/vendor_payment.dart';
import 'package:zite_web_pos/services/vendor_payment_service.dart';
import 'package:zite_web_pos/services/vendor_service.dart';
import 'package:zite_web_pos/services/purchase_order_service.dart';
import 'package:zite_web_pos/services/api_service.dart';
import 'package:zite_web_pos/models/vendor.dart';
import 'package:zite_web_pos/screens/unauthorized_screen.dart';
import 'package:zite_web_pos/utils/permissions.dart';
import 'package:zite_web_pos/models/bank_account.dart';
import 'package:zite_web_pos/services/bank_service.dart';

// Invoice Model
class VendorInvoice {
  final String invoiceNumber;
  final DateTime invoiceDate;
  final List<PurchaseOrderSummary> purchaseOrders;
  final double total;
  final double paid;
  final double balance;

  VendorInvoice({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.purchaseOrders,
    required this.total,
    required this.paid,
    required this.balance,
  });

  factory VendorInvoice.fromMap(Map<String, dynamic> map) {
    return VendorInvoice(
      invoiceNumber: map['invoice_number'],
      invoiceDate: DateTime.parse(map['invoice_date']),
      purchaseOrders: (map['purchase_orders'] as List)
          .map((po) => PurchaseOrderSummary.fromMap(po))
          .toList(),
      total: (map['total'] as num).toDouble(),
      paid: (map['paid'] as num).toDouble(),
      balance: (map['balance'] as num).toDouble(),
    );
  }
}

class PurchaseOrderSummary {
  final int id;
  final String poNumber;
  final double total;
  final double paid;
  final double balance;

  PurchaseOrderSummary({
    required this.id,
    required this.poNumber,
    required this.total,
    required this.paid,
    required this.balance,
  });

  factory PurchaseOrderSummary.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderSummary(
      id: map['id'],
      poNumber: map['po_number'],
      total: (map['total'] as num).toDouble(),
      paid: (map['paid'] as num).toDouble(),
      balance: (map['balance'] as num).toDouble(),
    );
  }
}

class VendorPaymentScreen extends StatefulWidget {
  const VendorPaymentScreen({super.key});

  @override
  State<VendorPaymentScreen> createState() => _VendorPaymentScreenState();
}

class _VendorPaymentScreenState extends State<VendorPaymentScreen> {
  final VendorPaymentService _paymentService = VendorPaymentService();
  final VendorService _vendorService = VendorService();
  final PurchaseOrderService _poService = PurchaseOrderService();

  List<VendorPaymentSummary> _summaries = [];
  List<Vendor> _vendors = [];
  final List<VendorPayment> _selectedVendorPayments = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Vendor? _selectedVendor;

  final _currencyFormat = NumberFormat("#,##0.00");
  final _dateFormat = DateFormat('dd/MM/yyyy');

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
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final summaries = await _paymentService.getVendorPaymentSummary();
    final vendors = await _vendorService.getAllVendors();
    setState(() {
      _summaries = summaries;
      _vendors = vendors;
      _isLoading = false;
    });
  }

  List<VendorPaymentSummary> get _filteredSummaries {
    if (_searchQuery.isEmpty) return _summaries;
    return _summaries.where((s) {
      return s.vendorName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  double _getPaidForPO(int poId) {
    final paid = _selectedVendorPayments
        .where((p) => p.purchaseOrderId == poId)
        .fold(0.0, (sum, p) => sum + p.amount);
    print('_getPaidForPO($poId) = $paid');
    return paid;
  }

  // Fetch invoices grouped by invoice number
  Future<List<VendorInvoice>> _getVendorInvoices(int vendorId) async {
    try {
      print('=== GETTING VENDOR INVOICES ===');
      print('Vendor ID: $vendorId');

      final response = await ApiService.getVendorInvoices(vendorId);
      print('API Response length: ${response.length}');

      if (response.isNotEmpty) {
        print('Has API invoices, using them');
        return response.map((i) => VendorInvoice.fromMap(i)).toList();
      }

      print('No API invoices, trying fallback...');

      // Fallback: If no invoices with numbers, show POs grouped by PO number
      final allPOs = await _poService.getAllPurchaseOrders();
      print('Total POs from service: ${allPOs.length}');

      final vendorPOs = allPOs
          .where(
            (po) =>
                _toInt(po['vendor_id']) == vendorId &&
                po['status'] == 'received',
          )
          .toList();

      print('Vendor POs (received): ${vendorPOs.length}');
      for (var po in vendorPOs) {
        print(
          '  PO: ${po['po_number']}, Total: ${po['total']}, Paid: ${_getPaidForPO(_toInt(po['id']))}',
        );
      }

      if (vendorPOs.isEmpty) return [];

      // Convert each PO to an "invoice" using PO number as identifier
      final List<VendorInvoice> fallbackInvoices = [];
      for (var po in vendorPOs) {
        final poId = _toInt(po['id']);
        final poTotal = _toDouble(po['total']);
        final poPaid = _getPaidForPO(poId);
        final balance = poTotal - poPaid;

        print('PO: ${po['po_number']}, Balance: $balance');

        if (balance > 0) {
          fallbackInvoices.add(
            VendorInvoice(
              invoiceNumber: po['po_number'],
              invoiceDate: DateTime.parse(po['order_date']),
              purchaseOrders: [
                PurchaseOrderSummary(
                  id: poId,
                  poNumber: po['po_number'],
                  total: poTotal,
                  paid: poPaid,
                  balance: balance,
                ),
              ],
              total: poTotal,
              paid: poPaid,
              balance: balance,
            ),
          );
        }
      }

      print('Fallback invoices count: ${fallbackInvoices.length}');
      return fallbackInvoices;
    } catch (e) {
      print('Error fetching vendor invoices: $e');
      return [];
    }
  }

  void _showAddPaymentDialog({
    int? poId,
    String? invoiceNumber,
    Vendor? vendor,
    double? invoiceTotal,
  }) {
    Vendor? selectedVendor = vendor ?? _selectedVendor;
    int? selectedPOId = poId;
    TextEditingController amountController = TextEditingController();
    TextEditingController referenceController = TextEditingController();
    TextEditingController notesController = TextEditingController();
    TextEditingController invoiceNumberController = TextEditingController(
      text: invoiceNumber ?? '',
    );
    DateTime selectedDate = DateTime.now();
    String selectedMethod = 'Bank Transfer';
    List<Map<String, dynamic>> availablePOs = [];

    // Bank account related variables
    List<BankAccount> bankAccounts = [];
    bool isLoadingAccounts = false;
    BankAccount? selectedBankAccount;

    if (invoiceTotal != null && invoiceTotal > 0) {
      amountController.text = invoiceTotal.toString();
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Load bank accounts when dialog opens
            if (bankAccounts.isEmpty && !isLoadingAccounts) {
              isLoadingAccounts = true;
              BankService.getBankAccounts()
                  .then((accounts) {
                    setStateDialog(() {
                      bankAccounts = accounts;
                      isLoadingAccounts = false;
                    });
                  })
                  .catchError((e) {
                    print('Error loading bank accounts: $e');
                    setStateDialog(() {
                      isLoadingAccounts = false;
                    });
                  });
            }

            return AlertDialog(
              title: const Text('Record Vendor Payment'),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Vendor dropdown (only if no vendor preselected)
                      if (invoiceNumber == null)
                        Container(
                          constraints: const BoxConstraints(
                            maxWidth: double.infinity,
                          ),
                          child: DropdownButtonFormField<Vendor>(
                            decoration: const InputDecoration(
                              labelText: 'Vendor *',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            isExpanded: true,
                            initialValue: selectedVendor,
                            items: _vendors.map((v) {
                              return DropdownMenuItem(
                                value: v,
                                child: Text(
                                  v.name,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) async {
                              if (value != null) {
                                setStateDialog(() {
                                  selectedVendor = value;
                                  selectedPOId = null;
                                  amountController.clear();
                                  availablePOs.clear();
                                });

                                final allPOs = await _poService
                                    .getAllPurchaseOrders();
                                final vendorPayments = await _paymentService
                                    .getPaymentsByVendor(value.id);

                                final Map<int, double> paidAmounts = {};
                                for (var payment in vendorPayments) {
                                  if (payment.purchaseOrderId != null) {
                                    paidAmounts[payment.purchaseOrderId!] =
                                        (paidAmounts[payment.purchaseOrderId] ??
                                            0) +
                                        payment.amount;
                                  }
                                }

                                final List<Map<String, dynamic>> tempPOs = [];
                                final Set<int> uniqueIds = {};

                                for (var po in allPOs) {
                                  final poIdValue = _toInt(po['id']);
                                  if (_toInt(po['vendor_id']) == value.id &&
                                      po['status'] == 'received' &&
                                      !uniqueIds.contains(poIdValue)) {
                                    double total = _toDouble(po['total']);
                                    double paid = paidAmounts[poIdValue] ?? 0;
                                    if (total - paid > 0) {
                                      tempPOs.add(po);
                                      uniqueIds.add(poIdValue);
                                    }
                                  }
                                }

                                setStateDialog(() {
                                  availablePOs = tempPOs;
                                });
                              }
                            },
                          ),
                        ),

                      if (invoiceNumber == null) const SizedBox(height: 12),

                      // Invoice Number field
                      TextField(
                        controller: invoiceNumberController,
                        decoration: InputDecoration(
                          labelText: 'Invoice Number *',
                          border: OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.receipt),
                          enabled: invoiceNumber == null,
                        ),
                        readOnly: invoiceNumber != null,
                      ),
                      const SizedBox(height: 12),

                      // PO dropdown (only if no invoice preselected)
                      if (invoiceNumber == null && selectedVendor != null)
                        DropdownButtonFormField<int?>(
                          decoration: const InputDecoration(
                            labelText: 'Purchase Order (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          isExpanded: true,
                          initialValue: selectedPOId,
                          hint: const Text('-- No PO (Direct Payment) --'),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('-- No PO (Direct Payment) --'),
                            ),
                            ...availablePOs.map((po) {
                              final poIdValue = _toInt(po['id']);
                              final total = _toDouble(po['total']);
                              final paid = _getPaidForPO(poIdValue);
                              final balance = total - paid;
                              final invNumber = po['invoice_number'];
                              String displayText = po['po_number'];
                              if (invNumber != null &&
                                  invNumber.toString().isNotEmpty) {
                                displayText += ' (Inv: $invNumber)';
                              }
                              displayText +=
                                  ' | ₦${_currencyFormat.format(total)} | Bal: ₦${_currencyFormat.format(balance)}';
                              return DropdownMenuItem<int?>(
                                value: poIdValue,
                                child: Text(
                                  displayText,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setStateDialog(() {
                              selectedPOId = value;
                              if (value != null) {
                                final selectedPO = availablePOs.firstWhere(
                                  (po) => _toInt(po['id']) == value,
                                  orElse: () => {},
                                );
                                if (selectedPO.isNotEmpty) {
                                  double total = _toDouble(selectedPO['total']);
                                  double paid = _getPaidForPO(value);
                                  double balance = total - paid;
                                  print('=== PO SELECTED DEBUG ===');
                                  print('PO ID: $value');
                                  print('Total from PO: $total');
                                  print('Paid from service: $paid');
                                  print('Calculated balance: $balance');
                                  print(
                                    'Raw total from selectedPO: ${selectedPO['total']}',
                                  );
                                  print(
                                    'Type of total: ${selectedPO['total'].runtimeType}',
                                  );
                                  amountController.text = balance.toString();
                                  if (selectedPO['invoice_number'] != null &&
                                      selectedPO['invoice_number']
                                          .toString()
                                          .isNotEmpty) {
                                    invoiceNumberController.text =
                                        selectedPO['invoice_number'];
                                  }
                                }
                              } else {
                                amountController.clear();
                              }
                            });
                          },
                        ),

                      if (invoiceNumber == null && selectedVendor != null)
                        const SizedBox(height: 12),

                      // Amount
                      TextField(
                        controller: amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount *',
                          prefixText: '₦',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),

                      // Payment Method
                      Container(
                        constraints: const BoxConstraints(
                          maxWidth: double.infinity,
                        ),
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Payment Method *',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          isExpanded: true,
                          initialValue: selectedMethod,
                          items: const [
                            DropdownMenuItem(
                              value: 'Cash',
                              child: Text('Cash'),
                            ),
                            DropdownMenuItem(
                              value: 'Bank Transfer',
                              child: Text('Bank Transfer'),
                            ),
                            DropdownMenuItem(
                              value: 'Cheque',
                              child: Text('Cheque'),
                            ),
                            DropdownMenuItem(
                              value: 'Card',
                              child: Text('Card'),
                            ),
                          ],
                          onChanged: (value) {
                            setStateDialog(() {
                              selectedMethod = value!;
                              selectedBankAccount =
                                  null; // Reset when method changes
                            });
                          },
                        ),
                      ),

                      // Bank Account dropdown (only for Bank Transfer or Cheque)
                      if (selectedMethod == 'Bank Transfer' ||
                          selectedMethod == 'Cheque')
                        Column(
                          children: [
                            const SizedBox(height: 12),
                            isLoadingAccounts
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : bankAccounts.isEmpty
                                ? Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.orange.shade200,
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.warning,
                                          color: Colors.orange,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'No bank accounts found. Please add a bank account first.',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : DropdownButtonFormField<BankAccount>(
                                    decoration: const InputDecoration(
                                      labelText: 'Bank Account *',
                                      border: OutlineInputBorder(),
                                    ),
                                    initialValue: selectedBankAccount,
                                    isExpanded: true, // ADD THIS
                                    items: bankAccounts.map((account) {
                                      return DropdownMenuItem(
                                        value: account,
                                        child: SizedBox(
                                          width:
                                              380, // ADD THIS - adjust as needed
                                          child: Text(
                                            '${account.bankName} - ${account.accountName} (${account.accountNumber ?? 'No account number'})',
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setStateDialog(() {
                                        selectedBankAccount = value;
                                      });
                                    },
                                  ),
                          ],
                        ),

                      const SizedBox(height: 12),

                      // Date
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setStateDialog(() {
                              selectedDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Payment Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_dateFormat.format(selectedDate)),
                              const Icon(Icons.calendar_today, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Reference
                      TextField(
                        controller: referenceController,
                        decoration: const InputDecoration(
                          labelText: 'Reference (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Notes
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
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
                    final vendor = selectedVendor;
                    if (vendor == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a vendor')),
                      );
                      return;
                    }

                    final amount = double.tryParse(amountController.text) ?? 0;
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid amount'),
                        ),
                      );
                      return;
                    }

                    final invoiceNum = invoiceNumberController.text;
                    if (invoiceNum.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter invoice number'),
                        ),
                      );
                      return;
                    }

                    // Validate bank account is selected when needed
                    if ((selectedMethod == 'Bank Transfer' ||
                            selectedMethod == 'Cheque') &&
                        selectedBankAccount == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a bank account'),
                        ),
                      );
                      return;
                    }

                    // Check if amount exceeds invoice balance
                    if (invoiceTotal != null && amount > invoiceTotal) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Payment amount (₦${_currencyFormat.format(amount)}) exceeds invoice balance of ₦${_currencyFormat.format(invoiceTotal)}',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final paymentPoId = selectedPOId ?? poId;

                    print('=== PAYMENT DEBUG ===');
                    print('Vendor: ${vendor.name}');
                    print('PO ID: $paymentPoId');
                    print('Amount: $amount');
                    print('Invoice: $invoiceNum');
                    print('Payment Method: $selectedMethod');
                    print('Bank Account: ${selectedBankAccount?.accountName}');

                    await _paymentService.addPayment(
                      vendorId: vendor.id,
                      purchaseOrderId: paymentPoId,
                      paymentDate: selectedDate,
                      amount: amount,
                      paymentMethod: selectedMethod,
                      reference: referenceController.text.isNotEmpty
                          ? referenceController.text
                          : null,
                      notes: notesController.text.isNotEmpty
                          ? notesController.text
                          : null,
                      createdBy: 1,
                      bankAccountId: selectedBankAccount?.id,
                    );

                    Navigator.pop(context);
                    _loadData();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Payment recorded for ${invoiceNum.isNotEmpty ? 'invoice $invoiceNum' : 'PO'}',
                        ),
                        backgroundColor: Colors.green,
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

  void _showVendorDetails(VendorPaymentSummary summary) async {
    final vendor = _vendors.firstWhere((v) => v.id == summary.vendorId);
    final invoices = await _getVendorInvoices(vendor.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
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
                        vendor.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Total Purchases',
                              '₦${_currencyFormat.format(_toDouble(summary.totalPurchases))}',
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Total Payments',
                              '₦${_currencyFormat.format(_toDouble(summary.totalPayments))}',
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Balance',
                              '₦${_currencyFormat.format(_toDouble(summary.balance))}',
                              _toDouble(summary.balance) > 0
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      const Text(
                        'Outstanding Invoices',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: invoices.isEmpty
                            ? const Center(
                                child: Text('No outstanding invoices'),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: invoices.length,
                                itemBuilder: (context, index) {
                                  final invoice = invoices[index];
                                  if (invoice.balance <= 0) {
                                    return const SizedBox.shrink();
                                  }

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ExpansionTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.orange.shade100,
                                        child: const Icon(
                                          Icons.receipt,
                                          color: Colors.orange,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        '📄 ${invoice.invoiceNumber}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Date: ${_dateFormat.format(invoice.invoiceDate)}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                          ),
                                          Text(
                                            'Balance: ₦${_currencyFormat.format(invoice.balance)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            children: [
                                              const Text(
                                                'Purchase Orders',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              ...invoice.purchaseOrders.map(
                                                (po) => Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 4,
                                                      ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          po.poNumber,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                              ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      Text(
                                                        '₦${_currencyFormat.format(po.balance)}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const Divider(),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  const Text(
                                                    'Total Balance:',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    '₦${_currencyFormat.format(invoice.balance)}',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.orange,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              // In the fallback invoice card, when creating the invoice, store the PO ID
                                              // Update the button onPressed to pass both invoice number and poId
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _showAddPaymentDialog(
                                                      invoiceNumber: invoice
                                                          .invoiceNumber, // PO number
                                                      poId: invoice
                                                          .purchaseOrders
                                                          .first
                                                          .id, // Pass the actual PO ID
                                                      vendor: vendor,
                                                      invoiceTotal:
                                                          invoice.balance,
                                                    );
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.green,
                                                      ),
                                                  child: const Text(
                                                    'Pay This Invoice',
                                                  ),
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
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Permissions.canManageVendors) {
      return const UnauthorizedScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Payments', style: TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF1e3a8a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddPaymentDialog(),
            tooltip: 'Record Payment',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
                hintText: 'Search by vendor name...',
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
                : _filteredSummaries.isEmpty
                ? const Center(child: Text('No vendors found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filteredSummaries.length,
                    itemBuilder: (context, index) {
                      final summary = _filteredSummaries[index];
                      final balance = _toDouble(summary.balance);
                      final balanceColor = balance > 0
                          ? Colors.orange
                          : Colors.green;
                      final balanceText = balance > 0
                          ? 'Outstanding'
                          : 'Fully Paid';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: const Icon(
                              Icons.business,
                              color: Colors.blue,
                            ),
                          ),
                          title: Text(
                            summary.vendorName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Purchases: ₦${_currencyFormat.format(_toDouble(summary.totalPurchases))}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Payments: ₦${_currencyFormat.format(_toDouble(summary.totalPayments))}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₦${_currencyFormat.format(balance)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: balanceColor,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: balanceColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  balanceText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: balanceColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _showVendorDetails(summary),
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
