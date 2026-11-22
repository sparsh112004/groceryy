import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pantry_app/core/api_client.dart';
import 'package:pantry_app/core/storage.dart';
import 'package:pantry_app/features/auth/state/auth_provider.dart';
import 'package:pantry_app/features/auth/ui/auth_screen.dart';

void main() {
  testWidgets('AuthScreen displays welcome message and toggles login/signup',
      (WidgetTester tester) async {
    // Increase test surface size so all form elements fit comfortably
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
}
