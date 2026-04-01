
class Sale {
  int? id;
  String invoiceNumber;
  DateTime saleDate;
  double subtotal;
  double tax;
  double total;
  String paymentMethod;
  double paidAmount;
  double change;
  int? customerId;
  int? cashierId;
  List<SaleItem> items;

  Sale({
    this.id,
    required this.invoiceNumber,
    required this.saleDate,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.paidAmount,
    required this.change,
    this.customerId,
    this.cashierId,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'sale_date': saleDate.toIso8601String(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'payment_method': paymentMethod,
      'paid_amount': paidAmount,
      'change': change,
      'customer_id': customerId,
      'cashier_id': cashierId,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as int?,
      invoiceNumber: map['invoice_number'] as String? ?? '',
      saleDate: map['sale_date'] != null
          ? DateTime.parse(map['sale_date'] as String)
          : DateTime.now(),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['payment_method'] as String? ?? 'Cash',
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0,
      change: (map['change'] as num?)?.toDouble() ?? 0,
      customerId: map['customer_id'] as int?,
      cashierId: map['cashier_id'] as int?,
    );
  }
}

class SaleItem {
  int id;
  int saleId;
  int productId;
  int quantity;
  double unitPrice;
  double total;
  bool isVatExempt;

  // These will be populated from JOIN with products table
  String? productName;
  String? sku;
  String? categoryName;

  SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.isVatExempt,
    this.productName,
    this.sku,
    this.categoryName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total': total,
      'is_vat_exempt': isVatExempt ? 1 : 0,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    final quantityValue = map['quantity'];
    int quantityInt;
    if (quantityValue is int) {
      quantityInt = quantityValue;
    } else if (quantityValue is double) {
      quantityInt = quantityValue.toInt();
    } else {
      quantityInt = 0;
    }

    return SaleItem(
      id: map['id'] as int,
      saleId: map['sale_id'] as int,
      productId: map['product_id'] as int,
      quantity: quantityInt,
      unitPrice: (map['unit_price'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      isVatExempt: map['is_vat_exempt'] == 1,
      productName: map['product_name'] as String?,
      sku: map['sku'] as String?,
      categoryName: map['category_name'] as String?,
    );
  }
}
