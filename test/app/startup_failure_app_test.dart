import 'package:fin_sight_ai/app/startup_failure_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('explains that local data could not be unlocked', (tester) async {
    await tester.pumpWidget(const StartupFailureApp());
    await tester.pump();

    expect(find.text('Local data could not be unlocked'), findsOneWidget);
    expect(find.textContaining('No records were deleted'), findsOneWidget);
  });
}
