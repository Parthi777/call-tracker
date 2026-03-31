import 'package:freezed_annotation/freezed_annotation.dart';

part 'call_record.freezed.dart';
part 'call_record.g.dart';

enum CallDirection { incoming, outgoing }

enum CallStatus { recorded, uploading, uploaded, failed }

@freezed
abstract class CallRecord with _$CallRecord {
  const factory CallRecord({
    required String id,
    required String executiveId,
    required CallDirection direction,
    required int duration,
    required DateTime timestamp,
    required String phoneNumber,
    String? driveFileId,
    @Default(CallStatus.recorded) CallStatus status,
  }) = _CallRecord;

  factory CallRecord.fromJson(Map<String, dynamic> json) =>
      _$CallRecordFromJson(json);
}
