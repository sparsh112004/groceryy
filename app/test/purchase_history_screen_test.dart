import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pantry_app/core/api_client.dart';
import 'package:pantry_app/core/storage.dart';
import 'package:pantry_app/features/auth/state/auth_provider.dart';
import 'package:pantry_app/features/pantry/data/items_repository.dart';
import 'package:pantry_app/features/pantry/state/items_provider.dart';
import 'package:pantry_app/features/shopping/data/shopping_item_model.dart';
import 'package:pantry_app/features/shopping/data/shopping_repository.dart';
import 'package:pantry_app/features/shopping/state/shopping_provider.dart';
import 'package:pantry_app/features/shopping/ui/purchase_history_screen.dart';
import 'package:pantry_app/router.dart';

class _FakeShoppingRepository extends ShoppingRepository {
  final List<ShoppingItem> itemsToReturn;

  _FakeShoppingRepository(this.itemsToReturn)
      : super(apiClient: ApiClient(storage: StorageService()));

  @override
  Future<List<ShoppingItem>> getShoppingItems({
    bool? bought,
    bool includeArchived = false,
  }) async {
    return itemsToReturn;
  }
}

class _FakeItemsRepository extends ItemsRepository {
  _FakeItemsRepository()
      : super(apiClient: ApiClient(storage: StorageService()));
}

void main() {
  testWidgets(
      'PurchaseHistoryScreen shows bought items grouped by date and tag and filters by name',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final boughtDate = DateTime(2024, 5, 26, 17, 14);
    final items = [
      ShoppingItem(
        id: '1',
        householdId: 'hh1',
        name: 'Bananas',
        quantity: 1.85,
        unit: 'kg',
        category: 'Produce',
        bought: true,
        boughtAt: boughtDate,
        archived: false,
        addedBy: 'u1',
        createdAt: boughtDate,
        updatedAt: boughtDate,
      ),
      ShoppingItem(
        id: '2',
        householdId: 'hh1',
        name: 'Milk',
        quantity: 2,
        unit: 'L',
        category: 'Dairy',
        bought: true,
        boughtAt: boughtDate,
        archived: false,
        addedBy: 'u1',
        createdAt: boughtDate,
        updatedAt: boughtDate,
      ),
      ShoppingItem(
        id: '3',
        householdId: 'hh1',
        name: 'Bread',
        quantity: 1,
        unit: 'pack',
        category: 'Bakery',
        bought: false,
        boughtAt: null,
        archived: false,
        addedBy: 'u1',
        createdAt: boughtDate,
        updatedAt: boughtDate,
      ),
    ];

    final shoppingProvider = ShoppingProvider(
      repository: _FakeShoppingRepository(items),
    );
    await shoppingProvider.loadItems();

    await tester.pumpWidget(
      ChangeNotifierProvider<ShoppingProvider>.value(
        value: shoppingProvider,
        child: const MaterialApp(
          home: PurchaseHistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Header and date group
    expect(find.text('History'), findsOneWidget);
    expect(find.text('May 26, 2024 (Sunday)'), findsOneWidget);
    expect(find.text('2 items purchased'), findsOneWidget);

    // Bought items with quantities
    expect(find.text('1.85 kg Bananas'), findsOneWidget);
    expect(find.text('2 L Milk'), findsOneWidget);
    // Unbought item is excluded
    expect(find.text('1 pack Bread'), findsNothing);

    // Switch to Tag grouping
    await tester.tap(find.text('Tag'));
    await tester.pumpAndSettle();

    expect(find.text('Produce'), findsOneWidget);
    expect(find.text('Dairy'), findsOneWidget);
    expect(find.text('May 26, 2024'), findsNWidgets(2));

    // Filter by product name
    await tester.enterText(find.byType(TextField), 'Bananas');
    await tester.pumpAndSettle();

    expect(find.text('1.85 kg Bananas'), findsOneWidget);
    expect(find.text('2 L Milk'), findsNothing);
  });

  testWidgets('MainShellScreen places History tab between Shopping and Household',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final storage = StorageService();
    final apiClient = ApiClient(storage: storage);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: apiClient),
          ChangeNotifierProvider(create: (_) => NavigationProvider()),
          ChangeNotifierProvider(
            create: (_) => AuthProvider(apiClient: apiClient, storage: storage),
          ),
          ChangeNotifierProvider(
            create: (_) => ItemsProvider(repository: _FakeItemsRepository()),
          ),
          ChangeNotifierProvider(
            create: (_) => ShoppingProvider(
              repository: _FakeShoppingRepository(const []),
            ),
          ),
        ],
        child: const MaterialApp(
          home: MainShellScreen(),
        ),
      ),
    );
    await tester.pump();

    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    final labels = navBar.destinations
        .map((d) => (d as NavigationDestination).label)
        .toList();

    expect(labels, ['Home', 'Pantry', 'Shopping', 'History', 'Household']);
  });

  test('ShoppingItem.fromJson treats naive server timestamps as UTC and converts to local',
      () {
    final item = ShoppingItem.fromJson({
      'id': '10',
      'household_id': 'hh1',
      'name': 'Salt',
      'quantity': 1,
      'unit': 'kg',
      'bought': true,
      'bought_at': '2026-11-25T09:14:00.000000',
      'archived': false,
      'added_by': 'u1',
      'created_at': '2026-11-25T09:10:00',
      'updated_at': '2026-11-25T09:14:00Z',
    });

    expect(item.boughtAt, DateTime.utc(2026, 11, 25, 9, 14).toLocal());
    expect(item.createdAt, DateTime.utc(2026, 11, 25, 9, 10).toLocal());
    expect(item.updatedAt, DateTime.utc(2026, 11, 25, 9, 14).toLocal());
  });
}
