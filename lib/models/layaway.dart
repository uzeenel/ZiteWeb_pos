class LayawayOrder {
  final int id;
  final int saleId;
  final int? customerId;
  final String invoiceNumber;
  final double totalAmount;
  final double depositAmount;
  final double paidAmount;
  final double balance;
  final String status;
  final List<dynamic> items;
  final String? notes;
  final int? cashierId;
  final DateTime createdAt;
  final DateTime updatedAt;

  LayawayOrder({
    required this.id,
    required this.saleId,
    this.customerId,
    required this.invoiceNumber,
    required this.totalAmount,
    required this.depositAmount,
    required this.paidAmount,
    required this.balance,
    required this.status,
    required this.items,
    this.notes,
    this.cashierId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LayawayOrder.fromMap(Map<String, dynamic> map) {
    return LayawayOrder(
      id: map['id'],
      saleId: map['sale_id'],
      customerId: map['customer_id'],
      invoiceNumber: map['invoice_number'] ?? '',
      totalAmount: _toDouble(map['total_amount']),
      depositAmount: _toDouble(map['deposit_amount']),
      paidAmount: _toDouble(map['paid_amount']),
      balance: _toDouble(map['balance']),
      status: map['status'] ?? 'active',
      items: map['items'] is String ? [] : (map['items'] as List? ?? []),
      notes: map['notes'],
      cashierId: map['cashier_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class LayawayPayment {
  final int id;
  final int layawayId;
  final double amount;
  final String paymentMethod;
  final String? reference;
  final String? notes;
  final int? recordedBy;
  final DateTime createdAt;

  LayawayPayment({
    required this.id,
    required this.layawayId,
    required this.amount,
    required this.paymentMethod,
    this.reference,
    this.notes,
    this.recordedBy,
    required this.createdAt,
  });

  factory LayawayPayment.fromMap(Map<String, dynamic> map) {
    return LayawayPayment(
      id: map['id'],
      layawayId: map['layaway_id'],
      amount: _toDouble(map['amount']),
      paymentMethod: map['payment_method'] ?? 'Cash',
      reference: map['reference'],
      notes: map['notes'],
      recordedBy: map['recorded_by'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
