import 'package:flutter/material.dart';
import 'package:ideas_app/data/db/app_database.dart';
import 'package:ideas_app/domain/models/idea_status_model.dart';

class StatusSelection extends StatelessWidget {
  final String value;
  final List<IdeaStatusModel> statuses;
  final ValueChanged<String> onChanged;

  const StatusSelection({
    super.key,
    required this.value,
    required this.statuses,
    required this.onChanged,
  });

  IconData _iconForStatus(String name) {
    switch (name.trim().toLowerCase()) {
      case 'planung':
        return Icons.psychology;
      case 'aktiv':
        return Icons.play_arrow;
      case 'pausiert':
        return Icons.pause;
      case 'zurückgestellt':
        return Icons.stop;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedStatus = statuses.firstWhere(
      (s) => s.id == value,
      orElse: () => statuses.first,
    );

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status - ${selectedStatus.name}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            showSelectedIcon: false,
            expandedInsets: EdgeInsets.zero,
            segments: statuses.map((status) {
              return ButtonSegment<String>(
                value: status.id,
                icon: Icon(_iconForStatus(status.name)),
                tooltip: status.name,
              );
            }).toList(),
            selected: {value},
            onSelectionChanged: (selection) {
              onChanged(selection.first);
            },
          ),
        ],
      ),
    );
  }
}