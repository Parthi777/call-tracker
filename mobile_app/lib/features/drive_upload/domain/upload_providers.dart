import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:salestrack_shared/salestrack_shared.dart';

import '../data/drive_service.dart';
import '../data/hive_upload_job.dart';
import '../data/upload_queue_repository.dart';
import 'upload_worker.dart';

/// Provides the authenticated HTTP client for Google APIs.
/// Must be overridden at app startup after Google Sign-In.
final googleAuthClientProvider = StateProvider<http.Client?>((ref) => null);

/// Provides the upload queue repository (Hive-backed).
/// Must be overridden at app startup after Hive init.
final uploadQueueRepositoryProvider =
    Provider<UploadQueueRepository>((ref) => throw UnimplementedError(
          'uploadQueueRepositoryProvider must be overridden',
        ));

/// Provides the Google Drive service.
final driveServiceProvider = Provider<DriveService?>((ref) {
  final client = ref.watch(googleAuthClientProvider);
  if (client == null) return null;
  return DriveService(client);
});

/// Provides the upload worker singleton.
final uploadWorkerProvider = Provider<UploadWorker?>((ref) {
  final driveService = ref.watch(driveServiceProvider);
  final queue = ref.watch(uploadQueueRepositoryProvider);

  if (driveService == null) return null;

  final worker = UploadWorker(
    queue: queue,
    driveService: driveService,
  );

  ref.onDispose(() => worker.stop());

  return worker;
});

/// Stream of pending upload count for badge/indicator.
final pendingUploadCountProvider = StreamProvider<int>((ref) {
  final worker = ref.watch(uploadWorkerProvider);
  if (worker == null) return Stream.value(0);
  return worker.pendingCountStream;
});

/// Stream of individual upload status changes.
final uploadStatusStreamProvider = StreamProvider<HiveUploadJob>((ref) {
  final worker = ref.watch(uploadWorkerProvider);
  if (worker == null) return const Stream.empty();
  return worker.statusStream;
});

/// Snapshot of all upload jobs for the queue UI.
final uploadJobsProvider = Provider<List<HiveUploadJob>>((ref) {
  // Re-read whenever status changes
  ref.watch(uploadStatusStreamProvider);
  final worker = ref.watch(uploadWorkerProvider);
  return worker?.allJobs ?? [];
});

const _uuid = Uuid();

/// Helper to create and enqueue a new upload job.
Future<void> enqueueUpload({
  required UploadWorker worker,
  required String recordingPath,
  required String callRecordId,
  required String executiveId,
  required String executiveName,
  required CallDirection direction,
  required String phoneNumber,
  required int durationSeconds,
  required DateTime callTimestamp,
}) async {
  final job = HiveUploadJob(
    id: _uuid.v4(),
    recordingPath: recordingPath,
    callRecordId: callRecordId,
    executiveId: executiveId,
    executiveName: executiveName,
    phoneNumber: phoneNumber,
    direction: direction == CallDirection.incoming ? 'incoming' : 'outgoing',
    durationSeconds: durationSeconds,
    callTimestamp: callTimestamp,
  );
  await worker.enqueue(job);
}
