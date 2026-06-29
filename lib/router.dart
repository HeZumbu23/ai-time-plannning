import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/backlog_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/home_shell.dart';
import 'screens/projekte_screen.dart';
import 'screens/tagesplan_screen.dart';
import 'screens/wochenplan_screen.dart';

const _supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

/// App-Router: Jedes Tab hat seine eigene URL → Browser-History funktioniert.
final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    // Wenn kein Key konfiguriert, zur No-Key-Seite weiterleiten.
    if (_supabaseKey.isEmpty && state.matchedLocation != '/no-key') {
      return '/no-key';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/no-key',
      builder: (_, __) => const _NoKeyScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          HomeShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const TagesplanScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/wochenplan',
            builder: (_, __) => const WochenplanScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/backlog',
            builder: (_, __) => const BacklogScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/projekte',
            builder: (_, __) => const ProjekteScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/chat',
            builder: (_, __) => const ChatScreen(),
          ),
        ]),
      ],
    ),
  ],
);

class _NoKeyScreen extends StatelessWidget {
  const _NoKeyScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Kein Supabase Key konfiguriert.\n\n'
            'SUPABASE_PUBLISHABLE_KEY Umgebungsvariable in Portainer setzen.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
