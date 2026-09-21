// lib/models/invoice.dart
import 'dart:convert';

class Invoice {
  final int id;
  final int vendorId;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final List<int> purchaseOrderIds;
  final double subtotal;
  final double tax;
  final double total;
  final double paidAmount;
  final double balance;
  final String status; // 'pending', 'partial', 'paid'
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    required this.id,
    required this.vendorId,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.purchaseOrderIds,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.paidAmount,
    required this.balance,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      vendorId: map['vendor_id'],
      invoiceNumber: map['invoice_number'],
      invoiceDate: DateTime.parse(map['invoice_date']),
      purchaseOrderIds: map['po_reference'] != null
          ? List<int>.from(jsonDecode(map['po_reference']))
          : [],
      subtotal: (map['subtotal'] as num).toDouble(),
      tax: (map['tax'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num).toDouble(),
      balance: (map['balance'] as num).toDouble(),
      status: map['status'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vendor_id': vendorId,
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate.toIso8601String().split('T')[0],
      'po_reference': jsonEncode(purchaseOrderIds),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'paid_amount': paidAmount,
      'balance': balance,
      'status': status,
      'notes': notes,
    };
  }
}

// lib/models/invoice_payment.dart
class InvoicePayment {
  final int id;
  final int invoiceId;
  final int? purchaseOrderId;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod;
  final String? reference;
  final String? notes;

  InvoicePayment({
    required this.id,
    required this.invoiceId,
    this.purchaseOrderId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.reference,
    this.notes,
  });
}
