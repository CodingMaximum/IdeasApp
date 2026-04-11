import 'package:flutter/material.dart';

class ModuleCardShell extends StatelessWidget {
  final Widget header;
  final Widget child;

  const ModuleCardShell({
    super.key,
    required this.header,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}