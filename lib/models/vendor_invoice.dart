// First, let's create an Invoice model
class VendorInvoice {
  final int id;
  final int purchaseOrderId;
  final String poNumber;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final double total;
  final double paid;
  final double balance;

  VendorInvoice({
    required this.id,
    required this.purchaseOrderId,
    required this.poNumber,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.total,
    required this.paid,
    required this.balance,
  });

  factory VendorInvoice.fromMap(Map<String, dynamic> map) {
    return VendorInvoice(
      id: map['id'],
      purchaseOrderId: map['purchase_order_id'],
      poNumber: map['po_number'],
      invoiceNumber: map['invoice_number'] ?? 'N/A',
      invoiceDate: DateTime.parse(map['order_date']),
      total: (map['total'] as num).toDouble(),
      paid: (map['paid'] as num).toDouble(),
      balance: (map['balance'] as num).toDouble(),
    );
  }
}
