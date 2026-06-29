import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Haupt-Navigation mit URL-basierter History für den Browser.
/// Jedes Tab hat eine eigene URL: / | /wochenplan | /backlog | /projekte | /chat
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _titles = [
    'Tagesplan',
    'Wochenplan',
    'Backlog',
    'Projekte',
    'Chat',
  ];

  static const _destinations = [
    NavigationDestination(
        icon: Icon(Icons.today_outlined),
        selectedIcon: Icon(Icons.today),
        label: 'Tagesplan'),
    NavigationDestination(
        icon: Icon(Icons.view_week_outlined),
        selectedIcon: Icon(Icons.view_week),
        label: 'Wochenplan'),
    NavigationDestination(
        icon: Icon(Icons.inbox_outlined),
        selectedIcon: Icon(Icons.inbox),
        label: 'Backlog'),
    NavigationDestination(
        icon: Icon(Icons.folder_outlined),
        selectedIcon: Icon(Icons.folder),
        label: 'Projekte'),
    NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline),
        selectedIcon: Icon(Icons.chat_bubble),
        label: 'Chat'),
  ];

  void _onSelect(int index) {
    navigationShell.goBranch(
      index,
      // Nochmaliges Tippen auf aktiven Tab → zurück zur Tab-Root
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;

    // WochenplanScreen bringt seinen eigenen AppBar (mit Wochennavigation) mit,
    // daher zeigen wir den Shell-AppBar nur für die anderen Tabs.
    final showShellAppBar = navigationShell.currentIndex != 1;

    final appBar = showShellAppBar
        ? AppBar(title: Text(_titles[navigationShell.currentIndex]))
        : null;

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
