import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zite_web_pos/services/api_service.dart';
import '../models/customer.dart';
import '../widgets/customer_credit_card.dart';
import 'customer_credit_detail_screen.dart';
// import '../models/customer.dart';

class CustomerCreditScreen extends StatefulWidget {
  const CustomerCreditScreen({super.key});

  @override
  State<CustomerCreditScreen> createState() => _CustomerCreditScreenState();
}

class _CustomerCreditScreenState extends State<CustomerCreditScreen> {
  List<Customer> _customers = [];
  bool _isLoading = true;
  String? _error;

  final NumberFormat currencyFormat = NumberFormat("#,##0.00");

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use ApiService.getCustomers() instead
      final customersData = await ApiService.getCustomers();

      // Convert to Customer objects
      final allCustomers = customersData
          .map((json) => Customer.fromMap(json))
          .toList();

      // Filter customers with credit balance or credit limit
      final creditCustomers = allCustomers
          .where((c) => c.currentBalance > 0 || c.creditLimit > 0)
          .toList();

      setState(() {
        _customers = creditCustomers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Credit', style: TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF1e3a8a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
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
                    onPressed: _loadCustomers,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _customers.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No customers with credit balance'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadCustomers,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _customers.length,
                itemBuilder: (context, index) {
                  final customer = _customers[index];
                  return CustomerCreditCard(
                    customer: customer,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CustomerCreditDetailScreen(customer: customer),
                        ),
                      ).then((_) => _loadCustomers()); // Refresh on return
                    },
                  );
                },
              ),
            ),
    );
  }
}
