import 'package:ideas_app/domain/enums/idea_module_type.dart';

class IdeaModuleModel {
  const IdeaModuleModel({
    required this.id,
    required this.ideaId,
    required this.type,
    required this.title,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ideaId;
  final IdeaModuleType type;
  final String title;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdeaModuleModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
