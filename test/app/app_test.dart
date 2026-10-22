import 'package:fin_sight_ai/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the FinSight AI foundation shell', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(const FinSightApp());

    // Assert
    expect(find.text('FinSight AI'), findsOneWidget);
    expect(find.text('Foundation ready'), findsOneWidget);
  });
}
