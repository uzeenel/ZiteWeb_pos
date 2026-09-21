import 'package:flutter/material.dart';
import 'package:zite_web_pos/models/bank.dart';
import 'package:zite_web_pos/services/bank_service.dart';
import 'package:zite_web_pos/screens/unauthorized_screen.dart';
import 'package:zite_web_pos/utils/permissions.dart';

class BankManagementScreen extends StatefulWidget {
  const BankManagementScreen({super.key});

  @override
  State<BankManagementScreen> createState() => _BankManagementScreenState();
}

class _BankManagementScreenState extends State<BankManagementScreen> {
  List<Bank> _banks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  Future<void> _loadBanks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final banks = await BankService.getBanks();
      setState(() {
        _banks = banks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addBank() async {
    final TextEditingController nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Bank'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Bank Name *',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter bank name')),
                  );
                  return;
                }

                await BankService.addBank({'name': name});
                Navigator.pop(context);
                _loadBanks();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bank added'),
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
  }

  Future<void> _editBank(Bank bank) async {
    final TextEditingController nameController = TextEditingController(
      text: bank.name,
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Bank'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Bank Name *',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter bank name')),
                  );
                  return;
                }

                await BankService.updateBank(bank.id, {'name': name});
                Navigator.pop(context);
                _loadBanks();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bank updated'),
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
  }

  Future<void> _deleteBank(Bank bank) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bank'),
        content: Text('Delete ${bank.name}?'),
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
      await BankService.deleteBank(bank.id);
      _loadBanks();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bank deleted'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Permissions.canManageBanks) {
      return const UnauthorizedScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Banks', style: TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF1e3a8a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addBank,
            tooltip: 'Add Bank',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBanks,
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
                    onPressed: _loadBanks,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _banks.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No banks'),
                  SizedBox(height: 8),
                  Text('Tap + to add a bank'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _banks.length,
              itemBuilder: (context, index) {
                final bank = _banks[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.account_balance),
                    title: Text(bank.name),
                    subtitle: bank.code != null
                        ? Text('Code: ${bank.code}')
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editBank(bank),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteBank(bank),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
