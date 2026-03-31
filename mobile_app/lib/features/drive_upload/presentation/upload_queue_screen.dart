import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/hive_upload_job.dart';
import '../domain/upload_providers.dart';

class UploadQueueScreen extends ConsumerWidget {
  const UploadQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(uploadJobsProvider);
    final worker = ref.watch(uploadWorkerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Queue'),
        actions: [
          if (jobs.any((j) => j.status == HiveUploadStatus.completed))
            TextButton(
              onPressed: () async {
                final queue = ref.read(uploadQueueRepositoryProvider);
                await queue.clearCompleted();
                // Force rebuild
                ref.invalidate(uploadJobsProvider);
              },
              child: const Text('Clear Completed'),
            ),
        ],
      ),
      body: jobs.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_done, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No uploads in queue',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return _UploadJobTile(
                  job: job,
                  onRetry: worker != null
                      ? () => worker.retryJob(job.id)
                      : null,
                );
              },
            ),
    );
  }
}

class _UploadJobTile extends StatelessWidget {
  final HiveUploadJob job;
  final VoidCallback? onRetry;

  const _UploadJobTile({required this.job, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeStr = DateFormat('MMM d, HH:mm').format(job.callTimestamp);
    final dirLabel = job.direction == 'incoming' ? 'IN' : 'OUT';

    return Card(
      child: ListTile(
        leading: _statusIcon(colorScheme),
        title: Text('$dirLabel  ${job.phoneNumber}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$timeStr · ${job.executiveName}'),
            if (job.status == HiveUploadStatus.failed &&
                job.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Error: ${job.errorMessage}',
                  style: TextStyle(
                    color: colorScheme.error,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (job.status == HiveUploadStatus.failed)
              Text(
                'Attempt ${job.retryCount}/5',
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: _trailingWidget(colorScheme),
        isThreeLine: job.status == HiveUploadStatus.failed,
      ),
    );
  }

  Widget _statusIcon(ColorScheme colors) {
    return switch (job.status) {
      HiveUploadStatus.pending => Icon(
          Icons.cloud_upload_outlined,
          color: colors.onSurfaceVariant,
        ),
      HiveUploadStatus.uploading => SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.primary,
          ),
        ),
      HiveUploadStatus.completed => Icon(
          Icons.cloud_done,
          color: colors.primary,
        ),
      HiveUploadStatus.failed => Icon(
          Icons.cloud_off,
          color: colors.error,
        ),
    };
  }

  Widget? _trailingWidget(ColorScheme colors) {
    if (job.status == HiveUploadStatus.failed && onRetry != null) {
      return IconButton(
        icon: Icon(Icons.refresh, color: colors.primary),
        onPressed: onRetry,
        tooltip: 'Retry upload',
      );
    }
    return null;
  }
}

/// Small badge widget for showing pending upload count on nav items.
class UploadBadge extends ConsumerWidget {
  final Widget child;

  const UploadBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(pendingUploadCountProvider);
    final count = countAsync.valueOrNull ?? 0;

    if (count == 0) return child;

    return Badge(
      label: Text('$count'),
      child: child,
    );
  }
}
