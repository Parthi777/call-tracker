import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:salestrack_shared/salestrack_shared.dart';

import '../data/drive_service.dart';
import '../data/hive_upload_job.dart';
import '../data/upload_queue_repository.dart';

/// Callback when a job's status changes.
typedef UploadStatusCallback = void Function(HiveUploadJob job);

/// Background upload worker that:
/// - Processes the Hive queue in FIFO order
/// - Pauses when offline, resumes when connectivity restores
/// - Retries failed uploads with exponential backoff
/// - Notifies listeners on status changes
class UploadWorker {
  final UploadQueueRepository _queue;
  final DriveService _driveService;
  final Connectivity _connectivity;

  /// Max retry attempts per job before marking permanently failed.
  final int maxRetries;

  /// Base delay for exponential backoff (doubles each retry).
  final Duration baseRetryDelay;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _processTimer;
  bool _isProcessing = false;
  bool _isOnline = true;

  /// Stream controller for upload status changes.
  final _statusController = StreamController<HiveUploadJob>.broadcast();

  /// Listen to upload status changes.
  Stream<HiveUploadJob> get statusStream => _statusController.stream;

  /// Stream controller for queue count changes.
  final _countController = StreamController<int>.broadcast();

  /// Listen to pending queue count changes.
  Stream<int> get pendingCountStream => _countController.stream;

  UploadWorker({
    required UploadQueueRepository queue,
    required DriveService driveService,
    Connectivity? connectivity,
    this.maxRetries = 5,
    this.baseRetryDelay = const Duration(seconds: 5),
  })  : _queue = queue,
        _driveService = driveService,
        _connectivity = connectivity ?? Connectivity();

  /// Start the upload worker. Call once at app initialization.
  Future<void> start() async {
    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _isOnline = !results.contains(ConnectivityResult.none);

    // Listen for connectivity changes
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = !results.contains(ConnectivityResult.none);

      if (_isOnline && !wasOnline) {
        debugPrint('[UploadWorker] Back online — resuming uploads');
        _scheduleProcessing();
      } else if (!_isOnline && wasOnline) {
        debugPrint('[UploadWorker] Went offline — pausing uploads');
        _processTimer?.cancel();
      }
    });

    // Reset any jobs stuck in "uploading" state from a previous crash
    for (final job in _queue.getUploadingJobs()) {
      await _queue.markFailed(job.id, 'App restarted during upload');
      _notifyStatus(job);
    }

    // Start processing
    _scheduleProcessing();
  }

  /// Stop the upload worker. Call on app dispose.
  Future<void> stop() async {
    _processTimer?.cancel();
    await _connectivitySub?.cancel();
    await _statusController.close();
    await _countController.close();
  }

  /// Enqueue a new recording for upload.
  Future<void> enqueue(HiveUploadJob job) async {
    await _queue.enqueue(job);
    _countController.add(_queue.pendingCount);
    _scheduleProcessing();
  }

  /// Manually retry a specific failed job.
  Future<void> retryJob(String jobId) async {
    await _queue.resetJob(jobId);
    final job = _queue.getJob(jobId);
    if (job != null) _notifyStatus(job);
    _countController.add(_queue.pendingCount);
    _scheduleProcessing();
  }

  /// Get current queue snapshot.
  List<HiveUploadJob> get allJobs => _queue.getAllJobs();

  /// Pending count.
  int get pendingCount => _queue.pendingCount;

  // ── Processing loop ──

  void _scheduleProcessing() {
    if (_isProcessing || !_isOnline) return;
    // Process immediately
    _processTimer?.cancel();
    _processTimer = Timer(Duration.zero, _processQueue);
  }

  Future<void> _processQueue() async {
    if (_isProcessing || !_isOnline) return;
    _isProcessing = true;

    try {
      while (_isOnline) {
        final pendingJobs = _queue.getPendingJobs(maxRetries: maxRetries);
        if (pendingJobs.isEmpty) break;

        final job = pendingJobs.first;
        await _processJob(job);
        _countController.add(_queue.pendingCount);
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _processJob(HiveUploadJob job) async {
    debugPrint('[UploadWorker] Processing job ${job.id} '
        '(attempt ${job.retryCount + 1}/$maxRetries)');

    await _queue.markUploading(job.id);
    _notifyStatus(job);

    try {
      final direction = job.direction == 'incoming'
          ? CallDirection.incoming
          : CallDirection.outgoing;

      final driveFileId = await _driveService.uploadWithFolderCreation(
        filePath: job.recordingPath,
        executiveName: job.executiveName,
        direction: direction,
        phoneNumber: job.phoneNumber,
        callTimestamp: job.callTimestamp,
        durationSeconds: job.durationSeconds,
      );

      await _queue.markCompleted(job.id, driveFileId);
      _notifyStatus(job);
      debugPrint('[UploadWorker] Job ${job.id} uploaded → $driveFileId');
    } catch (e) {
      final errorMsg = e.toString();
      await _queue.markFailed(job.id, errorMsg);
      _notifyStatus(job);
      debugPrint('[UploadWorker] Job ${job.id} failed: $errorMsg');

      // Exponential backoff before next attempt
      final updatedJob = _queue.getJob(job.id);
      if (updatedJob != null && updatedJob.retryCount < maxRetries) {
        final delay = _backoffDelay(updatedJob.retryCount);
        debugPrint('[UploadWorker] Retrying in ${delay.inSeconds}s');
        await Future<void>.delayed(delay);
      }
    }
  }

  /// Exponential backoff with jitter: base * 2^retry + random jitter.
  Duration _backoffDelay(int retryCount) {
    final exponential = baseRetryDelay.inMilliseconds * pow(2, retryCount);
    final jitter = Random().nextInt(1000);
    return Duration(milliseconds: exponential.toInt() + jitter);
  }

  void _notifyStatus(HiveUploadJob job) {
    if (!_statusController.isClosed) {
      final current = _queue.getJob(job.id);
      if (current != null) {
        _statusController.add(current);
      }
    }
  }
}
