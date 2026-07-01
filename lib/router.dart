import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'config/supabase_client.dart';
import 'screens/api_key_screen.dart';
import 'screens/backlog_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/projekte_screen.dart';
import 'screens/quartalplan_screen.dart';
import 'screens/wochenplan_screen.dart';
import 'services/auth_notifier.dart';

/// App-Router: Jedes Tab hat seine eigene URL → Browser-History funktioniert.
final appRouter = GoRouter(
  initialLocation: '/wochenplan',
  refreshListenable: authNotifier,
  redirect: (context, state) {
    final loc = state.matchedLocation;
    if (!isSupabaseInitialized && loc != '/setup') return '/setup';
    final hasSession =
        isSupabaseInitialized && supabaseClient.auth.currentSession != null;
    if (!hasSession && loc != '/login' && loc != '/setup') return '/login';
    if (hasSession && loc == '/login') return '/wochenplan';
    return null;
  },
  routes: [
    GoRoute(
      path: '/setup',
      builder: (_, __) => const ApiKeyScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginScreen(),
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
