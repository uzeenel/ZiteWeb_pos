class Product {
  final int id;
  final String name;
  final String sku;
  final String? barcode;
  final int? categoryId;
  final String? categoryName;
  final int? unitId;
  final String? unitName;
  final double costPrice;
  final double sellingPrice;
  final double stockQuantity;
  final double minStockLevel;
  final bool isVatExempt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? imageUrl;
  final double? markupPercent;
  final bool markupIsManual;
  final double effectiveMarkupPercent;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    this.barcode,
    this.categoryId,
    this.categoryName,
    this.unitId,
    this.unitName,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.minStockLevel,
    required this.isVatExempt,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.imageUrl,
    this.markupPercent,
    this.markupIsManual = false,
    this.effectiveMarkupPercent = 0,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Product(
      id: toInt(map['id']),
      name: map['name'] ?? '',
      sku: map['sku'] ?? '',
      barcode: map['barcode'],
      categoryId: map['category_id'] != null ? toInt(map['category_id']) : null,
      categoryName: map['category_name'],
      unitId: map['unit_id'] != null ? toInt(map['unit_id']) : null,
      unitName: map['unit_name'],
      costPrice: toDouble(map['cost_price']),
      sellingPrice: toDouble(map['selling_price']),
      stockQuantity: toDouble(map['stock_quantity']),
      minStockLevel: toDouble(map['min_stock_level']),
      isVatExempt: map['is_vat_exempt'] == 1,
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      imageUrl: map['image_url'],
      markupPercent: map['markup_percent'] != null
          ? toDouble(map['markup_percent'])
          : null,
      markupIsManual: map['markup_is_manual'] == 1,
      effectiveMarkupPercent: toDouble(map['effective_markup_percent']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'category_id': categoryId,
      'unit_id': unitId,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'stock_quantity': stockQuantity,
      'min_stock_level': minStockLevel,
      'is_vat_exempt': isVatExempt ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'image_url': imageUrl,
      'markup_percent': markupPercent,
      'markup_is_manual': markupIsManual ? 1 : 0,
    };
  }
}
