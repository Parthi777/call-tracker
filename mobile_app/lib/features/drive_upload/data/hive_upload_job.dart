import 'package:hive/hive.dart';

/// Hive type IDs for this feature.
const int hiveTypeUploadJob = 0;
const int hiveTypeUploadStatus = 1;

/// Upload status persisted in Hive.
@HiveType(typeId: hiveTypeUploadStatus)
enum HiveUploadStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  uploading,
  @HiveField(2)
  completed,
  @HiveField(3)
  failed,
}

/// Upload job persisted in the Hive offline queue.
@HiveType(typeId: hiveTypeUploadJob)
class HiveUploadJob extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String recordingPath;

  @HiveField(2)
  final String callRecordId;

  @HiveField(3)
  final String executiveId;

  @HiveField(4)
  final String executiveName;

  @HiveField(5)
  final String phoneNumber;

  @HiveField(6)
  final String direction; // 'incoming' or 'outgoing'

  @HiveField(7)
  final int durationSeconds;

  @HiveField(8)
  final DateTime callTimestamp;

  @HiveField(9)
  HiveUploadStatus status;

  @HiveField(10)
  int retryCount;

  @HiveField(11)
  String? driveFileId;

  @HiveField(12)
  String? errorMessage;

  @HiveField(13)
  DateTime createdAt;

  HiveUploadJob({
    required this.id,
    required this.recordingPath,
    required this.callRecordId,
    required this.executiveId,
    required this.executiveName,
    required this.phoneNumber,
    required this.direction,
    required this.durationSeconds,
    required this.callTimestamp,
    this.status = HiveUploadStatus.pending,
    this.retryCount = 0,
    this.driveFileId,
    this.errorMessage,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

// ── Manual Hive adapters (no code gen needed) ──

class HiveUploadStatusAdapter extends TypeAdapter<HiveUploadStatus> {
  @override
  final int typeId = hiveTypeUploadStatus;

  @override
  HiveUploadStatus read(BinaryReader reader) {
    final index = reader.readByte();
    return HiveUploadStatus.values[index];
  }

  @override
  void write(BinaryWriter writer, HiveUploadStatus obj) {
    writer.writeByte(obj.index);
  }
}

class HiveUploadJobAdapter extends TypeAdapter<HiveUploadJob> {
  @override
  final int typeId = hiveTypeUploadJob;

  @override
  HiveUploadJob read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return HiveUploadJob(
      id: fields[0] as String,
      recordingPath: fields[1] as String,
      callRecordId: fields[2] as String,
      executiveId: fields[3] as String,
      executiveName: fields[4] as String,
      phoneNumber: fields[5] as String,
      direction: fields[6] as String,
      durationSeconds: fields[7] as int,
      callTimestamp: fields[8] as DateTime,
      status: fields[9] as HiveUploadStatus,
      retryCount: fields[10] as int,
      driveFileId: fields[11] as String?,
      errorMessage: fields[12] as String?,
      createdAt: fields[13] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HiveUploadJob obj) {
    writer
      ..writeByte(14) // number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.recordingPath)
      ..writeByte(2)
      ..write(obj.callRecordId)
      ..writeByte(3)
      ..write(obj.executiveId)
      ..writeByte(4)
      ..write(obj.executiveName)
      ..writeByte(5)
      ..write(obj.phoneNumber)
      ..writeByte(6)
      ..write(obj.direction)
      ..writeByte(7)
      ..write(obj.durationSeconds)
      ..writeByte(8)
      ..write(obj.callTimestamp)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.retryCount)
      ..writeByte(11)
      ..write(obj.driveFileId)
      ..writeByte(12)
      ..write(obj.errorMessage)
      ..writeByte(13)
      ..write(obj.createdAt);
  }
}
