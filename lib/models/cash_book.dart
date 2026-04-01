enum TransactionType { cashIn, cashOut }

class CashTransaction {
  int? id;
  DateTime date;
  TransactionType type;
  double amount;
  String category;
  String description;
  String? reference;
  int? userId;
  DateTime createdAt;

  CashTransaction({
    this.id,
    required this.date,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    this.reference,
    this.userId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type == TransactionType.cashIn ? 'cash_in' : 'cash_out',
      'amount': amount,
      'category': category,
      'description': description,
      'reference': reference,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CashTransaction.fromMap(Map<String, dynamic> map) {
    // Handle amount that might be string or number
    double amountValue;
    if (map['amount'] is String) {
      amountValue = double.tryParse(map['amount']) ?? 0;
    } else {
      amountValue = (map['amount'] as num).toDouble();
    }

    // Parse type correctly - database stores 'cash_in' and 'cash_out'
    TransactionType transactionType;
    final typeStr = map['type'] as String;
    if (typeStr == 'cash_in') {
      transactionType = TransactionType.cashIn;
    } else if (typeStr == 'cash_out') {
      transactionType = TransactionType.cashOut;
    } else {
      // Fallback for old data
      transactionType = typeStr == 'in'
          ? TransactionType.cashIn
          : TransactionType.cashOut;
    }

    return CashTransaction(
      id: map['id'],
      date: DateTime.parse(map['date']),
      type: transactionType,
      amount: amountValue,
      category: map['category'],
      description: map['description'],
      reference: map['reference'],
      userId: map['user_id'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }
}

class CashSummary {
  final double totalCashIn;
  final double totalCashOut;
  final double netCash;
  final double openingBalance;
  final double closingBalance;
  final int transactionCount;

  CashSummary({
    required this.totalCashIn,
    required this.totalCashOut,
    required this.netCash,
    required this.openingBalance,
    required this.closingBalance,
    required this.transactionCount,
  });
}
