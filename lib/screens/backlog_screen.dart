import 'package:flutter/material.dart';

import '../models/project.dart';
import '../models/task.dart';
import '../services/project_service.dart';
import '../services/task_service.dart';
import '../widgets/status_views.dart';
import '../widgets/task_tile.dart';
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

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_BacklogData> _load() async {
    final results = await Future.wait([_service.backlog(), _projects.all()]);
    final tasks = results[0] as List<Task>;
    final projects = {for (final p in results[1] as List<Project>) p.id: p};
    return _BacklogData(tasks: tasks, projects: projects);
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

  Widget _buildGrouped(_BacklogData data) {
    // Gruppieren nach project_id (null -> "Ohne Projekt").
    final groups = <String?, List<Task>>{};
    for (final t in data.tasks) {
      (groups[t.projectId] ??= []).add(t);
    }

    String label(String? id) {
      if (id == null) return 'Ohne Projekt';
      final p = data.projects[id];
      if (p == null) return 'Projekt $id';
      return '${p.icon ?? '📁'}  ${p.name}';
    }

    final keys = groups.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1; // "Ohne Projekt" ans Ende
        if (b == null) return -1;
        return label(a).toLowerCase().compareTo(label(b).toLowerCase());
      });

    final children = <Widget>[];
    for (final key in keys) {
      children.add(SectionHeader(
          label(key), key == null ? Icons.inbox_outlined : Icons.folder_outlined));
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
          if (data.tasks.isEmpty) {
            return const EmptyView(message: 'Backlog ist leer. 📭');
          }
          return _buildGrouped(data);
        },
      ),
    );
  }
}

class _BacklogData {
  _BacklogData({required this.tasks, required this.projects});
  final List<Task> tasks;
  final Map<String, Project> projects;
}
