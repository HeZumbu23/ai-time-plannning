import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'config/supabase_client.dart';
import 'screens/api_key_screen.dart';
import 'screens/backlog_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/home_shell.dart';
import 'screens/projekte_screen.dart';
import 'screens/quartalplan_screen.dart';
import 'screens/wochenplan_screen.dart';

/// App-Router: Jedes Tab hat seine eigene URL → Browser-History funktioniert.
final appRouter = GoRouter(
  initialLocation: '/wochenplan',
  redirect: (context, state) {
    if (!isSupabaseInitialized && state.matchedLocation != '/setup') {
      return '/setup';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/setup',
      builder: (_, __) => const ApiKeyScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          HomeShell(navigationShell: navigationShell),
      branches: [
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
            path: '/quartale',
            builder: (_, __) => const QuartalplanScreen(),
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
