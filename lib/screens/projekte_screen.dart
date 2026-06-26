import 'package:flutter/material.dart';

import '../models/project.dart';
import '../models/task.dart';
import '../services/project_service.dart';
import '../services/task_service.dart';
import '../widgets/status_views.dart';
import '../widgets/task_tile.dart';
import 'task_detail_screen.dart';

/// Projekte: Liste aller Projekte, antippen öffnet die zugehörigen Tasks.
class ProjekteScreen extends StatefulWidget {
  const ProjekteScreen({super.key});

  @override
  State<ProjekteScreen> createState() => _ProjekteScreenState();
}

class _ProjekteScreenState extends State<ProjekteScreen> {
  final _service = ProjectService();
  late Future<List<Project>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.all();
  }

  Future<void> _refresh() async {
    setState(() => _future = _service.all());
    await _future;
  }

  void _openProject(Project project) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProjectDetailScreen(project: project),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Project>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(error: snapshot.error!, onRetry: _refresh);
          }
          final projects = snapshot.data!;
          if (projects.isEmpty) {
            return const EmptyView(message: 'Noch keine Projekte angelegt.');
          }
          return ListView.builder(
            itemCount: projects.length,
            itemBuilder: (context, i) {
              final p = projects[i];
              return ListTile(
                leading: Text(p.icon ?? '📁',
                    style: const TextStyle(fontSize: 22)),
                title: Text(p.name),
                subtitle: p.goal != null ? Text(p.goal!) : null,
                trailing: _StatusChip(status: p.status),
                onTap: () => _openProject(p),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({this.status});
  final String? status;

  @override
  Widget build(BuildContext context) {
    if (status == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final color = switch (status) {
      'active' => theme.colorScheme.primaryContainer,
      'done' => theme.colorScheme.surfaceContainerHighest,
      _ => theme.colorScheme.tertiaryContainer,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(status!, style: theme.textTheme.labelSmall),
    );
  }
}

/// Detailansicht: alle Tasks eines Projekts.
class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, required this.project});
  final Project project;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final _service = TaskService();
  late Future<List<Task>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.tasksForProject(widget.project.id);
  }

  Future<void> _refresh() async {
    setState(() => _future = _service.tasksForProject(widget.project.id));
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
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.project.icon ?? '📁'}  ${widget.project.name}'),
      ),
      body: RefreshIndicator(
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
                  message: 'Keine Tasks in diesem Projekt.');
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
      ),
    );
  }
}
