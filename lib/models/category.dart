class Category {
  final int id;
  final String name;
  final String? description;
  final bool isVatExempt;
  final double? markupPercent;

  Category({
    required this.id,
    required this.name,
    this.description,
    required this.isVatExempt,
    this.markupPercent,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      isVatExempt: map['is_vat_exempt'] == 1,
      markupPercent: map['markup_percent'] != null
          ? double.tryParse(map['markup_percent'].toString())
          : null,
    );
  }
}
