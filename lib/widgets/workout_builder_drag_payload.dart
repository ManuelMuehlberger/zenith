import '../models/typedefs.dart';

sealed class WorkoutBuilderDragPayload {
  const WorkoutBuilderDragPayload();
}

class TemplateDragPayload extends WorkoutBuilderDragPayload {
  const TemplateDragPayload({
    required this.templateId,
    required this.index,
    required this.parentFolderId,
  });

  final WorkoutTemplateId templateId;
  final int index;
  final WorkoutFolderId? parentFolderId;
}

class FolderDragPayload extends WorkoutBuilderDragPayload {
  const FolderDragPayload({
    required this.folderId,
    required this.index,
    required this.parentFolderId,
    required this.depth,
  });

  final WorkoutFolderId folderId;
  final int index;
  final WorkoutFolderId? parentFolderId;
  final int depth;
}
