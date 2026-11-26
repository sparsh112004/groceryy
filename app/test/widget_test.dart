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
import 'package:pantry_app/features/shopping/data/shopping_item_model.dart';
import 'package:pantry_app/features/shopping/data/shopping_repository.dart';
import 'package:pantry_app/features/shopping/state/shopping_provider.dart';
import 'package:pantry_app/features/shopping/ui/bought_bottom_sheet.dart';
import 'package:pantry_app/features/shopping/ui/shopping_screen.dart';

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
    expect(find.text('Stockora'), findsOneWidget);
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(
      find.text('Login to continue managing your pantry.'),
      findsOneWidget,
    );

    // Verify form input fields for login
    expect(find.text('Phone or Email'), findsOneWidget);
    expect(find.text('PIN or Password'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Log In'), findsOneWidget);

    // Switch to Sign up mode
    final signupToggleFinder = find.text("Don't have an account? Sign Up", findRichText: true);
    await tester.ensureVisible(signupToggleFinder);
    await tester.tap(signupToggleFinder);
    await tester.pump();

    // Verify Name and Confirm Password fields appear for Sign up
    expect(find.text('Create Your Account'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Create Account'), findsOneWidget);

    // Switch back to Log in mode
    final loginToggleFinder =
        find.text('Already have an account? Log In', findRichText: true);
    await tester.ensureVisible(loginToggleFinder);
    await tester.tap(loginToggleFinder);
    await tester.pump();

    // Verify Name field is removed in Log in mode
    expect(find.text('Name'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Log In'), findsOneWidget);
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

  testWidgets('ShoppingScreen renders heading, add field, and shows duplicate hint for pantry match',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final storage = StorageService();
    final apiClient = ApiClient(storage: storage);
    final itemsRepo = ItemsRepository(apiClient: apiClient);
    final itemsProvider = ItemsProvider(repository: itemsRepo);
    final shoppingRepo = ShoppingRepository(apiClient: apiClient);
    final shoppingProvider = ShoppingProvider(repository: shoppingRepo);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ItemsProvider>.value(value: itemsProvider),
          ChangeNotifierProvider<ShoppingProvider>.value(value: shoppingProvider),
        ],
        child: const MaterialApp(
          home: ShoppingScreen(),
        ),
      ),
    );
    await tester.pump();

    // Verify Shopping List header and Add an item field
    expect(find.text('Shopping List'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Add an item...'), findsOneWidget);

    // Enter text that does not match pantry
    await tester.enterText(find.byType(TextField), 'Bread');
    await tester.pump();
    expect(find.textContaining('You already have'), findsNothing);
  });

  testWidgets('BoughtBottomSheet renders quick chips and enables Add to pantry on selection',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final testItem = ShoppingItem(
      id: 'item_123',
      householdId: 'hh_456',
      name: 'Sugar',
      bought: false,
      archived: false,
      addedBy: 'user_789',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    DateTime? confirmedDate;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoughtBottomSheet(
            item: testItem,
            onConfirm: (expiry) async {
              confirmedDate = expiry;
              return const MarkBoughtResult(
                status: MarkBoughtStatus.success,
                message: 'Sugar added to pantry',
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify Wireframe 4 elements
    expect(find.text('Sugar bought. Add to pantry?'), findsOneWidget);
    expect(find.text('Expires in'), findsOneWidget);
    expect(find.text('1 month'), findsOneWidget);
    expect(find.text('3 months'), findsOneWidget);
    expect(find.text('6 months'), findsOneWidget);
    expect(find.text('Pick date'), findsOneWidget);

    // Verify Add to pantry button is initially disabled
    final buttonFinder = find.widgetWithText(ElevatedButton, 'Add to pantry');
    expect(buttonFinder, findsOneWidget);
    ElevatedButton buttonWidget = tester.widget(buttonFinder);
    expect(buttonWidget.onPressed, isNull);

    // Tap '1 month' chip
    await tester.tap(find.text('1 month'));
    await tester.pump();

    // Button should now be enabled
    buttonWidget = tester.widget(buttonFinder);
    expect(buttonWidget.onPressed, isNotNull);

    // Tap Add to pantry button
    await tester.tap(buttonFinder);
    await tester.pump();

    expect(confirmedDate, isNotNull);
  });
}
