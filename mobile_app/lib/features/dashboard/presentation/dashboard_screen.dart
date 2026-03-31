import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:salestrack_shared/salestrack_shared.dart';

import '../../../shared/connectivity_banner.dart';
import '../../call_recorder/domain/call_recorder_providers.dart';
import '../../drive_upload/presentation/upload_queue_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsAsync = ref.watch(callPermissionsProvider);
    final kpi = ref.watch(todayKpiProvider);
    final calls = ref.watch(todayCallsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SalesTrack'),
        actions: [
          UploadBadge(
            child: IconButton(
              icon: const Icon(Icons.cloud_upload),
              tooltip: 'Upload Queue',
              onPressed: () => context.push('/uploads'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Call History',
            onPressed: () => context.push('/call-history'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(todayCallsProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Offline banner
            const ConnectivityBanner(),

            // Permission banner
            permissionsAsync.when(
              data: (perms) {
                final allGranted = perms.values.every((v) => v);
                if (allGranted) return const SizedBox.shrink();
                return _PermissionBanner(
                  permissions: perms,
                  onRequest: () async {
                    await ref.read(callPermissionsProvider.notifier).request();
                  },
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),

            // Monitoring status card
            _MonitoringStatusCard(
              isActive: permissionsAsync.valueOrNull?.values.every((v) => v) ?? false,
            ),
            const SizedBox(height: 20),

            // KPI header
            Text(
              "Today's Summary",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // KPI grid
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _KpiCard(
                  title: 'Total Calls',
                  value: '${kpi.totalCalls}',
                  icon: Icons.phone,
                  color: Theme.of(context).colorScheme.primary,
                ),
                _KpiCard(
                  title: 'Incoming',
                  value: '${kpi.incoming}',
                  icon: Icons.call_received,
                  color: Colors.green,
                ),
                _KpiCard(
                  title: 'Outgoing',
                  value: '${kpi.outgoing}',
                  icon: Icons.call_made,
                  color: Colors.blue,
                ),
                _KpiCard(
                  title: 'Missed',
                  value: '${kpi.missed}',
                  icon: Icons.call_missed,
                  color: Colors.red,
                ),
                _KpiCard(
                  title: 'Avg Duration',
                  value: _formatDuration(kpi.avgDuration.round()),
                  icon: Icons.timer,
                  color: Colors.orange,
                ),
                _KpiCard(
                  title: 'Talk Time',
                  value: _formatDuration(kpi.talkTime),
                  icon: Icons.access_time,
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent calls
            if (calls.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Calls',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/call-history'),
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...calls.take(5).map((call) => _RecentCallTile(call: call)),
            ],

            if (calls.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.phone_in_talk,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No calls recorded today',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Calls will appear here automatically when detected',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return '0s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }
}

class _PermissionBanner extends StatelessWidget {
  final Map<String, bool> permissions;
  final VoidCallback onRequest;

  const _PermissionBanner({
    required this.permissions,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final denied = permissions.entries
        .where((e) => !e.value)
        .map((e) => _friendlyName(e.key))
        .toList();

    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Permissions Required',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Missing: ${denied.join(", ")}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onRequest,
                child: const Text('Grant Permissions'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _friendlyName(String key) {
    return switch (key) {
      'record_audio' => 'Microphone',
      'read_phone_state' => 'Phone State',
      'read_call_log' => 'Call Log',
      _ => key,
    };
  }
}

class _MonitoringStatusCard extends StatelessWidget {
  final bool isActive;

  const _MonitoringStatusCard({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: isActive
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? Colors.green : colorScheme.outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActive ? 'Call Monitoring Active' : 'Call Monitoring Inactive',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    isActive
                        ? 'Incoming and outgoing calls will be recorded automatically'
                        : 'Grant permissions to start monitoring calls',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isActive
                              ? colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.7)
                              : colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              isActive ? Icons.shield : Icons.shield_outlined,
              color: isActive ? Colors.green : colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentCallTile extends StatelessWidget {
  final CallRecord call;

  const _RecentCallTile({required this.call});

  @override
  Widget build(BuildContext context) {
    final isIncoming = call.direction == CallDirection.incoming;
    final isMissed = call.duration < 5 && isIncoming;
    final m = call.duration ~/ 60;
    final s = call.duration % 60;
    final durationStr = m > 0 ? '${m}m ${s}s' : '${s}s';
    final timeStr =
        '${call.timestamp.hour.toString().padLeft(2, '0')}:${call.timestamp.minute.toString().padLeft(2, '0')}';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isMissed
              ? Colors.red.withValues(alpha: 0.1)
              : isIncoming
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.blue.withValues(alpha: 0.1),
          child: Icon(
            isMissed
                ? Icons.call_missed
                : isIncoming
                    ? Icons.call_received
                    : Icons.call_made,
            color: isMissed
                ? Colors.red
                : isIncoming
                    ? Colors.green
                    : Colors.blue,
            size: 20,
          ),
        ),
        title: Text(
          call.phoneNumber,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text(
          '$timeStr  ·  ${isMissed ? "Missed" : durationStr}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Icon(
          call.status == CallStatus.uploaded
              ? Icons.cloud_done
              : call.status == CallStatus.uploading
                  ? Icons.cloud_upload
                  : Icons.cloud_upload_outlined,
          size: 20,
          color: call.status == CallStatus.uploaded
              ? Colors.green
              : Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}
