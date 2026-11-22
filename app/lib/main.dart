import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_app/app_theme.dart';
import 'package:pantry_app/core/api_client.dart';
import 'package:pantry_app/core/storage.dart';
import 'package:pantry_app/router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PantryApp());
}

/// Root widget of the Stockora application.
/// Configures dependency injection via Provider, Material 3 theme, and English-only UI.
class PantryApp extends StatelessWidget {
  const PantryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        Provider(create: (_) => StorageService()),
        ProxyProvider<StorageService, ApiClient>(
          update: (_, storage, _) => ApiClient(storage: storage),
        ),
      ],
      child: MaterialApp(
        title: 'Stockora',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const MainShellScreen(),
      ),
    );
  }
}
