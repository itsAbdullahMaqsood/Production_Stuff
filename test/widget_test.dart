import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HomeView renders with providers', (WidgetTester tester) async {
    expect(find.text('Notifier'), findsOneWidget);
    expect(find.text('Send Notification'), findsOneWidget);
    expect(find.text('Schedule to send after 1 minute'), findsOneWidget);
    expect(find.text('Trigger background task (10s)'), findsOneWidget);
    expect(find.text('Debug: list background tasks'), findsOneWidget);
  });
}
