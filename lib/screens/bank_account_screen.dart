import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zite_web_pos/models/bank_account.dart';
import 'package:zite_web_pos/models/bank.dart'; // Add this line
import 'package:zite_web_pos/services/bank_service.dart';
import 'package:zite_web_pos/screens/unauthorized_screen.dart';
import 'package:zite_web_pos/utils/permissions.dart';

class BankAccountScreen extends StatefulWidget {
  const BankAccountScreen({super.key});

  @override
  State<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends State<BankAccountScreen> {
  List<BankAccount> _accounts = [];
  bool _isLoading = true;
  String? _error;

  final _currencyFormat = NumberFormat("#,##0.00");

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final accounts = await BankService.getBankAccounts();
      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addBankAccount() async {
    final TextEditingController accountNameController = TextEditingController();
    final TextEditingController accountNumberController =
        TextEditingController();
    final TextEditingController openingBalanceController =
        TextEditingController();
    Bank? selectedBank;
    List<Bank> banks = [];

    // Load banks first
    try {
      banks = await BankService.getBanks();
      // print('Loaded banks: ${_banks.length}');
      // for (var bank in _banks) {
      //   print(
      //     'Bank: ${bank.id}, ${bank.name}, ${bank.code}, ${bank.isActive}, ${bank.createdAt}',
      //   );
      // }
    } catch (e) {
      print('Error loading banks: $e');
    }


    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Bank Account'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: accountNameController,
                      decoration: const InputDecoration(
                        labelText: 'Account Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Bank>(
                      initialValue: selectedBank,
                      decoration: const InputDecoration(
                        labelText: 'Select Bank *',
                        border: OutlineInputBorder(),
                      ),
                      items: banks.map<DropdownMenuItem<Bank>>((bank) {
                        return DropdownMenuItem(
                          value: bank,
                          child: Text(bank.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedBank = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: accountNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Account Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: openingBalanceController,
                      decoration: const InputDecoration(
                        labelText: 'Opening Balance',
                        prefixText: '₦',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
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
                    final accountName = accountNameController.text.trim();

                    if (accountName.isEmpty || selectedBank == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all required fields'),
                        ),
                      );
                      return;
                    }

                    final openingBalance =
                        double.tryParse(openingBalanceController.text) ?? 0;

                    await BankService.addBankAccount({
                      'account_name': accountName,
                      'bank_name': selectedBank!.name,
                      'bank_id': selectedBank!.id,
                      'account_number':
                          accountNumberController.text.trim().isEmpty
                          ? null
                          : accountNumberController.text.trim(),
                      'opening_balance': openingBalance,
                    });

                    Navigator.pop(context);
                    _loadAccounts();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bank account added'),
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

  @override
  Widget build(BuildContext context) {
    if (!Permissions.canManageBankAccounts) {
      return const UnauthorizedScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Accounts', style: TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF1e3a8a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addBankAccount,
            tooltip: 'Add Account',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAccounts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAccounts,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _accounts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No bank accounts'),
                  SizedBox(height: 8),
                  Text('Tap + to add an account'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAccounts,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _accounts.length,
                itemBuilder: (context, index) {
                  final account = _accounts[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.account_balance,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      account.accountName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      account.bankName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₦${_currencyFormat.format(account.currentBalance)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: account.currentBalance >= 0
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  if (account.accountNumber != null)
                                    Text(
                                      'Acc: ${account.accountNumber}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoChip(
                                'Opening',
                                '₦${_currencyFormat.format(account.openingBalance)}',
                                Colors.blue,
                              ),
                              _buildInfoChip(
                                'Current',
                                '₦${_currencyFormat.format(account.currentBalance)}',
                                account.currentBalance >= 0
                                    ? Colors.green
                                    : Colors.red,
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
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          const SizedBox(width: 8),
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
