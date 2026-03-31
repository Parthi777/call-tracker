import 'package:hive/hive.dart';

import 'hive_upload_job.dart';

/// Hive box name for the upload queue.
const String uploadQueueBoxName = 'upload_queue';

/// Repository for managing the local Hive upload queue.
///
/// All pending recordings are queued here. The upload worker
/// processes them in order, with retry on failure.
class UploadQueueRepository {
  final Box<HiveUploadJob> _box;

  UploadQueueRepository(this._box);

  /// Open the Hive box (call once at app start).
  static Future<UploadQueueRepository> open() async {
    final box = await Hive.openBox<HiveUploadJob>(uploadQueueBoxName);
    return UploadQueueRepository(box);
  }

  /// Enqueue a new upload job.
  Future<void> enqueue(HiveUploadJob job) async {
    await _box.put(job.id, job);
  }

  /// Get all pending jobs (status == pending or failed with retries left).
  List<HiveUploadJob> getPendingJobs({int maxRetries = 5}) {
    return _box.values.where((job) {
      if (job.status == HiveUploadStatus.pending) return true;
      if (job.status == HiveUploadStatus.failed &&
          job.retryCount < maxRetries) {
        return true;
      }
      return false;
    }).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Get all jobs currently being uploaded.
  List<HiveUploadJob> getUploadingJobs() {
    return _box.values
        .where((job) => job.status == HiveUploadStatus.uploading)
        .toList();
  }

  /// Get all completed jobs.
  List<HiveUploadJob> getCompletedJobs() {
    return _box.values
        .where((job) => job.status == HiveUploadStatus.completed)
        .toList();
  }

  /// Get all failed jobs that have exhausted retries.
  List<HiveUploadJob> getFailedJobs({int maxRetries = 5}) {
    return _box.values
        .where((job) =>
            job.status == HiveUploadStatus.failed &&
            job.retryCount >= maxRetries)
        .toList();
  }

  /// Get all jobs (for UI display).
  List<HiveUploadJob> getAllJobs() {
    return _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get a single job by ID.
  HiveUploadJob? getJob(String id) => _box.get(id);

  /// Mark a job as uploading.
  Future<void> markUploading(String jobId) async {
    final job = _box.get(jobId);
    if (job == null) return;
    job.status = HiveUploadStatus.uploading;
    await job.save();
  }

  /// Mark a job as completed with the Drive file ID.
  Future<void> markCompleted(String jobId, String driveFileId) async {
    final job = _box.get(jobId);
    if (job == null) return;
    job.status = HiveUploadStatus.completed;
    job.driveFileId = driveFileId;
    job.errorMessage = null;
    await job.save();
  }

  /// Mark a job as failed, incrementing the retry counter.
  Future<void> markFailed(String jobId, String errorMessage) async {
    final job = _box.get(jobId);
    if (job == null) return;
    job.status = HiveUploadStatus.failed;
    job.retryCount += 1;
    job.errorMessage = errorMessage;
    await job.save();
  }

  /// Reset a failed job back to pending (manual retry).
  Future<void> resetJob(String jobId) async {
    final job = _box.get(jobId);
    if (job == null) return;
    job.status = HiveUploadStatus.pending;
    job.retryCount = 0;
    job.errorMessage = null;
    await job.save();
  }

  /// Remove a completed or failed job from the queue.
  Future<void> removeJob(String jobId) async {
    await _box.delete(jobId);
  }

  /// Remove all completed jobs.
  Future<void> clearCompleted() async {
    final completedKeys = _box.keys.where((key) {
      final job = _box.get(key);
      return job != null && job.status == HiveUploadStatus.completed;
    }).toList();
    await _box.deleteAll(completedKeys);
  }

  /// Total count of items in the queue.
  int get totalCount => _box.length;

  /// Count of pending items.
  int get pendingCount =>
      _box.values
          .where((j) =>
              j.status == HiveUploadStatus.pending ||
              j.status == HiveUploadStatus.uploading)
          .length;
}
