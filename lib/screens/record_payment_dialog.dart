import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/credit_payment_service.dart';
import '../services/bank_service.dart';
import '../models/bank_account.dart';

enum PrintOption { pos, invoice, both }

class RecordPaymentDialog extends StatefulWidget {
  final String customerName;
  final int customerId;
  final int creditSaleId;
  final String invoiceNumber;
  final double totalAmount;
  final double remainingAmount;

  const RecordPaymentDialog({
    super.key,
    required this.customerName,
    required this.customerId,
    required this.creditSaleId,
    required this.invoiceNumber,
    required this.totalAmount,
    required this.remainingAmount,
  });

  @override
  State<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  final _accountNameController = TextEditingController();
  String _paymentMethod = 'cash';
  bool _isSubmitting = false;
  String? _selectedBankAccountId;
  List<BankAccount> _bankAccounts = [];
  bool _isLoadingBanks = false;
  PrintOption _selectedPrintOption = PrintOption.pos;

  final _currencyFormat = NumberFormat("#,##0.00");
  final _amountFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.remainingAmount.toString();
    _referenceController.text = widget.invoiceNumber;
    _loadBankAccounts();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    _accountNameController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  Future<void> _loadBankAccounts() async {
    setState(() => _isLoadingBanks = true);
    try {
      _bankAccounts = await BankService.getBankAccounts();
    } catch (e) {
      print('Error loading bank accounts: $e');
    }
    setState(() => _isLoadingBanks = false);
  }

  double? _getValidatedAmount() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showSnackBar('Please enter a valid amount', Colors.red);
      return null;
    }
    if (amount > widget.remainingAmount) {
      _showSnackBar(
        'Amount cannot exceed remaining balance (₦${_currencyFormat.format(widget.remainingAmount)})',
        Colors.red,
      );
      return null;
    }
    return amount;
  }

  Future<void> _submitPayment() async {
    final amount = _getValidatedAmount();
    if (amount == null) return;

    if (_paymentMethod != 'cash') {
      if (_accountNameController.text.trim().isEmpty) {
        _showSnackBar('Please enter account name', Colors.red);
        return;
      }
      if (_selectedBankAccountId == null) {
        _showSnackBar('Please select a bank account', Colors.red);
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      await CreditPaymentService.recordPayment(
        creditSaleId: widget.creditSaleId,
        customerId: widget.customerId,
        amount: amount,
        paymentMethod: _paymentMethod,
        referenceNumber: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        accountName: _accountNameController.text.trim().isEmpty
            ? null
            : _accountNameController.text.trim(),
        bankAccountId: _selectedBankAccountId != null
            ? int.parse(_selectedBankAccountId!)
            : null,
      );

      if (mounted) {
        _showSnackBar('✓ Payment recorded successfully!', Colors.green);
        Navigator.pop(context, {'success': true, 'amount': amount});
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Error: ${e.toString().replaceFirst('Exception: ', '')}',
          Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showBankFields = _paymentMethod != 'cash';

    return AlertDialog(
      title: const Text('Record Payment', style: TextStyle(fontSize: 18)),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Customer', widget.customerName),
              const SizedBox(height: 4),
              _buildInfoRow('Invoice', widget.invoiceNumber),
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Remaining Balance:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₦${_currencyFormat.format(widget.remainingAmount)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                focusNode: _amountFocus,
                decoration: const InputDecoration(
                  labelText: 'Payment Amount *',
                  border: OutlineInputBorder(),
                  prefixText: '₦',
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _submitPayment(),
              ),
              const SizedBox(height: 12),
              const Text(
                'Payment Method',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              // FIXED: Using Wrap with fixed width RadioListTiles
              Wrap(
                spacing: 0,
                runSpacing: 0,
                children: [
                  SizedBox(
                    width: 70,
                    child: RadioListTile(
                      title: const Text('Cash', style: TextStyle(fontSize: 11)),
                      value: 'cash',
                      groupValue: _paymentMethod,
                      onChanged: (val) =>
                          setState(() => _paymentMethod = val.toString()),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      visualDensity: const VisualDensity(
                        horizontal: -4,
                        vertical: -4,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: RadioListTile(
                      title: const Text('Card', style: TextStyle(fontSize: 11)),
                      value: 'card',
                      groupValue: _paymentMethod,
                      onChanged: (val) =>
                          setState(() => _paymentMethod = val.toString()),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      visualDensity: const VisualDensity(
                        horizontal: -4,
                        vertical: -4,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: RadioListTile(
                      title: const Text(
                        'Transfer',
                        style: TextStyle(fontSize: 11),
                      ),
                      value: 'transfer',
                      groupValue: _paymentMethod,
                      onChanged: (val) =>
                          setState(() => _paymentMethod = val.toString()),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      visualDensity: const VisualDensity(
                        horizontal: -4,
                        vertical: -4,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: RadioListTile(
                      title: const Text(
                        'Credit',
                        style: TextStyle(fontSize: 11),
                      ),
                      value: 'credit',
                      groupValue: _paymentMethod,
                      onChanged: (val) =>
                          setState(() => _paymentMethod = val.toString()),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      visualDensity: const VisualDensity(
                        horizontal: -4,
                        vertical: -4,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: RadioListTile(
                      title: const Text(
                        'Layaway',
                        style: TextStyle(fontSize: 11),
                      ),
                      value: 'layaway',
                      groupValue: _paymentMethod,
                      onChanged: (val) =>
                          setState(() => _paymentMethod = val.toString()),
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
              if (showBankFields) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _accountNameController,
                  decoration: const InputDecoration(
                    labelText: 'Account Name *',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                _isLoadingBanks
                    ? const Center(child: CircularProgressIndicator())
                    : _bankAccounts.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'No bank accounts available. Please add one in Bank Accounts.',
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      )
                    : DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Bank Account *',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedBankAccountId,
                        items: _bankAccounts.map((account) {
                          return DropdownMenuItem(
                            value: account.id.toString(),
                            child: Text(
                              '${account.accountName} (${account.bankName})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedBankAccountId = value),
                      ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText: 'Reference Number',
                  hintText: 'Optional',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Optional',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size(100, 36),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Record Payment'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
