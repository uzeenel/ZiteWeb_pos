enum ReturnStatus { pending, approved, rejected, completed }

class SalesReturn {
  int? id;
  String returnNumber;
  int saleId;
  String invoiceNumber;
  DateTime returnDate;
  double totalRefund;
  String reason;
  ReturnStatus status;
  int? cashierId;
  DateTime createdAt;
  List<ReturnItem> items;

  SalesReturn({
    this.id,
    required this.returnNumber,
    required this.saleId,
    required this.invoiceNumber,
    required this.returnDate,
    required this.totalRefund,
    required this.reason,
    required this.status,
    this.cashierId,
    required this.createdAt,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'return_number': returnNumber,
      'sale_id': saleId,
      'invoice_number': invoiceNumber,
      'return_date': returnDate.toIso8601String(),
      'total_refund': totalRefund,
      'reason': reason,
      'status': statusToString(status),
      'cashier_id': cashierId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SalesReturn.fromMap(Map<String, dynamic> map) {
    double _toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // Parse items
    List<ReturnItem> items = [];
    if (map['items'] != null && map['items'] is List) {
      items = (map['items'] as List).map((item) {
        return ReturnItem(
          id: _toInt(item['id']),
          returnId: _toInt(item['return_id']),
          saleItemId: _toInt(item['sale_item_id']),
          productId: _toInt(item['product_id']),
          productName: item['product_name'] ?? '',
          sku: item['sku'] ?? '',
          quantity: _toInt(item['quantity']),
          unitPrice: _toDouble(item['unit_price']),
          total: _toDouble(item['total']),
          reason: item['reason'] ?? '',
        );
      }).toList();
    }

    return SalesReturn(
      id: _toInt(map['id']),
      returnNumber: map['return_number'] ?? '',
      saleId: _toInt(map['sale_id']),
      invoiceNumber: map['invoice_number'] ?? '',
      returnDate: map['return_date'] != null
          ? DateTime.parse(map['return_date'])
          : DateTime.now(),
      totalRefund: _toDouble(map['total_refund']),
      reason: map['reason'] ?? '',
      status: stringToStatus(map['status'] ?? 'pending'),
      cashierId: _toInt(map['cashier_id']),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      items: items,
    );
  }

  static String statusToString(ReturnStatus status) {
    switch (status) {
      case ReturnStatus.pending:
        return 'pending';
      case ReturnStatus.approved:
        return 'approved';
      case ReturnStatus.rejected:
        return 'rejected';
      case ReturnStatus.completed:
        return 'completed';
    }
  }

  static ReturnStatus stringToStatus(String status) {
    switch (status) {
      case 'pending':
        return ReturnStatus.pending;
      case 'approved':
        return ReturnStatus.approved;
      case 'rejected':
        return ReturnStatus.rejected;
      case 'completed':
        return ReturnStatus.completed;
      default:
        return ReturnStatus.pending;
    }
  }
}

class ReturnItem {
  int id;
  int returnId;
  int saleItemId;
  int productId;
  String productName;
  String sku;
  int quantity;
  double unitPrice;
  double total;
  String reason;

  ReturnItem({
    required this.id,
    required this.returnId,
    required this.saleItemId,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'return_id': returnId,
      'sale_item_id': saleItemId,
      'product_id': productId,
      'product_name': productName,
      'sku': sku,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total': total,
      'reason': reason,
    };
  }

  factory ReturnItem.fromMap(Map<String, dynamic> map) {
    double _toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return ReturnItem(
      id: _toInt(map['id']),
      returnId: _toInt(map['return_id']),
      saleItemId: _toInt(map['sale_item_id']),
      productId: _toInt(map['product_id']),
      productName: map['product_name'] ?? '',
      sku: map['sku'] ?? '',
      quantity: _toInt(map['quantity']),
      unitPrice: _toDouble(map['unit_price']),
      total: _toDouble(map['total']),
      reason: map['reason'] ?? '',
    );
  }
}
