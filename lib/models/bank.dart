class Bank {
  final int id;
  final String name;
  final String? code;
  final bool isActive;
  final DateTime createdAt;

  Bank({
    required this.id,
    required this.name,
    this.code,
    this.isActive = true,
    required this.createdAt,
  });

  factory Bank.fromMap(Map<String, dynamic> map) {
    return Bank(
      id: map['id'],
      name: map['name'],
      code: map['code'],
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
