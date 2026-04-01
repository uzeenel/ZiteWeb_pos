class VendorPayment {
  int? id;
  int vendorId;
  String? vendorName;
  int? purchaseOrderId;
  String? purchaseOrderNumber;
  DateTime paymentDate;
  double amount;
  String paymentMethod; // Cash, Bank Transfer, Cheque, etc.
  String? reference;
  String? notes;
  int? createdBy;
  DateTime createdAt;
  DateTime? updatedAt;

  VendorPayment({
    this.id,
    required this.vendorId,
    this.vendorName,
    this.purchaseOrderId,
    this.purchaseOrderNumber,
    required this.paymentDate,
    required this.amount,
    required this.paymentMethod,
    this.reference,
    this.notes,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  factory VendorPayment.fromMap(Map<String, dynamic> map) {
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

    return VendorPayment(
      id: _toInt(map['id']),
      vendorId: _toInt(map['vendor_id']),
      vendorName: map['vendor_name'],
      purchaseOrderId: map['purchase_order_id'] != null
          ? _toInt(map['purchase_order_id'])
          : null,
      purchaseOrderNumber: map['purchase_order_number'],
      paymentDate: DateTime.parse(map['payment_date']),
      amount: _toDouble(map['amount']),
      paymentMethod: map['payment_method'] ?? 'Cash',
      reference: map['reference'],
      notes: map['notes'],
      createdBy: map['created_by'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'purchase_order_id': purchaseOrderId,
      'payment_date': paymentDate.toIso8601String(),
      'amount': amount,
      'payment_method': paymentMethod,
      'reference': reference,
      'notes': notes,
      'created_by': createdBy,
    };
  }
}

class VendorPaymentSummary {
  final int vendorId;
  final String vendorName;
  final double totalPurchases;
  final double totalPayments;
  final double balance;

  VendorPaymentSummary({
    required this.vendorId,
    required this.vendorName,
    required this.totalPurchases,
    required this.totalPayments,
    required this.balance,
  });
}
