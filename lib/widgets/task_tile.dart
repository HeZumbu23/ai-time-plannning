import 'package:flutter/material.dart';

import '../models/task.dart';

/// Wiederverwendbare Task-Zeile mit Checkbox zum Erledigen.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggleDone,
    this.onToggleNextAction,
    this.onTap,
    this.shaded = false,
  });

  final Task task;
  final ValueChanged<bool> onToggleDone;
  final VoidCallback? onToggleNextAction;

  /// Antippen der Zeile (öffnet z.B. die Detail-Seite).
  final VoidCallback? onTap;

  /// Für abwechselnde Zeilen-Schattierung (jede zweite Zeile).
  final bool shaded;

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
      title: Text(
        task.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          decoration: done ? TextDecoration.lineThrough : null,
          color: done ? theme.disabledColor : null,
        ),
      ),
      subtitle: _buildSubtitle(theme),
      trailing: onToggleNextAction == null
          ? null
          : IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Next Action',
              icon: Icon(
                task.nextAction ? Icons.bolt : Icons.bolt_outlined,
                color: task.nextAction ? theme.colorScheme.primary : null,
              ),
              onPressed: onToggleNextAction,
            ),
    );
  }

  Widget? _buildSubtitle(ThemeData theme) {
    final chips = <Widget>[];

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
