import 'package:freezed_annotation/freezed_annotation.dart';

part 'kpi_snapshot.freezed.dart';
part 'kpi_snapshot.g.dart';

@freezed
abstract class KpiSnapshot with _$KpiSnapshot {
  const factory KpiSnapshot({
    required String executiveId,
    required DateTime date,
    @Default(0) int totalCalls,
    @Default(0) int incoming,
    @Default(0) int outgoing,
    @Default(0) int missed,
    @Default(0.0) double avgDuration,
    @Default(0) int talkTime,
    @Default(0) int uniqueContacts,
    int? peakHour,
  }) = _KpiSnapshot;

  factory KpiSnapshot.fromJson(Map<String, dynamic> json) =>
      _$KpiSnapshotFromJson(json);
}
