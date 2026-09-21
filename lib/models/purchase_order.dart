class PurchaseOrder {
  final int id;
  final String poNumber;
  final int vendorId;
  final DateTime orderDate;
  final DateTime? expectedDelivery;
  final double subtotal;
  final double tax;
  final double total;
  final String status;
  final String? notes;
  final DateTime createdAt;

  PurchaseOrder({
    required this.id,
    required this.poNumber,
    required this.vendorId,
    required this.orderDate,
    this.expectedDelivery,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory PurchaseOrder.fromMap(Map<String, dynamic> map) {
    // Helper to safely convert to double
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Helper to safely convert to int
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // Helper to safely convert to DateTime
    DateTime toDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      return DateTime.parse(value.toString());
    }

    return PurchaseOrder(
      id: toInt(map['id']),
      poNumber: map['po_number']?.toString() ?? '',
      vendorId: toInt(map['vendor_id']),
      orderDate: toDateTime(map['order_date']),
      expectedDelivery: map['expected_delivery'] != null
          ? toDateTime(map['expected_delivery'])
          : null,
      subtotal: toDouble(map['subtotal']),
      tax: toDouble(map['tax']),
      total: toDouble(map['total']),
      status: map['status']?.toString() ?? 'pending',
      notes: map['notes']?.toString(),
      createdAt: toDateTime(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'po_number': poNumber,
      'vendor_id': vendorId,
      'order_date': orderDate.toIso8601String(),
      'expected_delivery': expectedDelivery?.toIso8601String(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class PurchaseOrderItem {
  final int id;
  final int purchaseOrderId;
  final int productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double total;
  double receivedQuantity;

  PurchaseOrderItem({
    required this.id,
    required this.purchaseOrderId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.receivedQuantity,
  });

  factory PurchaseOrderItem.fromMap(Map<String, dynamic> map) {
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

    return PurchaseOrderItem(
      id: toInt(map['id']),
      purchaseOrderId: toInt(map['purchase_order_id']),
      productId: toInt(map['product_id']),
      productName: map['product_name']?.toString() ?? '',
      quantity: toDouble(map['quantity']),
      unitPrice: toDouble(map['unit_price']),
      total: toDouble(map['total']),
      receivedQuantity: toDouble(map['received_quantity']),
    );
  }
}
