import 'dart:io';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:salestrack_shared/salestrack_shared.dart';

/// Manages Google Drive operations: folder creation and file uploads.
///
/// Folder hierarchy: `SalesTrack/{ExecutiveName}/{YYYY-MM}/`
/// File naming: `{YYYYMMDD_HHMMSS}_{IN|OUT}_{CallerNumber}.mp4`
class DriveService {
  final drive.DriveApi _driveApi;

  DriveService(http.Client authenticatedClient)
      : _driveApi = drive.DriveApi(authenticatedClient);

  /// Ensure the root `SalesTrack` folder exists in Drive.
  /// Returns the folder ID.
  Future<String> ensureRootFolder() async {
    return _findOrCreateFolder('SalesTrack', parentId: null);
  }

  /// Ensure the executive's personal folder exists under the root.
  /// Path: `SalesTrack/{executiveName}`
  /// Returns the folder ID.
  Future<String> ensureExecutiveFolder({
    required String rootFolderId,
    required String executiveName,
  }) async {
    return _findOrCreateFolder(executiveName, parentId: rootFolderId);
  }

  /// Ensure the month folder exists under the executive folder.
  /// Path: `SalesTrack/{executiveName}/{YYYY-MM}`
  /// Returns the folder ID.
  Future<String> ensureMonthFolder({
    required String executiveFolderId,
    required DateTime callTimestamp,
  }) async {
    final monthStr = DateFormat('yyyy-MM').format(callTimestamp);
    return _findOrCreateFolder(monthStr, parentId: executiveFolderId);
  }

  /// Upload a recording file to the correct Drive folder.
  ///
  /// Returns the Drive file ID of the uploaded file.
  Future<String> uploadRecording({
    required String monthFolderId,
    required String filePath,
    required CallDirection direction,
    required String phoneNumber,
    required DateTime callTimestamp,
    required int durationSeconds,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw FileSystemException('Recording file not found', filePath);
    }

    final fileName = _buildFileName(
      direction: direction,
      phoneNumber: phoneNumber,
      callTimestamp: callTimestamp,
    );

    final description = _buildDescription(
      direction: direction,
      phoneNumber: phoneNumber,
      durationSeconds: durationSeconds,
      callTimestamp: callTimestamp,
    );

    final driveFile = drive.File()
      ..name = fileName
      ..description = description
      ..parents = [monthFolderId]
      ..mimeType = 'audio/mp4';

    final media = drive.Media(file.openRead(), file.lengthSync());

    final uploaded = await _driveApi.files.create(
      driveFile,
      uploadMedia: media,
      uploadOptions: drive.UploadOptions.resumable,
    );

    if (uploaded.id == null) {
      throw Exception('Drive upload returned null file ID');
    }

    return uploaded.id!;
  }

  /// Full upload flow: ensures all folders exist, uploads file, returns Drive file ID.
  Future<String> uploadWithFolderCreation({
    required String filePath,
    required String executiveName,
    required CallDirection direction,
    required String phoneNumber,
    required DateTime callTimestamp,
    required int durationSeconds,
  }) async {
    final rootId = await ensureRootFolder();
    final execId = await ensureExecutiveFolder(
      rootFolderId: rootId,
      executiveName: executiveName,
    );
    final monthId = await ensureMonthFolder(
      executiveFolderId: execId,
      callTimestamp: callTimestamp,
    );

    return uploadRecording(
      monthFolderId: monthId,
      filePath: filePath,
      direction: direction,
      phoneNumber: phoneNumber,
      callTimestamp: callTimestamp,
      durationSeconds: durationSeconds,
    );
  }

  // ── Private helpers ──

  /// Build file name per spec: `{YYYYMMDD_HHMMSS}_{IN|OUT}_{CallerNumber}.mp4`
  String _buildFileName({
    required CallDirection direction,
    required String phoneNumber,
    required DateTime callTimestamp,
  }) {
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(callTimestamp);
    final dirStr = direction == CallDirection.incoming ? 'IN' : 'OUT';
    final sanitizedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    return '${dateStr}_${dirStr}_$sanitizedPhone.mp4';
  }

  /// Build Drive file description with metadata.
  String _buildDescription({
    required CallDirection direction,
    required String phoneNumber,
    required int durationSeconds,
    required DateTime callTimestamp,
  }) {
    final dirStr = direction == CallDirection.incoming ? 'Incoming' : 'Outgoing';
    final mins = durationSeconds ~/ 60;
    final secs = durationSeconds % 60;
    return '$dirStr call with $phoneNumber | '
        'Duration: ${mins}m ${secs}s | '
        '${DateFormat('yyyy-MM-dd HH:mm:ss').format(callTimestamp)}';
  }

  /// Find a folder by name under a parent, or create it.
  Future<String> _findOrCreateFolder(
    String name, {
    required String? parentId,
  }) async {
    // Search for existing folder
    final parentQuery =
        parentId != null ? "'$parentId' in parents and " : '';
    final query =
        "${parentQuery}name = '$name' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";

    final result = await _driveApi.files.list(
      q: query,
      spaces: 'drive',
      $fields: 'files(id, name)',
    );

    if (result.files != null && result.files!.isNotEmpty) {
      return result.files!.first.id!;
    }

    // Create the folder
    final folder = drive.File()
      ..name = name
      ..mimeType = 'application/vnd.google-apps.folder';

    if (parentId != null) {
      folder.parents = [parentId];
    }

    final created = await _driveApi.files.create(folder);
    if (created.id == null) {
      throw Exception('Failed to create Drive folder: $name');
    }

    return created.id!;
  }
}
