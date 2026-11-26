import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_app/features/home/ui/home_screen.dart';
import 'package:pantry_app/features/household/ui/household_screen.dart';
import 'package:pantry_app/features/pantry/ui/add_item_screen.dart';
import 'package:pantry_app/features/pantry/ui/pantry_screen.dart';
import 'package:pantry_app/features/shopping/ui/purchase_history_screen.dart';
import 'package:pantry_app/features/shopping/ui/shopping_screen.dart';

/// Navigation state provider managing the bottom tab selection.
class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }
}

/// Main shell widget hosting the bottom navigation bar and active tab screen.
class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key});

  static const List<Widget> _screens = [
    HomeScreen(),
    PantryScreen(),
    ShoppingScreen(),
    PurchaseHistoryScreen(),
    HouseholdScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final currentIndex = navProvider.currentIndex;

    // Per SPEC Section 8: A '+' floating button is shown on Home and Pantry
    final showFab = currentIndex == 0 || currentIndex == 1;

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddItemScreen(),
                  ),
                );
              },
              tooltip: 'Add Item',
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          context.read<NavigationProvider>().setIndex(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.kitchen_outlined),
            selectedIcon: Icon(Icons.kitchen),
            label: 'Pantry',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Shopping',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Household',
          ),
        ],
      ),
    );
  }
}
