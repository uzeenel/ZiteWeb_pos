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
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.createdAt,
    this.updatedAt,
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
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
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
    };
  }
}
