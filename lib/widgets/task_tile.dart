import 'package:flutter/material.dart';

import '../models/task.dart';

/// Wiederverwendbare Task-Zeile mit Checkbox zum Erledigen.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggleDone,
    this.onTap,
    this.shaded = false,
    this.projectIcon,
  });

  final Task task;
  final ValueChanged<bool> onToggleDone;

  /// Antippen der Zeile (öffnet z.B. die Detail-Seite).
  final VoidCallback? onTap;

  /// Für abwechselnde Zeilen-Schattierung (jede zweite Zeile).
  final bool shaded;

  /// Projekticon zum Anzeigen neben dem Titel.
  final String? projectIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = task.isDone;

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      onTap: onTap,
      tileColor: shaded
          ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.35)
          : null,
      leading: Checkbox(
        visualDensity: VisualDensity.compact,
        value: done,
        onChanged: (v) => onToggleDone(v ?? false),
      ),
      title: Row(
        children: [
          if (projectIcon != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(projectIcon!,
                  style: const TextStyle(fontSize: 16)),
            ),
          Expanded(
            child: Text(
              task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                decoration: done ? TextDecoration.lineThrough : null,
                color: done ? theme.disabledColor : null,
              ),
            ),
          ),
        ],
      ),
      subtitle: _buildSubtitle(theme),
    );
  }

  Widget? _buildSubtitle(ThemeData theme) {
    final chips = <Widget>[];

    // Next Action ist jetzt ein Attribut-Chip (Stern) wie size/context.
    if (task.nextAction) {
      chips.add(_Tag(label: '⭐', color: theme.colorScheme.primaryContainer));
    }
    if (task.size != null) {
      chips.add(_Tag(label: task.size!));
    }
    if (task.context != null) {
      chips.add(_Tag(label: task.context!));
    }
    if (task.deadlineDate != null) {
      final d = task.deadlineDate!;
      chips.add(_Tag(
        label:
            '⏰ ${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}',
        color: theme.colorScheme.errorContainer,
      ));
    }
    if ((task.project ?? task.projectId) != null) {
      chips.add(_Tag(label: '📁 ${task.project ?? task.projectId}'));
    }

    if (chips.isEmpty) return null;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(spacing: 6, runSpacing: 4, children: chips),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: theme.textTheme.labelSmall),
    );
  }
}
