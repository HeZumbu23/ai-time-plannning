import 'package:flutter/material.dart';

import '../models/project.dart';
import '../models/task.dart';
import '../services/project_service.dart';
import '../services/task_service.dart';
import '../widgets/grouped_drag_drop_list.dart';
import '../widgets/status_views.dart';
import 'task_detail_screen.dart';

/// Wochenplan: Tasks der gewählten Kalenderwoche, gruppiert nach Wochentag.
class WochenplanScreen extends StatefulWidget {
  const WochenplanScreen({super.key});

  @override
  State<WochenplanScreen> createState() => _WochenplanScreenState();
}

class _WochenplanScreenState extends State<WochenplanScreen> {
  final _service = TaskService();
  final _projects = ProjectService();
  late int _week;
  late Future<_WochenplanData> _future;
  bool _allCollapsed = false;
  int _collapseGen = 0;
  final _doneOverrides = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _week = _isoWeekNumber(DateTime.now());
    _future = _load();
  }

  Future<_WochenplanData> _load() async {
    final results = await Future.wait([
      _service.tasksForWeek(_week),
      _projects.all(),
    ]);
    return _WochenplanData(
      tasks: results[0] as List<Task>,
      projects: {for (final p in results[1] as List<Project>) p.id: p},
    );
  }

  static int _isoWeekNumber(DateTime date) {
    final d = DateTime.utc(date.year, date.month, date.day);
    final dayOfYear = d.difference(DateTime.utc(d.year, 1, 1)).inDays + 1;
    final weekday = d.weekday;
    var week = ((dayOfYear - weekday + 10) / 7).floor();
    if (week < 1) {
      week = _isoWeekNumber(DateTime.utc(d.year - 1, 12, 31));
    } else if (week > 52) {
      final dec31Weekday = DateTime.utc(d.year, 12, 31).weekday;
      if (week == 53 && dec31Weekday < 4) week = 1;
    }
    return week;
  }

  void _changeWeek(int delta) {
    setState(() {
      _week += delta;
      _doneOverrides.clear();
      _future = _load();
    });
  }

  void _toggleAll() => setState(() {
        _allCollapsed = !_allCollapsed;
        _collapseGen++;
      });

  Future<void> _refresh() async {
    setState(() {
      _doneOverrides.clear();
      _future = _load();
    });
    await _future;
  }

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

  Future<void> _addTaskForDay(DateTime? day) async {
    await _openDetail(Task(
      id: '',
      title: '',
      status: 'open',
      plannedWeek: _week,
      plannedDay: day,
    ));
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _moveTask(Task task, DateTime? newDay) async {
    await _service.updateFields(task.id, {
      'planned_day': newDay == null ? null : _dateStr(newDay),
    });
    await _refresh();
  }

  static const _weekdays = [
    'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag',
    'Freitag', 'Samstag', 'Sonntag',
  ];

  static String _dayLabel(DateTime? d) {
    if (d == null) return 'Ohne festen Tag';
    return '${_weekdays[d.weekday - 1]} · '
        '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.';
  }

  List<GroupEntry<DateTime?>> _toGroups(_WochenplanData data) {
    final groupsMap = <DateTime?, List<Task>>{};
    for (final t in data.tasks) {
      final key = t.plannedDay == null
          ? null
          : DateTime(
              t.plannedDay!.year, t.plannedDay!.month, t.plannedDay!.day);
      (groupsMap[key] ??= []).add(
        _doneOverrides.containsKey(t.id)
            ? t.withStatus(_doneOverrides[t.id]! ? 'done' : 'open')
            : t,
      );
    }
    final keys = groupsMap.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        return a.compareTo(b);
      });
    return [
      for (final key in keys)
        GroupEntry(
          key: key,
          title: _dayLabel(key),
          icon: key == null ? '📥' : '📅',
          tasks: groupsMap[key]!,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kalenderwoche $_week'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _changeWeek(-1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeWeek(1),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_WochenplanData>(
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
                  message: 'Keine Tasks in dieser Woche geplant.');
            }
            return GroupedDragDropList<DateTime?>(
              groups: _toGroups(data),
              onMove: _moveTask,
              onTap: _openDetail,
              onToggleDone: _toggleDone,
              onAddTask: _addTaskForDay,
              projectIconFor: (t) =>
                  t.projectId != null
                      ? data.projects[t.projectId]?.icon
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
        onPressed: () => _addTaskForDay(null),
        tooltip: 'Neue Task',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _WochenplanData {
  _WochenplanData({required this.tasks, required this.projects});
  final List<Task> tasks;
  final Map<String, Project> projects;
}
