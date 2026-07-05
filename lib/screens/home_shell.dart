import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/app_version.dart';
import '../config/supabase_client.dart';

/// Haupt-Navigation mit URL-basierter History für den Browser.
/// Jedes Tab hat eine eigene URL: / | /wochenplan | /backlog | /projekte | /chat
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _titles = [
    'Wochenplan',
    'Backlog',
    'Quartalsplanung',
    'Projekte',
    'Chat',
    'Entscheidungen',
  ];

  static const _destinations = [
    NavigationDestination(
        icon: Icon(Icons.view_week_outlined),
        selectedIcon: Icon(Icons.view_week),
        label: 'Woche'),
    NavigationDestination(
        icon: Icon(Icons.inbox_outlined),
        selectedIcon: Icon(Icons.inbox),
        label: 'Backlog'),
    NavigationDestination(
        icon: Icon(Icons.calendar_view_month_outlined),
        selectedIcon: Icon(Icons.calendar_view_month),
        label: 'Quartale'),
    NavigationDestination(
        icon: Icon(Icons.folder_outlined),
        selectedIcon: Icon(Icons.folder),
        label: 'Projekte'),
    NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline),
        selectedIcon: Icon(Icons.chat_bubble),
        label: 'Chat'),
    NavigationDestination(
        icon: Icon(Icons.lightbulb_outlined),
        selectedIcon: Icon(Icons.lightbulb),
        label: 'Entscheidungen'),
  ];

  void _onSelect(int index) {
    navigationShell.goBranch(
      index,
      // Nochmaliges Tippen auf aktiven Tab → zurück zur Tab-Root
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  AppBar? _buildAppBar(BuildContext context) {
    // WochenplanScreen hat seinen eigenen AppBar (mit Wochennavigation).
    if (navigationShell.currentIndex == 0) return null;

    return AppBar(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_titles[navigationShell.currentIndex]),
          Text(
            'v$appVersion',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
      actions: [
        if (isSupabaseInitialized)
          IconButton(
            icon: const Icon(Icons.vpn_key_outlined),
            tooltip: 'API-Key / QR',
            onPressed: () => context.push('/setup'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final appBar = _buildAppBar(context);

    if (wide) {
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onSelect,
              labelType: NavigationRailLabelType.all,
              destinations: _destinations
                  .map((d) => NavigationRailDestination(
                        icon: d.icon,
                        selectedIcon: d.selectedIcon,
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onSelect,
        destinations: _destinations,
      ),
    );
  }
}
