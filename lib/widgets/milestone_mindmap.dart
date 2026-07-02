import 'package:flutter/material.dart';

import '../models/milestone.dart';
import '../models/task.dart';

class MilestoneMindmapWidget extends StatelessWidget {
  const MilestoneMindmapWidget({
    super.key,
    required this.milestones,
    required this.tasks,
    required this.onMilestoneToggle,
    required this.onTaskToggle,
    required this.onTaskTap,
    required this.onMilestoneEdit,
    required this.onTaskMilestoneChanged,
  });

  final List<Milestone> milestones;
  final List<Task> tasks;
  final void Function(Milestone) onMilestoneToggle;
  final void Function(Task, bool) onTaskToggle;
  final void Function(Task) onTaskTap;
  final void Function(Milestone) onMilestoneEdit;
  final void Function(Task, String?) onTaskMilestoneChanged;

  List<Milestone> _getChildMilestones(String parentId) {
    return milestones
        .where((m) => m.parentMilestoneId == parentId)
        .toList();
  }

  List<Milestone> _getRootMilestones() {
    return milestones.where((m) => m.parentMilestoneId == null).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (milestones.isEmpty) {
      return Center(
        child: Text(
          'Noch keine Milestones.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
      );
    }

    final rootMilestones = _getRootMilestones();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (final milestone in rootMilestones)
            _buildMilestoneNode(
              context,
              milestone,
              depth: 0,
            ),
        ],
      ),
    );
  }

  Widget _buildMilestoneNode(
    BuildContext context,
    Milestone milestone, {
    required int depth,
  }) {
    final theme = Theme.of(context);
    final childMilestones = _getChildMilestones(milestone.id);
    final milestoneTasks = tasks
        .where((t) => t.milestoneId == milestone.id)
        .toList();

    return Column(
      children: [
        // Milestone Card
        Container(
          constraints: const BoxConstraints(maxWidth: 280),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            milestone.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (milestone.plannedYear != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                milestone.plannedQuarter != null
                                    ? 'Q${milestone.plannedQuarter} ${milestone.plannedYear}'
                                    : '${milestone.plannedYear}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer
                                      .withOpacity(0.7),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Checkbox(
                      value: milestone.isDone,
                      onChanged: (_) =>
                          onMilestoneToggle(milestone),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                if (milestoneTasks.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    height: 1,
                    color: theme.colorScheme.primary
                        .withOpacity(0.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tasks (${milestoneTasks.length})',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer
                          .withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Column(
                    children: [
                      for (final (i, task) in
                          milestoneTasks.take(3).indexed)
                        _TaskChip(
                          task: task,
                          onToggle: (v) =>
                              onTaskToggle(task, v),
                          onTap: () => onTaskTap(task),
                          isDone: task.isDone,
                          theme: theme,
                        ),
                      if (milestoneTasks.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '+${milestoneTasks.length - 3} mehr',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(
                              color: theme.colorScheme
                                  .onPrimaryContainer
                                  .withOpacity(0.6),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        // Connector line if has children
        if (childMilestones.isNotEmpty)
          Container(
            width: 2,
            height: 20,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),

        // Children
        if (childMilestones.isNotEmpty)
          Container(
            padding: EdgeInsets.only(
              left: depth == 0 ? 0 : 32,
              top: 0,
              bottom: 16,
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 20,
              children: [
                for (final child in childMilestones)
                  _buildMilestoneNode(
                    context,
                    child,
                    depth: depth + 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TaskChip extends StatelessWidget {
  const _TaskChip({
    required this.task,
    required this.onToggle,
    required this.onTap,
    required this.isDone,
    required this.theme,
  });

  final Task task;
  final void Function(bool) onToggle;
  final VoidCallback onTap;
  final bool isDone;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDone
                ? theme.colorScheme.outlineVariant
                : theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: isDone,
                  onChanged: (v) => onToggle(v ?? false),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  task.title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    decoration: isDone
                        ? TextDecoration.lineThrough
                        : null,
                    color: isDone
                        ? theme.colorScheme.outline
                        : null,
                  ),
                  maxLines: 1,
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
