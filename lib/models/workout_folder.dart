import 'package:uuid/uuid.dart';
import 'typedefs.dart';

class WorkoutFolder {
  final WorkoutFolderId id;
  String name;
  int? orderIndex;

  WorkoutFolder({
    WorkoutFolderId? id,
    required this.name,
    this.orderIndex,
  }) : id = id ?? const Uuid().v4();

  factory WorkoutFolder.fromMap(Map<String, dynamic> map) {
    return WorkoutFolder(
      id: map['id'] as WorkoutFolderId,
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
    WorkoutFolderId? id,
    String? name,
    Object? orderIndex = _undefined,
  }) {
    return WorkoutFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      orderIndex: orderIndex == _undefined ? this.orderIndex : orderIndex as int?,
    );
  }
}

// Sentinel object to distinguish between null and undefined
const Object _undefined = Object();
