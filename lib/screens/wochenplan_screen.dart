import 'package:flutter/material.dart';

import '../models/project.dart';
import '../models/task.dart';
import '../services/project_service.dart';
import '../services/task_service.dart';
import '../widgets/status_views.dart';
import '../widgets/task_tile.dart';
import 'task_detail_screen.dart';

/// Wochenplan: Tasks der gewählten Kalenderwoche (planned_week).
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
    final tasks = results[0] as List<Task>;
    final projects = {for (final p in results[1] as List<Project>) p.id: p};
    return _WochenplanData(tasks: tasks, projects: projects);
  }

  /// ISO-8601 Kalenderwoche.
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
      _future = _load();
    });
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

  Future<void> _createNewTask() async {
    final newTask = Task(
      id: '',
      title: '',
      status: 'open',
      plannedWeek: _week,
    );
    await _openDetail(newTask);
  }

  static const _weekdays = [
    'Montag',
    'Dienstag',
    'Mittwoch',
    'Donnerstag',
    'Freitag',
    'Samstag',
    'Sonntag',
  ];

  static String _dayLabel(DateTime? d) {
    if (d == null) return 'Ohne festen Tag';
    final wd = _weekdays[d.weekday - 1];
    return '$wd · ${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.';
  }

  /// Tasks nach Wochentag gruppiert (planned_day) mit einklappbaren Gruppen.
  Widget _buildGrouped(_WochenplanData data) {
    final theme = Theme.of(context);
    final groups = <DateTime?, List<Task>>{};
    for (final t in data.tasks) {
      final key = t.plannedDay == null
          ? null
          : DateTime(t.plannedDay!.year, t.plannedDay!.month, t.plannedDay!.day);
      (groups[key] ??= []).add(t);
    }
    final keys = groups.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1; // "ohne Tag" ans Ende
        if (b == null) return -1;
        return a.compareTo(b);
      });

    final headerColor = theme.colorScheme.secondaryContainer;
    final onHeader = theme.colorScheme.onSecondaryContainer;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
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
              key: PageStorageKey<String>('wochenplan_${key?.toString() ?? 'none'}'),
              initiallyExpanded: true,
              backgroundColor: headerColor.withOpacity(0.25),
              collapsedBackgroundColor: headerColor,
              iconColor: onHeader,
              collapsedIconColor: onHeader,
              tilePadding: const EdgeInsets.symmetric(horizontal: 14),
              childrenPadding: EdgeInsets.zero,
              leading: Text(
                key == null ? '📥' : '📅',
                style: const TextStyle(fontSize: 20),
              ),
              title: Text(
                _dayLabel(key),
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

class _WochenplanData {
  _WochenplanData({required this.tasks, required this.projects});
  final List<Task> tasks;
  final Map<String, Project> projects;
}
