import 'package:flutter_test/flutter_test.dart';
import 'package:salestrack_web/main.dart';

void main() {
  testWidgets('App renders admin login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SalesTrackWebApp());
    await tester.pumpAndSettle();

    expect(find.text('SalesTrack Admin'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });
}
