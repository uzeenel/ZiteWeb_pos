class StockMovement {
  final int id;
  final int productId;
  final String productName;
  final String sku;
  final DateTime date;
  final String reference; // PO-123, SALE-456, ADJ-789, RETURN-123
  final String movementType; // 'IN' or 'OUT'
  final double quantity;
  final double balanceBefore;
  final double balanceAfter;
  final String? notes;
  final int? userId;
  final String? unitSymbol;
  final String? invoiceNumber;

  StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.date,
    required this.reference,
    required this.movementType,
    required this.quantity,
    required this.balanceBefore,
    required this.balanceAfter,
    this.notes,
    this.userId,
    this.unitSymbol,
    this.invoiceNumber,
  });

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    // Helper function to safely convert to double
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return StockMovement(
      id: map['id'],
      productId: map['product_id'],
      productName: map['product_name'] ?? '',
      sku: map['sku'] ?? '',
      date: DateTime.parse(map['date']),
      reference: map['reference'] ?? '',
      movementType: map['movement_type'] ?? '',
      quantity: toDouble(map['quantity']),
      balanceBefore: toDouble(map['balance_before']),
      balanceAfter: toDouble(map['balance_after']),
      notes: map['notes'],
      userId: map['user_id'],
      unitSymbol: map['unit_symbol'],
      invoiceNumber: map['invoice_number'],
    );
  }
}
