import 'package:flutter/material.dart';

import '../models/project.dart';
import '../models/task.dart';
import '../services/project_service.dart';
import '../services/task_service.dart';
import '../widgets/status_views.dart';
import '../widgets/task_tile.dart';
import 'task_detail_screen.dart';

/// Backlog: offene Tasks ohne konkrete Tagesplanung, nach Projekt gruppiert.
class BacklogScreen extends StatefulWidget {
  const BacklogScreen({super.key});

  @override
  State<BacklogScreen> createState() => _BacklogScreenState();
}

class _BacklogScreenState extends State<BacklogScreen> {
  final _service = TaskService();
  final _projects = ProjectService();
  late Future<_BacklogData> _future;
  bool _allCollapsed = false;
  int _collapseGen = 0;
  bool _nurUngeplante = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_BacklogData> _load() async {
    final results = await Future.wait([_service.backlog(), _projects.all()]);
    final tasks = results[0] as List<Task>;
    final projects = {for (final p in results[1] as List<Project>) p.id: p};
    return _BacklogData(tasks: tasks, projects: projects);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  void _toggleAll() => setState(() {
        _allCollapsed = !_allCollapsed;
        _collapseGen++;
      });

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

  Future<void> _createNewTask() async {
    final newTask = Task(
      id: '',
      title: '',
      status: 'open',
    );
    await _openDetail(newTask);
  }

  Widget _buildGrouped(_BacklogData data) {
    final theme = Theme.of(context);

    final filteredTasks = _nurUngeplante
        ? data.tasks.where((t) => t.plannedWeek == null).toList()
        : data.tasks;

    // Gruppieren nach project_id (null -> "Ohne Projekt").
    final groups = <String?, List<Task>>{};
    for (final t in filteredTasks) {
      (groups[t.projectId] ??= []).add(t);
    }

    String label(String? id) {
      if (id == null) return 'Ohne Projekt';
      final p = data.projects[id];
      if (p == null) return 'Projekt $id';
      return p.name;
    }

    String? icon(String? id) => id == null ? null : data.projects[id]?.icon;

    final keys = groups.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1; // "Ohne Projekt" ans Ende
        if (b == null) return -1;
        return label(a).toLowerCase().compareTo(label(b).toLowerCase());
      });

    final headerColor = theme.colorScheme.secondaryContainer;
    final onHeader = theme.colorScheme.onSecondaryContainer;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 4, 0),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Nur ungeplante'),
                selected: _nurUngeplante,
                onSelected: (v) => setState(() => _nurUngeplante = v),
                visualDensity: VisualDensity.compact,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _toggleAll,
                icon: Icon(
                  _allCollapsed ? Icons.unfold_more : Icons.unfold_less,
                  size: 16,
                ),
                label: Text(_allCollapsed ? 'Alle ausklappen' : 'Alle einklappen'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
        if (filteredTasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('Alle Tasks sind bereits geplant. 🎉',
                  textAlign: TextAlign.center),
            ),
          ),
        for (final key in keys)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: ExpansionTile(
              key: ValueKey('backlog_${key ?? 'none'}_$_collapseGen'),
              initiallyExpanded: !_allCollapsed,
              backgroundColor: headerColor.withOpacity(0.25),
              collapsedBackgroundColor: headerColor,
              iconColor: onHeader,
              collapsedIconColor: onHeader,
              tilePadding: const EdgeInsets.symmetric(horizontal: 14),
              childrenPadding: EdgeInsets.zero,
              leading: Text(
                key == null ? '📥' : (icon(key) ?? '📁'),
                style: const TextStyle(fontSize: 20),
              ),
              title: Text(
                label(key),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold, color: onHeader),
              ),
              subtitle: Text(
                '${groups[key]!.length} Aufgaben',
                style: theme.textTheme.labelSmall?.copyWith(color: onHeader),
              ),
              children: [
                for (final (i, t) in groups[key]!.indexed)
                  TaskTile(
                    task: t,
                    shaded: i.isOdd,
                    onTap: () => _openDetail(t),
                    onToggleDone: (v) => _toggleDone(t, v),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 24),
      ],
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
            return _buildGrouped(data);
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

class _BacklogData {
  _BacklogData({required this.tasks, required this.projects});
  final List<Task> tasks;
  final Map<String, Project> projects;
}
