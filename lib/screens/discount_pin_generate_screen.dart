import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zite_web_pos/services/api_service.dart';
import 'package:zite_web_pos/utils/permissions.dart';
import 'package:zite_web_pos/screens/unauthorized_screen.dart';

class DiscountPinGenerateScreen extends StatefulWidget {
  const DiscountPinGenerateScreen({super.key});

  @override
  State<DiscountPinGenerateScreen> createState() =>
      _DiscountPinGenerateScreenState();
}

class _DiscountPinGenerateScreenState extends State<DiscountPinGenerateScreen> {
  final _countController = TextEditingController(text: '5');
  final _valueController = TextEditingController(text: '10');
  final _notesController = TextEditingController();

  String _discountType = 'percent';
  bool _isGenerating = false;
  List<Map<String, dynamic>> _generatedPins = [];

  Future<void> _generate() async {
    final count = int.tryParse(_countController.text) ?? 0;
    final value = double.tryParse(_valueController.text) ?? 0;

    if (count < 1 || count > 100) {
      _showSnack('Count must be between 1 and 100', isError: true);
      return;
    }
    if (value <= 0) {
      _showSnack('Discount value must be positive', isError: true);
      return;
    }
    if (_discountType == 'percent' && value > 100) {
      _showSnack('Percent cannot exceed 100', isError: true);
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final result = await ApiService.generateDiscountPins(
        count: count,
        maxDiscountType: _discountType,
        maxDiscountValue: value,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      setState(() {
        _generatedPins = List<Map<String, dynamic>>.from(result['pins']);
        _isGenerating = false;
      });

      _showSnack('Generated ${_generatedPins.length} PINs');
    } catch (e) {
      setState(() => _isGenerating = false);
      _showSnack('Error: $e', isError: true);
    }
  }

  void _copyAllPins() {
    final text = _generatedPins
        .map(
          (p) =>
              '${p['pin']}  (max: ${p['max_discount_value']}${_discountType == 'percent' ? '%' : ''})',
        )
        .join('\n');
    Clipboard.setData(ClipboardData(text: text));
    _showSnack('Copied to clipboard');
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Permissions.canManageCompanySettings) {
      return const UnauthorizedScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Generate Discount PINs',
          style: TextStyle(fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1e3a8a),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                      'Generate a Batch',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _countController,
                            decoration: const InputDecoration(
                              labelText: 'How many PINs?',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _discountType,
                            decoration: const InputDecoration(
                              labelText: 'Discount Type',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'percent',
                                child: Text('Percent (%)'),
                              ),
                              DropdownMenuItem(
                                value: 'amount',
                                child: Text('Amount (₦)'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(
                                () => _discountType = value ?? 'percent',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _valueController,
                      decoration: InputDecoration(
                        labelText: _discountType == 'percent'
                            ? 'Max Discount (%)'
                            : 'Max Discount (₦)',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                        hintText: 'e.g. For manager John, week of 20 Sep',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isGenerating ? null : _generate,
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.vpn_key),
                        label: Text(
                          _isGenerating ? 'Generating...' : 'Generate',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1e3a8a),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_generatedPins.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Generated PINs',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _copyAllPins,
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('Copy all'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Print or copy this list. Store it securely — PINs are consumed once used.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      ..._generatedPins.map((p) {
                        final maxVal = p['max_discount_value'];
                        final suffix = _discountType == 'percent' ? '%' : '';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.circle, size: 6),
                              const SizedBox(width: 8),
                              SelectableText(
                                p['pin'].toString(),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '(max: $maxVal$suffix)',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _countController.dispose();
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
