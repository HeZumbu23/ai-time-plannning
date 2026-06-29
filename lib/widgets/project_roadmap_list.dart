import 'package:flutter/material.dart';

import '../models/project.dart';
import 'project_card.dart';

class ProjectRoadmapEntry {
  const ProjectRoadmapEntry({
    required this.key,
    required this.title,
    required this.icon,
    required this.projects,
  });

  final String? key;
  final String title;
  final String icon;
  final List<Project> projects;
}

/// Roadmap-Liste mit Drag & Drop zwischen Quartal-Gruppen.
class ProjectRoadmapList extends StatefulWidget {
  const ProjectRoadmapList({
    super.key,
    required this.groups,
    required this.onMove,
    required this.onTap,
    required this.onAddProject,
  });

  final List<ProjectRoadmapEntry> groups;
  final Future<void> Function(Project project, String? newKey) onMove;
  final void Function(Project project) onTap;
  final void Function(String? groupKey) onAddProject;

  @override
  State<ProjectRoadmapList> createState() => _ProjectRoadmapListState();
}

class _ProjectRoadmapListState extends State<ProjectRoadmapList> {
  String? _movingProjectId;

  Future<void> _handleMove(Project project, String? newKey) async {
    setState(() => _movingProjectId = project.id);
    await widget.onMove(project, newKey);
    if (mounted) setState(() => _movingProjectId = null);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final group in widget.groups) _buildGroupCard(context, group),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildGroupCard(BuildContext context, ProjectRoadmapEntry group) {
    final theme = Theme.of(context);
    final headerColor = theme.colorScheme.secondaryContainer;
    final onHeader = theme.colorScheme.onSecondaryContainer;

    final visible = group.projects
        .where((p) => p.id != _movingProjectId)
        .toList();

    return DragTarget<Project>(
      onWillAcceptWithDetails: (d) =>
          !group.projects.any((p) => p.id == d.data.id),
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
            key: ValueKey('proj_${group.key}'),
            initiallyExpanded: true,
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
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold, color: onHeader),
            ),
            subtitle: Text(
              '${group.projects.length} Projekte',
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
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: Text(
                      'Keine Projekte – hierher ziehen',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                for (final (i, project) in visible.indexed)
                  _DraggableProjectRow(
                    key: ValueKey(project.id),
                    project: project,
                    shaded: i.isOdd,
                    theme: theme,
                    onTap: () => widget.onTap(project),
                  ),
            ],
          ),
        );
      },
    );
  }
}

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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 14),
                  child: Icon(Icons.drag_handle,
                      size: 18,
                      color: widget.theme.colorScheme.outline),
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
  const _ProjectDragFeedback(
      {required this.project, required this.theme});
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
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
