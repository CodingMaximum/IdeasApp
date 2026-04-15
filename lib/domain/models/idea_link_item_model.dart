class IdeaLinkItemModel {
  const IdeaLinkItemModel({
    required this.id,
    required this.moduleId,
    this.label,
    required this.url,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String moduleId;
  final String? label;
  final String url;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdeaLinkItemModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
