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
    return SalesReturn(
      id: map['id'],
      returnNumber: map['return_number'],
      saleId: map['sale_id'],
      invoiceNumber: map['invoice_number'],
      returnDate: DateTime.parse(map['return_date']),
      totalRefund: map['total_refund'].toDouble(),
      reason: map['reason'],
      status: stringToStatus(map['status']),
      cashierId: map['cashier_id'],
      createdAt: DateTime.parse(map['created_at']),
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
    return ReturnItem(
      id: map['id'],
      returnId: map['return_id'],
      saleItemId: map['sale_item_id'],
      productId: map['product_id'],
      productName: map['product_name'],
      sku: map['sku'],
      quantity: map['quantity'],
      unitPrice: map['unit_price'].toDouble(),
      total: map['total'].toDouble(),
      reason: map['reason'],
    );
  }
}
