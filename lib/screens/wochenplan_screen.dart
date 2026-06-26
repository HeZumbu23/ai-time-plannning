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

  Future<void> _toggleNext(Task task) async {
    await _service.setNextAction(task.id, !task.nextAction);
    await _refresh();
  }

  Future<void> _openDetail(Task task) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
    );
    if (changed == true) await _refresh();
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
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, i) => TaskTile(
                    task: tasks[i],
                    shaded: i.isOdd,
                    onTap: () => _openDetail(tasks[i]),
                    onToggleDone: (v) => _toggleDone(tasks[i], v),
                    onToggleNextAction: () => _toggleNext(tasks[i]),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
