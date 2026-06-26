import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/task_service.dart';
import '../widgets/status_views.dart';
import '../widgets/task_tile.dart';

/// Tagesplan: Tasks für heute (planned_day = today) + offene Next Actions.
class TagesplanScreen extends StatefulWidget {
  const TagesplanScreen({super.key});

  @override
  State<TagesplanScreen> createState() => _TagesplanScreenState();
}

class _TagesplanScreenState extends State<TagesplanScreen> {
  final _service = TaskService();
  late Future<_TagesplanData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_TagesplanData> _load() async {
    final today = DateTime.now();
    final results = await Future.wait([
      _service.tasksForDay(today),
      _service.nextActions(),
    ]);
    final dayTasks = results[0];
    final dayIds = dayTasks.map((t) => t.id).toSet();
    // Next Actions, die nicht schon im Tagesplan stehen.
    final nextActions =
        results[1].where((t) => !dayIds.contains(t.id)).toList();
    return _TagesplanData(dayTasks: dayTasks, nextActions: nextActions);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
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
          if (data.dayTasks.isEmpty && data.nextActions.isEmpty) {
            return const EmptyView(
                message: 'Heute nichts geplant. Genieß den Tag! 🎉');
          }
          return ListView(
            children: [
              if (data.dayTasks.isNotEmpty) ...[
                const SectionHeader('Heute', Icons.today),
                ...data.dayTasks.indexed.map((e) => TaskTile(
                      task: e.$2,
                      shaded: e.$1.isOdd,
                      onToggleDone: (v) => _toggleDone(e.$2, v),
                      onToggleNextAction: () => _toggleNext(e.$2),
                    )),
              ],
              if (data.nextActions.isNotEmpty) ...[
                const SectionHeader('Next Actions', Icons.bolt),
                ...data.nextActions.indexed.map((e) => TaskTile(
                      task: e.$2,
                      shaded: e.$1.isOdd,
                      onToggleDone: (v) => _toggleDone(e.$2, v),
                      onToggleNextAction: () => _toggleNext(e.$2),
                    )),
              ],
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _TagesplanData {
  _TagesplanData({required this.dayTasks, required this.nextActions});
  final List<Task> dayTasks;
  final List<Task> nextActions;
}
