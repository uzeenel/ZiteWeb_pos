import 'package:flutter/material.dart';
import 'package:pos_system/services/customer_service.dart';
import 'package:pos_system/models/customer.dart';
import 'package:pos_system/models/region.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final CustomerService _customerService = CustomerService();
  List<Customer> _customers = [];
  List<Region> _states = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final customers = await _customerService.getAllCustomers();
    final states = await _customerService.getAllStates();

    setState(() {
      _customers = customers;
      _states = states;
      _isLoading = false;
    });
  }

  List<Customer> get _filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    return _customers
        .where(
          (c) =>
              c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (c.phone?.contains(_searchQuery) ?? false) ||
              (c.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                  false),
        )
        .toList();
  }

  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    final taxIdController = TextEditingController();
    final creditLimitController = TextEditingController();
    final creditDaysController = TextEditingController();
    Region? selectedState;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Customer'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Region>(
                        value: selectedState,
                        decoration: const InputDecoration(
                          labelText: 'State/Region',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Select State'),
                          ),
                          ..._states.map(
                            (state) => DropdownMenuItem(
                              value: state,
                              child: Text(state.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedState = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: taxIdController,
                        decoration: const InputDecoration(
                          labelText: 'Tax ID / VAT Number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: creditLimitController,
                              decoration: const InputDecoration(
                                labelText: 'Credit Limit',
                                prefixText: '₦',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: creditDaysController,
                              decoration: const InputDecoration(
                                labelText: 'Credit Days',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
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
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter customer name'),
                        ),
                      );
                      return;
                    }

                    await _customerService.addCustomer(
                      name: nameController.text,
                      phone: phoneController.text.isEmpty
                          ? null
                          : phoneController.text,
                      email: emailController.text.isEmpty
                          ? null
                          : emailController.text,
                      address: addressController.text.isEmpty
                          ? null
                          : addressController.text,
                      stateId: selectedState?.id,
                      taxId: taxIdController.text.isEmpty
                          ? null
                          : taxIdController.text,
                      creditLimit:
                          double.tryParse(creditLimitController.text) ?? 0,
                      creditDays: int.tryParse(creditDaysController.text) ?? 0,
                    );

                    Navigator.pop(context);
                    _loadData();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Customer added successfully'),
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

  void _showEditCustomerDialog(Customer customer) {
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone ?? '');
    final emailController = TextEditingController(text: customer.email ?? '');
    final addressController = TextEditingController(
      text: customer.address ?? '',
    );
    final taxIdController = TextEditingController(text: customer.taxId ?? '');
    final creditLimitController = TextEditingController(
      text: customer.creditLimit.toString(),
    );
    final creditDaysController = TextEditingController(
      text: customer.creditDays.toString(),
    );

    Region? selectedState = _states.firstWhere(
      (s) => s.id == customer.stateId,
      orElse: () => Region(id: 0, name: ''),
    );
    if (selectedState.id == 0) selectedState = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Customer'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Region>(
                        value: selectedState,
                        decoration: const InputDecoration(
                          labelText: 'State/Region',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Select State'),
                          ),
                          ..._states.map(
                            (state) => DropdownMenuItem(
                              value: state,
                              child: Text(state.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedState = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: taxIdController,
                        decoration: const InputDecoration(
                          labelText: 'Tax ID / VAT Number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: creditLimitController,
                              decoration: const InputDecoration(
                                labelText: 'Credit Limit',
                                prefixText: '₦',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: creditDaysController,
                              decoration: const InputDecoration(
                                labelText: 'Credit Days',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
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
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter customer name'),
                        ),
                      );
                      return;
                    }

                    final updatedCustomer = Customer(
                      id: customer.id,
                      name: nameController.text,
                      phone: phoneController.text.isEmpty
                          ? null
                          : phoneController.text,
                      email: emailController.text.isEmpty
                          ? null
                          : emailController.text,
                      address: addressController.text.isEmpty
                          ? null
                          : addressController.text,
                      stateId: selectedState?.id,
                      stateName: selectedState?.name,
                      taxId: taxIdController.text.isEmpty
                          ? null
                          : taxIdController.text,
                      creditLimit:
                          double.tryParse(creditLimitController.text) ?? 0,
                      creditDays: int.tryParse(creditDaysController.text) ?? 0,
                      isActive: customer.isActive,
                      createdAt: customer.createdAt,
                    );

                    await _customerService.updateCustomer(updatedCustomer);
                    Navigator.pop(context);
                    _loadData();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Customer updated successfully'),
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

  void _deleteCustomer(Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.name}?'),
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
      await _customerService.deleteCustomer(customer.id);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer deleted'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCustomerDetails(Customer customer) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(customer.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (customer.phone != null) Text('📞 ${customer.phone}'),
              if (customer.email != null) Text('✉️ ${customer.email}'),
              if (customer.address != null) Text('📍 ${customer.address}'),
              if (customer.stateName != null) Text('🏢 ${customer.stateName}'),
              if (customer.taxId != null) Text('🆔 Tax ID: ${customer.taxId}'),
              const Divider(),
              Text(
                '💳 Credit Limit: ₦${customer.creditLimit.toStringAsFixed(0)}',
              ),
              Text('📅 Credit Days: ${customer.creditDays}'),
              Text(
                '📅 Added: ${customer.createdAt.toString().substring(0, 10)}',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showEditCustomerDialog(customer);
              },
              child: const Text('Edit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteCustomer(customer);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers', style: TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF1e3a8a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCustomerDialog,
        backgroundColor: const Color(0xFF1e3a8a),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, phone or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Customer list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                ? const Center(child: Text('No customers found'))
                : ListView.builder(
                    itemCount: _filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = _filteredCustomers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              customer.name.isNotEmpty
                                  ? customer.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            customer.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (customer.phone != null)
                                Text(
                                  '📞 ${customer.phone}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              if (customer.stateName != null)
                                Text(
                                  '📍 ${customer.stateName}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                                onPressed: () =>
                                    _showEditCustomerDialog(customer),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteCustomer(customer),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () => _showCustomerDetails(customer),
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
