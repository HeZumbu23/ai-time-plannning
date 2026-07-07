import 'package:flutter/material.dart';

import '../models/milestone.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../services/milestone_service.dart';
import '../services/project_service.dart';
import '../services/task_service.dart';
import '../widgets/milestone_mindmap.dart';
import '../widgets/milestone_tree.dart';
import '../widgets/status_views.dart';
import '../widgets/task_tile.dart';
import 'task_detail_screen.dart';

typedef ReorderCallback = void Function(int oldIndex, int newIndex);

class ProjekteScreen extends StatefulWidget {
  const ProjekteScreen({super.key});

  @override
  State<ProjekteScreen> createState() => _ProjekteScreenState();
}

class _ProjekteScreenState extends State<ProjekteScreen> {
  final _service = ProjectService();
  final _taskService = TaskService();
  final _milestoneService = MilestoneService();
  List<Project> _projects = [];
  List<Task> _tasks = [];
  List<Milestone> _milestones = [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.all(),
        _taskService.backlog(),
        _milestoneService.all(),
      ]);
      if (mounted) {
        setState(() {
          _projects = results[0] as List<Project>;
          _tasks = results[1] as List<Task>;
          _milestones = results[2] as List<Milestone>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _openProject(Project project) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => ProjectDetailScreen(project: project),
        ))
        .then((_) => _load());
  }

  ({int tasks, int milestones}) _getProjectCounts(Project project) {
    final tasks = _tasks.where((t) => t.projectId == project.id).length;
    final milestones = _milestones.where((m) => m.projectId == project.id).length;
    return (tasks: tasks, milestones: milestones);
  }

  Widget? _buildProjectSubtitle(Project project) {
    final counts = _getProjectCounts(project);
    final hasGoal = project.goal != null && project.goal!.isNotEmpty;

    if (!hasGoal && counts.tasks == 0 && counts.milestones == 0) {
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasGoal) ...[
          Text(
            project.goal!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
        ],
        Wrap(
          spacing: 8,
          children: [
            if (counts.tasks > 0)
              Text(
                '📋 ${counts.tasks} ${counts.tasks == 1 ? 'Task' : 'Tasks'}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            if (counts.milestones > 0)
              Text(
                '🎯 ${counts.milestones} ${counts.milestones == 1 ? 'Milestone' : 'Milestones'}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _addProject() async {
    final data = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (_) => const _NewProjectDialog(),
    );
    if (data != null) {
      await _service.createProject(data);
      await _load();
    }
  }

  Future<void> _reorderProjects(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    const statusOrder = {'active': 0, 'backlog': 1, 'done': 2};
    final sorted = [..._projects]..sort((a, b) {
      final sa = statusOrder[a.status] ?? 1;
      final sb = statusOrder[b.status] ?? 1;
      if (sa != sb) return sa.compareTo(sb);
      if (a.position != b.position) return a.position.compareTo(b.position);
      return a.name.compareTo(b.name);
    });

    sorted.insert(newIndex, sorted.removeAt(oldIndex));

    setState(() {
      _projects = sorted;
    });

    try {
      for (int i = 0; i < sorted.length; i++) {
        await _service.updatePosition(sorted[i].id, i);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Position-Update fehlgeschlagen: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      await _load();
    }
  }

  Future<void> _changeProjectIcon(Project project) async {
    final icon = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) => _IconPickerSheet(currentIcon: project.icon),
    );
    if (icon != null) {
      try {
        await _service.updateProject(project.id, {'icon': icon});
        await _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Icon-Update: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleProjectInFocus(Project project) async {
    try {
      await _service.toggleInFocus(project.id, !project.inFocus);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Focus-Toggle nicht möglich (Migration ausstehend)'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorView(error: _error!, onRetry: _load);

    const statusOrder = {'active': 0, 'backlog': 1, 'done': 2};
    final sorted = [..._projects]..sort((a, b) {
        final sa = statusOrder[a.status] ?? 1;
        final sb = statusOrder[b.status] ?? 1;
        if (sa != sb) return sa.compareTo(sb);
        if (a.position != b.position) return a.position.compareTo(b.position);
        return a.name.compareTo(b.name);
      });

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: sorted.isEmpty
            ? const EmptyView(message: 'Noch keine Projekte.')
            : ReorderableListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                onReorder: _reorderProjects,
                children: [
                  for (int i = 0; i < sorted.length; i++)
                    Container(
                      key: ValueKey(sorted[i].id),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: ListTile(
                        leading: GestureDetector(
                          onTap: () => _changeProjectIcon(sorted[i]),
                          child: Text(sorted[i].icon ?? '📁',
                              style: const TextStyle(fontSize: 22)),
                        ),
                        title: Text(sorted[i].name),
                        subtitle: _buildProjectSubtitle(sorted[i]),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (sorted[i].size != null) _SizeChip(sorted[i].size!),
                            if (sorted[i].priority != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                switch (sorted[i].priority!) {
                                  'high' => '🔴',
                                  'medium' => '🟡',
                                  'low' => '🟢',
                                  _ => '',
                                },
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                            if (sorted[i].status == 'done') ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.check_circle_outline,
                                  size: 16, color: Colors.green),
                            ],
                            IconButton(
                              icon: Icon(
                                sorted[i].inFocus ? Icons.star : Icons.star_outline,
                                size: 18,
                              ),
                              onPressed: () => _toggleProjectInFocus(sorted[i]),
                              visualDensity: VisualDensity.compact,
                              tooltip: sorted[i].inFocus ? 'Aus Focus entfernen' : 'In Focus',
                            ),
                            ReorderableDragStartListener(
                              index: i,
                              child: const MouseRegion(
                                cursor: SystemMouseCursors.grab,
                                child: Icon(Icons.drag_handle, size: 18),
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _openProject(sorted[i]),
                      ),
                    ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProject,
        tooltip: 'Neues Projekt',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.label,
    required this.value,
    required this.theme,
  });
  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip(this.size);
  final String size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (size) {
      'S' => theme.colorScheme.tertiaryContainer,
      'M' => theme.colorScheme.secondaryContainer,
      'L' => theme.colorScheme.primaryContainer,
      _ => theme.colorScheme.surfaceContainer,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(size,
          style: theme.textTheme.labelSmall
              ?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}

// ── New Project Dialog ────────────────────────────────────────────────────────

class _NewProjectDialog extends StatefulWidget {
  const _NewProjectDialog();

  @override
  State<_NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<_NewProjectDialog> {
  final _name = TextEditingController();
  final _icon = TextEditingController(text: '📁');
  String? _size;
  String? _priority;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _icon.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    Navigator.of(context).pop({
      'name': _name.text.trim(),
      'icon': _icon.text.trim().isEmpty ? null : _icon.text.trim(),
      'size': _size,
      'priority': _priority,
      'status': 'active',
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Neues Projekt'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 64,
                  child: TextField(
                    controller: _icon,
                    decoration: const InputDecoration(
                        labelText: 'Icon', border: OutlineInputBorder()),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _name,
                    autofocus: true,
                    decoration: const InputDecoration(
                        labelText: 'Name *', border: OutlineInputBorder()),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _size,
                    decoration: const InputDecoration(
                        labelText: 'Größe', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('—')),
                      DropdownMenuItem(value: 'S', child: Text('S – Klein')),
                      DropdownMenuItem(value: 'M', child: Text('M – Mittel')),
                      DropdownMenuItem(value: 'L', child: Text('L – Groß')),
                    ],
                    onChanged: (v) => setState(() => _size = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _priority,
                    decoration: const InputDecoration(
                        labelText: 'Priorität', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('—')),
                      DropdownMenuItem(value: 'high', child: Text('🔴 Hoch')),
                      DropdownMenuItem(
                          value: 'medium', child: Text('🟡 Mittel')),
                      DropdownMenuItem(
                          value: 'low', child: Text('🟢 Niedrig')),
                    ],
                    onChanged: (v) => setState(() => _priority = v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen')),
        FilledButton(
            onPressed: _name.text.trim().isEmpty ? null : _submit,
            child: const Text('Erstellen')),
      ],
    );
  }
}

// ── Project Detail Screen ─────────────────────────────────────────────────────

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, required this.project});
  final Project project;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final _taskService = TaskService();
  final _projectService = ProjectService();
  final _milestoneService = MilestoneService();
  late Project _project;
  late Future<(List<Milestone>, List<Task>)> _future;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _future = _loadAll();
  }

  Future<(List<Milestone>, List<Task>)> _loadAll() async {
    final results = await Future.wait([
      _milestoneService.forProject(_project.id),
      _taskService.tasksForProject(_project.id),
    ]);
    return (results[0] as List<Milestone>, results[1] as List<Task>);
  }

  Future<void> _refresh() async {
    setState(() => _future = _loadAll());
    await _future;
  }

  // ── Milestones ───────────────────────────────────────────────────────────────

  Future<void> _addMilestone(List<Milestone> milestones) async {
    final data = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (_) => _MilestoneDialog(
        projectId: _project.id,
        allMilestones: milestones,
      ),
    );
    if (data != null) {
      await _milestoneService.create(data);
      await _refresh();
    }
  }

  Future<void> _editMilestone(Milestone milestone, List<Milestone> milestones) async {
    final data = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (_) => _MilestoneDialog(
        projectId: _project.id,
        existing: milestone,
        allMilestones: milestones,
      ),
    );
    if (data == null) return;
    if (data.containsKey('_delete')) {
      await _milestoneService.delete(milestone.id);
    } else {
      await _milestoneService.update(milestone.id, data);
    }
    await _refresh();
  }

  Future<void> _toggleMilestone(Milestone milestone) async {
    await _milestoneService
        .update(milestone.id, {'status': milestone.isDone ? 'open' : 'done'});
    await _refresh();
  }

  // ── Tasks ────────────────────────────────────────────────────────────────────

  Future<void> _toggleDone(Task task, bool done) async {
    await _taskService.setStatus(task.id, done ? 'done' : 'open');
    await _refresh();
  }

  Future<void> _openDetail(Task task) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
    );
    if (changed == true) await _refresh();
  }

  Future<void> _createNewTask() async {
    await _openDetail(Task(
      id: '',
      title: '',
      status: 'open',
      projectId: _project.id,
    ));
  }

  // ── Project delete ───────────────────────────────────────────────────────────

  Future<void> _deleteProject([List<Task>? tasks]) async {
    tasks ??= await _taskService.tasksForProject(_project.id);
    final deleteTasksToo = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Projekt löschen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Möchtest du das Projekt "${_project.name}" wirklich löschen?'),
            if (tasks.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Das Projekt hat ${tasks.length} ${tasks.length == 1 ? 'Task' : 'Tasks'}.',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              const Text('Was soll mit den Tasks passieren?'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          if (tasks.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Tasks behalten, nur Projekt löschen'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tasks.isEmpty
                ? 'Projekt löschen'
                : 'Projekt + Tasks löschen'),
          ),
        ],
      ),
    );

    if (deleteTasksToo == null) return;

    try {
      if (deleteTasksToo) {
        for (final task in tasks) {
          await _taskService.delete(task.id);
        }
      }
      await _projectService.deleteProject(_project.id);
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Projekt gelöscht')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  // ── Project edit ─────────────────────────────────────────────────────────────

  Future<void> _editProject() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ProjectEditSheet(
        project: _project,
        onSave: (patch) async {
          await _projectService.updateProject(_project.id, patch);
          setState(() {
            _project = Project(
              id: _project.id,
              name: patch['name'] as String? ?? _project.name,
              icon: patch.containsKey('icon')
                  ? patch['icon'] as String?
                  : _project.icon,
              status: patch['status'] as String? ?? _project.status,
              size: patch['size'] as String? ?? _project.size,
              goal: patch.containsKey('goal')
                  ? patch['goal'] as String?
                  : _project.goal,
              notes: _project.notes,
              shortCode: _project.shortCode,
              plannedYear: patch.containsKey('planned_year')
                  ? patch['planned_year'] as int?
                  : _project.plannedYear,
              plannedQuarter: patch.containsKey('planned_quarter')
                  ? patch['planned_quarter'] as int?
                  : _project.plannedQuarter,
              priority: patch.containsKey('priority')
                  ? patch['priority'] as String?
                  : _project.priority,
            );
          });
          Navigator.of(ctx).pop();
        },
      ),
    );
    // Trigger parent screen (ProjekteScreen) to reload project list
    if (mounted) Navigator.of(context).pop(true);
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_project.icon ?? '📁'}  ${_project.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Projekt bearbeiten',
            onPressed: _editProject,
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                child: const Text('Löschen'),
                onTap: _deleteProject,
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<(List<Milestone>, List<Task>)>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErrorView(error: snapshot.error!, onRetry: _refresh);
            }
            final (milestones, tasks) = snapshot.data!;

            if (isWideScreen) {
              return _ProjectDetailSplitView(
                project: _project,
                milestones: milestones,
                tasks: tasks,
                onAddMilestone: () => _addMilestone(milestones),
                onEditMilestone: (m) => _editMilestone(m, milestones),
                onToggleMilestone: _toggleMilestone,
                onToggleTask: _toggleDone,
                onTaskTap: _openDetail,
                onRefresh: _refresh,
              );
            } else {
              return _ProjectDetailMobileView(
                project: _project,
                milestones: milestones,
                tasks: tasks,
                onAddMilestone: () => _addMilestone(milestones),
                onEditMilestone: (m) => _editMilestone(m, milestones),
                onToggleMilestone: _toggleMilestone,
                onToggleTask: _toggleDone,
                onTaskTap: _openDetail,
                onRefresh: _refresh,
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewTask,
        tooltip: 'Neue Task',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── Milestones Section ────────────────────────────────────────────────────────

class _MilestonesSection extends StatelessWidget {
  const _MilestonesSection({
    required this.milestones,
    required this.onAdd,
    required this.onTap,
    required this.onToggle,
  });

  final List<Milestone> milestones;
  final VoidCallback onAdd;
  final void Function(Milestone) onTap;
  final void Function(Milestone) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Text('Milestones', style: theme.textTheme.labelLarge),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: onAdd,
                tooltip: 'Milestone hinzufügen',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        if (milestones.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(
              'Noch keine Milestones.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          )
        else
          for (final m in milestones)
            ListTile(
              dense: true,
              leading: Checkbox(
                value: m.isDone,
                onChanged: (_) => onToggle(m),
                visualDensity: VisualDensity.compact,
              ),
              title: Text(
                m.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  decoration:
                      m.isDone ? TextDecoration.lineThrough : null,
                  color: m.isDone ? theme.colorScheme.outline : null,
                ),
              ),
              subtitle: _quarterLabel(m, theme),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => onTap(m),
            ),
      ],
    );
  }

  Widget? _quarterLabel(Milestone m, ThemeData theme) {
    if (m.plannedYear == null) return null;
    final label = m.plannedQuarter != null
        ? 'Q${m.plannedQuarter} ${m.plannedYear}'
        : '${m.plannedYear}';
    return Text(label,
        style: theme.textTheme.labelSmall
            ?.copyWith(color: theme.colorScheme.primary));
  }
}

// ── Milestone Dialog ──────────────────────────────────────────────────────────

class _MilestoneDialog extends StatefulWidget {
  const _MilestoneDialog({
    required this.projectId,
    this.existing,
    required this.allMilestones,
  });
  final String projectId;
  final Milestone? existing;
  final List<Milestone> allMilestones;

  @override
  State<_MilestoneDialog> createState() => _MilestoneDialogState();
}

class _MilestoneDialogState extends State<_MilestoneDialog> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  String? _parentMilestoneId;
  int? _year;
  int? _quarter;

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _title = TextEditingController(text: m?.title ?? '');
    _description = TextEditingController(text: m?.description ?? '');
    _parentMilestoneId = m?.parentMilestoneId;
    _year = m?.plannedYear;
    _quarter = m?.plannedQuarter;
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (_title.text.trim().isEmpty) return;
    Navigator.of(context).pop({
      'project_id': widget.projectId,
      'title': _title.text.trim(),
      'description':
          _description.text.trim().isEmpty ? null : _description.text.trim(),
      'parent_milestone_id': _parentMilestoneId,
      'planned_year': _year,
      'planned_quarter': _quarter,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Milestone bearbeiten' : 'Neuer Milestone'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              autofocus: true,
              decoration: const InputDecoration(
                  labelText: 'Titel *', border: OutlineInputBorder()),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Beschreibung', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _parentMilestoneId,
              decoration: const InputDecoration(
                  labelText: 'Parent Milestone (optional)',
                  border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('— Kein Parent')),
                for (final m in widget.allMilestones
                    .where((m) => m.id != widget.existing?.id))
                  DropdownMenuItem(value: m.id, child: Text(m.title)),
              ],
              onChanged: (v) => setState(() => _parentMilestoneId = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _year,
                    decoration: const InputDecoration(
                        labelText: 'Jahr', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('—')),
                      for (final y in List.generate(
                          5, (i) => DateTime.now().year + i))
                        DropdownMenuItem(value: y, child: Text('$y')),
                    ],
                    onChanged: (v) => setState(() {
                      _year = v;
                      if (v == null) _quarter = null;
                    }),
                  ),
                ),
                if (_year != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _quarter,
                      decoration: const InputDecoration(
                          labelText: 'Quartal', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('—')),
                        DropdownMenuItem(value: 1, child: Text('Q1')),
                        DropdownMenuItem(value: 2, child: Text('Q2')),
                        DropdownMenuItem(value: 3, child: Text('Q3')),
                        DropdownMenuItem(value: 4, child: Text('Q4')),
                      ],
                      onChanged: (v) => setState(() => _quarter = v),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (isEdit)
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop({'_delete': true}),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Löschen'),
          ),
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen')),
        FilledButton(
            onPressed: _title.text.trim().isEmpty ? null : _submit,
            child: Text(isEdit ? 'Speichern' : 'Erstellen')),
      ],
    );
  }
}

// ── Project Detail Split View (Desktop/Tablet) ────────────────────────────────

class _ProjectDetailSplitView extends StatefulWidget {
  const _ProjectDetailSplitView({
    required this.project,
    required this.milestones,
    required this.tasks,
    required this.onAddMilestone,
    required this.onEditMilestone,
    required this.onToggleMilestone,
    required this.onToggleTask,
    required this.onTaskTap,
    required this.onRefresh,
  });

  final Project project;
  final List<Milestone> milestones;
  final List<Task> tasks;
  final VoidCallback onAddMilestone;
  final void Function(Milestone) onEditMilestone;
  final void Function(Milestone) onToggleMilestone;
  final void Function(Task, bool) onToggleTask;
  final void Function(Task) onTaskTap;
  final VoidCallback onRefresh;

  @override
  State<_ProjectDetailSplitView> createState() =>
      _ProjectDetailSplitViewState();
}

class _ProjectDetailSplitViewState extends State<_ProjectDetailSplitView> {
  final _taskService = TaskService();
  bool _useMindmap = false;

  Future<void> _updateTaskMilestone(
      Task task, String? newMilestoneId) async {
    try {
      await _taskService
          .updateFields(task.id, {'milestone_id': newMilestoneId});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newMilestoneId == null
              ? 'Task entfernt'
              : 'Task zugeordnet'),
          duration: const Duration(seconds: 2),
        ),
      );
      widget.onRefresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Info Bar
        Container(
          color: theme.colorScheme.surfaceContainer,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (widget.project.goal != null && widget.project.goal!.isNotEmpty) ...[
                  _InfoBadge(
                    label: 'Ziel',
                    value: widget.project.goal!,
                    theme: theme,
                  ),
                  const SizedBox(width: 16),
                ],
                if (widget.project.status != null) ...[
                  _InfoBadge(
                    label: 'Status',
                    value: widget.project.status!,
                    theme: theme,
                  ),
                  const SizedBox(width: 16),
                ],
                if (widget.project.size != null) ...[
                  _InfoBadge(
                    label: 'Größe',
                    value: widget.project.size!,
                    theme: theme,
                  ),
                  const SizedBox(width: 16),
                ],
                if (widget.project.priority != null) ...[
                  _InfoBadge(
                    label: 'Priorität',
                    value: switch (widget.project.priority!) {
                      'high' => '🔴 Hoch',
                      'medium' => '🟡 Mittel',
                      'low' => '🟢 Niedrig',
                      _ => widget.project.priority!,
                    },
                    theme: theme,
                  ),
                  const SizedBox(width: 16),
                ],
                if (widget.project.plannedYear != null)
                  _InfoBadge(
                    label: 'Geplant',
                    value: widget.project.plannedQuarter != null
                        ? 'Q${widget.project.plannedQuarter} ${widget.project.plannedYear}'
                        : '${widget.project.plannedYear}',
                    theme: theme,
                  ),
              ],
            ),
          ),
        ),

        // Milestone Tree + Tasks
        Expanded(
          child: Row(
            children: [
              // Left: Milestones
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            'Milestones',
                            style: theme.textTheme.labelLarge,
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              _useMindmap ? Icons.list : Icons.dashboard,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _useMindmap = !_useMindmap),
                            tooltip: _useMindmap
                                ? 'Zur Liste wechseln'
                                : 'Zur Mind-Map wechseln',
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 20),
                            onPressed: widget.onAddMilestone,
                            tooltip: 'Milestone hinzufügen',
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: widget.milestones.isEmpty
                          ? Center(
                              child: Text(
                                'Noch keine Milestones.',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            )
                          : _useMindmap
                              ? MilestoneMindmapWidget(
                                  milestones: widget.milestones,
                                  tasks: widget.tasks,
                                  onMilestoneToggle: widget.onToggleMilestone,
                                  onTaskToggle: widget.onToggleTask,
                                  onTaskTap: widget.onTaskTap,
                                  onMilestoneEdit: widget.onEditMilestone,
                                  onTaskMilestoneChanged:
                                      _updateTaskMilestone,
                                )
                              : MilestoneTreeWidget(
                                  milestones: widget.milestones,
                                  tasks: widget.tasks,
                                  onMilestoneToggle: widget.onToggleMilestone,
                                  onTaskToggle: widget.onToggleTask,
                                  onTaskTap: widget.onTaskTap,
                                  onMilestoneEdit: widget.onEditMilestone,
                                  onTaskMilestoneChanged:
                                      _updateTaskMilestone,
                                ),
                    ),
                  ],
                ),
              ),
              // Right: Tasks without milestone
              if (widget.tasks.any((t) => t.milestoneId == null))
                Container(
                  width: 1,
                  color: theme.colorScheme.outlineVariant,
                ),
              if (widget.tasks.any((t) => t.milestoneId == null))
                SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Text(
                          'Offene Tasks',
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          children: [
                            for (final (i, task) in widget.tasks
                                .where((t) => t.milestoneId == null)
                                .indexed)
                              TaskTile(
                                task: task,
                                shaded: i.isOdd,
                                onTap: () => widget.onTaskTap(task),
                                onToggleDone: (v) =>
                                    widget.onToggleTask(task, v),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Project Detail Mobile View ─────────────────────────────────────────────────

class _ProjectDetailMobileView extends StatelessWidget {
  const _ProjectDetailMobileView({
    required this.project,
    required this.milestones,
    required this.tasks,
    required this.onAddMilestone,
    required this.onEditMilestone,
    required this.onToggleMilestone,
    required this.onToggleTask,
    required this.onTaskTap,
    required this.onRefresh,
  });

  final Project project;
  final List<Milestone> milestones;
  final List<Task> tasks;
  final VoidCallback onAddMilestone;
  final void Function(Milestone) onEditMilestone;
  final void Function(Milestone) onToggleMilestone;
  final void Function(Task, bool) onToggleTask;
  final void Function(Task) onTaskTap;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _MilestonesSection(
          milestones: milestones,
          onAdd: onAddMilestone,
          onTap: onEditMilestone,
          onToggle: onToggleMilestone,
        ),
        if (tasks.isNotEmpty) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('Tasks',
                style: Theme.of(context).textTheme.labelLarge),
          ),
          for (final (i, task) in tasks.indexed)
            TaskTile(
              task: task,
              shaded: i.isOdd,
              onTap: () => onTaskTap(task),
              onToggleDone: (v) => onToggleTask(task, v),
            ),
        ] else if (milestones.isEmpty)
          const EmptyView(
              message: 'Noch keine Tasks oder Milestones.'),
      ],
    );
  }
}

// ── Project Edit Bottom Sheet ─────────────────────────────────────────────────

class _ProjectEditSheet extends StatefulWidget {
  const _ProjectEditSheet({required this.project, required this.onSave});
  final Project project;
  final Future<void> Function(Map<String, dynamic> patch) onSave;

  @override
  State<_ProjectEditSheet> createState() => _ProjectEditSheetState();
}

class _ProjectEditSheetState extends State<_ProjectEditSheet> {
  late final TextEditingController _goal;
  late String? _status;
  late String? _size;
  late String? _priority;
  late int? _plannedYear;
  late int? _plannedQuarter;
  bool _saving = false;

  static const _statuses = ['active', 'backlog', 'done'];
  static const _sizes = ['S', 'M', 'L'];
  static const _quarters = [1, 2, 3, 4];

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    _goal = TextEditingController(text: p.goal ?? '');
    _status = _statuses.contains(p.status) ? p.status : null;
    _size = _sizes.contains(p.size) ? p.size : null;
    _priority = ['high', 'medium', 'low'].contains(p.priority) ? p.priority : null;
    _plannedYear = p.plannedYear;
    _plannedQuarter = _quarters.contains(p.plannedQuarter) ? p.plannedQuarter : null;
  }

  @override
  void dispose() {
    _goal.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave({
      'goal': _goal.text.trim().isEmpty ? null : _goal.text.trim(),
      'status': _status,
      'size': _size,
      'priority': _priority,
      'planned_year': _plannedYear,
      'planned_quarter': _plannedQuarter,
    });
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Projekt bearbeiten', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _goal,
            maxLines: 2,
            decoration: const InputDecoration(
                labelText: 'Ziel', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _status,
                  decoration: const InputDecoration(
                      labelText: 'Status', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('—')),
                    for (final s in _statuses)
                      DropdownMenuItem(value: s, child: Text(s)),
                  ],
                  onChanged: (v) => setState(() => _status = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _size,
                  decoration: const InputDecoration(
                      labelText: 'Größe', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('—')),
                    for (final s in _sizes)
                      DropdownMenuItem(value: s, child: Text(s)),
                  ],
                  onChanged: (v) => setState(() => _size = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _priority,
                  decoration: const InputDecoration(
                      labelText: 'Priorität', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('—')),
                    DropdownMenuItem(value: 'high', child: Text('🔴 Hoch')),
                    DropdownMenuItem(value: 'medium', child: Text('🟡 Mittel')),
                    DropdownMenuItem(value: 'low', child: Text('🟢 Niedrig')),
                  ],
                  onChanged: (v) => setState(() => _priority = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _plannedYear,
                  decoration: const InputDecoration(
                      labelText: 'Jahr', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('—')),
                    for (final y in List.generate(
                        5, (i) => DateTime.now().year + i))
                      DropdownMenuItem(value: y, child: Text('$y')),
                  ],
                  onChanged: (v) => setState(() {
                    _plannedYear = v;
                    if (v == null) _plannedQuarter = null;
                  }),
                ),
              ),
            ],
          ),
          if (_plannedYear != null) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: _plannedQuarter,
              decoration: const InputDecoration(
                  labelText: 'Quartal (optional)',
                  border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('— (ganzes Jahr)')),
                for (final q in _quarters)
                  DropdownMenuItem(value: q, child: Text('Q$q')),
              ],
              onChanged: (v) => setState(() => _plannedQuarter = v),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}

// ── Icon Picker Sheet ─────────────────────────────────────────────────────

class _IconPickerSheet extends StatelessWidget {
  const _IconPickerSheet({required this.currentIcon});
  final String? currentIcon;

  static const _icons = [
    '📁', '📂', '📦', '🎯', '🚀', '💡', '🔧', '⚙️',
    '📱', '💻', '🌐', '🎨', '✏️', '📝', '📊', '📈',
    '🎬', '🎭', '🎪', '🎸', '🎤', '🎨', '🖼️', '📸',
    '🏆', '🎁', '⭐', '✨', '🌟', '💫', '🔥', '❄️',
    '🌈', '☀️', '🌙', '⚡', '🌊', '🌳', '🍕', '🍔',
    '🚗', '🚕', '✈️', '🚀', '🚁', '⛵', '🚂', '🚆',
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Icon wählen',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _icons.length,
                itemBuilder: (context, index) {
                  final icon = _icons[index];
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(icon),
                    child: Container(
                      decoration: BoxDecoration(
                        border: currentIcon == icon
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          icon,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

