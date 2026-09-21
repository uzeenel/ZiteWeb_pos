import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zite_web_pos/models/expense.dart';
import 'package:zite_web_pos/services/expense_service.dart';
import 'package:zite_web_pos/screens/unauthorized_screen.dart';
import 'package:zite_web_pos/utils/permissions.dart';
import 'package:zite_web_pos/models/bank_account.dart';
import 'package:zite_web_pos/services/bank_service.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final ExpenseService _service = ExpenseService();
  List<Expense> _expenses = [];
  DateTime _selectedDate = DateTime.now();
  ExpenseSummary? _summary;
  bool _isLoading = true;

  final _currencyFormat = NumberFormat("#,##0.00");
  final _dateFormat = DateFormat('yyyy-MM-dd');

  final Map<ExpenseCategory, String> _categoryIcons = {
    ExpenseCategory.utilities: '💡',
    ExpenseCategory.rent: '🏠',
    ExpenseCategory.salary: '👥',
    ExpenseCategory.supplies: '📦',
    ExpenseCategory.maintenance: '🔧',
    ExpenseCategory.marketing: '📢',
    ExpenseCategory.transportation: '🚗',
    ExpenseCategory.taxes: '📊',
    ExpenseCategory.insurance: '🛡️',
    ExpenseCategory.software: '💻',
    ExpenseCategory.training: '📚',
    ExpenseCategory.legal: '⚖️',
    ExpenseCategory.professional_fees: '👔',
    ExpenseCategory.advertising: '📺',
    ExpenseCategory.travel: '✈️',
    ExpenseCategory.meals: '🍽️',
    ExpenseCategory.office_supplies: '📎',
    ExpenseCategory.equipment: '🖥️',
    ExpenseCategory.repairs: '🔨',
    ExpenseCategory.cleaning: '🧹',
    ExpenseCategory.security: '🔒',
    ExpenseCategory.internet: '🌐',
    ExpenseCategory.phone: '📱',
    ExpenseCategory.electricity: '💡',
    ExpenseCategory.bank_charges: '🏦',
    ExpenseCategory.subscriptions: '📰',
    ExpenseCategory.refunds: '↩️',
    ExpenseCategory.discounts: '🏷️',
    ExpenseCategory.shipping: '📦',
    ExpenseCategory.packaging: '📦',
    ExpenseCategory.raw_materials: '🏭',
    ExpenseCategory.inventory: '📊',
    ExpenseCategory.other: '📝',
  };

  final Map<ExpenseCategory, Color> _categoryColors = {
    ExpenseCategory.utilities: Colors.blue,
    ExpenseCategory.rent: Colors.orange,
    ExpenseCategory.salary: Colors.green,
    ExpenseCategory.supplies: Colors.purple,
    ExpenseCategory.maintenance: Colors.teal,
    ExpenseCategory.marketing: Colors.pink,
    ExpenseCategory.transportation: Colors.cyan,
    ExpenseCategory.taxes: Colors.red,
    ExpenseCategory.insurance: Colors.indigo,
    ExpenseCategory.software: Colors.deepPurple,
    ExpenseCategory.training: Colors.brown,
    ExpenseCategory.legal: Colors.deepOrange,
    ExpenseCategory.professional_fees: Colors.blueGrey,
    ExpenseCategory.advertising: Colors.amber,
    ExpenseCategory.travel: Colors.lightBlue,
    ExpenseCategory.meals: Colors.lime,
    ExpenseCategory.office_supplies: Colors.grey,
    ExpenseCategory.equipment: Colors.cyan,
    ExpenseCategory.repairs: Colors.orangeAccent,
    ExpenseCategory.cleaning: Colors.lightGreen,
    ExpenseCategory.security: Colors.indigoAccent,
    ExpenseCategory.internet: Colors.blueAccent,
    ExpenseCategory.phone: Colors.greenAccent,
    ExpenseCategory.electricity: Colors.yellowAccent,
    ExpenseCategory.bank_charges: Colors.redAccent,
    ExpenseCategory.subscriptions: Colors.purpleAccent,
    ExpenseCategory.refunds: Colors.pinkAccent,
    ExpenseCategory.discounts: Colors.yellow,
    ExpenseCategory.shipping: Colors.deepOrangeAccent,
    ExpenseCategory.packaging: Colors.tealAccent,
    ExpenseCategory.raw_materials: Colors.brown,
    ExpenseCategory.inventory: Colors.blueGrey,
    ExpenseCategory.other: Colors.grey,
  };

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

    final expenses = await _service.getExpensesByDateRange(
      startOfDay,
      endOfDay,
    );
    final summary = await _service.getSummaryForDateRange(startOfDay, endOfDay);

    setState(() {
      _expenses = expenses;
      _summary = summary;
      _isLoading = false;
    });
  }

  Future<void> _addExpense() async {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController referenceController = TextEditingController();
    final TextEditingController vendorController = TextEditingController();
    ExpenseCategory selectedCategory = ExpenseCategory.other;
    String selectedPaymentMethod = 'cash';
    BankAccount? selectedBankAccount;
    List<BankAccount> bankAccounts = [];

    // Load bank accounts first
    try {
      bankAccounts = await BankService.getBankAccounts();
    } catch (e) {
      print('Error loading bank accounts: $e');
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final showBankFields = selectedPaymentMethod != 'cash';
            final availableBankAccounts = bankAccounts
                .where((a) => a.isActive)
                .toList();

            return AlertDialog(
              title: const Text('Add Expense'),
              content: SizedBox(
                width: 350,
                child: SingleChildScrollView(
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
                      DropdownButtonFormField<ExpenseCategory>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: ExpenseCategory.values.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(
                              '${_categoryIcons[category]} ${_categoryName(category)}',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedCategory = value);
                          }
                        },
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
                        controller: vendorController,
                        decoration: const InputDecoration(
                          labelText: 'Vendor (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedPaymentMethod,
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
                          DropdownMenuItem(
                            value: 'bank',
                            child: Text('Bank Transfer'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedPaymentMethod = value;
                              selectedBankAccount = null;
                            });
                          }
                        },
                      ),
                      if (showBankFields &&
                          availableBankAccounts.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: DropdownButtonFormField<BankAccount>(
                            initialValue: selectedBankAccount,
                            decoration: const InputDecoration(
                              labelText: 'Select Bank Account *',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            isExpanded: true,
                            items: availableBankAccounts.map((account) {
                              return DropdownMenuItem(
                                value: account,
                                child: SizedBox(
                                  width: 260,
                                  child: Text(
                                    '${account.accountName} - ${account.bankName}',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => selectedBankAccount = value);
                              }
                            },
                          ),
                        ),
                      ],
                      if (showBankFields &&
                          availableBankAccounts.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: DropdownButtonFormField<BankAccount>(
                            initialValue: selectedBankAccount,
                            decoration: const InputDecoration(
                              labelText: 'Select Bank Account *',
                              border: OutlineInputBorder(),
                            ),
                            isExpanded: true,
                            items: availableBankAccounts.map((account) {
                              return DropdownMenuItem(
                                value: account,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 280,
                                  ),
                                  child: Text(
                                    '${account.accountName} - ${account.bankName}',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => selectedBankAccount = value);
                              }
                            },
                          ),
                        ),
                      ],
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
                        const SnackBar(
                          content: Text('Please enter a valid amount'),
                        ),
                      );
                      return;
                    }
                    if (descriptionController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a description'),
                        ),
                      );
                      return;
                    }

                    // Validate bank account selection for non-cash payments
                    if (selectedPaymentMethod != 'cash') {
                      if (selectedBankAccount == null &&
                          availableBankAccounts.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a bank account'),
                          ),
                        );
                        return;
                      }
                    }

                    final expense = Expense(
                      date: _selectedDate,
                      category: selectedCategory,
                      amount: amount,
                      description: descriptionController.text,
                      reference: referenceController.text.isNotEmpty
                          ? referenceController.text
                          : null,
                      vendor: vendorController.text.isNotEmpty
                          ? vendorController.text
                          : null,
                      paymentMethod: selectedPaymentMethod,
                      bankAccountId: selectedBankAccount?.id,
                      createdAt: DateTime.now(),
                    );

                    await _service.addExpense(expense);
                    Navigator.pop(context);
                    _loadData();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Expense recorded'),
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

  Future<void> _deleteExpense(Expense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
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
      await _service.deleteExpense(expense.id!);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense deleted'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _categoryName(ExpenseCategory category) {
    return category.toString().split('.').last.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // Check permissions - Only Admin  can manage expenses
    if (!Permissions.canManageExpenses) {
      return const UnauthorizedScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses', style: TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF1e3a8a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addExpense,
            tooltip: 'Add Expense',
          ),
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
              if (nextDay.isBefore(
                DateTime.now().add(const Duration(days: 1)),
              )) {
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
                // Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade100,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Expenses',
                          '₦${_currencyFormat.format(_summary?.totalExpenses ?? 0)}',
                          Colors.red,
                          Icons.money_off,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          'Transactions',
                          '${_summary?.transactionCount ?? 0}',
                          Colors.blue,
                          Icons.receipt,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Category Breakdown
                if (_summary != null && _summary!.categoryTotals.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Breakdown by Category',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._summary!.categoryTotals.entries.map((entry) {
                          final percentage = (_summary!.totalExpenses > 0)
                              ? (entry.value / _summary!.totalExpenses) * 100
                              : 0;
                          final color =
                              _categoryColors[entry.key] ?? Colors.grey;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${_categoryIcons[entry.key]} ${_categoryName(entry.key)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '₦${_currencyFormat.format(entry.value)} (${percentage.toStringAsFixed(1)}%)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation(color),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                // Expenses List
                Expanded(
                  child: _expenses.isEmpty
                      ? const Center(child: Text('No expenses for this day'))
                      : ListView.builder(
                          itemCount: _expenses.length,
                          itemBuilder: (context, index) {
                            final expense = _expenses[index];
                            final color =
                                _categoryColors[expense.category] ??
                                Colors.grey;
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _categoryIcons[expense.category] ?? '📝',
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  expense.description,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  '${_categoryName(expense.category)}${expense.vendor != null ? ' | Vendor: ${expense.vendor}' : ''}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '-₦${_currencyFormat.format(expense.amount)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      _dateFormat.format(expense.date),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => _deleteExpense(expense),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
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
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
