import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/task_service.dart';
import '../widgets/status_views.dart';
import '../widgets/task_tile.dart';

/// Backlog: offene Tasks ohne konkrete Tagesplanung.
class BacklogScreen extends StatefulWidget {
  const BacklogScreen({super.key});

  @override
  State<BacklogScreen> createState() => _BacklogScreenState();
}

class _BacklogScreenState extends State<BacklogScreen> {
  final _service = TaskService();
  late Future<List<Task>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.backlog();
  }

  Future<void> _refresh() async {
    setState(() => _future = _service.backlog());
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
            return const EmptyView(message: 'Backlog ist leer. 📭');
          }
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, i) => TaskTile(
              task: tasks[i],
              onToggleDone: (v) => _toggleDone(tasks[i], v),
              onToggleNextAction: () => _toggleNext(tasks[i]),
            ),
          );
        },
      ),
    );
  }
}
