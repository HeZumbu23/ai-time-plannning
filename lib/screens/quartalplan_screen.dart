import 'package:flutter/material.dart';

import '../models/milestone.dart';
import '../models/project.dart';
import '../services/milestone_service.dart';
import '../services/project_service.dart';
import '../widgets/project_roadmap_list.dart';
import '../widgets/status_views.dart';

class QuartalplanScreen extends StatefulWidget {
  const QuartalplanScreen({super.key});

  @override
  State<QuartalplanScreen> createState() => _QuartalplanScreenState();
}

class _QuartalplanScreenState extends State<QuartalplanScreen> {
  final _projectService = ProjectService();
  final _milestoneService = MilestoneService();

  List<Project> _projects = [];
  List<Milestone> _milestones = [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _projectService.all(),
        _milestoneService.all(),
      ]);
      if (mounted) {
        setState(() {
          _projects = results[0] as List<Project>;
          _milestones = results[1] as List<Milestone>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  // ── Group key helpers ────────────────────────────────────────────────────────

  static String? _encodeKey(int? year, int? quarter) =>
      year == null ? null : quarter == null ? '$year' : '$year-$quarter';

  static ({int? year, int? quarter}) _decodeKey(String? key) {
    if (key == null) return (year: null, quarter: null);
    final parts = key.split('-');
    return (
      year: int.parse(parts[0]),
      quarter: parts.length > 1 ? int.parse(parts[1]) : null,
    );
  }

  // ── Group building ───────────────────────────────────────────────────────────

  List<ProjectRoadmapEntry> _buildGroups() {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentQuarter = (now.month - 1) ~/ 3 + 1;

    final defaultKeys = <String?>[];
    for (var q = currentQuarter; q <= 4; q++) {
      defaultKeys.add('$currentYear-$q');
    }
    for (var q = 1; q <= 4; q++) {
      defaultKeys.add('${currentYear + 1}-$q');
    }
    defaultKeys.add('${currentYear + 2}');

    final projectKeys = _projects
        .map((p) => _encodeKey(p.plannedYear, p.plannedQuarter))
        .toSet();
    final milestoneKeys = _milestones
        .map((m) => _encodeKey(m.plannedYear, m.plannedQuarter))
        .toSet();
    final allUsedKeys = {...projectKeys, ...milestoneKeys};
    final extraKeys =
        allUsedKeys.difference({...defaultKeys, null}).toList()
          ..sort((a, b) {
            if (a == null) return 1;
            if (b == null) return -1;
            return a.compareTo(b);
          });

    final allKeys = [...defaultKeys, ...extraKeys, null];

    // Distribute projects
    const priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
    final groupedProjects = <String?, List<Project>>{
      for (final k in allKeys) k: [],
    };
    for (final p in _projects) {
      (groupedProjects[_encodeKey(p.plannedYear, p.plannedQuarter)] ??= [])
          .add(p);
    }
    for (final list in groupedProjects.values) {
      list.sort((a, b) {
        final pa = priorityOrder[a.priority] ?? 3;
        final pb = priorityOrder[b.priority] ?? 3;
        if (pa != pb) return pa.compareTo(pb);
        return a.name.compareTo(b.name);
      });
    }

    // Distribute milestones
    final groupedMilestones = <String?, List<Milestone>>{
      for (final k in allKeys) k: [],
    };
    for (final m in _milestones) {
      (groupedMilestones[_encodeKey(m.plannedYear, m.plannedQuarter)] ??= [])
          .add(m);
    }

    return allKeys
        .map((k) => ProjectRoadmapEntry(
              key: k,
              title: _groupTitle(k),
              icon: _groupIcon(k),
              projects: groupedProjects[k]!,
              milestones: groupedMilestones[k]!,
            ))
        .toList();
  }

  static const _quarterMonths = {
    1: 'Jan/Feb/Mär',
    2: 'Apr/Mai/Jun',
    3: 'Jul/Aug/Sep',
    4: 'Okt/Nov/Dez',
  };

  static String _groupTitle(String? key) {
    if (key == null) return 'Backlog';
    final parts = key.split('-');
    if (parts.length == 1) return 'Jahr ${parts[0]}';
    final q = int.parse(parts[1]);
    return 'Q$q ${parts[0]}  ·  ${_quarterMonths[q] ?? ''}';
  }

  static String _groupIcon(String? key) {
    if (key == null) return '📋';
    final parts = key.split('-');
    if (parts.length == 1) return '📅';
    return switch (int.parse(parts[1])) {
      1 => '❄️',
      2 => '🌱',
      3 => '☀️',
      4 => '🍂',
      _ => '📅',
    };
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  Future<void> _moveProject(Project project, String? newKey) async {
    final (:year, :quarter) = _decodeKey(newKey);
    await _projectService.updateProject(project.id, {
      'planned_year': year,
      'planned_quarter': quarter,
    });
    await _load();
  }

  Future<void> _moveMilestone(Milestone milestone, String? newKey) async {
    final (:year, :quarter) = _decodeKey(newKey);
    await _milestoneService.update(milestone.id, {
      'planned_year': year,
      'planned_quarter': quarter,
    });
    await _load();
  }

  Future<void> _toggleMilestone(Milestone milestone) async {
    await _milestoneService.update(
      milestone.id,
      {'status': milestone.isDone ? 'open' : 'done'},
    );
    await _load();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorView(error: _error!, onRetry: _load);

    return RefreshIndicator(
      onRefresh: _load,
      child: ProjectRoadmapList(
        groups: _buildGroups(),
        onMove: _moveProject,
        onMoveMilestone: _moveMilestone,
        onToggleMilestone: _toggleMilestone,
        onTap: (_) {},
        onAddProject: (_) {},
      ),
    );
  }
}
