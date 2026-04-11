import 'package:flutter/material.dart';
import 'package:ideas_app/data/db/app_database.dart';

class CategorySelection extends StatelessWidget {
  final String? value;
  final List<Category> categories;
  final ValueChanged<String?> onChanged;

  const CategorySelection({
    super.key,
    required this.value,
    required this.categories,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<String>(
      width: double.infinity,
      initialSelection: value,
      label: const Text('Kategorie'),
      dropdownMenuEntries: categories
          .map(
            (category) => DropdownMenuEntry<String>(
              value: category.id,
              label: category.name,
            ),
          )
          .toList(),
      onSelected: onChanged,
    );
  }
}