class BaseUnit {
  final int id;
  final String name;
  final String symbol;
  final String? description;

  BaseUnit({
    required this.id,
    required this.name,
    required this.symbol,
    this.description,
  });

  factory BaseUnit.fromMap(Map<String, dynamic> map) {
    return BaseUnit(
      id: map['id'],
      name: map['name'],
      symbol: map['symbol'],
      description: map['description'],
    );
  }
}
