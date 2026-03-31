import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salestrack_shared/salestrack_shared.dart';
import 'package:uuid/uuid.dart';

import '../../auth/data/auth_service.dart';
import '../../drive_upload/domain/upload_providers.dart';
import '../data/call_log_repository.dart';
import '../data/call_recorder_service.dart';
import '../data/firestore_sync_service.dart';

const _uuid = Uuid();

/// Singleton instance of the native call recorder service.
final callRecorderServiceProvider = Provider<CallRecorderService>((ref) {
  return CallRecorderService();
});

/// Firestore sync service for pushing data to the cloud.
final firestoreSyncServiceProvider = Provider<FirestoreSyncService>((ref) {
  return FirestoreSyncService();
});

/// Call log repository (Hive-backed). Must be overridden at startup.
final callLogRepositoryProvider = Provider<CallLogRepository>((ref) {
  throw UnimplementedError('callLogRepositoryProvider must be overridden');
});

/// Permission status — map of permission name to granted boolean.
final callPermissionsProvider =
    StateNotifierProvider<CallPermissionsNotifier, AsyncValue<Map<String, bool>>>(
  (ref) => CallPermissionsNotifier(ref.watch(callRecorderServiceProvider)),
);

class CallPermissionsNotifier
    extends StateNotifier<AsyncValue<Map<String, bool>>> {
  final CallRecorderService _service;

  CallPermissionsNotifier(this._service)
      : super(const AsyncValue.loading()) {
    check();
  }

  Future<void> check() async {
    state = const AsyncValue.loading();
    try {
      final perms = await _service.checkPermissions();
      state = AsyncValue.data(perms);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> request() async {
    final granted = await _service.requestPermissions();
    await check();
    return granted;
  }

  bool get allGranted {
    return state.valueOrNull?.values.every((v) => v) ?? false;
  }
}

/// Stream of call events from the native layer.
final callEventStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final service = ref.watch(callRecorderServiceProvider);
  return service.callEventStream;
});

/// Today's call records from local Hive storage.
final todayCallsProvider = StateNotifierProvider<TodayCallsNotifier, List<CallRecord>>(
  (ref) {
    final repo = ref.watch(callLogRepositoryProvider);
    return TodayCallsNotifier(repo, ref);
  },
);

class TodayCallsNotifier extends StateNotifier<List<CallRecord>> {
  final CallLogRepository _repo;
  final Ref _ref;
  StreamSubscription<AsyncValue<Map<String, dynamic>>>? _eventSub;

  TodayCallsNotifier(this._repo, this._ref) : super([]) {
    _loadCalls();
    _listenForCallEvents();
  }

  void _loadCalls() {
    state = _repo.getTodayCalls();
  }

  void _listenForCallEvents() {
    // Listen to native call events and create CallRecord entries
    _ref.listen<AsyncValue<Map<String, dynamic>>>(
      callEventStreamProvider,
      (previous, next) {
        next.whenData((event) => _handleCallEvent(event));
      },
    );
  }

  Future<void> _handleCallEvent(Map<String, dynamic> event) async {
    final eventType = event['event'] as String?;
    if (eventType == null) return;

    if (eventType == 'call_recorded' || eventType == 'missed') {
      final phoneNumber = event['phoneNumber'] as String? ?? 'Unknown';
      final isIncoming = event['isIncoming'] as bool? ?? false;
      final duration = event['duration'] as int? ?? 0;
      final timestamp = event['timestamp'] as int? ?? 0;

      final record = CallRecord(
        id: _uuid.v4(),
        executiveId: _ref.read(currentUserProvider)?.uid ?? 'unknown',
        direction:
            isIncoming ? CallDirection.incoming : CallDirection.outgoing,
        duration: duration,
        timestamp: timestamp > 0
            ? DateTime.fromMillisecondsSinceEpoch(timestamp)
            : DateTime.now(),
        phoneNumber: phoneNumber,
        status: eventType == 'missed' ? CallStatus.failed : CallStatus.recorded,
      );

      await _repo.saveCall(record);
      _loadCalls(); // Refresh state

      // Sync to Firestore for web dashboard
      final syncService = _ref.read(firestoreSyncServiceProvider);
      await syncService.syncCallRecord(record);

      // Also update KPI snapshot in Firestore
      final kpi = _computeKpi();
      if (kpi != null) {
        await syncService.syncKpiSnapshot(kpi);
      }

      // Enqueue recording for Google Drive upload
      final recordingPath = event['recordingPath'] as String?;
      final worker = _ref.read(uploadWorkerProvider);
      if (recordingPath != null && recordingPath.isNotEmpty && worker != null) {
        await enqueueUpload(
          worker: worker,
          recordingPath: recordingPath,
          callRecordId: record.id,
          executiveId: record.executiveId,
          executiveName: _ref.read(currentUserProvider)?.displayName ?? 'Unknown',
          direction: record.direction,
          phoneNumber: record.phoneNumber,
          durationSeconds: record.duration,
          callTimestamp: record.timestamp,
        );
      }
    }
  }

  KpiSnapshot? _computeKpi() {
    final calls = _repo.getTodayCalls();
    if (calls.isEmpty) return null;
    final now = DateTime.now();
    final incoming = calls.where((c) => c.direction == CallDirection.incoming).length;
    final outgoing = calls.where((c) => c.direction == CallDirection.outgoing).length;
    final missed = calls
        .where((c) => c.duration < 5 && c.direction == CallDirection.incoming)
        .length;
    final nonMissed = calls.where((c) => c.duration >= 5).toList();
    final avgDuration = nonMissed.isEmpty
        ? 0.0
        : nonMissed.fold<int>(0, (sum, c) => sum + c.duration) / nonMissed.length;
    final talkTime = calls.fold<int>(0, (sum, c) => sum + c.duration);
    final uniqueContacts = calls.map((c) => c.phoneNumber).toSet().length;
    return KpiSnapshot(
      executiveId: _ref.read(currentUserProvider)?.uid ?? 'unknown',
      date: DateTime(now.year, now.month, now.day),
      totalCalls: calls.length,
      incoming: incoming,
      outgoing: outgoing,
      missed: missed,
      avgDuration: avgDuration,
      talkTime: talkTime,
      uniqueContacts: uniqueContacts,
    );
  }

  void refresh() => _loadCalls();

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }
}

/// Computed KPIs from today's calls.
final todayKpiProvider = Provider<KpiSnapshot>((ref) {
  final calls = ref.watch(todayCallsProvider);
  final now = DateTime.now();

  final incoming = calls.where((c) => c.direction == CallDirection.incoming).length;
  final outgoing = calls.where((c) => c.direction == CallDirection.outgoing).length;
  final missed = calls
      .where((c) =>
          c.duration < 5 && c.direction == CallDirection.incoming)
      .length;
  final nonMissed = calls.where((c) => c.duration >= 5).toList();
  final avgDuration = nonMissed.isEmpty
      ? 0.0
      : nonMissed.fold<int>(0, (sum, c) => sum + c.duration) /
          nonMissed.length;
  final talkTime = calls.fold<int>(0, (sum, c) => sum + c.duration);
  final uniqueContacts = calls.map((c) => c.phoneNumber).toSet().length;

  // Peak hour calculation
  int? peakHour;
  if (calls.isNotEmpty) {
    final hourCounts = <int, int>{};
    for (final c in calls) {
      final hour = c.timestamp.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }
    peakHour = hourCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  return KpiSnapshot(
    executiveId: ref.read(currentUserProvider)?.uid ?? 'unknown',
    date: DateTime(now.year, now.month, now.day),
    totalCalls: calls.length,
    incoming: incoming,
    outgoing: outgoing,
    missed: missed,
    avgDuration: avgDuration,
    talkTime: talkTime,
    uniqueContacts: uniqueContacts,
    peakHour: peakHour,
  );
});
