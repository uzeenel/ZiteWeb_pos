import 'dart:convert';


class CreditSale {
  final int id;
  final int saleId;
  final int customerId;
  final String customerName;
  final String invoiceNumber;
  final DateTime saleDate;
  final double total;
  final DateTime dueDate;
  final String status; // pending, approved, rejected, partially_paid, paid
  final int? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final String? notes;
  final DateTime createdAt;
  final double paidAmount; // Add this field
  final double remainingAmount; // Add this field

  CreditSale({
    required this.id,
    required this.saleId,
    required this.customerId,
    required this.customerName,
    required this.invoiceNumber,
    required this.saleDate,
    required this.total,
    required this.dueDate,
    required this.status,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.rejectionReason,
    this.notes,
    required this.createdAt,
    this.paidAmount = 0, // Add this
    this.remainingAmount = 0, // Add this
  });

  factory CreditSale.fromMap(Map<String, dynamic> map) {
    final total = (json['total'] as num).toDouble();
    final paid = (json['paid_amount'] ?? 0).toDouble();
    return CreditSale(
      id: map['id'],
      saleId: map['sale_id'],
      customerId: map['customer_id'],
      customerName: map['customer_name'] ?? '',
      invoiceNumber: map['invoice_number'],
      saleDate: DateTime.parse(map['sale_date']),
      total: (map['total'] as num).toDouble(),
      dueDate: DateTime.parse(map['due_date']),
      status: map['status'],
      approvedBy: map['approved_by'],
      approvedByName: map['approved_by_name'],
      approvedAt: map['approved_at'] != null
          ? DateTime.parse(map['approved_at'])
          : null,
      rejectionReason: map['rejection_reason'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      total: total,
      paidAmount: paid,
      remainingAmount: total - paid,
    );
  }
}
