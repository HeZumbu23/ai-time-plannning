import 'package:flutter/material.dart';

import '../models/project.dart';
import '../models/task.dart';
import '../services/project_service.dart';
import '../services/task_service.dart';
import '../widgets/status_views.dart';
import '../widgets/task_tile.dart';
import 'task_detail_screen.dart';

/// Tagesplan: Tasks für heute (planned_day = today).
class TagesplanScreen extends StatefulWidget {
  const TagesplanScreen({super.key});

  @override
  State<TagesplanScreen> createState() => _TagesplanScreenState();
}

class _TagesplanScreenState extends State<TagesplanScreen> {
  final _service = TaskService();
  final _projects = ProjectService();
  late Future<_TagesplanData> _future;
  bool _allCollapsed = false;
  int _collapseGen = 0;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_TagesplanData> _load() async {
    final results = await Future.wait([
      _service.tasksForDay(DateTime.now()),
      _projects.all(),
    ]);
    final tasks = results[0] as List<Task>;
    final projects = {for (final p in results[1] as List<Project>) p.id: p};
    return _TagesplanData(tasks: tasks, projects: projects);
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
      plannedDay: DateTime.now(),
    );
    await _openDetail(newTask);
  }

  // Bevorzugte Reihenfolge der Kontexte; Unbekanntes danach, "ohne" ganz hinten.
  static const _contextOrder = ['büro', 'stadt', 'samstag', 'sonntag', 'flexibel'];

  /// Tasks nach Kontext gruppiert mit einklappbaren Gruppen.
  Widget _buildGrouped(_TagesplanData data) {
    final theme = Theme.of(context);
    final groups = <String?, List<Task>>{};
    for (final t in data.tasks) {
      (groups[t.context] ??= []).add(t);
    }

    int rank(String? c) {
      if (c == null) return 1000; // "ohne Kontext" ans Ende
      final i = _contextOrder.indexOf(c);
      return i == -1 ? 500 : i;
    }

    final keys = groups.keys.toList()
      ..sort((a, b) {
        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : (a ?? '').compareTo(b ?? '');
      });

    final headerColor = theme.colorScheme.secondaryContainer;
    final onHeader = theme.colorScheme.onSecondaryContainer;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        CollapseButton(collapsed: _allCollapsed, onTap: _toggleAll),
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
              key: ValueKey('tagesplan_${key ?? 'none'}_$_collapseGen'),
              initiallyExpanded: !_allCollapsed,
              backgroundColor: headerColor.withOpacity(0.25),
              collapsedBackgroundColor: headerColor,
              iconColor: onHeader,
              collapsedIconColor: onHeader,
              tilePadding: const EdgeInsets.symmetric(horizontal: 14),
              childrenPadding: EdgeInsets.zero,
              leading: Text(
                key == null ? '📥' : '📍',
                style: const TextStyle(fontSize: 20),
              ),
              title: Text(
                key == null ? 'Ohne Kontext' : key,
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
                    projectIcon: t.projectId != null
                        ? data.projects[t.projectId]?.icon
                        : null,
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
        child: FutureBuilder<_TagesplanData>(
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
              return const EmptyView(
                  message: 'Heute nichts geplant. Genieß den Tag! 🎉');
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

class _TagesplanData {
  _TagesplanData({required this.tasks, required this.projects});
  final List<Task> tasks;
  final Map<String, Project> projects;
}
