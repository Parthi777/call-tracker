import 'package:test/test.dart';
import 'package:salestrack_shared/salestrack_shared.dart';

void main() {
  group('CallRecord', () {
    test('creates with required fields', () {
      final record = CallRecord(
        id: '1',
        executiveId: 'exec1',
        direction: CallDirection.incoming,
        duration: 120,
        timestamp: DateTime(2026, 3, 30),
        phoneNumber: '+1234567890',
      );
      expect(record.id, '1');
      expect(record.direction, CallDirection.incoming);
      expect(record.status, CallStatus.recorded);
    });

    test('missed call is IN with duration < 5', () {
      final record = CallRecord(
        id: '2',
        executiveId: 'exec1',
        direction: CallDirection.incoming,
        duration: 3,
        timestamp: DateTime(2026, 3, 30),
        phoneNumber: '+1234567890',
      );
      final isMissed = record.direction == CallDirection.incoming && record.duration < 5;
      expect(isMissed, true);
    });
  });

  group('Executive', () {
    test('creates with defaults', () {
      final exec = Executive(
        id: '1',
        name: 'John Doe',
        phone: '+1234567890',
        createdAt: DateTime(2026, 3, 30),
      );
      expect(exec.isActive, true);
      expect(exec.driveFolder, isNull);
    });
  });

  group('KpiSnapshot', () {
    test('defaults to zero values', () {
      final kpi = KpiSnapshot(
        executiveId: 'exec1',
        date: DateTime(2026, 3, 30),
      );
      expect(kpi.totalCalls, 0);
      expect(kpi.missed, 0);
      expect(kpi.avgDuration, 0.0);
    });
  });
}
