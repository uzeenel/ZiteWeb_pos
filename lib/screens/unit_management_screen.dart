import 'package:flutter/material.dart';
import 'package:pos_system/services/unit_service.dart';
import 'package:pos_system/models/unit.dart';
import 'package:pos_system/screens/unauthorized_screen.dart';
import 'package:pos_system/utils/permissions.dart';

class UnitManagementScreen extends StatefulWidget {
  const UnitManagementScreen({super.key});

  @override
  State<UnitManagementScreen> createState() => _UnitManagementScreenState();
}

class _UnitManagementScreenState extends State<UnitManagementScreen> {
  final UnitService _unitService = UnitService();
  List<Unit> _units = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    setState(() {
      _isLoading = true;
    });
    final units = await _unitService.getAllUnits();
    setState(() {
      _units = units;
      _isLoading = false;
    });
  }

  List<Unit> get _filteredUnits {
    if (_searchQuery.isEmpty) return _units;
    return _units
        .where(
          (u) =>
              u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              u.symbol.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  void _showAddUnitDialog() {
    final nameController = TextEditingController();
    final symbolController = TextEditingController();
    final conversionController = TextEditingController(text: '1');
    bool isBaseUnit = false;
    int? selectedBaseUnitId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Unit'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Unit Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: symbolController,
                      decoration: const InputDecoration(
                        labelText: 'Symbol *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text('Is Base Unit'),
                      value: isBaseUnit,
                      onChanged: (value) {
                        setState(() {
                          isBaseUnit = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (!isBaseUnit) ...[
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Base Unit *',
                          border: OutlineInputBorder(),
                        ),
                        items: _units.where((u) => u.isBaseUnit).map((u) {
                          return DropdownMenuItem(
                            value: u.id,
                            child: Text('${u.name} (${u.symbol})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedBaseUnitId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: conversionController,
                        decoration: const InputDecoration(
                          labelText: 'Conversion Factor (1 base unit = ?)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
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
                    if (nameController.text.isEmpty ||
                        symbolController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter name and symbol'),
                        ),
                      );
                      return;
                    }
                    await _unitService.addUnit(
                      name: nameController.text,
                      symbol: symbolController.text,
                      isBaseUnit: isBaseUnit,
                      baseUnitId: isBaseUnit ? null : selectedBaseUnitId,
                      conversionFactor: isBaseUnit
                          ? 1.0
                          : double.tryParse(conversionController.text) ?? 1.0,
                    );
                    Navigator.pop(context);
                    _loadUnits();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unit added successfully'),
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

  void _showEditUnitDialog(Unit unit) {
    final nameController = TextEditingController(text: unit.name);
    final symbolController = TextEditingController(text: unit.symbol);
    final conversionController = TextEditingController(
      text: unit.conversionFactor.toString(),
    );
    int? selectedBaseUnitId = unit.baseUnitId;
    bool isBaseUnit = unit.isBaseUnit;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Unit'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Unit Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: symbolController,
                      decoration: const InputDecoration(
                        labelText: 'Symbol *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text('Is Base Unit'),
                      value: isBaseUnit,
                      onChanged: (value) {
                        setState(() {
                          isBaseUnit = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (!isBaseUnit) ...[
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Base Unit *',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedBaseUnitId,
                        items: _units.where((u) => u.isBaseUnit).map((u) {
                          return DropdownMenuItem(
                            value: u.id,
                            child: Text('${u.name} (${u.symbol})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedBaseUnitId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: conversionController,
                        decoration: const InputDecoration(
                          labelText: 'Conversion Factor (1 base unit = ?)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
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
                    if (nameController.text.isEmpty ||
                        symbolController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter name and symbol'),
                        ),
                      );
                      return;
                    }
                    final updatedUnit = Unit(
                      id: unit.id,
                      name: nameController.text,
                      symbol: symbolController.text,
                      baseUnitId: isBaseUnit ? 0 : selectedBaseUnitId ?? 0,
                      baseUnitName: '',
                      conversionFactor: isBaseUnit
                          ? 1.0
                          : double.tryParse(conversionController.text) ?? 1.0,
                      isBaseUnit: isBaseUnit,
                    );
                    await _unitService.updateUnit(updatedUnit);
                    Navigator.pop(context);
                    _loadUnits();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unit updated successfully'),
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

  void _showDeleteDialog(Unit unit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Unit'),
        content: Text('Are you sure you want to delete "${unit.name}"?'),
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
      await _unitService.deleteUnit(unit.id);
      _loadUnits();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${unit.name} deleted'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Permissions.canManageUnits) {
      return const UnauthorizedScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Units', style: TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF1e3a8a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddUnitDialog,
            tooltip: 'Add Unit',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUnits,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or symbol...',
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
                : _filteredUnits.isEmpty
                ? const Center(child: Text('No units found'))
                : ListView.builder(
                    itemCount: _filteredUnits.length,
                    itemBuilder: (context, index) {
                      final unit = _filteredUnits[index];
                      final baseUnit = _units.firstWhere(
                        (u) => u.id == unit.baseUnitId,
                        orElse: () => Unit(
                          id: 0,
                          name: '',
                          symbol: '',
                          baseUnitId: 0,
                          baseUnitName: '',
                          conversionFactor: 1.0,
                          isBaseUnit: false,
                        ),
                      );
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal.shade100,
                            child: Text(
                              unit.symbol,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade800,
                              ),
                            ),
                          ),
                          title: Text(
                            unit.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: unit.isBaseUnit
                              ? Text(
                                  'Base Unit',
                                  style: const TextStyle(fontSize: 12),
                                )
                              : Text(
                                  '1 ${unit.symbol} = ${unit.conversionFactor} ${baseUnit.symbol}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _showEditUnitDialog(unit),
                              ),
                              if (!unit.isBaseUnit)
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  onPressed: () => _showDeleteDialog(unit),
                                  color: Colors.red,
                                ),
                            ],
                          ),
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
