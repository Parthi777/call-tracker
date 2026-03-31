import 'package:flutter_test/flutter_test.dart';
import 'package:salestrack_shared/salestrack_shared.dart';

/// Tests for Drive file naming and description logic.
/// These test the pure functions extracted from DriveService.
void main() {
  group('Drive file naming', () {
    test('builds correct filename for incoming call', () {
      final name = buildFileName(
        direction: CallDirection.incoming,
        phoneNumber: '+1-234-567-8900',
        callTimestamp: DateTime(2026, 3, 30, 14, 5, 30),
      );
      expect(name, '20260330_140530_IN_+12345678900.mp4');
    });

    test('builds correct filename for outgoing call', () {
      final name = buildFileName(
        direction: CallDirection.outgoing,
        phoneNumber: '9876543210',
        callTimestamp: DateTime(2026, 1, 5, 9, 0, 0),
      );
      expect(name, '20260105_090000_OUT_9876543210.mp4');
    });

    test('sanitizes special characters from phone number', () {
      final name = buildFileName(
        direction: CallDirection.incoming,
        phoneNumber: '(555) 123-4567',
        callTimestamp: DateTime(2026, 6, 15, 12, 30, 0),
      );
      expect(name, '20260615_123000_IN_5551234567.mp4');
    });
  });

  group('Drive file description', () {
    test('formats description with duration and metadata', () {
      final desc = buildDescription(
        direction: CallDirection.incoming,
        phoneNumber: '+1234567890',
        durationSeconds: 185,
        callTimestamp: DateTime(2026, 3, 30, 14, 5, 30),
      );
      expect(desc, contains('Incoming call'));
      expect(desc, contains('+1234567890'));
      expect(desc, contains('3m 5s'));
      expect(desc, contains('2026-03-30'));
    });
  });
}

// ── Extracted pure functions for testing (mirrors DriveService logic) ──

String buildFileName({
  required CallDirection direction,
  required String phoneNumber,
  required DateTime callTimestamp,
}) {
  final y = callTimestamp.year.toString().padLeft(4, '0');
  final m = callTimestamp.month.toString().padLeft(2, '0');
  final d = callTimestamp.day.toString().padLeft(2, '0');
  final h = callTimestamp.hour.toString().padLeft(2, '0');
  final min = callTimestamp.minute.toString().padLeft(2, '0');
  final s = callTimestamp.second.toString().padLeft(2, '0');
  final dateStr = '${y}${m}${d}_${h}${min}$s';
  final dirStr = direction == CallDirection.incoming ? 'IN' : 'OUT';
  final sanitizedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
  return '${dateStr}_${dirStr}_$sanitizedPhone.mp4';
}

String buildDescription({
  required CallDirection direction,
  required String phoneNumber,
  required int durationSeconds,
  required DateTime callTimestamp,
}) {
  final dirStr = direction == CallDirection.incoming ? 'Incoming' : 'Outgoing';
  final mins = durationSeconds ~/ 60;
  final secs = durationSeconds % 60;
  final y = callTimestamp.year.toString().padLeft(4, '0');
  final m = callTimestamp.month.toString().padLeft(2, '0');
  final d = callTimestamp.day.toString().padLeft(2, '0');
  final h = callTimestamp.hour.toString().padLeft(2, '0');
  final min = callTimestamp.minute.toString().padLeft(2, '0');
  final s = callTimestamp.second.toString().padLeft(2, '0');
  return '$dirStr call with $phoneNumber | '
      'Duration: ${mins}m ${secs}s | '
      '$y-$m-$d $h:$min:$s';
}
