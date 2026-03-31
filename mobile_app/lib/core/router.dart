import 'package:go_router/go_router.dart';
import 'package:salestrack_mobile/features/auth/presentation/login_screen.dart';
import 'package:salestrack_mobile/features/call_recorder/presentation/call_history_screen.dart';
import 'package:salestrack_mobile/features/dashboard/presentation/dashboard_screen.dart';
import 'package:salestrack_mobile/features/drive_upload/presentation/upload_queue_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/uploads',
      builder: (context, state) => const UploadQueueScreen(),
    ),
    GoRoute(
      path: '/call-history',
      builder: (context, state) => const CallHistoryScreen(),
    ),
  ],
);
