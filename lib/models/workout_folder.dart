import 'package:uuid/uuid.dart';
import 'typedefs.dart';

class WorkoutFolder {
  final WorkoutFolderId id;
  String name;
  WorkoutFolderId? parentFolderId;
  int depth;
  int? orderIndex;

  WorkoutFolder({
    WorkoutFolderId? id,
    required this.name,
    this.parentFolderId,
    this.depth = 0,
    this.orderIndex,
  }) : id = id ?? const Uuid().v4();

  factory WorkoutFolder.fromMap(Map<String, dynamic> map) {
    return WorkoutFolder(
      id: map['id'] as WorkoutFolderId,
      name: map['name'] as String,
      parentFolderId: map['parentFolderId'] as WorkoutFolderId?,
      depth: (map['depth'] as int?) ?? 0,
      orderIndex: map['orderIndex'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parentFolderId': parentFolderId,
      'depth': depth,
      'orderIndex': orderIndex,
    };
  }

  WorkoutFolder copyWith({
    WorkoutFolderId? id,
    String? name,
    Object? parentFolderId = _undefined,
    int? depth,
    Object? orderIndex = _undefined,
  }) {
    return WorkoutFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      parentFolderId: parentFolderId == _undefined
          ? this.parentFolderId
          : parentFolderId as WorkoutFolderId?,
      depth: depth ?? this.depth,
      orderIndex: orderIndex == _undefined
          ? this.orderIndex
          : orderIndex as int?,
    );
  }
}

// Sentinel object to distinguish between null and undefined
const Object _undefined = Object();
