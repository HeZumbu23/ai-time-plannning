import 'package:flutter/material.dart';

import '../config/app_config.dart';
import 'backlog_screen.dart';
import 'config_qr_screen.dart';
import 'projekte_screen.dart';
import 'tagesplan_screen.dart';
import 'wochenplan_screen.dart';

/// Haupt-Navigation: Tagesplan | Wochenplan | Backlog | Projekte
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _titles = ['Tagesplan', 'Wochenplan', 'Backlog', 'Projekte'];

  Future<void> _openConfig() async {
    final result =
        await Navigator.of(context).push<({String url, String anonKey})>(
      MaterialPageRoute(builder: (_) => const ConfigQrScreen()),
    );
    if (result == null || !mounted) return;

    await AppConfig.save(url: result.url, anonKey: result.anonKey);
    if (!mounted) return;
    // Supabase ist bereits initialisiert und kann nicht live neu verbunden
    // werden -> Neustart der App nötig, damit der neue Key greift.
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gespeichert'),
        content: const Text(
          'Die neuen Verbindungsdaten wurden gespeichert. '
          'Bitte die App einmal komplett schließen und neu öffnen, '
          'damit sie wirksam werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  final _screens = const [
    TagesplanScreen(),
    WochenplanScreen(),
    BacklogScreen(),
    ProjekteScreen(),
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
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;

    final appBar = AppBar(
      title: Text(_titles[_index]),
      actions: [
        IconButton(
          tooltip: 'Verbindung / Key ändern',
          icon: const Icon(Icons.settings),
          onPressed: _openConfig,
        ),
      ],
    );

    final body = IndexedStack(index: _index, children: _screens);

    if (wide) {
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
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
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _destinations,
      ),
    );
  }
}
