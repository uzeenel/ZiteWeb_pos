enum BankTransactionType { deposit, withdrawal, transfer }

class BankTransaction {
  int? id;
  DateTime date;
  BankTransactionType type;
  double amount;
  String accountName;
  String bankName;
  String? chequeNumber;
  String description;
  String? reference;
  int? userId;
  DateTime createdAt;

  BankTransaction({
    this.id,
    required this.date,
    required this.type,
    required this.amount,
    required this.accountName,
    required this.bankName,
    this.chequeNumber,
    required this.description,
    this.reference,
    this.userId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': _typeToString(type),
      'amount': amount,
      'account_name': accountName,
      'bank_name': bankName,
      'cheque_number': chequeNumber,
      'description': description,
      'reference': reference,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BankTransaction.fromMap(Map<String, dynamic> map) {
    // Safe date parser
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      return DateTime.parse(value.toString());
    }

    // Safe amount parser
    double parseAmount(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return BankTransaction(
      id: map['id'],
      date: parseDate(map['date']),
      type: map['type'] == 'deposit'
          ? BankTransactionType.deposit
          : BankTransactionType.withdrawal,
      amount: parseAmount(map['amount']),
      accountName: map['account_name'] ?? '',
      bankName: map['bank_name'] ?? '',
      chequeNumber: map['cheque_number'],
      description: map['description'] ?? '',
      reference: map['reference'],
      userId: map['user_id'],
      createdAt: parseDate(map['created_at']),
    );
  }
  static String _typeToString(BankTransactionType type) {
    switch (type) {
      case BankTransactionType.deposit:
        return 'deposit';
      case BankTransactionType.withdrawal:
        return 'withdrawal';
      case BankTransactionType.transfer:
        return 'transfer';
    }
  }

  static BankTransactionType _stringToType(String type) {
    switch (type) {
      case 'deposit':
        return BankTransactionType.deposit;
      case 'withdrawal':
        return BankTransactionType.withdrawal;
      case 'transfer':
        return BankTransactionType.transfer;
      default:
        return BankTransactionType.deposit;
    }
  }
}

class BankSummary {
  final double totalDeposits;
  final double totalWithdrawals;
  final double netChange;
  final double openingBalance;
  final double closingBalance;
  final int transactionCount;
  final Map<String, double> bankBalances;

  BankSummary({
    required this.totalDeposits,
    required this.totalWithdrawals,
    required this.netChange,
    required this.openingBalance,
    required this.closingBalance,
    required this.transactionCount,
    required this.bankBalances,
  });
}
