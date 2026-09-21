enum ExpenseCategory {
  utilities,
  rent,
  salary,
  supplies,
  maintenance,
  marketing,
  transportation,
  taxes,
  insurance,
  software,
  training,
  legal,
  professional_fees,
  advertising,
  travel,
  meals,
  office_supplies,
  equipment,
  repairs,
  cleaning,
  security,
  internet,
  phone,
  electricity,
  bank_charges,
  subscriptions,
  refunds,
  discounts,
  shipping,
  packaging,
  raw_materials,
  inventory,
  other,
}

class Expense {
  int? id;
  DateTime date;
  ExpenseCategory category;
  double amount;
  String description;
  String? reference;
  String? vendor;
  final String? paymentMethod;
  int? userId;
  DateTime createdAt;
  final String? accountName;
  final String? bankName;
  final int? bankAccountId;

  Expense({
    this.id,
    required this.date,
    required this.category,
    required this.amount,
    required this.description,
    this.reference,
    this.vendor,
    this.paymentMethod,
    this.userId,
    required this.createdAt,
    this.accountName,
    this.bankName,
    this.bankAccountId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'category': categoryToString(category),
      'amount': amount,
      'description': description,
      'reference': reference,
      'vendor': vendor,
      'payment_method': paymentMethod,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'account_name': accountName,
      'bank_name': bankName,
      'bank_account_id': bankAccountId,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      category: stringToCategory(map['category'] ?? 'other'),
      amount: (map['amount'] is num)
          ? (map['amount'] as num).toDouble()
          : double.tryParse(map['amount'].toString()) ?? 0.0,
      description: map['description'] ?? '',
      reference: map['reference'],
      vendor: map['vendor'],
      paymentMethod: map['payment_method'] ?? map['paymentMethod'] ?? 'cash',
      createdAt: DateTime.parse(map['created_at']),
      accountName: map['account_name'],
      bankName: map['bank_name'],
    );
  }

  static String categoryToString(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.utilities:
        return 'utilities';
      case ExpenseCategory.rent:
        return 'rent';
      case ExpenseCategory.salary:
        return 'salary';
      case ExpenseCategory.supplies:
        return 'supplies';
      case ExpenseCategory.maintenance:
        return 'maintenance';
      case ExpenseCategory.marketing:
        return 'marketing';
      case ExpenseCategory.transportation:
        return 'transportation';
      case ExpenseCategory.taxes:
        return 'taxes';
      case ExpenseCategory.insurance:
        return 'insurance';
      case ExpenseCategory.software:
        return 'software';
      case ExpenseCategory.training:
        return 'training';
      case ExpenseCategory.legal:
        return 'legal';
      case ExpenseCategory.professional_fees:
        return 'professional_fees';
      case ExpenseCategory.advertising:
        return 'advertising';
      case ExpenseCategory.travel:
        return 'travel';
      case ExpenseCategory.meals:
        return 'meals';
      case ExpenseCategory.office_supplies:
        return 'office_supplies';
      case ExpenseCategory.equipment:
        return 'equipment';
      case ExpenseCategory.repairs:
        return 'repairs';
      case ExpenseCategory.cleaning:
        return 'cleaning';
      case ExpenseCategory.security:
        return 'security';
      case ExpenseCategory.internet:
        return 'internet';
      case ExpenseCategory.phone:
        return 'phone';
      case ExpenseCategory.electricity:
        return 'electricity';
      case ExpenseCategory.bank_charges:
        return 'bank_charges';
      case ExpenseCategory.subscriptions:
        return 'subscriptions';
      case ExpenseCategory.refunds:
        return 'refunds';
      case ExpenseCategory.discounts:
        return 'discounts';
      case ExpenseCategory.shipping:
        return 'shipping';
      case ExpenseCategory.packaging:
        return 'packaging';
      case ExpenseCategory.raw_materials:
        return 'raw_materials';
      case ExpenseCategory.inventory:
        return 'inventory';
      default:
        return 'other';
    }
  }

  static ExpenseCategory stringToCategory(String category) {
    switch (category) {
      case 'utilities':
        return ExpenseCategory.utilities;
      case 'rent':
        return ExpenseCategory.rent;
      case 'salary':
        return ExpenseCategory.salary;
      case 'supplies':
        return ExpenseCategory.supplies;
      case 'maintenance':
        return ExpenseCategory.maintenance;
      case 'marketing':
        return ExpenseCategory.marketing;
      case 'transportation':
        return ExpenseCategory.transportation;
      case 'taxes':
        return ExpenseCategory.taxes;
      case 'insurance':
        return ExpenseCategory.insurance;
      case 'software':
        return ExpenseCategory.software;
      case 'training':
        return ExpenseCategory.training;
      case 'legal':
        return ExpenseCategory.legal;
      case 'professional_fees':
        return ExpenseCategory.professional_fees;
      case 'advertising':
        return ExpenseCategory.advertising;
      case 'travel':
        return ExpenseCategory.travel;
      case 'meals':
        return ExpenseCategory.meals;
      case 'office_supplies':
        return ExpenseCategory.office_supplies;
      case 'equipment':
        return ExpenseCategory.equipment;
      case 'repairs':
        return ExpenseCategory.repairs;
      case 'cleaning':
        return ExpenseCategory.cleaning;
      case 'security':
        return ExpenseCategory.security;
      case 'internet':
        return ExpenseCategory.internet;
      case 'phone':
        return ExpenseCategory.phone;
      case 'electricity':
        return ExpenseCategory.electricity;
      case 'bank_charges':
        return ExpenseCategory.bank_charges;
      case 'subscriptions':
        return ExpenseCategory.subscriptions;
      case 'refunds':
        return ExpenseCategory.refunds;
      case 'discounts':
        return ExpenseCategory.discounts;
      case 'shipping':
        return ExpenseCategory.shipping;
      case 'packaging':
        return ExpenseCategory.packaging;
      case 'raw_materials':
        return ExpenseCategory.raw_materials;
      case 'inventory':
        return ExpenseCategory.inventory;
      default:
        return ExpenseCategory.other;
    }
  }
}

class ExpenseSummary {
  final double totalExpenses;
  final double totalByCategory;
  final int transactionCount;
  final Map<ExpenseCategory, double> categoryTotals;

  ExpenseSummary({
    required this.totalExpenses,
    required this.totalByCategory,
    required this.transactionCount,
    required this.categoryTotals,
  });
}
