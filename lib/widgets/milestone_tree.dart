import 'package:flutter/material.dart';

import '../models/milestone.dart';
import '../models/task.dart';
import '../services/milestone_service.dart';
import '../services/task_service.dart';

class MilestoneTreeWidget extends StatefulWidget {
  const MilestoneTreeWidget({
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

  List<Milestone> _getChildMilestones(String parentId) {
    return widget.milestones
        .where((m) => m.parentMilestoneId == parentId)
        .toList();
  }

  List<Milestone> _getRootMilestones() {
    return widget.milestones
        .where((m) => m.parentMilestoneId == null)
        .toList();
  }

  Future<void> _moveMilestone(Milestone milestone, int direction) async {
    final service = MilestoneService();
    try {
      await service.updatePosition(
        milestone.id,
        milestone.position + direction,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Position-Update nicht möglich (Migration ausstehend)'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleMilestoneInFocus(Milestone milestone) async {
    final service = MilestoneService();
    try {
      await service.toggleInFocus(milestone.id, !milestone.inFocus);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Focus-Toggle nicht möglich (Migration ausstehend)'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unassignedTasks = widget.tasks.where((t) => t.milestoneId == null).toList();
    final rootMilestones = _getRootMilestones();
    final hasContent = unassignedTasks.isNotEmpty || rootMilestones.isNotEmpty;

    if (!hasContent && widget.milestones.isEmpty) {
      return Center(
        child: Text(
          'Noch keine Milestones oder Tasks.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
      );
    }

    return ListView(
      children: [
        if (unassignedTasks.isNotEmpty) ...[
          _buildProjectTasksSection(context, unassignedTasks),
          const Divider(),
        ],
        ...rootMilestones.map((milestone) => _buildMilestoneTree(
          context,
          milestone,
          depth: 0,
        )),
      ],
    );
  }

  Widget _buildProjectTasksSection(
    BuildContext context,
    List<Task> unassignedTasks,
  ) {
    final theme = Theme.of(context);
    final isExpanded = _expandedMilestones['__project__'] ?? true;
    final tasksToShow = unassignedTasks.take(5).toList();
    final hasMore = unassignedTasks.length > 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _toggleExpanded('__project__'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: false,
                    onChanged: null,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '📋 Projekt (${unassignedTasks.length} ${unassignedTasks.length == 1 ? 'Task' : 'Tasks'})',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          for (final task in tasksToShow)
            Padding(
              padding: const EdgeInsets.fromLTRB(52, 4, 12, 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: task.isDone,
                      onChanged: (v) =>
                          widget.onTaskToggle(task, v ?? false),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onTaskTap(task),
                      child: Text(
                        task.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.isDone
                              ? theme.colorScheme.outline
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (hasMore)
            Padding(
              padding: const EdgeInsets.fromLTRB(52, 4, 12, 4),
              child: Text(
                '+${unassignedTasks.length - 5} mehr',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildMilestoneTree(
    BuildContext context,
    Milestone milestone, {
    required int depth,
  }) {
    final theme = Theme.of(context);
    final allTasksForMilestone = widget.tasks
        .where((t) => t.milestoneId == milestone.id)
        .toList();
    final tasksForMilestone = allTasksForMilestone.take(3).toList();
    final isExpanded = _expandedMilestones[milestone.id] ?? true;
    final hasMoreTasks = allTasksForMilestone.length > 3;
    final childMilestones = _getChildMilestones(milestone.id);
    final hasChildren = childMilestones.isNotEmpty;

    return DragTarget<Task>(
      onAccept: (task) {
        if (task.milestoneId != milestone.id) {
          widget.onTaskMilestoneChanged(task, milestone.id);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _toggleExpanded(milestone.id),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  12.0 + (depth * 20.0),
                  8,
                  12,
                  8,
                ),
                child: Row(
                  children: [
                    if (hasChildren || tasksForMilestone.isNotEmpty)
                      Icon(
                        isExpanded
                            ? Icons.expand_more
                            : Icons.chevron_right,
                        size: 20,
                        color: theme.colorScheme.onSurface,
                      )
                    else
                      const SizedBox(width: 20),
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
                                  style: theme.textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                    decoration:
                                        milestone.isDone
                                            ? TextDecoration
                                                .lineThrough
                                            : null,
                                    color: milestone.isDone
                                        ? theme.colorScheme
                                            .outline
                                        : null,
                                  ),
                                ),
                              ),
                              if (tasksForMilestone
                                  .isNotEmpty)
                                Container(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color: theme.colorScheme
                                        .tertiary
                                        .withOpacity(0.3),
                                    borderRadius:
                                        BorderRadius
                                            .circular(6),
                                  ),
                                  child: Text(
                                    '${tasksForMilestone.length}${hasMoreTasks ? '+' : ''}',
                                    style: theme
                                        .textTheme.labelSmall
                                        ?.copyWith(
                                      color: theme
                                          .colorScheme
                                          .onTertiary,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (milestone.plannedYear !=
                              null)
                            Text(
                              milestone.plannedQuarter !=
                                      null
                                  ? 'Q${milestone.plannedQuarter} ${milestone.plannedYear}'
                                  : '${milestone.plannedYear}',
                              style: theme.textTheme
                                  .labelSmall
                                  ?.copyWith(
                                      color: theme
                                          .colorScheme
                                          .primary),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        milestone.inFocus
                            ? Icons.star
                            : Icons.star_outline,
                        size: 18,
                      ),
                      onPressed: () =>
                          _toggleMilestoneInFocus(milestone),
                      visualDensity:
                          VisualDensity.compact,
                      tooltip: milestone.inFocus
                          ? 'Aus Focus entfernen'
                          : 'In Focus',
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.expand_less, size: 18),
                      onPressed: () =>
                          _moveMilestone(milestone, -1),
                      visualDensity:
                          VisualDensity.compact,
                      tooltip: 'Nach oben',
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.expand_more, size: 18),
                      onPressed: () =>
                          _moveMilestone(milestone, 1),
                      visualDensity:
                          VisualDensity.compact,
                      tooltip: 'Nach unten',
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.edit, size: 18),
                      onPressed: () =>
                          widget.onMilestoneEdit(milestone),
                      visualDensity:
                          VisualDensity.compact,
                      tooltip: 'Bearbeiten',
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded && tasksForMilestone.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                    left: 32.0 + (depth * 20.0)),
                child: Column(
                  children: [
                    for (final (i, task) in
                        tasksForMilestone.indexed)
                      Draggable<Task>(
                        data: task,
                        feedback: Material(
                          child: Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration:
                                BoxDecoration(
                              color: theme.colorScheme
                                  .secondaryContainer,
                              borderRadius:
                                  BorderRadius.circular(
                                      8),
                            ),
                            child: Text(
                              task.title,
                              style: theme.textTheme
                                  .bodySmall,
                            ),
                          ),
                        ),
                        child: _TaskTile(
                          task: task,
                          onToggle: (v) =>
                              widget.onTaskToggle(task, v),
                          onTap: () =>
                              widget.onTaskTap(task),
                          shaded: i.isOdd,
                        ),
                      ),
                    if (hasMoreTasks)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Text(
                          '+${allTasksForMilestone.length - 3} weitere Tasks',
                          style: theme.textTheme
                              .bodySmall
                              ?.copyWith(
                            color:
                                theme.colorScheme
                                    .outline,
                            fontStyle:
                                FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (isExpanded && childMilestones.isNotEmpty)
              for (final child in childMilestones)
                _buildMilestoneTree(
                  context,
                  child,
                  depth: depth + 1,
                ),
            if (isExpanded &&
                tasksForMilestone.isEmpty &&
                childMilestones.isEmpty)
              Padding(
                padding: EdgeInsets.only(
                  left: 48.0 + (depth * 20.0),
                  top: 4,
                  bottom: 4,
                ),
                child: Text(
                  'Keine Tasks oder Sub-Milestones',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(
                    color:
                        theme.colorScheme.outline,
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
