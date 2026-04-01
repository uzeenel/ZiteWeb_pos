import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/models/company.dart';
import 'package:pos_system/models/region.dart';
import 'package:pos_system/services/company_service.dart';
import 'package:pos_system/screens/unauthorized_screen.dart';
import 'package:pos_system/utils/permissions.dart';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  final CompanyService _companyService = CompanyService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  // Form controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _taxIdController = TextEditingController();

  // Settings
  bool _autoCashBook = true;
  bool _autoBankBook = true;

  // Region selection
  List<Region> _regions = [];
  Region? _selectedRegion;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Load company data
    final company = await _companyService.getCompany();

    // Load regions/states
    final regions = await _companyService.getAllStates();

    setState(() {
      _regions = regions;

      if (company != null) {
        _nameController.text = company.name;
        _addressController.text = company.address ?? '';
        _phoneController.text = company.phone ?? '';
        _emailController.text = company.email ?? '';
        _taxIdController.text = company.taxId ?? '';
        _autoCashBook = company.autoCashBook;
        _autoBankBook = company.autoBankBook;

        if (company.stateId != null) {
          _selectedRegion = regions.firstWhere(
            (r) => r.id == company.stateId,
            orElse: () => Region(id: 0, name: ''),
          );
        }
      }

      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _companyService.saveCompany(
        name: _nameController.text,
        address: _addressController.text.isNotEmpty
            ? _addressController.text
            : null,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        taxId: _taxIdController.text.isNotEmpty ? _taxIdController.text : null,
        stateId: _selectedRegion?.id,
        autoCashBook: _autoCashBook,
        autoBankBook: _autoBankBook,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Permissions.canManageCompanySettings) {
      return const UnauthorizedScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Settings', style: TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF1e3a8a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveSettings,
            tooltip: 'Save',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Company Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Company Name',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.business),
                              ),
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'Company name is required'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Address',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_on),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 12),
                            // Region/State Dropdown
                            DropdownButtonFormField<Region>(
                              value: _selectedRegion,
                              decoration: const InputDecoration(
                                labelText: 'State/Region',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.map),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Select State/Region'),
                                ),
                                ..._regions.map((region) {
                                  return DropdownMenuItem(
                                    value: region,
                                    child: Text(region.name),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedRegion = value;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _taxIdController,
                              decoration: const InputDecoration(
                                labelText: 'Tax ID / VAT Number',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.receipt),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'System Settings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: const Text('Auto Cash Book'),
                              subtitle: const Text(
                                'Automatically add cash sales to cash book',
                              ),
                              value: _autoCashBook,
                              onChanged: (value) {
                                setState(() {
                                  _autoCashBook = value;
                                });
                              },
                              activeColor: Colors.green,
                            ),
                            const Divider(),
                            SwitchListTile(
                              title: const Text('Auto Bank Book'),
                              subtitle: const Text(
                                'Automatically add card/transfer sales to bank book',
                              ),
                              value: _autoBankBook,
                              onChanged: (value) {
                                setState(() {
                                  _autoBankBook = value;
                                });
                              },
                              activeColor: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveSettings,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }
}
