class UserProfile {
  final String name;
  final int age;
  final String units; // 'metric' or 'imperial'
  final double weight;
  final DateTime createdAt;

  UserProfile({
    required this.name,
    required this.age,
    required this.units,
    required this.weight,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'units': units,
      'weight': weight,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      units: map['units'] ?? 'metric',
      weight: map['weight']?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  UserProfile copyWith({
    String? name,
    int? age,
    String? units,
    double? weight,
    DateTime? createdAt,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      units: units ?? this.units,
      weight: weight ?? this.weight,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get weightUnit => units == 'metric' ? 'kg' : 'lbs';
}
