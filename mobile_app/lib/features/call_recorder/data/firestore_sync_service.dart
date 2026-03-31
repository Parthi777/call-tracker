import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:salestrack_shared/salestrack_shared.dart';

/// Syncs call records and KPI snapshots to Firestore so the web dashboard
/// can read them in real-time.
///
/// Firestore structure (per CLAUDE.md):
///   /calls/{callId}                        — full CallRecord
///   /executives/{executiveId}              — executive profile
///   /kpi_daily/{executiveId}_{date}        — daily KPI aggregation
class FirestoreSyncService {
  final FirebaseFirestore _firestore;

  FirestoreSyncService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Push a single call record to Firestore.
  Future<void> syncCallRecord(CallRecord record) async {
    try {
      await _firestore.collection('calls').doc(record.id).set({
        'id': record.id,
        'executiveId': record.executiveId,
        'direction': record.direction.name,
        'duration': record.duration,
        'timestamp': Timestamp.fromDate(record.timestamp),
        'phoneNumber': record.phoneNumber,
        'driveFileId': record.driveFileId,
        'status': record.status.name,
      });
      debugPrint('[FirestoreSync] Call ${record.id} synced');
    } catch (e) {
      debugPrint('[FirestoreSync] Failed to sync call: $e');
    }
  }

  /// Update call status in Firestore (e.g., after Drive upload).
  Future<void> updateCallStatus(
    String callId,
    CallStatus status, {
    String? driveFileId,
  }) async {
    try {
      final data = <String, dynamic>{'status': status.name};
      if (driveFileId != null) data['driveFileId'] = driveFileId;
      await _firestore.collection('calls').doc(callId).update(data);
    } catch (e) {
      debugPrint('[FirestoreSync] Failed to update call status: $e');
    }
  }

  /// Push / update the daily KPI snapshot.
  Future<void> syncKpiSnapshot(KpiSnapshot kpi) async {
    final dateStr =
        '${kpi.date.year}-${kpi.date.month.toString().padLeft(2, '0')}-${kpi.date.day.toString().padLeft(2, '0')}';
    final docId = '${kpi.executiveId}_$dateStr';

    try {
      await _firestore.collection('kpi_daily').doc(docId).set({
        'executiveId': kpi.executiveId,
        'date': Timestamp.fromDate(kpi.date),
        'totalCalls': kpi.totalCalls,
        'incoming': kpi.incoming,
        'outgoing': kpi.outgoing,
        'missed': kpi.missed,
        'avgDuration': kpi.avgDuration,
        'talkTime': kpi.talkTime,
        'uniqueContacts': kpi.uniqueContacts,
        'peakHour': kpi.peakHour,
      });
      debugPrint('[FirestoreSync] KPI $docId synced');
    } catch (e) {
      debugPrint('[FirestoreSync] Failed to sync KPI: $e');
    }
  }

  /// Register or update executive profile.
  Future<void> syncExecutive(Executive exec) async {
    try {
      await _firestore.collection('executives').doc(exec.id).set({
        'id': exec.id,
        'name': exec.name,
        'phone': exec.phone,
        'driveFolder': exec.driveFolder,
        'isActive': exec.isActive,
        'createdAt': Timestamp.fromDate(exec.createdAt),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirestoreSync] Failed to sync executive: $e');
    }
  }
}
