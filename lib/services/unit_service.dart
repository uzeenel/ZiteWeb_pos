import 'package:pos_system/models/unit.dart';
import 'package:pos_system/services/api_service.dart';

class UnitService {
  // Get all units
  // Get all units
  Future<List<Unit>> getAllUnits() async {
    try {
      final response = await ApiService.getUnits();
      final units = response.map((json) => Unit.fromMap(json)).toList();
      return units;
    } catch (e) {
      print('Error fetching units from API: $e');
      return [];
    }
  }

  // Get all base units (units that are base for conversion)
  Future<List<Unit>> getAllBaseUnits() async {
    try {
      final units = await getAllUnits();
      return units.where((u) => u.isBaseUnit).toList();
    } catch (e) {
      print('Error fetching base units: $e');
      return [];
    }
  }

  // Get unit by ID
  Future<Unit?> getUnitById(int id) async {
    try {
      final response = await ApiService.getUnitById(id);
      if (response.isNotEmpty) {
        return Unit.fromMap(response);
      }
      return null;
    } catch (e) {
      print('Error fetching unit by ID from API: $e');
      return null;
    }
  }

  // Get unit by name
  Future<Unit?> getUnitByName(String name) async {
    try {
      final units = await getAllUnits();
      return units.firstWhere(
        (u) => u.name.toLowerCase() == name.toLowerCase(),
        orElse: () => throw Exception('Unit not found'),
      );
    } catch (e) {
      print('Error fetching unit by name from API: $e');
      return null;
    }
  }

  // Get unit by symbol
  Future<Unit?> getUnitBySymbol(String symbol) async {
    try {
      final units = await getAllUnits();
      return units.firstWhere(
        (u) => u.symbol == symbol,
        orElse: () => throw Exception('Unit not found'),
      );
    } catch (e) {
      print('Error fetching unit by symbol from API: $e');
      return null;
    }
  }

  // Get units for a specific product (for unit conversion)
  Future<List<Unit>> getUnitsForProduct(int productId) async {
    // For now, return all units
    return await getAllUnits();
  }

  // Add new unit
  Future<Unit> addUnit({
    required String name,
    required String symbol,
    int? baseUnitId,
    double? conversionFactor,
    bool? isBaseUnit,
  }) async {
    try {
      final unitData = {
        'name': name,
        'symbol': symbol,
        'baseUnitId': baseUnitId,
        'conversionFactor': conversionFactor ?? 1.0,
        'isBaseUnit': isBaseUnit ?? false,
      };

      final response = await ApiService.addUnit(unitData);
      return Unit.fromMap(response);
    } catch (e) {
      print('Error adding unit via API: $e');
      rethrow;
    }
  }

  // Add base unit
  Future<Unit> addBaseUnit({
    required String name,
    required String symbol,
  }) async {
    return await addUnit(
      name: name,
      symbol: symbol,
      isBaseUnit: true,
      conversionFactor: 1.0,
    );
  }

  // Update unit
  Future<bool> updateUnit(Unit unit) async {
    try {
      final unitData = {
        'name': unit.name,
        'symbol': unit.symbol,
        'baseUnitId': unit.baseUnitId,
        'conversionFactor': unit.conversionFactor,
        'isBaseUnit': unit.isBaseUnit ? 1 : 0,
      };

      await ApiService.updateUnit(unit.id, unitData);
      return true;
    } catch (e) {
      print('Error updating unit via API: $e');
      return false;
    }
  }

  // Delete unit (soft delete)
  Future<bool> deleteUnit(int id) async {
    try {
      await ApiService.deleteUnit(id);
      return true;
    } catch (e) {
      print('Error deleting unit via API: $e');
      return false;
    }
  }

  // Search units
  Future<List<Unit>> searchUnits(String query) async {
    try {
      final units = await getAllUnits();
      return units.where((u) {
        return u.name.toLowerCase().contains(query.toLowerCase()) ||
            u.symbol.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      print('Error searching units via API: $e');
      return [];
    }
  }
}
