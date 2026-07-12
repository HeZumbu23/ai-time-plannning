import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

import '../models/milestone.dart';
import '../models/task.dart';

class MilestoneMindmapWidget extends StatefulWidget {
  const MilestoneMindmapWidget({
    super.key,
    required this.milestones,
    required this.tasks,
    required this.onMilestoneToggle,
    required this.onTaskToggle,
    required this.onTaskTap,
    required this.onMilestoneEdit,
    required this.onTaskMilestoneChanged,
  });

  final List<Milestone> milestones;
  final List<Task> tasks;
  final void Function(Milestone) onMilestoneToggle;
  final void Function(Task, bool) onTaskToggle;
  final void Function(Task) onTaskTap;
  final void Function(Milestone) onMilestoneEdit;
  final void Function(Task, String?) onTaskMilestoneChanged;

  @override
  State<MilestoneMindmapWidget> createState() => _MilestoneMindmapWidgetState();
}

class _MilestoneMindmapWidgetState extends State<MilestoneMindmapWidget> {
  late WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (url) {
              _sendDataToWebView();
            },
          ),
        )
        ..loadFlutterAsset('assets/html/mindmap.html');
    } else {
      _webViewController = null;
    }
  }

  void _sendDataToWebView() {
    if (_webViewController != null) {
      final data = _buildMindMapData();
      final jsonData = jsonEncode(data);

      _webViewController!.runJavaScript('''
        window.postMessage({
          type: 'initData',
          payload: $jsonData
        }, '*');
      ''');
    }
  }

  Map<String, dynamic> _buildMindMapData() {
    final rootMilestones = widget.milestones
        .where((m) => m.parentMilestoneId == null)
        .toList();

    return {
      'root': true,
      'data': {
        'text': 'Projekt',
        'expandNode': true,
      },
      'children': [
        ...rootMilestones.map((m) => _buildMilestoneNode(m)),
        if (widget.tasks.where((t) => t.milestoneId == null).isNotEmpty)
          {
            'data': {'text': 'Offene Tasks'},
            'children': widget.tasks
                .where((t) => t.milestoneId == null)
                .map((t) => {
                  'data': {
                    'text': t.title,
                    'expandNode': false,
                  },
                })
                .toList(),
          },
      ],
    };
  }

  Map<String, dynamic> _buildMilestoneNode(Milestone milestone) {
    final childMilestones = widget.milestones
        .where((m) => m.parentMilestoneId == milestone.id)
        .toList();

    final tasksForMilestone = widget.tasks
        .where((t) => t.milestoneId == milestone.id)
        .toList();

    return {
      'data': {
        'text': milestone.title,
        'expandNode': true,
      },
      'children': [
        ...childMilestones.map((m) => _buildMilestoneNode(m)),
        ...tasksForMilestone.map((t) => {
          'data': {
            'text': t.title,
            'expandNode': false,
          },
        }),
      ],
    };
  }

  @override
  void didUpdateWidget(MilestoneMindmapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.milestones != widget.milestones ||
        oldWidget.tasks != widget.tasks) {
      _sendDataToWebView();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebFallback();
    }
    return WebViewWidget(controller: _webViewController!);
  }

  Widget _buildWebFallback() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Milestones',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ..._buildMilestoneWidgets(widget.milestones.where((m) => m.parentMilestoneId == null).toList()),
          if (widget.tasks.where((t) => t.milestoneId == null).isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Offene Tasks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._buildTaskWidgets(widget.tasks.where((t) => t.milestoneId == null).toList()),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildMilestoneWidgets(List<Milestone> milestones) {
    return milestones.map((m) {
      final childMilestones = widget.milestones
          .where((child) => child.parentMilestoneId == m.id)
          .toList();
      final tasks = widget.tasks.where((t) => t.milestoneId == m.id).toList();

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• ${m.title}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (childMilestones.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildMilestoneWidgets(childMilestones),
                ),
              ),
            if (tasks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildTaskWidgets(tasks),
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildTaskWidgets(List<Task> tasks) {
    return tasks.map((t) {
      return Text(
        '  - ${t.title}',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }).toList();
  }
}
