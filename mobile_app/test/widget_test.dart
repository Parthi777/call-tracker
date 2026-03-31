import 'package:flutter_test/flutter_test.dart';
import 'package:salestrack_mobile/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SalesTrackApp());
    await tester.pumpAndSettle();

    expect(find.text('SalesTrack'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });
}
