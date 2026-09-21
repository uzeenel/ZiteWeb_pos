class BankAccount {
  final int id;
  final String accountName;
  final String bankName;
  final int? bankId;
  final String? accountNumber;
  final double openingBalance;
  final double currentBalance;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BankAccount({
    required this.id,
    required this.accountName,
    required this.bankName,
    this.bankId,
    this.accountNumber,
    this.openingBalance = 0.0,
    this.currentBalance = 0.0,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory BankAccount.fromMap(Map<String, dynamic> map) {
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return BankAccount(
      id: map['id'],
      accountName: map['account_name'],
      bankName: map['bank_name'],
      bankId: map['bank_id'],
      accountNumber: map['account_number'],
      openingBalance: toDouble(map['opening_balance']),
      currentBalance: toDouble(map['current_balance']),
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_name': accountName,
      'bank_name': bankName,
      'bank_id': bankId,
      'account_number': accountNumber,
      'opening_balance': openingBalance,
      'current_balance': currentBalance,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
