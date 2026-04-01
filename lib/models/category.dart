class Category {
  final int id;
  final String name;
  final String? description;
  final bool isVatExempt;

  Category({
    required this.id,
    required this.name,
    this.description,
    required this.isVatExempt,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      isVatExempt: map['is_vat_exempt'] == 1,
    );
  }
}
