import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/models/vendor_payment.dart';
import 'package:pos_system/services/vendor_payment_service.dart';
import 'package:pos_system/services/vendor_service.dart';
import 'package:pos_system/services/purchase_order_service.dart';
import 'package:pos_system/models/vendor.dart';
import 'package:pos_system/screens/unauthorized_screen.dart';
import 'package:pos_system/utils/permissions.dart';

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
  List<Map<String, dynamic>> _vendorPOs = [];
  List<VendorPayment> _selectedVendorPayments = [];
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

  Future<void> _loadVendorDetails(Vendor vendor) async {
    setState(() => _isLoading = true);
    final allPOs = await _poService.getAllPurchaseOrders();
    final vendorPOs = allPOs
        .where(
          (po) =>
              _toInt(po['vendor_id']) == vendor.id &&
              po['status'] == 'received',
        )
        .toList();
    final payments = await _paymentService.getPaymentsByVendor(vendor.id);
    setState(() {
      _selectedVendor = vendor;
      _vendorPOs = vendorPOs;
      _selectedVendorPayments = payments;
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
    return _selectedVendorPayments
        .where((p) => p.purchaseOrderId == poId)
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  void _showAddPaymentDialog({int? poId}) {
    Vendor? selectedVendor = _selectedVendor;
    int? selectedPOId = poId;
    TextEditingController amountController = TextEditingController();
    TextEditingController referenceController = TextEditingController();
    TextEditingController notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedMethod = 'Bank Transfer';
    List<Map<String, dynamic>> availablePOs = [];
    List<VendorPayment> _dialogVendorPayments = [];

    _loadPaymentDialogData() async {
      if (selectedVendor != null) {
        final allPOs = await _poService.getAllPurchaseOrders();
        final vendorPayments = await _paymentService.getPaymentsByVendor(
          selectedVendor!.id,
        );

        final Map<int, double> paidAmounts = {};
        for (var payment in vendorPayments) {
          if (payment.purchaseOrderId != null) {
            paidAmounts[payment.purchaseOrderId!] =
                (paidAmounts[payment.purchaseOrderId] ?? 0) + payment.amount;
          }
        }

        final List<Map<String, dynamic>> tempPOs = [];
        final Set<int> uniqueIds = {};

        for (var po in allPOs) {
          final poIdValue = _toInt(po['id']);
          if (_toInt(po['vendor_id']) == selectedVendor!.id &&
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

        return {'pos': tempPOs, 'payments': vendorPayments};
      }
      return {'pos': <Map<String, dynamic>>[], 'payments': <VendorPayment>[]};
    }

    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder(
          future: _loadPaymentDialogData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasData && snapshot.data != null) {
              final data = snapshot.data as Map<String, dynamic>;
              availablePOs = List<Map<String, dynamic>>.from(data['pos']);
              _dialogVendorPayments = List<VendorPayment>.from(
                data['payments'],
              );

              if (selectedPOId != null) {
                final selectedPO = availablePOs.firstWhere(
                  (po) => _toInt(po['id']) == selectedPOId,
                  orElse: () => {},
                );
                if (selectedPO.isNotEmpty) {
                  double total = _toDouble(selectedPO['total']);
                  double paid = 0;
                  for (var payment in _dialogVendorPayments) {
                    if (payment.purchaseOrderId == selectedPOId) {
                      paid += payment.amount;
                    }
                  }
                  double balance = total - paid;
                  amountController.text = balance.toString();
                }
              }
            }

            return StatefulBuilder(
              builder: (context, setStateDialog) {
                return AlertDialog(
                  title: const Text('Record Vendor Payment'),
                  content: SizedBox(
                    width: 450,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Vendor dropdown
                          IgnorePointer(
                            ignoring: selectedPOId != null,
                            child: DropdownButtonFormField<Vendor>(
                              decoration: const InputDecoration(
                                labelText: 'Vendor *',
                                border: OutlineInputBorder(),
                              ),
                              isExpanded: true,
                              value: selectedVendor,
                              items: _vendors.map((v) {
                                return DropdownMenuItem(
                                  value: v,
                                  child: Text(v.name),
                                );
                              }).toList(),
                              onChanged: (value) async {
                                if (value != null && selectedPOId == null) {
                                  setStateDialog(() {
                                    selectedVendor = value;
                                    selectedPOId = null;
                                    amountController.clear();
                                  });
                                  final allPOs = await _poService
                                      .getAllPurchaseOrders();
                                  final vendorPayments = await _paymentService
                                      .getPaymentsByVendor(value.id);

                                  final Map<int, double> paidAmounts = {};
                                  for (var payment in vendorPayments) {
                                    if (payment.purchaseOrderId != null) {
                                      paidAmounts[payment.purchaseOrderId!] =
                                          (paidAmounts[payment
                                                  .purchaseOrderId] ??
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
                                    _dialogVendorPayments = vendorPayments;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 12),

                          // PO dropdown - Simplified single line layout
                          DropdownButtonFormField<int?>(
                            decoration: const InputDecoration(
                              labelText: 'Purchase Order (Optional)',
                              border: OutlineInputBorder(),
                            ),
                            isExpanded: true,
                            value: selectedPOId,
                            hint: const Text('-- No PO (Direct Payment) --'),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('-- No PO (Direct Payment) --'),
                              ),
                              ...availablePOs.map((po) {
                                final poIdValue = _toInt(po['id']);
                                final total = _toDouble(po['total']);

                                double paid = 0;
                                for (var payment in _dialogVendorPayments) {
                                  if (payment.purchaseOrderId == poIdValue) {
                                    paid += payment.amount;
                                  }
                                }

                                final balance = total - paid;
                                final invoiceNumber = po['invoice_number'];

                                // Combine all information into a single line to avoid layout issues
                                String displayText = po['po_number'];
                                if (invoiceNumber != null &&
                                    invoiceNumber.toString().isNotEmpty) {
                                  displayText += ' (Inv: $invoiceNumber)';
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
                                    double total = _toDouble(
                                      selectedPO['total'],
                                    );
                                    double paid = 0;
                                    for (var payment in _dialogVendorPayments) {
                                      if (payment.purchaseOrderId == value) {
                                        paid += payment.amount;
                                      }
                                    }
                                    double balance = total - paid;
                                    amountController.text = balance.toString();
                                  }
                                } else {
                                  amountController.clear();
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 12),

                          // PO Details Card
                          if (selectedPOId != null &&
                              availablePOs.isNotEmpty) ...[
                            Builder(
                              builder: (context) {
                                final selectedPO = availablePOs.firstWhere(
                                  (po) => _toInt(po['id']) == selectedPOId,
                                  orElse: () => {},
                                );
                                if (selectedPO.isNotEmpty) {
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'PO: ${selectedPO['po_number']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (selectedPO['invoice_number'] !=
                                                null &&
                                            selectedPO['invoice_number']
                                                .toString()
                                                .isNotEmpty)
                                          Text(
                                            'Invoice: ${selectedPO['invoice_number']}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Balance: ₦${_currencyFormat.format(_toDouble(amountController.text))}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                            const SizedBox(height: 12),
                          ],

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
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Payment Method *',
                              border: OutlineInputBorder(),
                            ),
                            value: selectedMethod,
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
                              });
                            },
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                            const SnackBar(
                              content: Text('Please select a vendor'),
                            ),
                          );
                          return;
                        }

                        final amount =
                            double.tryParse(amountController.text) ?? 0;
                        if (amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid amount'),
                            ),
                          );
                          return;
                        }

                        if (selectedPOId != null) {
                          final selectedPO = availablePOs.firstWhere(
                            (po) => _toInt(po['id']) == selectedPOId,
                            orElse: () => {},
                          );
                          if (selectedPO.isNotEmpty) {
                            double total = _toDouble(selectedPO['total']);
                            double paid = 0;
                            for (var payment in _dialogVendorPayments) {
                              if (payment.purchaseOrderId == selectedPOId) {
                                paid += payment.amount;
                              }
                            }
                            double balance = total - paid;
                            if (amount > balance) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Amount exceeds PO balance of ₦${_currencyFormat.format(balance)}',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                          }
                        }

                        await _paymentService.addPayment(
                          vendorId: vendor.id,
                          purchaseOrderId: selectedPOId,
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
                        );

                        Navigator.pop(context);

                        final currentSelectedVendor = _selectedVendor;
                        if (currentSelectedVendor != null &&
                            vendor.id == currentSelectedVendor.id) {
                          await _loadVendorDetails(currentSelectedVendor);
                        }
                        _loadData();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payment recorded successfully'),
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
      },
    );
  }

  void _showVendorDetails(VendorPaymentSummary summary) async {
    final vendor = _vendors.firstWhere((v) => v.id == summary.vendorId);
    await _loadVendorDetails(vendor);

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
                        summary.vendorName,
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
                        'Outstanding Purchase Orders',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.25,
                        ),
                        child: _vendorPOs.isEmpty
                            ? const Center(child: Text('No outstanding POs'))
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _vendorPOs.length,
                                itemBuilder: (context, index) {
                                  final po = _vendorPOs[index];
                                  final poId = _toInt(po['id']);
                                  final paid = _getPaidForPO(poId);
                                  final total = _toDouble(po['total']);
                                  final balance = total - paid;
                                  final invoiceNumber = po['invoice_number'];

                                  if (balance <= 0)
                                    return const SizedBox.shrink();

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      title: Text(
                                        po['po_number'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (invoiceNumber != null &&
                                              invoiceNumber
                                                  .toString()
                                                  .isNotEmpty)
                                            Text(
                                              'Invoice: $invoiceNumber',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          Text(
                                            'Date: ${_dateFormat.format(DateTime.parse(po['order_date']))}',
                                          ),
                                          Text(
                                            'Total: ₦${_currencyFormat.format(total)}',
                                          ),
                                          Text(
                                            'Paid: ₦${_currencyFormat.format(paid)}',
                                          ),
                                        ],
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Balance: ₦${_currencyFormat.format(balance)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _showAddPaymentDialog(poId: poId);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              minimumSize: const Size(80, 30),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                            ),
                                            child: const Text(
                                              'Pay',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                      const Divider(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Payment History',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showAddPaymentDialog();
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Record Payment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _selectedVendorPayments.isEmpty
                            ? const Center(child: Text('No payments recorded'))
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: _selectedVendorPayments.length,
                                itemBuilder: (context, index) {
                                  final payment =
                                      _selectedVendorPayments[index];
                                  final po = _vendorPOs.firstWhere(
                                    (p) =>
                                        _toInt(p['id']) ==
                                        payment.purchaseOrderId,
                                    orElse: () => {
                                      'po_number': 'N/A',
                                      'invoice_number': null,
                                    },
                                  );
                                  final invoiceNumber = po['invoice_number'];

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.green.shade100,
                                        child: const Icon(
                                          Icons.payment,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        '₦${_currencyFormat.format(payment.amount)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${payment.paymentMethod} • ${_dateFormat.format(payment.paymentDate)}',
                                          ),
                                          if (payment.purchaseOrderId !=
                                              null) ...[
                                            Text(
                                              'PO: ${po['po_number']}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                            ),
                                            if (invoiceNumber != null &&
                                                invoiceNumber
                                                    .toString()
                                                    .isNotEmpty)
                                              Text(
                                                'Invoice: $invoiceNumber',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                          ],
                                          if (payment.reference != null)
                                            Text(
                                              'Ref: ${payment.reference}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                            ),
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                'Delete Payment',
                                              ),
                                              content: Text(
                                                'Delete payment of ₦${_currencyFormat.format(payment.amount)} to ${summary.vendorName}?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await _paymentService.deletePayment(
                                              payment.id!,
                                            );
                                            await _loadVendorDetails(
                                              _selectedVendor!,
                                            );
                                            _loadData();
                                            setStateSheet(() {});
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Payment deleted',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                      ),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
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
                                  color: balanceColor.withOpacity(0.2),
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
