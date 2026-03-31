import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salestrack_shared/salestrack_shared.dart';

import '../domain/call_recorder_providers.dart';

class CallHistoryScreen extends ConsumerWidget {
  const CallHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(callLogRepositoryProvider);
    final calls = repo.getAllCalls();

    return Scaffold(
      appBar: AppBar(title: const Text('Call History')),
      body: calls.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No calls recorded yet',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: calls.length,
              itemBuilder: (context, index) {
                final call = calls[index];
                return _CallHistoryTile(call: call);
              },
            ),
    );
  }
}

class _CallHistoryTile extends StatelessWidget {
  final CallRecord call;

  const _CallHistoryTile({required this.call});

  @override
  Widget build(BuildContext context) {
    final isIncoming = call.direction == CallDirection.incoming;
    final isMissed = call.duration < 5 && isIncoming;
    final m = call.duration ~/ 60;
    final s = call.duration % 60;
    final durationStr = m > 0 ? '${m}m ${s}s' : '${s}s';

    final date = call.timestamp;
    final dateStr =
        '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';

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
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$dateStr  ·  ${isMissed ? "Missed" : durationStr}',
        ),
        trailing: _statusChip(context, call.status),
      ),
    );
  }

  Widget _statusChip(BuildContext context, CallStatus status) {
    final (label, color) = switch (status) {
      CallStatus.recorded => ('Recorded', Colors.orange),
      CallStatus.uploading => ('Uploading', Colors.blue),
      CallStatus.uploaded => ('Uploaded', Colors.green),
      CallStatus.failed => ('Failed', Colors.red),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
