import 'package:flutter/material.dart';

import '../models/task.dart';
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
  late Future<List<Task>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.tasksForDay(DateTime.now());
  }

  Future<void> _refresh() async {
    setState(() => _future = _service.tasksForDay(DateTime.now()));
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
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
                message: 'Heute nichts geplant. Genieß den Tag! 🎉');
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
    );
  }
}
