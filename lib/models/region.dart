class Region {
  final int id;
  final String name;
  final String? code;
  final bool isActive;

  Region({
    required this.id,
    required this.name,
    this.code,
    this.isActive = true,
  });

  factory Region.fromMap(Map<String, dynamic> map) {
    return Region(
      id: map['id'],
      name: map['name'],
      code: map['code'],
      isActive: map['is_active'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'is_active': isActive ? 1 : 0,
    };
  }
}
