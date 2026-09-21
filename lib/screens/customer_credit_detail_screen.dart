import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../services/credit_payment_service.dart';
import 'record_payment_dialog.dart'; // Keep only one

class CustomerCreditDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerCreditDetailScreen({super.key, required this.customer});

  @override
  State<CustomerCreditDetailScreen> createState() =>
      _CustomerCreditDetailScreenState();
}

class _CustomerCreditDetailScreenState
    extends State<CustomerCreditDetailScreen> {
  List<Map<String, dynamic>> _outstandingSales = [];
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _creditSummary;

  final NumberFormat _currencyFormat = NumberFormat("#,##0.00");
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  // Helper method to safely convert to double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summary = await CreditPaymentService.getCustomerCreditSummary(
        widget.customer.id,
      );
      final sales = await CreditPaymentService.getCustomerOutstandingSales(
        widget.customer.id,
      );

      setState(() {
        _creditSummary = summary;
        _outstandingSales = sales;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _recordPayment(Map<String, dynamic> sale) async {
    print('=== RECORD PAYMENT BUTTON CLICKED ===');
    print('Sale ID: ${sale['id']}');
    print('Remaining amount: ${sale['remaining_amount']}');
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RecordPaymentDialog(
        customerName: widget.customer.name,
        customerId: widget.customer.id,
        creditSaleId: sale['id'],
        invoiceNumber: sale['invoice_number'],
        totalAmount: _toDouble(sale['total']),
        remainingAmount: _toDouble(sale['remaining_amount']),
      ),
    );
    
    if (result == true) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate values once
    final outstandingBalance = widget.customer.currentBalance.abs();
    final creditLimit = widget.customer.creditLimit;
    final hasOutstandingSales = _outstandingSales.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer.name, style: const TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF1e3a8a),
        foregroundColor: Colors.white,
      ),
      body: _buildBody(hasOutstandingSales, outstandingBalance, creditLimit),
    );
  }

  Widget _buildBody(
    bool hasOutstandingSales,
    double outstandingBalance,
    double creditLimit,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCreditSummaryCard(outstandingBalance, creditLimit),
            const SizedBox(height: 24),
            _buildOutstandingSalesHeader(),
            const SizedBox(height: 8),
            hasOutstandingSales
                ? _buildOutstandingSalesList()
                : _buildEmptyStateWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $_error'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildCreditSummaryCard(
    double outstandingBalance,
    double creditLimit,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade900],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Outstanding Balance',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                '₦${_currencyFormat.format(outstandingBalance)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCreditInfoColumn(
                'Credit Limit',
                '₦${_currencyFormat.format(creditLimit)}',
              ),
              _buildCreditInfoColumn(
                'Available Credit',
                '₦${_currencyFormat.format(creditLimit - outstandingBalance)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreditInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        Text(value, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget _buildOutstandingSalesHeader() {
    return Text(
      'Outstanding Sales',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'No outstanding sales for this customer',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ),
    );
  }

  Widget _buildOutstandingSalesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _outstandingSales.length,
      itemBuilder: (context, index) {
        final sale = _outstandingSales[index];
        return _buildSaleCard(sale);
      },
    );
  }

  Widget _buildSaleCard(Map<String, dynamic> sale) {
    final remaining = _toDouble(sale['remaining_amount']);
    final total = _toDouble(sale['total']);
    final dueDate = DateTime.parse(sale['due_date']);
    final isOverdue = dueDate.isBefore(DateTime.now());
    final progressValue = total > 0 ? (total - remaining) / total : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    sale['invoice_number'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (isOverdue) _buildOverdueBadge(),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Due: ${_dateFormat.format(dueDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOverdue ? Colors.red : Colors.grey.shade600,
                  ),
                ),
                Text(
                  '₦${_currencyFormat.format(remaining)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progressValue.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _recordPayment(sale),
                icon: const Icon(Icons.payment),
                label: const Text('Record Payment'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverdueBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'OVERDUE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.red.shade700,
        ),
      ),
    );
  }
}
