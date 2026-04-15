class IdeaChecklistItemModel {
  const IdeaChecklistItemModel({
    required this.id,
    required this.moduleId,
    required this.content,
    required this.isDone,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String moduleId;
  final String content;
  final bool isDone;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdeaChecklistItemModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
