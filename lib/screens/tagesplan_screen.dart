import 'package:flutter/material.dart';

import '../models/project.dart';
import '../models/task.dart';
import '../services/project_service.dart';
import '../services/task_service.dart';
import '../widgets/grouped_drag_drop_list.dart';
import '../widgets/status_views.dart';
import 'task_detail_screen.dart';

/// Tagesplan: Tasks für heute (planned_day = today), gruppiert nach Tagesabschnitt.
/// Die drei Abschnitte Vormittag/Nachmittag/Abend sind immer sichtbar, auch wenn leer.
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
  final _doneOverrides = <String, bool>{};

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
    return _TagesplanData(
      tasks: results[0] as List<Task>,
      projects: {for (final p in results[1] as List<Project>) p.id: p},
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _doneOverrides.clear();
      _future = _load();
    });
    await _future;
  }

  void _toggleAll() => setState(() {
        _allCollapsed = !_allCollapsed;
        _collapseGen++;
      });

  Future<void> _toggleDone(Task task, bool done) async {
    setState(() => _doneOverrides[task.id] = done);
    await _service.setStatus(task.id, done ? 'done' : 'open');
  }

  Future<void> _openDetail(Task task) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
    );
    if (changed == true) await _refresh();
  }

  Future<void> _addTaskToSection(String? section) async {
    await _openDetail(Task(
      id: '',
      title: '',
      status: 'open',
      plannedDay: DateTime.now(),
      daySection: section,
    ));
  }

  Future<void> _moveTask(Task task, String? newSection) async {
    await _service.updateFields(task.id, {'day_section': newSection});
    await _refresh();
  }

  static const _fixedSections = ['vormittag', 'nachmittag', 'abend'];

  static const _sectionLabel = <String?, String>{
    'vormittag': 'Vormittag',
    'nachmittag': 'Nachmittag',
    'abend': 'Abend',
    null: 'Ohne Abschnitt',
  };

  static const _sectionIcon = <String?, String>{
    'vormittag': '🌅',
    'nachmittag': '☀️',
    'abend': '🌙',
    null: '📥',
  };

  List<GroupEntry<String?>> _toGroups(_TagesplanData data) {
    final groups = <String?, List<Task>>{};
    for (final t in data.tasks) {
      (groups[t.daySection] ??= []).add(
        _doneOverrides.containsKey(t.id)
            ? t.withStatus(_doneOverrides[t.id]! ? 'done' : 'open')
            : t,
      );
    }
    return [
      // Feste Abschnitte immer anzeigen (auch wenn leer – als Drag-Ziel)
      for (final key in _fixedSections)
        GroupEntry(
          key: key,
          title: _sectionLabel[key]!,
          icon: _sectionIcon[key]!,
          tasks: groups[key] ?? [],
        ),
      // "Ohne Abschnitt" nur wenn Tasks ohne Abschnitt vorhanden
      if (groups.containsKey(null))
        GroupEntry(
          key: null,
          title: _sectionLabel[null]!,
          icon: _sectionIcon[null]!,
          tasks: groups[null]!,
        ),
    ];
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
            return GroupedDragDropList<String?>(
              groups: _toGroups(snapshot.data!),
              onMove: _moveTask,
              onTap: _openDetail,
              onToggleDone: _toggleDone,
              onAddTask: _addTaskToSection,
              projectIconFor: (t) =>
                  t.projectId != null
                      ? snapshot.data!.projects[t.projectId]?.icon
                      : null,
              allCollapsed: _allCollapsed,
              collapseGen: _collapseGen,
              headerWidget:
                  CollapseButton(collapsed: _allCollapsed, onTap: _toggleAll),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTaskToSection(null),
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
