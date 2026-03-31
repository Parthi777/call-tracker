import 'package:hive/hive.dart';
import 'package:salestrack_shared/salestrack_shared.dart';

/// Local Hive repository for persisting call records.
///
/// This stores call metadata (not the recording file itself) so the
/// dashboard can display KPIs even when offline.
const String callLogBoxName = 'call_log';

class CallLogRepository {
  final Box<Map> _box;

  CallLogRepository(this._box);

  static Future<CallLogRepository> open() async {
    final box = await Hive.openBox<Map>(callLogBoxName);
    return CallLogRepository(box);
  }

  /// Save a call record.
  Future<void> saveCall(CallRecord record) async {
    await _box.put(record.id, record.toJson());
  }

  /// Get all call records, newest first.
  List<CallRecord> getAllCalls() {
    return _box.values
        .map((json) => CallRecord.fromJson(Map<String, dynamic>.from(json)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get calls for today.
  List<CallRecord> getTodayCalls() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return getAllCalls()
        .where((c) => c.timestamp.isAfter(startOfDay))
        .toList();
  }

  /// Get a single call by ID.
  CallRecord? getCall(String id) {
    final json = _box.get(id);
    if (json == null) return null;
    return CallRecord.fromJson(Map<String, dynamic>.from(json));
  }

  /// Update call status (e.g., after upload).
  Future<void> updateStatus(String id, CallStatus status,
      {String? driveFileId}) async {
    final json = _box.get(id);
    if (json == null) return;
    final record = CallRecord.fromJson(Map<String, dynamic>.from(json));
    final updated = record.copyWith(
      status: status,
      driveFileId: driveFileId ?? record.driveFileId,
    );
    await _box.put(id, updated.toJson());
  }

  /// Count of all calls.
  int get totalCount => _box.length;
}
