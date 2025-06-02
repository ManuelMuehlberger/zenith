class WorkoutFolder {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkoutFolder({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkoutFolder.fromMap(Map<String, dynamic> map) {
    return WorkoutFolder(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  WorkoutFolder copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
