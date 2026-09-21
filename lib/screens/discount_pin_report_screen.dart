import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zite_web_pos/services/api_service.dart';
import 'package:zite_web_pos/utils/permissions.dart';
import 'package:zite_web_pos/screens/unauthorized_screen.dart';

class DiscountPinReportScreen extends StatefulWidget {
  const DiscountPinReportScreen({super.key});

  @override
  State<DiscountPinReportScreen> createState() =>
      _DiscountPinReportScreenState();
}

class _DiscountPinReportScreenState extends State<DiscountPinReportScreen> {
  List<Map<String, dynamic>> _pins = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String _statusFilter = 'all';
  DateTime? _start;
  DateTime? _end;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final pins = await ApiService.getDiscountPins(
      status: _statusFilter == 'all' ? null : _statusFilter,
      start: _start,
      end: _end,
    );
    setState(() {
      _pins = pins;
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    final q = _searchController.text.trim();
    setState(() {
      _filtered = q.isEmpty
          ? _pins
          : _pins.where((p) => p['pin'].toString().contains(q)).toList();
    });
  }

    Future<void> _export() async {
    if (_filtered.isEmpty) return;

    final csv = StringBuffer();
    csv.writeln(
      'PIN,Max Type,Max Value,Status,Created By,Created At,Used By,Used At,Applied,Sale Invoice,Notes',
    );

    for (final p in _filtered) {
      final used = p['used_at'] != null;
      csv.writeln(
        [
          p['pin'] ?? '',
          p['max_discount_type'] ?? '',
          p['max_discount_value'] ?? '',
          used ? 'Used' : 'Unused',
          p['created_by_username'] ?? '',
          p['created_at'] ?? '',
          p['used_by_username'] ?? '',
          p['used_at'] ?? '',
          p['discount_applied'] ?? '',
          p['sale_invoice'] ?? '',
          (p['notes'] ?? '').toString().replaceAll(',', ' '),
        ].join(','),
      );
    }

    final bytes = utf8.encode(csv.toString());
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final filename =
        'DiscountPINs_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    html.document.body!.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Exported $filename')));
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _start != null && _end != null
          ? DateTimeRange(start: _start!, end: _end!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _start = picked.start;
        _end = picked.end;
      });
      _load();
    }
  }

  void _clearDates() {
    setState(() {
      _start = null;
      _end = null;
    });
    _load();
  }

  Widget _statusChip(Map<String, dynamic> pin) {
    final used = pin['used_at'] != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: used ? Colors.grey.shade300 : Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        used ? 'Used' : 'Unused',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: used ? Colors.grey.shade700 : Colors.green.shade800,
        ),
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
          'Discount PIN Report',
          style: TextStyle(fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1e3a8a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _filtered.isEmpty ? null : _export,
            tooltip: 'Export CSV',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Search by PIN...',
                      hintStyle: const TextStyle(color: Colors.black54),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 18,
                        color: Colors.black54,
                      ),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    onChanged: (_) => _applyFilter(),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _statusFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'used', child: Text('Used')),
                    DropdownMenuItem(value: 'unused', child: Text('Unused')),
                  ],
                  onChanged: (v) {
                    setState(() => _statusFilter = v ?? 'all');
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range, size: 16),
                  label: Text(
                    _start == null
                        ? 'Date range'
                        : '${DateFormat('dd/MM').format(_start!)} - ${DateFormat('dd/MM').format(_end!)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                if (_start != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: _clearDates,
                    tooltip: 'Clear dates',
                  ),
              ],
            ),
          ),
          // Body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                ? const Center(child: Text('No PINs found'))
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('PIN')),
                          DataColumn(label: Text('Max')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Created by')),
                          DataColumn(label: Text('Created at')),
                          DataColumn(label: Text('Used by')),
                          DataColumn(label: Text('Used at')),
                          DataColumn(label: Text('Applied')),
                          DataColumn(label: Text('Sale')),
                          DataColumn(label: Text('Notes')),
                        ],
                        rows: _filtered.map((p) {
                          final maxType = p['max_discount_type'];
                          final maxVal = p['max_discount_value'];
                          final maxLabel = maxType == 'percent'
                              ? '$maxVal%'
                              : '₦$maxVal';
                          final createdAt = p['created_at'] != null
                              ? DateFormat('dd/MM/yy HH:mm').format(
                                  DateTime.parse(p['created_at']).toLocal(),
                                )
                              : '-';
                          final usedAt = p['used_at'] != null
                              ? DateFormat(
                                  'dd/MM/yy HH:mm',
                                ).format(DateTime.parse(p['used_at']).toLocal())
                              : '-';

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  p['pin'].toString(),
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(Text(maxLabel)),
                              DataCell(_statusChip(p)),
                              DataCell(Text(p['created_by_username'] ?? '-')),
                              DataCell(Text(createdAt)),
                              DataCell(Text(p['used_by_username'] ?? '-')),
                              DataCell(Text(usedAt)),
                              DataCell(
                                Text(
                                  p['discount_applied'] != null
                                      ? '₦${p['discount_applied']}'
                                      : '-',
                                ),
                              ),
                              DataCell(Text(p['sale_invoice'] ?? '-')),
                              DataCell(Text(p['notes'] ?? '-')),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
