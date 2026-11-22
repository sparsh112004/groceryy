import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pantry_app/core/api_client.dart';
import 'package:pantry_app/core/storage.dart';
import 'package:pantry_app/features/auth/state/auth_provider.dart';
import 'package:pantry_app/features/auth/ui/auth_screen.dart';
import 'package:pantry_app/features/pantry/data/items_repository.dart';
import 'package:pantry_app/features/pantry/state/items_provider.dart';
import 'package:pantry_app/features/pantry/ui/add_item_screen.dart';

void main() {
  testWidgets('AuthScreen displays welcome message and toggles login/signup',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final storage = StorageService();
    final apiClient = ApiClient(storage: storage);
    final authProvider = AuthProvider(apiClient: apiClient, storage: storage);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: const MaterialApp(
          home: AuthScreen(),
        ),
      ),
    );
    await tester.pump();

    // Verify Welcome header
    expect(find.text('Welcome to Stockora'), findsOneWidget);
    expect(
      find.text('Know what is at home, use it before it expires.'),
      findsOneWidget,
    );

    // Verify form input fields for login
    expect(find.text('Phone or email'), findsOneWidget);
    expect(find.text('PIN or password'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);

    // Switch to Sign up mode
    final signupToggleFinder = find.text("Don't have an account? Sign up");
    await tester.ensureVisible(signupToggleFinder);
    await tester.tap(signupToggleFinder);
    await tester.pump();

    // Verify Name field appears for Sign up
    expect(find.text('Name'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign up'), findsOneWidget);

    // Switch back to Log in mode
    final loginToggleFinder = find.text('Already have an account? Log in');
    await tester.ensureVisible(loginToggleFinder);
    await tester.tap(loginToggleFinder);
    await tester.pump();

    // Verify Name field is removed in Log in mode
    expect(find.text('Name'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
  });

  testWidgets('AddItemScreen renders wireframe elements and enables save on input',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final storage = StorageService();
    final apiClient = ApiClient(storage: storage);
    final repository = ItemsRepository(apiClient: apiClient);
    final itemsProvider = ItemsProvider(repository: repository);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ItemsProvider>.value(value: itemsProvider),
        ],
        child: const MaterialApp(
          home: AddItemScreen(),
        ),
      ),
    );
    await tester.pump();

    // Verify Wireframe 1 elements
    expect(find.text('Item name'), findsOneWidget);
    expect(find.text('Expires in'), findsOneWidget);
    expect(find.text('1 week'), findsOneWidget);
    expect(find.text('2 weeks'), findsOneWidget);
    expect(find.text('1 month'), findsOneWidget);
    expect(find.text('3 months'), findsOneWidget);
    expect(find.text('Pick date'), findsOneWidget);
    expect(find.text('More details (optional)'), findsOneWidget);

    // Save button initially disabled
    final saveButtonFinder = find.widgetWithText(FilledButton, 'Save item');
    expect(saveButtonFinder, findsOneWidget);
    final FilledButton initialButton = tester.widget(saveButtonFinder);
    expect(initialButton.onPressed, isNull);

    // Enter Item Name
    await tester.enterText(find.byType(TextFormField).first, 'Organic Milk');
    await tester.pump();

    // Tap '1 week' chip
    await tester.tap(find.text('1 week'));
    await tester.pump();

    // Save button should now be enabled
    final FilledButton enabledButton = tester.widget(saveButtonFinder);
    expect(enabledButton.onPressed, isNotNull);
  });
}
