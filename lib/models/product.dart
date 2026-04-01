class Product {
  final int id;
  final int? categoryId;
  final String? categoryName;
  final int? unitId;
  final String? unitName;
  final String? unitSymbol;
  final String name;
  final String sku;
  final String? barcode;
  final double costPrice;
  final double sellingPrice;
  final double stockQuantity;
  final double minStockLevel;
  final bool isVatExempt;
  final bool isActive;

  Product({
    required this.id,
    this.categoryId,
    this.categoryName,
    this.unitId,
    this.unitName,
    this.unitSymbol,
    required this.name,
    required this.sku,
    this.barcode,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.minStockLevel,
    required this.isVatExempt,
    required this.isActive,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    // Helper function to safely convert to double
    double _toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Helper function to safely convert to int
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Product(
      id: _toInt(map['id']),
      categoryId: map['category_id'] != null
          ? _toInt(map['category_id'])
          : null,
      categoryName: map['category_name'],
      unitId: map['unit_id'] != null ? _toInt(map['unit_id']) : null,
      unitName: map['unit_name'],
      unitSymbol: map['unit_symbol'],
      name: map['name'] ?? '',
      sku: map['sku'] ?? '',
      barcode: map['barcode'],
      costPrice: _toDouble(map['cost_price']),
      sellingPrice: _toDouble(map['selling_price']),
      stockQuantity: _toDouble(map['stock_quantity']),
      minStockLevel: _toDouble(map['min_stock_level']),
      isVatExempt: map['is_vat_exempt'] == 1 || map['is_vat_exempt'] == true,
      isActive: map['is_active'] == 1 || map['is_active'] == true,
    );
  }
}
