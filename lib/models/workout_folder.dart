import 'package:uuid/uuid.dart';

class WorkoutFolder {
  final String id;
  String name;
  int? orderIndex;

  WorkoutFolder({
    String? id,
    required this.name,
    this.orderIndex,
  }) : id = id ?? const Uuid().v4();

  factory WorkoutFolder.fromMap(Map<String, dynamic> map) {
    return WorkoutFolder(
      id: map['id'] as String,
      name: map['name'] as String,
      orderIndex: map['orderIndex'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'orderIndex': orderIndex,
    };
  }

  WorkoutFolder copyWith({
    String? id,
    String? name,
    int? orderIndex,
  }) {
    return WorkoutFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
