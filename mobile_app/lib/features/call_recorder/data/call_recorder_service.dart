import 'dart:async';

import 'package:flutter/services.dart';

/// Platform channel bridge to native Android call recording.
///
/// Communicates with [CallReceiver] and [CallRecordingService] on the
/// Android side via MethodChannel (commands) and EventChannel (events).
class CallRecorderService {
  static const _methodChannel =
      MethodChannel('com.salestrack.mobile/call_recorder');
  static const _eventChannel =
      EventChannel('com.salestrack.mobile/call_events');

  /// Stream of call events from the native layer.
  /// Each event is a Map with keys: event, phoneNumber, isIncoming,
  /// recordingPath, duration, timestamp, error.
  Stream<Map<String, dynamic>> get callEventStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event as Map);
    });
  }

  /// Request all call-related permissions.
  /// Returns true if all permissions were granted.
  Future<bool> requestPermissions() async {
    final result = await _methodChannel.invokeMethod<bool>('requestPermissions');
    return result ?? false;
  }

  /// Check current permission status.
  /// Returns a map of permission name → granted boolean.
  Future<Map<String, bool>> checkPermissions() async {
    final result =
        await _methodChannel.invokeMethod<Map>('checkPermissions');
    if (result == null) return {};
    return result.map((key, value) => MapEntry(key.toString(), value as bool));
  }

  /// Get the last call event from SharedPreferences (for catching events
  /// that happened while Flutter was not listening).
  Future<Map<String, dynamic>?> getLastCallEvent() async {
    final result = await _methodChannel.invokeMethod<Map>('getLastCallEvent');
    if (result == null) return null;
    return Map<String, dynamic>.from(result);
  }

  /// Get the directory where recordings are stored.
  Future<String> getRecordingsDir() async {
    final result =
        await _methodChannel.invokeMethod<String>('getRecordingsDir');
    return result ?? '';
  }

  /// Get list of all recording files on disk.
  Future<List<Map<String, dynamic>>> getCallRecordings() async {
    final result =
        await _methodChannel.invokeMethod<List>('getCallRecordings');
    if (result == null) return [];
    return result
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  /// Delete a recording file.
  Future<bool> deleteRecording(String path) async {
    final result = await _methodChannel
        .invokeMethod<bool>('deleteRecording', {'path': path});
    return result ?? false;
  }
}
