import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/main.dart';

void main() {
  testWidgets('PantryApp launches and displays bottom navigation',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PantryApp());
    await tester.pumpAndSettle();

    // Verify presence of navigation destinations
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Pantry'), findsWidgets);
    expect(find.text('Shopping'), findsWidgets);
    expect(find.text('Household'), findsWidgets);
  });
}
