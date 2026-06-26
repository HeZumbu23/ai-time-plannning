import 'package:flutter/material.dart';

import '../models/task.dart';
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
  late int _week;
  late Future<List<Task>> _future;

  @override
  void initState() {
    super.initState();
    _week = _isoWeekNumber(DateTime.now());
    _future = _service.tasksForWeek(_week);
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
      _future = _service.tasksForWeek(_week);
    });
  }

  Future<void> _refresh() async {
    setState(() => _future = _service.tasksForWeek(_week));
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

  /// Tasks nach Wochentag gruppiert (planned_day), mit Tages-Überschrift.
  Widget _buildGrouped(List<Task> tasks) {
    final groups = <DateTime?, List<Task>>{};
    for (final t in tasks) {
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

    final children = <Widget>[];
    for (final key in keys) {
      children.add(SectionHeader(
          _dayLabel(key), key == null ? Icons.inbox_outlined : Icons.event));
      final list = groups[key]!;
      for (var i = 0; i < list.length; i++) {
        final t = list[i];
        children.add(TaskTile(
          task: t,
          shaded: i.isOdd,
          onTap: () => _openDetail(t),
          onToggleDone: (v) => _toggleDone(t, v),
        ));
      }
    }
    children.add(const SizedBox(height: 24));
    return ListView(children: children);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeWeek(-1),
              ),
              Text('Kalenderwoche $_week',
                  style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _changeWeek(1),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
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
                  return const EmptyView(
                      message: 'Keine Tasks in dieser Woche geplant.');
                }
                return _buildGrouped(tasks);
              },
            ),
          ),
        ),
      ],
    );
  }
}
