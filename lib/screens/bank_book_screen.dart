import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/models/bank_book.dart';
import 'package:pos_system/services/bank_book_service.dart';
import 'package:pos_system/services/export_service.dart' as expService;
import 'package:pos_system/screens/unauthorized_screen.dart';
import 'package:pos_system/utils/permissions.dart';

class BankBookScreen extends StatefulWidget {
  const BankBookScreen({super.key});

  @override
  State<BankBookScreen> createState() => _BankBookScreenState();
}

class _BankBookScreenState extends State<BankBookScreen> {
  final BankBookService _service = BankBookService();
  final expService.ExportService _exportService = expService.ExportService();
  List<BankTransaction> _transactions = [];
  DateTime _selectedDate = DateTime.now();
  Map<String, double> _openingBalances = {};
  BankSummary? _summary;
  bool _isLoading = true;
  bool _isExporting = false;

  final _currencyFormat = NumberFormat("#,##0.00");
  final _dateFormat = DateFormat('yyyy-MM-dd');

  final List<String> _bankAccounts = [
    'First Bank',
    'GTBank',
    'UBA',
    'Access Bank',
    'Zenith Bank',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final startOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));

    print('=== BANK BOOK DEBUG ===');
    print('Start: $startOfDay');
    print('End: $endOfDay');

    final transactions = await _service.getTransactionsByDateRange(
      startOfDay,
      endOfDay,
    );
    print('Transactions count: ${transactions.length}');
    for (var t in transactions) {
      print('Transaction: ${t.type}, amount: ${t.amount}, bank: ${t.bankName}');
    }

    final summary = await _service.getSummaryForDateRange(
      startOfDay,
      endOfDay,
      _openingBalances,
    );
    print(
      'Summary: deposits=${summary?.totalDeposits}, withdrawals=${summary?.totalWithdrawals}',
    );

    setState(() {
      _transactions = transactions;
      _summary = summary;
      _isLoading = false;
    });
  }

  Future<void> _addTransaction({required bool isDeposit}) async {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController referenceController = TextEditingController();
    final TextEditingController chequeController = TextEditingController();
    String selectedBank = _bankAccounts.first;
    String selectedAccount = 'Main Account';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isDeposit ? 'Bank Deposit' : 'Bank Withdrawal'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₦',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedBank,
                      decoration: const InputDecoration(
                        labelText: 'Bank',
                        border: OutlineInputBorder(),
                      ),
                      items: _bankAccounts.map((bank) {
                        return DropdownMenuItem(
                          value: bank,
                          child: Text(bank),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => selectedBank = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: chequeController,
                      decoration: const InputDecoration(
                        labelText: 'Cheque Number (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: referenceController,
                      decoration: const InputDecoration(
                        labelText: 'Reference (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text) ?? 0;
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid amount')),
                      );
                      return;
                    }
                    if (descriptionController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a description')),
                      );
                      return;
                    }

                    final transaction = BankTransaction(
                      date: _selectedDate,
                      type: isDeposit ? BankTransactionType.deposit : BankTransactionType.withdrawal,
                      amount: amount,
                      accountName: selectedAccount,
                      bankName: selectedBank,
                      chequeNumber: chequeController.text.isNotEmpty ? chequeController.text : null,
                      description: descriptionController.text,
                      reference: referenceController.text.isNotEmpty ? referenceController.text : null,
                      createdAt: DateTime.now(),
                    );

                    await _service.addTransaction(transaction);
                    Navigator.pop(context);
                    _loadData();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${isDeposit ? 'Deposit' : 'Withdrawal'} recorded successfully'),
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

  Future<void> _deleteTransaction(BankTransaction transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteTransaction(transaction.id!);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check permissions - Only Admin and can manage bank book
    if (!Permissions.canManageBankBook) {
      return const UnauthorizedScreen();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Book', style: TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF1e3a8a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                _loadData();
              });
            },
            tooltip: 'Previous Day',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                  _loadData();
                });
              }
            },
            tooltip: 'Select Date',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final nextDay = _selectedDate.add(const Duration(days: 1));
              if (nextDay.isBefore(DateTime.now().add(const Duration(days: 1)))) {
                setState(() {
                  _selectedDate = nextDay;
                  _loadData();
                });
              }
            },
            tooltip: 'Next Day',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Date Header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade100,
                  child: Column(
                    children: [
                      Text(
                        _dateFormat.format(_selectedDate),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Opening Balance',
                              '₦${_currencyFormat.format(_summary?.openingBalance ?? 0)}',
                              Colors.blue,
                              Icons.account_balance,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Deposits',
                              '₦${_currencyFormat.format(_summary?.totalDeposits ?? 0)}',
                              Colors.green,
                              Icons.arrow_downward,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Withdrawals',
                              '₦${_currencyFormat.format(_summary?.totalWithdrawals ?? 0)}',
                              Colors.red,
                              Icons.arrow_upward,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Net Change',
                              '₦${_currencyFormat.format(_summary?.netChange ?? 0)}',
                              Colors.orange,
                              Icons.trending_up,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Closing Balance',
                              '₦${_currencyFormat.format(_summary?.closingBalance ?? 0)}',
                              Colors.purple,
                              Icons.account_balance_wallet,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Transactions',
                              '${_summary?.transactionCount ?? 0}',
                              Colors.teal,
                              Icons.receipt,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addTransaction(isDeposit: true),
                          icon: const Icon(Icons.arrow_downward),
                          label: const Text('Deposit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addTransaction(isDeposit: false),
                          icon: const Icon(Icons.arrow_upward),
                          label: const Text('Withdrawal'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Transactions List
                Expanded(
                  child: _transactions.isEmpty
                      ? const Center(child: Text('No transactions for this day'))
                      : ListView.builder(
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _transactions[index];
                            final isDeposit = transaction.type == BankTransactionType.deposit;
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: (isDeposit ? Colors.green : Colors.red).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: isDeposit ? Colors.green : Colors.red,
                                  ),
                                ),
                                title: Text(
                                  transaction.description,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  '${transaction.bankName} | ${transaction.accountName}${transaction.chequeNumber != null ? ' | Chq: ${transaction.chequeNumber}' : ''}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${isDeposit ? '+' : '-'}₦${_currencyFormat.format(transaction.amount)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDeposit ? Colors.green : Colors.red,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      _dateFormat.format(transaction.date),
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                onTap: () => _deleteTransaction(transaction),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 10, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}