import 'package:flutter/material.dart';

import '../models/project.dart';
import '../models/task.dart';
import '../services/project_service.dart';
import '../services/task_service.dart';
import '../widgets/project_roadmap_list.dart';
import '../widgets/status_views.dart';
import '../widgets/task_tile.dart';
import 'task_detail_screen.dart';

class ProjekteScreen extends StatefulWidget {
  const ProjekteScreen({super.key});

  @override
  State<ProjekteScreen> createState() => _ProjekteScreenState();
}

class _ProjekteScreenState extends State<ProjekteScreen> {
  final _service = ProjectService();
  List<Project> _projects = [];
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
      final projects = await _service.all();
      if (mounted) setState(() {
        _projects = projects;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  // ── Group key encoding ──────────────────────────────────────────────────────

  static String? _encodeKey(int? year, int? quarter) =>
      year == null ? null : quarter == null ? '$year' : '$year-$quarter';

  static ({int? year, int? quarter}) _decodeKey(String? key) {
    if (key == null) return (year: null, quarter: null);
    final parts = key.split('-');
    return (
      year: int.parse(parts[0]),
      quarter: parts.length > 1 ? int.parse(parts[1]) : null,
    );
  }

  // ── Group building ──────────────────────────────────────────────────────────

  List<ProjectRoadmapEntry> _buildGroups() {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentQuarter = (now.month - 1) ~/ 3 + 1;

    // Default timeline: current quarter → Q4 of next year → year+2 catch-all
    final defaultKeys = <String?>[null];
    for (var q = currentQuarter; q <= 4; q++) {
      defaultKeys.add('$currentYear-$q');
    }
    for (var q = 1; q <= 4; q++) {
      defaultKeys.add('${currentYear + 1}-$q');
    }
    defaultKeys.add('${currentYear + 2}');

    // Add groups for projects that fall outside the default range
    final projectKeys =
        _projects.map((p) => _encodeKey(p.plannedYear, p.plannedQuarter)).toSet();
    final extraKeys = (projectKeys.difference(defaultKeys.toSet())).toList()
      ..sort((a, b) {
        if (a == null) return -1;
        if (b == null) return 1;
        return a.compareTo(b);
      });

    final allKeys = [...defaultKeys, ...extraKeys];

    // Distribute projects into groups, sorted by priority then name
    final grouped = <String?, List<Project>>{
      for (final k in allKeys) k: [],
    };
    for (final p in _projects) {
      (grouped[_encodeKey(p.plannedYear, p.plannedQuarter)] ??= []).add(p);
    }
    const _priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
    for (final list in grouped.values) {
      list.sort((a, b) {
        final pa = _priorityOrder[a.priority] ?? 3;
        final pb = _priorityOrder[b.priority] ?? 3;
        if (pa != pb) return pa.compareTo(pb);
        return a.name.compareTo(b.name);
      });
    }

    return allKeys
        .map((k) => ProjectRoadmapEntry(
              key: k,
              title: _groupTitle(k),
              icon: _groupIcon(k),
              projects: grouped[k]!,
            ))
        .toList();
  }

  static String _groupTitle(String? key) {
    if (key == null) return 'Backlog';
    final parts = key.split('-');
    return parts.length == 1 ? 'Jahr ${parts[0]}' : 'Q${parts[1]} ${parts[0]}';
  }

  static String _groupIcon(String? key) {
    if (key == null) return '📋';
    final parts = key.split('-');
    if (parts.length == 1) return '📅';
    return switch (int.parse(parts[1])) {
      1 => '❄️',
      2 => '🌱',
      3 => '☀️',
      4 => '🍂',
      _ => '📅',
    };
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _moveProject(Project project, String? newKey) async {
    final (:year, :quarter) = _decodeKey(newKey);
    await _service.updateProject(project.id, {
      'planned_year': year,
      'planned_quarter': quarter,
    });
    await _load();
  }

  Future<void> _addProject(String? groupKey) async {
    final (:year, :quarter) = _decodeKey(groupKey);
    final data = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) => _NewProjectDialog(
        initialYear: year,
        initialQuarter: quarter,
      ),
    );
    if (data != null) {
      await _service.createProject(data);
      await _load();
    }
  }

  void _openProject(Project project) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => ProjectDetailScreen(project: project),
        ))
        .then((_) => _load());
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorView(error: _error!, onRetry: _load);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ProjectRoadmapList(
        groups: _buildGroups(),
        onMove: _moveProject,
        onTap: _openProject,
        onAddProject: _addProject,
      ),
    );
  }
}

// ── New Project Dialog ────────────────────────────────────────────────────────

class _NewProjectDialog extends StatefulWidget {
  const _NewProjectDialog({this.initialYear, this.initialQuarter});
  final int? initialYear;
  final int? initialQuarter;

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
      if (widget.initialYear != null) 'planned_year': widget.initialYear,
      if (widget.initialQuarter != null) 'planned_quarter': widget.initialQuarter,
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupLabel = widget.initialYear == null
        ? 'Backlog'
        : widget.initialQuarter == null
            ? 'Jahr ${widget.initialYear}'
            : 'Q${widget.initialQuarter} ${widget.initialYear}';

    return AlertDialog(
      title: Text('Neues Projekt – $groupLabel'),
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
                      DropdownMenuItem(
                          value: 'high', child: Text('🔴 Hoch')),
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
  late Project _project;
  late Future<List<Task>> _future;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _future = _taskService.tasksForProject(_project.id);
  }

  Future<void> _refresh() async {
    setState(() => _future = _taskService.tasksForProject(_project.id));
    await _future;
  }

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

  Future<void> _editProject() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ProjectEditSheet(
        project: _project,
        onSave: (patch) async {
          await _projectService.updateProject(_project.id, patch);
          // Reload project from service isn't available as a single-item fetch,
          // so apply the patch locally.
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
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_project.icon ?? '📁'}  ${_project.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Projekt bearbeiten',
            onPressed: _editProject,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Task>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErrorView(error: snapshot.error!, onRetry: _refresh);
            }
            final tasks = snapshot.data!;
            if (tasks.isEmpty) {
              return const EmptyView(message: 'Keine Tasks in diesem Projekt.');
            }
            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, i) => TaskTile(
                task: tasks[i],
                shaded: i.isOdd,
                onTap: () => _openDetail(tasks[i]),
                onToggleDone: (v) => _toggleDone(tasks[i], v),
              ),
            );
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
    _status = p.status;
    _size = p.size;
    _priority = p.priority;
    _plannedYear = p.plannedYear;
    _plannedQuarter = p.plannedQuarter;
  }

  @override
  void dispose() {
    _goal.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final patch = <String, dynamic>{
      'goal': _goal.text.trim().isEmpty ? null : _goal.text.trim(),
      'status': _status,
      'size': _size,
      'priority': _priority,
      'planned_year': _plannedYear,
      'planned_quarter': _plannedQuarter,
    };
    await widget.onSave(patch);
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
          Text('Projekt bearbeiten',
              style: theme.textTheme.titleMedium),
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
                    DropdownMenuItem(
                        value: 'medium', child: Text('🟡 Mittel')),
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
