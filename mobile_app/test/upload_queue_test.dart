import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'dart:io';

import 'package:salestrack_mobile/features/drive_upload/data/hive_upload_job.dart';
import 'package:salestrack_mobile/features/drive_upload/data/upload_queue_repository.dart';

void main() {
  late UploadQueueRepository repo;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(hiveTypeUploadStatus)) {
      Hive.registerAdapter(HiveUploadStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(hiveTypeUploadJob)) {
      Hive.registerAdapter(HiveUploadJobAdapter());
    }

    repo = await UploadQueueRepository.open();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  HiveUploadJob _makeJob({
    String id = 'job-1',
    HiveUploadStatus status = HiveUploadStatus.pending,
    int retryCount = 0,
  }) {
    return HiveUploadJob(
      id: id,
      recordingPath: '/tmp/recording.mp4',
      callRecordId: 'call-1',
      executiveId: 'exec-1',
      executiveName: 'John Doe',
      phoneNumber: '+1234567890',
      direction: 'incoming',
      durationSeconds: 120,
      callTimestamp: DateTime(2026, 3, 30, 14, 30),
      status: status,
      retryCount: retryCount,
    );
  }

  group('UploadQueueRepository', () {
    test('enqueue and retrieve a job', () async {
      final job = _makeJob();
      await repo.enqueue(job);

      expect(repo.totalCount, 1);
      final retrieved = repo.getJob('job-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.phoneNumber, '+1234567890');
      expect(retrieved.status, HiveUploadStatus.pending);
    });

    test('getPendingJobs returns pending and retryable failed jobs', () async {
      await repo.enqueue(_makeJob(id: 'pending-1'));
      await repo.enqueue(_makeJob(
        id: 'failed-retryable',
        status: HiveUploadStatus.failed,
        retryCount: 2,
      ));
      await repo.enqueue(_makeJob(
        id: 'failed-exhausted',
        status: HiveUploadStatus.failed,
        retryCount: 5,
      ));
      await repo.enqueue(_makeJob(
        id: 'completed-1',
        status: HiveUploadStatus.completed,
      ));

      final pending = repo.getPendingJobs(maxRetries: 5);
      final pendingIds = pending.map((j) => j.id).toList();

      expect(pendingIds, contains('pending-1'));
      expect(pendingIds, contains('failed-retryable'));
      expect(pendingIds, isNot(contains('failed-exhausted')));
      expect(pendingIds, isNot(contains('completed-1')));
    });

    test('markUploading transitions status', () async {
      await repo.enqueue(_makeJob());
      await repo.markUploading('job-1');

      final job = repo.getJob('job-1');
      expect(job!.status, HiveUploadStatus.uploading);
    });

    test('markCompleted sets driveFileId', () async {
      await repo.enqueue(_makeJob());
      await repo.markCompleted('job-1', 'drive-file-abc');

      final job = repo.getJob('job-1');
      expect(job!.status, HiveUploadStatus.completed);
      expect(job.driveFileId, 'drive-file-abc');
    });

    test('markFailed increments retryCount', () async {
      await repo.enqueue(_makeJob());
      await repo.markFailed('job-1', 'Network error');

      final job = repo.getJob('job-1');
      expect(job!.status, HiveUploadStatus.failed);
      expect(job.retryCount, 1);
      expect(job.errorMessage, 'Network error');
    });

    test('resetJob clears retry state', () async {
      await repo.enqueue(_makeJob(
        status: HiveUploadStatus.failed,
        retryCount: 3,
      ));
      await repo.resetJob('job-1');

      final job = repo.getJob('job-1');
      expect(job!.status, HiveUploadStatus.pending);
      expect(job.retryCount, 0);
    });

    test('clearCompleted removes only completed jobs', () async {
      await repo.enqueue(_makeJob(id: 'pending'));
      await repo.enqueue(_makeJob(
        id: 'done',
        status: HiveUploadStatus.completed,
      ));

      await repo.clearCompleted();

      expect(repo.totalCount, 1);
      expect(repo.getJob('pending'), isNotNull);
      expect(repo.getJob('done'), isNull);
    });

    test('pendingCount tracks active queue size', () async {
      await repo.enqueue(_makeJob(id: 'a'));
      await repo.enqueue(_makeJob(
        id: 'b',
        status: HiveUploadStatus.uploading,
      ));
      await repo.enqueue(_makeJob(
        id: 'c',
        status: HiveUploadStatus.completed,
      ));

      expect(repo.pendingCount, 2); // pending + uploading
    });
  });
}
