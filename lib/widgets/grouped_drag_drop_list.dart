import 'package:flutter/material.dart';

import '../models/task.dart';
import 'task_tile.dart';

/// Datensatz für eine Gruppe im [GroupedDragDropList].
class GroupEntry<K> {
  const GroupEntry({
    required this.key,
    required this.title,
    required this.icon,
    required this.tasks,
  });

  final K key;
  final String title;
  final String icon;

  /// Tasks in dieser Gruppe. Leere Liste → Gruppe trotzdem angezeigt (als Drop-Ziel).
  final List<Task> tasks;
}

/// Generische Gruppen-Liste mit Drag & Drop zwischen Gruppen.
///
/// [K] ist der Gruppen-Schlüssel (z.B. `String?` für Tagesabschnitte,
/// `DateTime?` für Wochentage, `String?` für Projekt-IDs).
///
/// Drag-Verhalten:
/// - Langer Druck (mobil) oder Maus-Drag (Desktop/Web) startet den Drag.
/// - Der gezogene Task wird sofort aus seiner Gruppe ausgeblendet.
/// - Beim Ablegen auf einer anderen Gruppe wird [onMove] aufgerufen.
class GroupedDragDropList<K> extends StatefulWidget {
  const GroupedDragDropList({
    super.key,
    required this.groups,
    required this.onMove,
    required this.onTap,
    required this.onToggleDone,
    required this.onAddTask,
    this.projectIconFor,
    this.allCollapsed = false,
    this.collapseGen = 0,
    this.headerWidget,
  });

  /// Gruppen in der gewünschten Anzeigereihenfolge.
  final List<GroupEntry<K>> groups;

  /// Aufgerufen wenn ein Task in eine andere Gruppe gezogen wird.
  final Future<void> Function(Task task, K newGroup) onMove;

  /// Antippen einer Task-Zeile → öffnet Detail-Screen.
  final void Function(Task task) onTap;

  /// Checkbox-Toggle.
  final void Function(Task task, bool done) onToggleDone;

  /// "+" im Gruppen-Header → neue Task für diese Gruppe.
  final void Function(K groupKey) onAddTask;

  /// Liefert optionales Projekt-Icon für eine Task (erscheint in TaskTile).
  final String? Function(Task)? projectIconFor;

  final bool allCollapsed;
  final int collapseGen;

  /// Optionales Widget über den Gruppen (z.B. CollapseButton oder FilterChip).
  final Widget? headerWidget;

  @override
  State<GroupedDragDropList<K>> createState() =>
      _GroupedDragDropListState<K>();
}

class _GroupedDragDropListState<K>
    extends State<GroupedDragDropList<K>> {
  /// ID des Tasks, der gerade verschoben wird – wird in ALLEN Gruppen
  /// ausgeblendet, bis [onMove] abgeschlossen ist.
  String? _movingTaskId;

  Future<void> _handleMove(Task task, K newGroup) async {
    setState(() => _movingTaskId = task.id);
    await widget.onMove(task, newGroup);
    if (mounted) setState(() => _movingTaskId = null);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (widget.headerWidget != null) widget.headerWidget!,
        for (final group in widget.groups)
          _buildGroupCard(context, group),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildGroupCard(BuildContext context, GroupEntry<K> group) {
    final theme = Theme.of(context);
    final headerColor = theme.colorScheme.secondaryContainer;
    final onHeader = theme.colorScheme.onSecondaryContainer;

    final visibleTasks =
        group.tasks.where((t) => t.id != _movingTaskId).toList();

    return DragTarget<Task>(
      onWillAcceptWithDetails: (d) =>
          !group.tasks.any((t) => t.id == d.data.id),
      onAcceptWithDetails: (d) => _handleMove(d.data, group.key),
      builder: (context, candidateData, _) {
        final hover = candidateData.isNotEmpty;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          clipBehavior: Clip.antiAlias,
          elevation: hover ? 4 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: hover
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: hover ? 2 : 1,
            ),
          ),
          child: ExpansionTile(
            key: ValueKey('group_${group.key}_${widget.collapseGen}'),
            initiallyExpanded: !widget.allCollapsed,
            backgroundColor: headerColor.withOpacity(0.25),
            collapsedBackgroundColor: headerColor,
            iconColor: onHeader,
            collapsedIconColor: onHeader,
            tilePadding: const EdgeInsets.symmetric(horizontal: 14),
            childrenPadding: EdgeInsets.zero,
            leading:
                Text(group.icon, style: const TextStyle(fontSize: 20)),
            title: Text(
              group.title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: onHeader),
            ),
            subtitle: Text(
              '${group.tasks.length} Aufgaben',
              style:
                  theme.textTheme.labelSmall?.copyWith(color: onHeader),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.add, size: 20, color: onHeader),
                  onPressed: () => widget.onAddTask(group.key),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  tooltip: 'Task hinzufügen',
                ),
                Icon(Icons.expand_more, color: onHeader, size: 18),
              ],
            ),
            children: [
              if (visibleTasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: Text(
                      'Keine Tasks – hierher ziehen',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                for (final (i, task) in visibleTasks.indexed)
                  Draggable<Task>(
                    data: task,
                    feedback: _DragFeedback(task: task, theme: theme),
                    childWhenDragging: Opacity(
                      opacity: 0.35,
                      child: TaskTile(
                        task: task,
                        shaded: i.isOdd,
                        projectIcon:
                            widget.projectIconFor?.call(task),
                        onToggleDone: (_) {},
                      ),
                    ),
                    child: TaskTile(
                      task: task,
                      shaded: i.isOdd,
                      projectIcon: widget.projectIconFor?.call(task),
                      onTap: () => widget.onTap(task),
                      onToggleDone: (v) =>
                          widget.onToggleDone(task, v),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.task, required this.theme});

  final Task task;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.drag_indicator,
                  size: 18, color: theme.colorScheme.outline),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  task.title,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurface),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
