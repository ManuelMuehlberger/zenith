import 'package:uuid/uuid.dart';
import 'typedefs.dart';

class WorkoutTemplate {
  final WorkoutTemplateId id;
  String name;
  String? description;
  int? iconCodePoint;
  int? colorValue;
  WorkoutFolderId? folderId;
  String? notes;
  String? lastUsed;
  int? orderIndex;

  WorkoutTemplate({
    WorkoutTemplateId? id,
    required this.name,
    this.description,
    this.iconCodePoint,
    this.colorValue,
    this.folderId,
    this.notes,
    this.lastUsed,
    this.orderIndex,
  }) : id = id ?? const Uuid().v4();

  factory WorkoutTemplate.fromMap(Map<String, dynamic> map) {
    return WorkoutTemplate(
      id: map['id'] as WorkoutTemplateId,
      name: map['name'] as String,
      description: map['description'] as String?,
      iconCodePoint: map['iconCodePoint'] as int?,
      colorValue: map['colorValue'] as int?,
      folderId: map['folderId'] as WorkoutFolderId?,
      notes: map['notes'] as String?,
      lastUsed: map['lastUsed'] as String?,
      orderIndex: map['orderIndex'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'folderId': folderId,
      'notes': notes,
      'lastUsed': lastUsed,
      'orderIndex': orderIndex,
    };
  }

  WorkoutTemplate copyWith({
    WorkoutTemplateId? id,
    String? name,
    Object? description = _undefined,
    Object? iconCodePoint = _undefined,
    Object? colorValue = _undefined,
    Object? folderId = _undefined,
    Object? notes = _undefined,
    Object? lastUsed = _undefined,
    Object? orderIndex = _undefined,
  }) {
    return WorkoutTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description == _undefined ? this.description : description as String?,
      iconCodePoint: iconCodePoint == _undefined ? this.iconCodePoint : iconCodePoint as int?,
      colorValue: colorValue == _undefined ? this.colorValue : colorValue as int?,
      folderId: folderId == _undefined ? this.folderId : folderId as WorkoutFolderId?,
      notes: notes == _undefined ? this.notes : notes as String?,
      lastUsed: lastUsed == _undefined ? this.lastUsed : lastUsed as String?,
      orderIndex: orderIndex == _undefined ? this.orderIndex : orderIndex as int?,
    );
  }
}

// Sentinel object to distinguish between null and undefined
const Object _undefined = Object();
