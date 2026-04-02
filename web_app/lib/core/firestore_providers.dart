import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firestore instance provider.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Real-time stream of all call records, newest first.
final callsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('calls')
      .orderBy('timestamp', descending: true)
      .limit(200)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
});

/// Real-time stream of today's KPI snapshots (all executives).
final kpiStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);

  return firestore
      .collection('kpi_daily')
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
});

/// Real-time stream of executives.
final executivesStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('executives')
      .orderBy('name')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
});

/// Aggregated KPIs computed from all call records (unfiltered).
final aggregatedKpiProvider = Provider<Map<String, dynamic>>((ref) {
  final calls = ref.watch(callsStreamProvider).valueOrNull ?? [];
  return _computeKpi(calls);
});

/// State provider for the selected date range filter.
final dateRangeFilterProvider = StateProvider<DateTimeRange?>((ref) => null);

/// Calls filtered by date range. Falls back to all calls if no range set.
final filteredCallsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final allCalls = ref.watch(callsStreamProvider).valueOrNull ?? [];
  final range = ref.watch(dateRangeFilterProvider);
  if (range == null) return allCalls;

  return allCalls.where((c) {
    final ts = c['timestamp'];
    if (ts is Timestamp) {
      final dt = ts.toDate();
      return !dt.isBefore(range.start) &&
          dt.isBefore(range.end.add(const Duration(days: 1)));
    }
    return false;
  }).toList();
});

/// Aggregated KPIs from the filtered calls.
final filteredKpiProvider = Provider<Map<String, dynamic>>((ref) {
  final calls = ref.watch(filteredCallsProvider);
  return _computeKpi(calls);
});

Map<String, dynamic> _computeKpi(List<Map<String, dynamic>> calls) {
  if (calls.isEmpty) {
    return {
      'totalCalls': 0,
      'incoming': 0,
      'outgoing': 0,
      'missed': 0,
      'avgDuration': '0s',
      'talkTime': '0m',
      'uniqueContacts': 0,
      'peakHour': '--',
    };
  }

  final incoming = calls.where((c) => c['direction'] == 'incoming').length;
  final outgoing = calls.where((c) => c['direction'] == 'outgoing').length;
  final missed = calls
      .where((c) =>
          (c['duration'] as int? ?? 0) < 5 && c['direction'] == 'incoming')
      .length;
  final nonMissed =
      calls.where((c) => (c['duration'] as int? ?? 0) >= 5).toList();
  final avgDurationSec = nonMissed.isEmpty
      ? 0
      : (nonMissed.fold<int>(
                  0, (total, c) => total + (c['duration'] as int? ?? 0)) /
              nonMissed.length)
          .round();
  final talkTimeSec =
      calls.fold<int>(0, (total, c) => total + (c['duration'] as int? ?? 0));
  final uniqueContacts =
      calls.map((c) => c['phoneNumber'] as String? ?? '').toSet().length;

  String peakHour = '--';
  final hourCounts = <int, int>{};
  for (final c in calls) {
    final ts = c['timestamp'];
    if (ts is Timestamp) {
      final hour = ts.toDate().hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }
  }
  if (hourCounts.isNotEmpty) {
    final peak =
        hourCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    peakHour =
        '${peak % 12 == 0 ? 12 : peak % 12}-${(peak + 1) % 12 == 0 ? 12 : (peak + 1) % 12} ${peak < 12 ? "AM" : "PM"}';
  }

  return {
    'totalCalls': calls.length,
    'incoming': incoming,
    'outgoing': outgoing,
    'missed': missed,
    'avgDuration': _formatDuration(avgDurationSec),
    'talkTime': _formatDuration(talkTimeSec),
    'uniqueContacts': uniqueContacts,
    'peakHour': peakHour,
  };
}

/// Per-executive KPIs computed from call records.
final perExecutiveKpiProvider =
    Provider<List<Map<String, dynamic>>>((ref) {
  final calls = ref.watch(callsStreamProvider).valueOrNull ?? [];
  final executives = ref.watch(executivesStreamProvider).valueOrNull ?? [];
  if (calls.isEmpty || executives.isEmpty) return [];

  final Map<String, List<Map<String, dynamic>>> callsByExec = {};
  for (final call in calls) {
    final execId = call['executiveId'] as String? ?? '';
    callsByExec.putIfAbsent(execId, () => []).add(call);
  }

  final results = <Map<String, dynamic>>[];
  for (final exec in executives) {
    final execId = exec['id'] as String? ?? '';
    final name = exec['name'] as String? ?? 'Unknown';
    final isActive = exec['isActive'] as bool? ?? false;
    final execCalls = callsByExec[execId] ?? [];
    final totalCalls = execCalls.length;
    final nonMissed = execCalls.where((c) => (c['duration'] as int? ?? 0) >= 5).toList();
    final avgDurSec = nonMissed.isEmpty
        ? 0
        : (nonMissed.fold<int>(0, (s, c) => s + (c['duration'] as int? ?? 0)) / nonMissed.length).round();
    final talkTime = execCalls.fold<int>(0, (s, c) => s + (c['duration'] as int? ?? 0));
    final incoming = execCalls.where((c) => c['direction'] == 'incoming').length;
    final outgoing = execCalls.where((c) => c['direction'] == 'outgoing').length;
    final missed = execCalls.where((c) =>
        (c['duration'] as int? ?? 0) < 5 && c['direction'] == 'incoming').length;

    results.add({
      'executiveId': execId,
      'name': name,
      'isActive': isActive,
      'totalCalls': totalCalls,
      'incoming': incoming,
      'outgoing': outgoing,
      'missed': missed,
      'avgDuration': _formatDuration(avgDurSec),
      'avgDurationSec': avgDurSec,
      'talkTime': talkTime,
      'talkTimeFormatted': _formatDuration(talkTime),
    });
  }

  results.sort((a, b) => (b['totalCalls'] as int).compareTo(a['totalCalls'] as int));
  return results;
});

String _formatDuration(int seconds) {
  if (seconds == 0) return '0s';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return '${m}m ${s}s';
  return '${s}s';
}
