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
    return BankTransaction(
      id: map['id'],
      date: DateTime.parse(map['date']),
      type: _stringToType(map['type']),
      amount: map['amount'].toDouble(),
      accountName: map['account_name'],
      bankName: map['bank_name'],
      chequeNumber: map['cheque_number'],
      description: map['description'],
      reference: map['reference'],
      userId: map['user_id'],
      createdAt: DateTime.parse(map['created_at']),
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
