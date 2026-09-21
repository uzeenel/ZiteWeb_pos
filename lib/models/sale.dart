
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

    return Sale(
      id: _toInt(map['id']),
      invoiceNumber: map['invoice_number'] as String? ?? '',
      saleDate: map['sale_date'] != null
          ? DateTime.parse(map['sale_date'] as String)
          : DateTime.now(),
      subtotal: _toDouble(map['subtotal']),
      tax: _toDouble(map['tax']),
      total: _toDouble(map['total']),
      paymentMethod: map['payment_method'] as String? ?? 'Cash',
      paidAmount: _toDouble(map['paid_amount']),
      change: _toDouble(map['change_amount']),
      customerId: _toInt(map['customer_id']),
      cashierId: _toInt(map['cashier_id']),
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

    return SaleItem(
      id: _toInt(map['id']),
      saleId: _toInt(map['sale_id']),
      productId: _toInt(map['product_id']),
      quantity: _toInt(map['quantity']),
      unitPrice: _toDouble(map['unit_price']),
      total: _toDouble(map['total']),
      isVatExempt: map['is_vat_exempt'] == 1,
      productName: map['product_name'] as String?,
      sku: map['sku'] as String?,
      categoryName: map['category_name'] as String?,
    );
  }
}
