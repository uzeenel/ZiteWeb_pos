class Vendor {
  final int id;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final int? stateId;
  final String? stateName;
  final String? taxId;
  final String? paymentTerms;
  final bool isVatRegistered;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Vendor({
    required this.id,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.stateId,
    this.stateName,
    this.taxId,
    this.paymentTerms,
    this.isVatRegistered = false,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Vendor.fromMap(Map<String, dynamic> map) {
    // Helper function to safely convert to double
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Helper function to safely convert to int
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Vendor(
      id: toInt(map['id']),
      name: map['name'] ?? '',
      contactPerson: map['contact_person'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      stateId: map['state_id'] != null ? toInt(map['state_id']) : null,
      stateName: map['state_name'],
      taxId: map['tax_id'],
      paymentTerms: map['payment_terms'],
      isVatRegistered: map['is_vat_registered'] == 1,
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
      'name': name,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'state_id': stateId,
      'tax_id': taxId,
      'payment_terms': paymentTerms,
      'is_vat_registered': isVatRegistered ? 1 : 0,
      'is_active': isActive ? 1 : 0,
    };
  }
}
