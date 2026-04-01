import 'package:flutter/material.dart';
import 'package:pos_system/services/vendor_service.dart';
import 'package:pos_system/models/vendor.dart';
import 'package:pos_system/models/region.dart';
import 'package:pos_system/screens/unauthorized_screen.dart';
import 'package:pos_system/utils/permissions.dart';

class VendorManagementScreen extends StatefulWidget {
  const VendorManagementScreen({super.key});

  @override
  State<VendorManagementScreen> createState() => _VendorManagementScreenState();
}

class _VendorManagementScreenState extends State<VendorManagementScreen> {
  final VendorService _vendorService = VendorService();
  List<Vendor> _vendors = [];
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

    final vendors = await _vendorService.getAllVendors();
    final states = await _vendorService.getAllStates();

    setState(() {
      _vendors = vendors;
      _states = states;
      _isLoading = false;
    });
  }

  List<Vendor> get _filteredVendors {
    if (_searchQuery.isEmpty) return _vendors;
    return _vendors
        .where(
          (v) =>
              v.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (v.phone?.contains(_searchQuery) ?? false) ||
              (v.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                  false),
        )
        .toList();
  }

  void _showAddVendorDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    final contactController = TextEditingController();
    final taxIdController = TextEditingController();
    final paymentTermsController = TextEditingController();
    Region? selectedState;
    bool isVatRegistered = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Vendor'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Company Name *',
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
                        controller: contactController,
                        decoration: const InputDecoration(
                          labelText: 'Contact Person',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: taxIdController,
                        decoration: const InputDecoration(
                          labelText: 'Tax ID / RC Number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: paymentTermsController,
                        decoration: const InputDecoration(
                          labelText: 'Payment Terms',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text('VAT Registered'),
                        value: isVatRegistered,
                        onChanged: (value) {
                          setState(() {
                            isVatRegistered = value!;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
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
                          content: Text('Please enter vendor name'),
                        ),
                      );
                      return;
                    }
                    await _vendorService.addVendor(
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
                      contactPerson: contactController.text.isEmpty
                          ? null
                          : contactController.text,
                      taxId: taxIdController.text.isEmpty
                          ? null
                          : taxIdController.text,
                      paymentTerms: paymentTermsController.text.isEmpty
                          ? null
                          : paymentTermsController.text,
                      isVatRegistered: isVatRegistered,
                    );
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vendor added successfully'),
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

  void _showEditVendorDialog(Vendor vendor) {
    final nameController = TextEditingController(text: vendor.name);
    final phoneController = TextEditingController(text: vendor.phone ?? '');
    final emailController = TextEditingController(text: vendor.email ?? '');
    final addressController = TextEditingController(text: vendor.address ?? '');
    final contactController = TextEditingController(
      text: vendor.contactPerson ?? '',
    );
    final taxIdController = TextEditingController(text: vendor.taxId ?? '');
    final paymentTermsController = TextEditingController(
      text: vendor.paymentTerms ?? '',
    );

    Region? selectedState = _states.firstWhere(
      (s) => s.id == vendor.stateId,
      orElse: () => Region(id: 0, name: ''),
    );
    if (selectedState.id == 0) selectedState = null;

    bool isVatRegistered = vendor.isVatRegistered;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Vendor'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Company Name *',
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
                        controller: contactController,
                        decoration: const InputDecoration(
                          labelText: 'Contact Person',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: taxIdController,
                        decoration: const InputDecoration(
                          labelText: 'Tax ID / RC Number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: paymentTermsController,
                        decoration: const InputDecoration(
                          labelText: 'Payment Terms',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text('VAT Registered'),
                        value: isVatRegistered,
                        onChanged: (value) {
                          setState(() {
                            isVatRegistered = value!;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
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
                          content: Text('Please enter vendor name'),
                        ),
                      );
                      return;
                    }
                    await _vendorService.updateVendor(
                      id: vendor.id,
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
                      contactPerson: contactController.text.isEmpty
                          ? null
                          : contactController.text,
                      taxId: taxIdController.text.isEmpty
                          ? null
                          : taxIdController.text,
                      paymentTerms: paymentTermsController.text.isEmpty
                          ? null
                          : paymentTermsController.text,
                      isVatRegistered: isVatRegistered,
                    );
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vendor updated successfully'),
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

  void _showDeleteDialog(Vendor vendor) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Vendor'),
          content: Text('Are you sure you want to delete "${vendor.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _vendorService.deleteVendor(vendor.id);
                Navigator.pop(context);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${vendor.name} deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Permissions.canManageVendors) {
      return const UnauthorizedScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Vendors', style: TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF1e3a8a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVendorDialog,
        backgroundColor: const Color(0xFF1e3a8a),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVendors.isEmpty
                ? const Center(child: Text('No vendors found'))
                : ListView.builder(
                    itemCount: _filteredVendors.length,
                    itemBuilder: (context, index) {
                      final vendor = _filteredVendors[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: const Icon(
                              Icons.business,
                              color: Colors.orange,
                            ),
                          ),
                          title: Text(
                            vendor.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (vendor.phone != null)
                                Text(
                                  vendor.phone!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              if (vendor.stateName != null)
                                Text(
                                  vendor.stateName!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              if (vendor.isVatRegistered)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'VAT Registered',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _showEditVendorDialog(vendor),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () => _showDeleteDialog(vendor),
                                color: Colors.red,
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () => _showEditVendorDialog(vendor),
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
