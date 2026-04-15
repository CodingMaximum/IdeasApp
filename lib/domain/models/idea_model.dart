import 'package:ideas_app/domain/models/sync_status.dart';

class IdeaModel {
  const IdeaModel({
    required this.id,
    required this.title,
    this.description,
    this.categoryId,
    required this.statusId,
    this.archivedAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.syncStatus = SyncStatus.synced,
  });

  final String id;
  final String title;
  final String? description;
  final String? categoryId;
  final String statusId;
  final DateTime? archivedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final SyncStatus syncStatus;

  IdeaModel copyWith({
    String? id,
    String? title,
    String? description,
    String? categoryId,
    String? statusId,
    DateTime? archivedAt,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    SyncStatus? syncStatus,
  }) {
    return IdeaModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      statusId: statusId ?? this.statusId,
      archivedAt: archivedAt ?? this.archivedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdeaModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
