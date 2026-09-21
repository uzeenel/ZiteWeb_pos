class Company {
  final int id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? taxId;
  final int? stateId;
  final String? stateName;
  final bool autoCashBook;
  final bool autoBankBook;
  final double defaultMarkupPercent;
  final bool vatEnabled;
  final double vatRate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? logoPath;

  Company({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.taxId,
    this.stateId,
    this.stateName,
    this.autoCashBook = true,
    this.autoBankBook = true,
    this.defaultMarkupPercent = 0,
    this.vatEnabled = false,
    this.vatRate = 7.5,
    this.createdAt,
    this.updatedAt,
    this.logoPath,
  });

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      phone: map['phone'],
      email: map['email'],
      taxId: map['tax_id'],
      stateId: map['state_id'],
      stateName: map['state_name'],
      autoCashBook: map['auto_cash_book'] == 1,
      autoBankBook: map['auto_bank_book'] == 1,
      defaultMarkupPercent: map['default_markup_percent'] != null
          ? double.tryParse(map['default_markup_percent'].toString()) ?? 0
          : 0,
      vatEnabled: map['vat_enabled'] == 1,
      vatRate: map['vat_rate'] != null
          ? double.tryParse(map['vat_rate'].toString()) ?? 0
          : 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      logoPath: map['logo_path'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'tax_id': taxId,
      'state_id': stateId,
      'auto_cash_book': autoCashBook ? 1 : 0,
      'auto_bank_book': autoBankBook ? 1 : 0,
      'default_markup_percent': defaultMarkupPercent,
      'vat_enabled': vatEnabled ? 1 : 0,
      'vat_rate': vatRate,
      'logo_path': logoPath,
    };
  }
}
