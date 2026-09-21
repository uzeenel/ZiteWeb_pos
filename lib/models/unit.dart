class Unit {
  final int id;
  final int baseUnitId;
  final String baseUnitName;
  final String name;
  final String symbol;
  final double conversionFactor;
  final bool isBaseUnit;

  Unit({
    required this.id,
    required this.baseUnitId,
    required this.baseUnitName,
    required this.name,
    required this.symbol,
    required this.conversionFactor,
    required this.isBaseUnit,
  });

  factory Unit.fromMap(Map<String, dynamic> map) {
    // Helper function to safely convert to double
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Helper function to safely convert to int
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Unit(
      id: toInt(map['id']),
      baseUnitId: map['base_unit_id'] != null ? toInt(map['base_unit_id']) : 0,
      baseUnitName: map['base_unit_name'] ?? '',
      name: map['name'] ?? '',
      symbol: map['symbol'] ?? '',
      conversionFactor: toDouble(map['conversion_factor']),
      isBaseUnit: map['is_base_unit'] == 1,
    );
  }
}
