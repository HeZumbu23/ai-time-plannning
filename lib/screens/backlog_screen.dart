import 'package:flutter/material.dart';

import '../models/project.dart';
import '../models/task.dart';
import '../services/project_service.dart';
import '../services/task_service.dart';
import '../widgets/grouped_drag_drop_list.dart';
import '../widgets/status_views.dart';
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
    return _BacklogData(
      tasks: results[0] as List<Task>,
      projects: {for (final p in results[1] as List<Project>) p.id: p},
    );
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

  Future<void> _moveTask(Task task, String? newProjectId) async {
    await _service.updateFields(task.id, {'project_id': newProjectId});
    await _refresh();
  }

  String _projectLabel(_BacklogData data, String? id) {
    if (id == null) return 'Ohne Projekt';
    return data.projects[id]?.name ?? 'Projekt $id';
  }

  String _projectIcon(_BacklogData data, String? id) =>
      id == null ? '📥' : (data.projects[id]?.icon ?? '📁');

  List<GroupEntry<String?>> _toGroups(_BacklogData data) {
    final filteredTasks = _nurUngeplante
        ? data.tasks.where((t) => t.plannedWeek == null).toList()
        : data.tasks;

    final groups = <String?, List<Task>>{};
    for (final t in filteredTasks) {
      (groups[t.projectId] ??= []).add(t);
    }

    final keys = groups.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        return _projectLabel(data, a)
            .toLowerCase()
            .compareTo(_projectLabel(data, b).toLowerCase());
      });

    return [
      for (final key in keys)
        GroupEntry(
          key: key,
          title: _projectLabel(data, key),
          icon: _projectIcon(data, key),
          tasks: groups[key]!,
        ),
    ];
  }

  Widget _headerWidget() {
    return Padding(
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
            label: Text(
                _allCollapsed ? 'Alle ausklappen' : 'Alle einklappen'),
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
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
            final groups = _toGroups(data);

            if (data.tasks.isEmpty) {
              return const EmptyView(message: 'Backlog ist leer. 📭');
            }

            if (groups.isEmpty) {
              return ListView(
                children: [
                  _headerWidget(),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'Alle Tasks sind bereits geplant. 🎉',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            }

            return GroupedDragDropList<String?>(
              groups: groups,
              onMove: _moveTask,
              onTap: _openDetail,
              onToggleDone: _toggleDone,
              onAddTask: (projectId) => _openDetail(Task(
                id: '',
                title: '',
                status: 'open',
                projectId: projectId,
              )),
              allCollapsed: _allCollapsed,
              collapseGen: _collapseGen,
              headerWidget: _headerWidget(),
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
}

class _BacklogData {
  _BacklogData({required this.tasks, required this.projects});
  final List<Task> tasks;
  final Map<String, Project> projects;
}
