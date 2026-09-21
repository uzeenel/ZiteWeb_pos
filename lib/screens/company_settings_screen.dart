import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zite_web_pos/models/company.dart';
import 'package:zite_web_pos/models/region.dart';
import 'package:zite_web_pos/services/company_service.dart';
import 'package:zite_web_pos/screens/unauthorized_screen.dart';
import 'package:zite_web_pos/utils/permissions.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
  final _defaultMarkupController = TextEditingController();
  final _vatRateController = TextEditingController();

  // Settings
  bool _autoCashBook = true;
  bool _autoBankBook = true;
  bool _vatEnabled = true;

  // Region selection
  List<Region> _regions = [];
  Region? _selectedRegion;

  // Logo
  String? _logoPath;
  File? _logoFile;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final company = await _companyService.getCompany();
    final regions = await _companyService.getAllStates();

    print('=== COMPANY DATA ===');
    print('Company: $company');
    print('Logo path: ${company?.logoPath}');

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
        _defaultMarkupController.text = company.defaultMarkupPercent.toString();
        _vatEnabled = company.vatEnabled;
        _vatRateController.text = company.vatRate.toString();
        _logoPath = company.logoPath; // Make sure this is being set

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

  Future<void> _pickLogo() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _logoFile = File(image.path);
          _logoPath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeLogo() async {
    setState(() {
      _logoFile = null;
      _logoPath = null;
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
        defaultMarkupPercent:
            double.tryParse(_defaultMarkupController.text) ?? 0,
        vatEnabled: _vatEnabled,
        vatRate: double.tryParse(_vatRateController.text) ?? 0,
        logoFile: _logoFile,
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
                            // Logo Section
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: _logoFile != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Image.file(
                                              _logoFile!,
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : _logoPath != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Image.network(
                                              'http://localhost:3000$_logoPath',
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    print(
                                                      'Image load error: $error',
                                                    );
                                                    return const Icon(
                                                      Icons.business,
                                                      size: 60,
                                                      color: Colors.grey,
                                                    );
                                                  },
                                            ),
                                          )
                                        : const Icon(
                                            Icons.business,
                                            size: 60,
                                            color: Colors.grey,
                                          ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton.icon(
                                        onPressed: _pickLogo,
                                        icon: const Icon(Icons.upload_file),
                                        label: const Text('Upload Logo'),
                                      ),
                                      if (_logoFile != null ||
                                          _logoPath != null)
                                        TextButton.icon(
                                          onPressed: _removeLogo,
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          label: const Text(
                                            'Remove',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Divider(),
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
                            DropdownButtonFormField<Region?>(
                              value: _selectedRegion,
                              decoration: const InputDecoration(
                                labelText: 'State/Region',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.map),
                              ),
                              items: [
                                const DropdownMenuItem<Region?>(
                                  value: null,
                                  child: Text('Select State/Region'),
                                ),
                                ..._regions.map((region) {
                                  return DropdownMenuItem<Region?>(
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
                              activeThumbColor: Colors.green,
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
                              activeThumbColor: Colors.blue,
                            ),

                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: TextFormField(
                                controller: _defaultMarkupController,
                                decoration: const InputDecoration(
                                  labelText: 'Default Markup %',
                                  helperText:
                                      'Applied to products without a category or product markup',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.trending_up),
                                  suffixText: '%',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                            ),

                            const Divider(),
                            SwitchListTile(
                              title: const Text('VAT Enabled'),
                              subtitle: const Text(
                                'Turn off for businesses that do not charge VAT',
                              ),
                              value: _vatEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _vatEnabled = value;
                                });
                              },
                              activeThumbColor: Colors.orange,
                            ),
                            if (_vatEnabled)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: TextFormField(
                                  controller: _vatRateController,
                                  decoration: const InputDecoration(
                                    labelText: 'VAT Rate',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.percent),
                                    suffixText: '%',
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
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
    _defaultMarkupController.dispose();
    _vatRateController.dispose();
    super.dispose();
  }
}
