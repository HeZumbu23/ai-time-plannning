import 'package:flutter/material.dart';

import '../models/milestone.dart';
import '../models/project.dart';
import 'drag_auto_scroll.dart';
import 'project_card.dart';

class ProjectRoadmapEntry {
  const ProjectRoadmapEntry({
    required this.key,
    required this.title,
    required this.icon,
    required this.projects,
    this.milestones = const [],
  });

  final String? key;
  final String title;
  final String icon;
  final List<Project> projects;
  final List<Milestone> milestones;
}

/// Roadmap-Liste mit Drag & Drop zwischen Quartal-Gruppen.
class ProjectRoadmapList extends StatefulWidget {
  const ProjectRoadmapList({
    super.key,
    required this.groups,
    required this.onMove,
    required this.onTap,
    required this.onAddProject,
    this.onMoveMilestone,
    this.onToggleMilestone,
  });

  final List<ProjectRoadmapEntry> groups;
  final Future<void> Function(Project project, String? newKey) onMove;
  final void Function(Project project) onTap;
  final void Function(String? groupKey) onAddProject;
  final Future<void> Function(Milestone milestone, String? newKey)?
      onMoveMilestone;
  final Future<void> Function(Milestone milestone)? onToggleMilestone;

  @override
  State<ProjectRoadmapList> createState() => _ProjectRoadmapListState();
}

class _ProjectRoadmapListState extends State<ProjectRoadmapList> {
  String? _movingProjectId;
  String? _movingMilestoneId;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleMoveProject(Project project, String? newKey) async {
    setState(() => _movingProjectId = project.id);
    await widget.onMove(project, newKey);
    if (mounted) setState(() => _movingProjectId = null);
  }

  Future<void> _handleMoveMilestone(
      Milestone milestone, String? newKey) async {
    setState(() => _movingMilestoneId = milestone.id);
    await widget.onMoveMilestone?.call(milestone, newKey);
    if (mounted) setState(() => _movingMilestoneId = null);
  }

  @override
  Widget build(BuildContext context) {
    return DragAutoScrollView(
      controller: _scrollController,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final group in widget.groups) _buildGroupCard(context, group),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, ProjectRoadmapEntry group) {
    final theme = Theme.of(context);
    final headerColor = theme.colorScheme.secondaryContainer;
    final onHeader = theme.colorScheme.onSecondaryContainer;

    final visibleProjects = group.projects
        .where((p) => p.id != _movingProjectId)
        .toList();
    final visibleMilestones = group.milestones
        .where((m) => m.id != _movingMilestoneId)
        .toList();

    final totalCount = group.projects.length + group.milestones.length;

    return DragTarget<Object>(
      onWillAcceptWithDetails: (d) {
        if (d.data is Project) {
          return !group.projects.any((p) => p.id == (d.data as Project).id);
        }
        if (d.data is Milestone) {
          return !group.milestones
              .any((m) => m.id == (d.data as Milestone).id);
        }
        return false;
      },
      onAcceptWithDetails: (d) {
        if (d.data is Project) {
          _handleMoveProject(d.data as Project, group.key);
        } else if (d.data is Milestone) {
          _handleMoveMilestone(d.data as Milestone, group.key);
        }
      },
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
            key: ValueKey('group_${group.key}'),
            initiallyExpanded: true,
            backgroundColor: headerColor.withOpacity(0.25),
            collapsedBackgroundColor: headerColor,
            iconColor: onHeader,
            collapsedIconColor: onHeader,
            tilePadding: const EdgeInsets.symmetric(horizontal: 14),
            childrenPadding: EdgeInsets.zero,
            leading: Text(group.icon, style: const TextStyle(fontSize: 20)),
            title: Text(
              group.title,
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold, color: onHeader),
            ),
            subtitle: Text(
              _subtitleText(group),
              style: theme.textTheme.labelSmall?.copyWith(color: onHeader),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.add, size: 20, color: onHeader),
                  onPressed: () => widget.onAddProject(group.key),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.only(right: 16),
                  tooltip: 'Projekt hinzufügen',
                ),
                Icon(Icons.expand_more, color: onHeader, size: 18),
              ],
            ),
            children: [
              if (visibleProjects.isEmpty && visibleMilestones.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: Text(
                      'Leer – hierher ziehen',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else ...[
                for (final (i, project) in visibleProjects.indexed)
                  _DraggableProjectRow(
                    key: ValueKey(project.id),
                    project: project,
                    shaded: i.isOdd,
                    theme: theme,
                    onTap: () => widget.onTap(project),
                  ),
                if (visibleMilestones.isNotEmpty) ...[
                  if (visibleProjects.isNotEmpty)
                    Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: theme.colorScheme.outlineVariant),
                  for (final (i, milestone) in visibleMilestones.indexed)
                    _DraggableMilestoneRow(
                      key: ValueKey(milestone.id),
                      milestone: milestone,
                      shaded: i.isOdd,
                      theme: theme,
                      onToggle: widget.onToggleMilestone != null
                          ? () => widget.onToggleMilestone!(milestone)
                          : null,
                    ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  static String _subtitleText(ProjectRoadmapEntry group) {
    final p = group.projects.length;
    final m = group.milestones.length;
    if (p > 0 && m > 0) return '$p Projekte · $m Milestones';
    if (p > 0) return '$p Projekte';
    if (m > 0) return '$m Milestones';
    return 'Leer';
  }
}

// ── Draggable Project Row ─────────────────────────────────────────────────────

class _DraggableProjectRow extends StatefulWidget {
  const _DraggableProjectRow({
    super.key,
    required this.project,
    required this.shaded,
    required this.theme,
    required this.onTap,
  });

  final Project project;
  final bool shaded;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  State<_DraggableProjectRow> createState() => _DraggableProjectRowState();
}

class _DraggableProjectRowState extends State<_DraggableProjectRow> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.shaded
        ? widget.theme.colorScheme.surfaceContainerHighest.withOpacity(0.35)
        : null;

    return ColoredBox(
      color: bg ?? Colors.transparent,
      child: Opacity(
        opacity: _isDragging ? 0.35 : 1.0,
        child: Row(
          children: [
            Draggable<Project>(
              data: widget.project,
              feedback: _ProjectDragFeedback(
                  project: widget.project, theme: widget.theme),
              onDragStarted: () => setState(() => _isDragging = true),
              onDragEnd: (_) {
                if (mounted) setState(() => _isDragging = false);
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                  child: Icon(Icons.drag_handle,
                      size: 18, color: widget.theme.colorScheme.outline),
                ),
              ),
            ),
            Expanded(
              child: ProjectCard(
                project: widget.project,
                shaded: false,
                onTap: widget.onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectDragFeedback extends StatelessWidget {
  const _ProjectDragFeedback({required this.project, required this.theme});
  final Project project;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(project.icon ?? '📁',
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  project.name,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurface),
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

// ── Draggable Milestone Row ───────────────────────────────────────────────────

class _DraggableMilestoneRow extends StatefulWidget {
  const _DraggableMilestoneRow({
    super.key,
    required this.milestone,
    required this.shaded,
    required this.theme,
    this.onToggle,
  });

  final Milestone milestone;
  final bool shaded;
  final ThemeData theme;
  final VoidCallback? onToggle;

  @override
  State<_DraggableMilestoneRow> createState() =>
      _DraggableMilestoneRowState();
}

class _DraggableMilestoneRowState extends State<_DraggableMilestoneRow> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final milestone = widget.milestone;
    final bg = widget.shaded
        ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.25)
        : null;

    return ColoredBox(
      color: bg ?? Colors.transparent,
      child: Opacity(
        opacity: _isDragging ? 0.35 : 1.0,
        child: Row(
          children: [
            Draggable<Milestone>(
              data: milestone,
              feedback: _MilestoneDragFeedback(
                  milestone: milestone, theme: theme),
              onDragStarted: () => setState(() => _isDragging = true),
              onDragEnd: (_) {
                if (mounted) setState(() => _isDragging = false);
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Icon(Icons.drag_handle,
                      size: 18, color: theme.colorScheme.outline),
                ),
              ),
            ),
            Checkbox(
              value: milestone.isDone,
              onChanged: widget.onToggle != null
                  ? (_) => widget.onToggle!()
                  : null,
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text('🎯',
                            style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            milestone.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              decoration: milestone.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: milestone.isDone
                                  ? theme.colorScheme.outline
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (milestone.projectName != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 19),
                        child: Text(
                          milestone.projectName!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class _MilestoneDragFeedback extends StatelessWidget {
  const _MilestoneDragFeedback(
      {required this.milestone, required this.theme});
  final Milestone milestone;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎯', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  milestone.title,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurface),
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
