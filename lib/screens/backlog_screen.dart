import 'package:flutter/material.dart';

import '../models/milestone.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../services/milestone_service.dart';
import '../services/project_service.dart';
import '../services/task_service.dart';
import '../widgets/status_views.dart';
import 'task_detail_screen.dart';

/// Backlog: flat list of open tasks with filtering and sorting.
class BacklogScreen extends StatefulWidget {
  const BacklogScreen({super.key});

  @override
  State<BacklogScreen> createState() => _BacklogScreenState();
}

class _BacklogScreenState extends State<BacklogScreen> {
  final _service = TaskService();
  final _projects = ProjectService();
  final _milestones = MilestoneService();
  late Future<_BacklogData> _future;

  Set<String> _selectedStatuses = {'open'};
  Set<String?> _selectedSizes = {};
  Set<String?> _selectedContexts = {};
  Set<int?> _selectedUrgencies = {};
  Set<String?> _selectedProjects = {};
  bool _nextActionOnly = false;
  bool _unplannedOnly = false;
  String _sortBy = 'title';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_BacklogData> _load() async {
    final results = await Future.wait([
      _service.backlog(),
      _projects.all(),
      _milestones.all(),
    ]);
    return _BacklogData(
      tasks: results[0] as List<Task>,
      projects: {for (final p in results[1] as List<Project>) p.id: p},
      milestones: results[2] as List<Milestone>,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _toggleDone(Task task, bool done) async {
    await _service.setStatus(task.id, done ? 'done' : 'open');
    await _refresh();
  }

  Future<void> _openDetail(Task task) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
    );
    if (changed == true) await _refresh();
  }

  List<Task> _filterAndSort(_BacklogData data) {
    var filtered = data.tasks.where((t) {
      if (!_selectedStatuses.contains(t.status)) return false;
      if (_selectedSizes.isNotEmpty && !_selectedSizes.contains(t.size)) return false;
      if (_selectedContexts.isNotEmpty && !_selectedContexts.contains(t.context)) return false;
      if (_selectedUrgencies.isNotEmpty && !_selectedUrgencies.contains(t.emotionalUrgency)) return false;

      // Check project filter: include if task is in selected project OR task's milestone is in selected project
      if (_selectedProjects.isNotEmpty) {
        bool inSelectedProject = _selectedProjects.contains(t.projectId);
        if (!inSelectedProject && t.milestoneId != null) {
          try {
            final milestone = data.milestones.firstWhere((m) => m.id == t.milestoneId);
            inSelectedProject = _selectedProjects.contains(milestone.projectId);
          } catch (e) {
            // Milestone not found
          }
        }
        if (!inSelectedProject) return false;
      }

      if (_nextActionOnly && !t.nextAction) return false;
      if (_unplannedOnly && t.plannedDay != null) return false;
      return true;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'title':
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case 'deadline':
          if (a.deadlineDate == null) return 1;
          if (b.deadlineDate == null) return -1;
          return a.deadlineDate!.compareTo(b.deadlineDate!);
        case 'size':
          const sizeOrder = {'S': 0, 'M': 1, 'L': 2};
          return (sizeOrder[a.size] ?? 3).compareTo(sizeOrder[b.size] ?? 3);
        case 'emotional_urgency':
          return (b.emotionalUrgency ?? 0).compareTo(a.emotionalUrgency ?? 0);
        default:
          return 0;
      }
    });

    return filtered;
  }

  Widget _buildFilterChips(_BacklogData data) {
    final allStatuses = {'open', 'done', 'blocked'};
    final allSizes = {'S', 'M', 'L'};
    final allContexts = {'büro', 'stadt', 'samstag', 'sonntag', 'flexibel'};
    const allUrgencies = {1, 2, 3};

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Nur ungeplant'),
              selected: _unplannedOnly,
              onSelected: (v) => setState(() => _unplannedOnly = v),
              visualDensity: VisualDensity.compact,
            ),
            FilterChip(
              label: const Text('Next Action'),
              selected: _nextActionOnly,
              onSelected: (v) => setState(() => _nextActionOnly = v),
              visualDensity: VisualDensity.compact,
            ),
            for (final status in allStatuses)
              FilterChip(
                label: Text(status),
                selected: _selectedStatuses.contains(status),
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _selectedStatuses.add(status);
                    } else {
                      _selectedStatuses.remove(status);
                    }
                  });
                },
                visualDensity: VisualDensity.compact,
              ),
            for (final size in allSizes)
              FilterChip(
                label: Text(size),
                selected: _selectedSizes.contains(size),
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _selectedSizes.add(size);
                    } else {
                      _selectedSizes.remove(size);
                    }
                  });
                },
                visualDensity: VisualDensity.compact,
              ),
            for (final context in allContexts)
              FilterChip(
                label: Text(context),
                selected: _selectedContexts.contains(context),
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _selectedContexts.add(context);
                    } else {
                      _selectedContexts.remove(context);
                    }
                  });
                },
                visualDensity: VisualDensity.compact,
              ),
            for (final urgency in allUrgencies)
              FilterChip(
                label: Text('🔥$urgency'),
                selected: _selectedUrgencies.contains(urgency),
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _selectedUrgencies.add(urgency);
                    } else {
                      _selectedUrgencies.remove(urgency);
                    }
                  });
                },
                visualDensity: VisualDensity.compact,
              ),
            if (data.projects.isNotEmpty)
              const SizedBox(width: 4),
            for (final project in data.projects.values)
              FilterChip(
                label: Text('${project.icon} ${project.name}'),
                selected: _selectedProjects.contains(project.id),
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _selectedProjects.add(project.id);
                    } else {
                      _selectedProjects.remove(project.id);
                    }
                  });
                },
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_BacklogData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErrorView(error: snapshot.error!, onRetry: _refresh);
            }
            final data = snapshot.data!;

            if (data.tasks.isEmpty) {
              return const EmptyView(message: 'Backlog ist leer. 📭');
            }

            final filtered = _filterAndSort(data);

            if (filtered.isEmpty) {
              return ListView(
                children: [
                  _buildFilterChips(data),
                  _buildSortWidget(),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'Keine Tasks mit dieser Filterung. 🔍',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView(
              children: [
                _buildFilterChips(data),
                _buildSortWidget(),
                for (final (i, task) in filtered.indexed)
                  _TaskTile(
                    task: task,
                    projectLabel: _projectLabel(data, task.projectId),
                    projectIcon: _projectIcon(data, task.projectId),
                    onToggle: (done) => _toggleDone(task, done),
                    onTap: () => _openDetail(task),
                    shaded: i.isOdd,
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openDetail(Task(id: '', title: '', status: 'open')),
        tooltip: 'Neue Task',
        child: const Icon(Icons.add),
      ),
    );
  }

  String _projectLabel(_BacklogData data, String? id) {
    if (id == null) return 'Ohne Projekt';
    return data.projects[id]?.name ?? 'Projekt $id';
  }

  String _projectIcon(_BacklogData data, String? id) =>
      id == null ? '📥' : (data.projects[id]?.icon ?? '📁');

  Widget _buildSortWidget() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          const Text('Sortieren nach:'),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _sortBy,
            items: const [
              DropdownMenuItem(value: 'title', child: Text('Titel')),
              DropdownMenuItem(value: 'deadline', child: Text('Deadline')),
              DropdownMenuItem(value: 'size', child: Text('Größe')),
              DropdownMenuItem(value: 'emotional_urgency', child: Text('Energie/Bedürfnis')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _sortBy = v);
            },
            isDense: true,
          ),
        ],
      ),
    );
  }
}

class _BacklogData {
  _BacklogData({
    required this.tasks,
    required this.projects,
    required this.milestones,
  });
  final List<Task> tasks;
  final Map<String, Project> projects;
  final List<Milestone> milestones;
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.projectLabel,
    required this.projectIcon,
    required this.onToggle,
    required this.onTap,
    required this.shaded,
  });

  final Task task;
  final String projectLabel;
  final String projectIcon;
  final void Function(bool) onToggle;
  final VoidCallback onTap;
  final bool shaded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: shaded ? theme.colorScheme.surfaceContainer : theme.colorScheme.surface,
      child: ListTile(
        splashColor: theme.colorScheme.primary.withOpacity(0.1),
        leading: Checkbox(
          value: task.isDone,
          onChanged: (v) => onToggle(v ?? false),
          visualDensity: VisualDensity.compact,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              task.title,
              style: theme.textTheme.bodyMedium?.copyWith(
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
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$projectIcon $projectLabel',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                if (task.size != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      task.size!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (task.context != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      task.context!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                if (task.emotionalUrgency != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '🔥${task.emotionalUrgency}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: task.deadlineDate != null
            ? Text(
                '⏰ ${task.deadlineDate!.day}.${task.deadlineDate!.month}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              )
            : null,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
