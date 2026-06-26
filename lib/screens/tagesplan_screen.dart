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

  // Bevorzugte Reihenfolge der Kontexte; Unbekanntes danach, "ohne" ganz hinten.
  static const _contextOrder = ['büro', 'stadt', 'samstag', 'sonntag', 'flexibel'];

  /// Tasks nach Kontext gruppiert.
  Widget _buildGrouped(List<Task> tasks) {
    final groups = <String?, List<Task>>{};
    for (final t in tasks) {
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

    final children = <Widget>[];
    for (final key in keys) {
      children.add(SectionHeader(
          key == null ? 'Ohne Kontext' : key,
          key == null ? Icons.inbox_outlined : Icons.place_outlined));
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
          return _buildGrouped(tasks);
        },
      ),
    );
  }
}
