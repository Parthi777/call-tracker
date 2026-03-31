import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:salestrack_web/features/auth/presentation/admin_login_screen.dart';
import 'package:salestrack_web/features/dashboard/presentation/dashboard_screen.dart';
import 'package:salestrack_web/features/call_feed/presentation/call_feed_screen.dart';
import 'package:salestrack_web/features/agent_performance/presentation/agent_performance_screen.dart';
import 'package:salestrack_web/features/reports/presentation/reports_screen.dart';
import 'package:salestrack_web/features/executives/presentation/executives_screen.dart';
import 'package:salestrack_web/features/settings/presentation/settings_screen.dart';
import 'package:salestrack_web/shared/admin_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AdminLoginScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AdminShell(
        currentPath: state.uri.path,
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/call-feed',
          builder: (context, state) => const CallFeedScreen(),
        ),
        GoRoute(
          path: '/agent-performance',
          builder: (context, state) => const AgentPerformanceScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/executives',
          builder: (context, state) => const ExecutivesScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
