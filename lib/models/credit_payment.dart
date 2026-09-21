// lib/models/credit_payment.dart

class CreditPayment {
  final int id;
  final int creditSaleId;
  final int customerId;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod; // cash, card, transfer
  final String? referenceNumber;
  final String? notes;
  final int? recordedBy;
  final String? recordedByName;

  CreditPayment({
    required this.id,
    required this.creditSaleId,
    required this.customerId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.referenceNumber,
    this.notes,
    this.recordedBy,
    this.recordedByName,
  });

  factory CreditPayment.fromJson(Map<String, dynamic> json) {
    return CreditPayment(
      id: json['id'],
      creditSaleId: json['credit_sale_id'],
      customerId: json['customer_id'],
      amount: (json['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['payment_date']),
      paymentMethod: json['payment_method'],
      referenceNumber: json['reference_number'],
      notes: json['notes'],
      recordedBy: json['recorded_by'],
      recordedByName: json['recorded_by_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'credit_sale_id': creditSaleId,
      'customer_id': customerId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'payment_method': paymentMethod,
      'reference_number': referenceNumber,
      'notes': notes,
      'recorded_by': recordedBy,
    };
  }
}
