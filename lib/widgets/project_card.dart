import 'package:flutter/material.dart';

import '../models/project.dart';

/// Kompakte Projektkarte für die Roadmap-Ansicht.
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.shaded = false,
  });

  final Project project;
  final VoidCallback onTap;
  final bool shaded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = shaded
        ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.35)
        : null;

    return ColoredBox(
      color: bg ?? Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(project.icon ?? '📁',
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(project.name,
                        style: theme.textTheme.titleSmall),
                    if (project.goal != null && project.goal!.isNotEmpty)
                      Text(
                        project.goal!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (project.size != null)
                _SizeChip(size: project.size!, theme: theme),
              if (project.priority != null) ...[
                const SizedBox(width: 4),
                _PriorityDot(priority: project.priority!),
              ],
              if (project.status != null) ...[
                const SizedBox(width: 6),
                _StatusChip(status: project.status!, theme: theme),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({required this.size, required this.theme});
  final String size;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final color = switch (size) {
      'S' => theme.colorScheme.tertiaryContainer,
      'M' => theme.colorScheme.secondaryContainer,
      'L' => theme.colorScheme.primaryContainer,
      _ => theme.colorScheme.surfaceContainer,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(size,
          style: theme.textTheme.labelSmall
              ?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  const _PriorityDot({required this.priority});
  final String priority;

  @override
  Widget build(BuildContext context) {
    final emoji = switch (priority) {
      'high' => '🔴',
      'medium' => '🟡',
      'low' => '🟢',
      _ => '',
    };
    if (emoji.isEmpty) return const SizedBox.shrink();
    return Text(emoji, style: const TextStyle(fontSize: 13));
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.theme});
  final String status;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'active' => theme.colorScheme.primaryContainer,
      'done' => theme.colorScheme.surfaceContainerHighest,
      _ => theme.colorScheme.tertiaryContainer,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(status, style: theme.textTheme.labelSmall),
    );
  }
}
