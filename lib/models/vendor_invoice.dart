class VendorInvoice {
  final String invoiceNumber;
  final DateTime invoiceDate;
  final List<PurchaseOrderSummary> purchaseOrders;
  final double total;
  final double paid;
  final double balance;

  VendorInvoice({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.purchaseOrders,
    required this.total,
    required this.paid,
    required this.balance,
  });

  factory VendorInvoice.fromMap(Map<String, dynamic> map) {
    return VendorInvoice(
      invoiceNumber: map['invoice_number'],
      invoiceDate: DateTime.parse(map['invoice_date']),
      purchaseOrders: (map['purchase_orders'] as List)
          .map((po) => PurchaseOrderSummary.fromMap(po))
          .toList(),
      total: (map['total'] as num).toDouble(),
      paid: (map['paid'] as num).toDouble(),
      balance: (map['balance'] as num).toDouble(),
    );
  }
}

class PurchaseOrderSummary {
  final int id;
  final String poNumber;
  final double total;
  final double paid;
  final double balance;

  PurchaseOrderSummary({
    required this.id,
    required this.poNumber,
    required this.total,
    required this.paid,
    required this.balance,
  });

  factory PurchaseOrderSummary.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderSummary(
      id: map['id'],
      poNumber: map['po_number'],
      total: (map['total'] as num).toDouble(),
      paid: (map['paid'] as num).toDouble(),
      balance: (map['balance'] as num).toDouble(),
    );
  }
}
