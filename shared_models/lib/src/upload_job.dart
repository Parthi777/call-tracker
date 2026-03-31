import 'package:freezed_annotation/freezed_annotation.dart';

part 'upload_job.freezed.dart';
part 'upload_job.g.dart';

enum UploadStatus { pending, uploading, completed, failed }

@freezed
abstract class UploadJob with _$UploadJob {
  const factory UploadJob({
    required String id,
    required String recordingPath,
    required String callRecordId,
    @Default(UploadStatus.pending) UploadStatus status,
    @Default(0) int retryCount,
  }) = _UploadJob;

  factory UploadJob.fromJson(Map<String, dynamic> json) =>
      _$UploadJobFromJson(json);
}
