import 'package:flutter/material.dart';

import '../models/milestone.dart';
import '../models/task.dart';

class MilestoneTreeWidget extends StatefulWidget {
  const MilestoneTreeWidget({
    super.key,
    required this.milestones,
    required this.tasks,
    required this.onMilestoneToggle,
    required this.onTaskToggle,
    required this.onTaskTap,
    required this.onMilestoneEdit,
  });

  final List<Milestone> milestones;
  final List<Task> tasks;
  final void Function(Milestone) onMilestoneToggle;
  final void Function(Task, bool) onTaskToggle;
  final void Function(Task) onTaskTap;
  final void Function(Milestone) onMilestoneEdit;

  @override
  State<MilestoneTreeWidget> createState() => _MilestoneTreeWidgetState();
}

class _MilestoneTreeWidgetState extends State<MilestoneTreeWidget> {
  final Map<String, bool> _expandedMilestones = {};

  void _toggleExpanded(String milestoneId) {
    setState(() {
      _expandedMilestones[milestoneId] =
          !(_expandedMilestones[milestoneId] ?? true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.milestones.isEmpty) {
      return Center(
        child: Text(
          'Noch keine Milestones.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.milestones.length,
      itemBuilder: (context, index) {
        final milestone = widget.milestones[index];
        final allProjectTasks = widget.tasks
            .where((t) => t.projectId == milestone.projectId)
            .toList();
        final tasksForMilestone =
            allProjectTasks.take(3).toList();
        final isExpanded = _expandedMilestones[milestone.id] ?? true;
        final hasMoreTasks = allProjectTasks.length > 3;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _toggleExpanded(milestone.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      isExpanded
                          ? Icons.expand_more
                          : Icons.chevron_right,
                      size: 20,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Checkbox(
                      value: milestone.isDone,
                      onChanged: (_) =>
                          widget.onMilestoneToggle(milestone),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  milestone.title,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                    decoration:
                                        milestone.isDone
                                            ? TextDecoration
                                                .lineThrough
                                            : null,
                                    color: milestone.isDone
                                        ? theme.colorScheme.outline
                                        : null,
                                  ),
                                ),
                              ),
                              if (tasksForMilestone.isNotEmpty)
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme
                                        .tertiary
                                        .withOpacity(0.3),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${tasksForMilestone.length}${hasMoreTasks ? '+' : ''}',
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(
                                      color: theme.colorScheme
                                          .onTertiary,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (milestone.plannedYear != null)
                            Text(
                              milestone.plannedQuarter != null
                                  ? 'Q${milestone.plannedQuarter} ${milestone.plannedYear}'
                                  : '${milestone.plannedYear}',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(
                                      color:
                                          theme.colorScheme.primary),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () =>
                          widget.onMilestoneEdit(milestone),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Bearbeiten',
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded && tasksForMilestone.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Column(
                  children: [
                    for (final (i, task) in tasksForMilestone
                        .indexed)
                      _TaskTile(
                        task: task,
                        onToggle: (v) =>
                            widget.onTaskToggle(task, v),
                        onTap: () => widget.onTaskTap(task),
                        shaded: i.isOdd,
                      ),
                    if (hasMoreTasks)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Text(
                          '+${allProjectTasks.length - 3} weitere Tasks',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(
                            color:
                                theme.colorScheme.outline,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (isExpanded && tasksForMilestone.isEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  left: 48,
                  top: 4,
                  bottom: 4,
                ),
                child: Text(
                  'Keine Tasks',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.onToggle,
    required this.onTap,
    required this.shaded,
  });

  final Task task;
  final void Function(bool) onToggle;
  final VoidCallback onTap;
  final bool shaded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: shaded ? theme.colorScheme.surfaceContainer : null,
      child: ListTile(
        dense: true,
        leading: Checkbox(
          value: task.isDone,
          onChanged: (v) => onToggle(v ?? false),
          visualDensity: VisualDensity.compact,
        ),
        title: Text(
          task.title,
          style: theme.textTheme.bodySmall?.copyWith(
            decoration: task.isDone
                ? TextDecoration.lineThrough
                : null,
            color: task.isDone
                ? theme.colorScheme.outline
                : null,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: task.size != null
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.size!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
