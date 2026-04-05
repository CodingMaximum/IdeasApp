import 'package:drift/drift.dart';
import 'package:ideas_app/data/db/app_database.dart';
import 'seed_ids.dart';
import 'tables/categories.dart';
import 'tables/idea_statuses.dart';

class SeedDefaults {
  static List<CategoriesCompanion> get categories => [
        CategoriesCompanion.insert(
          id: SeedIds.giftCategory,
          name: 'Geschenkidee',
          isSystem: const Value(true),
          sortOrder: const Value(1),
          createdAt: (DateTime.now()),
          updatedAt: (DateTime.now()),
        ),
        CategoriesCompanion.insert(
          id: SeedIds.businessCategory,
          name: 'Geschäftsidee',
          isSystem: const Value(true),
          sortOrder: const Value(2),
          createdAt: (DateTime.now()),
          updatedAt: (DateTime.now()),
        ),
        CategoriesCompanion.insert(
          id: SeedIds.travelCategory,
          name: 'Reiseziele',
          isSystem: const Value(true),
          sortOrder: const Value(3),
          createdAt: (DateTime.now()),
          updatedAt: (DateTime.now()),
        ),
        CategoriesCompanion.insert(
          id: SeedIds.diyCategory,
          name: 'DIY',
          isSystem: const Value(true),
          sortOrder: const Value(4),
          createdAt: (DateTime.now()),
          updatedAt: (DateTime.now()),
        ),
        CategoriesCompanion.insert(
          id: SeedIds.otherCategory,
          name: 'Sonstiges',
          isSystem: const Value(true),
          sortOrder: const Value(5),
          createdAt: (DateTime.now()),
          updatedAt: (DateTime.now()),
        ),
      ];

static List<IdeaStatusesCompanion> get ideaStatuses => [
  IdeaStatusesCompanion.insert(
    id: SeedIds.planningStatus,
    name: 'Planung',
    isSystem: const Value(true),
    sortOrder: const Value(1),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  IdeaStatusesCompanion.insert(
    id: SeedIds.activeStatus,
    name: 'Aktiv',
    isSystem: const Value(true),
    sortOrder: const Value(2),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  IdeaStatusesCompanion.insert(
    id: SeedIds.pausedStatus,
    name: 'Pausiert',
    isSystem: const Value(true),
    sortOrder: const Value(3),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  IdeaStatusesCompanion.insert(
    id: SeedIds.deferredStatus,
    name: 'Zurückgestellt',
    isSystem: const Value(true),
    sortOrder: const Value(4),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
];  
}