import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_app/app_theme.dart';
import 'package:pantry_app/core/api_client.dart';
import 'package:pantry_app/core/notification_service.dart';
import 'package:pantry_app/core/storage.dart';
import 'package:pantry_app/features/auth/state/auth_provider.dart';
import 'package:pantry_app/features/auth/ui/auth_screen.dart';
import 'package:pantry_app/features/pantry/data/items_repository.dart';
import 'package:pantry_app/features/pantry/state/items_provider.dart';
import 'package:pantry_app/features/shopping/data/shopping_repository.dart';
import 'package:pantry_app/features/shopping/state/shopping_provider.dart';
import 'package:pantry_app/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialise notification service and request permission at startup.
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermission();
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
        ChangeNotifierProxyProvider2<ApiClient, StorageService, AuthProvider>(
          create: (ctx) => AuthProvider(
            apiClient: ctx.read<ApiClient>(),
            storage: ctx.read<StorageService>(),
          ),
          update: (_, apiClient, storage, previous) =>
              previous ?? AuthProvider(apiClient: apiClient, storage: storage),
        ),
        ProxyProvider<ApiClient, ItemsRepository>(
          update: (_, apiClient, _) => ItemsRepository(apiClient: apiClient),
        ),
        ChangeNotifierProxyProvider2<ItemsRepository, AuthProvider, ItemsProvider>(
          create: (ctx) => ItemsProvider(
            repository: ctx.read<ItemsRepository>(),
            onUnauthorized: () => ctx.read<AuthProvider>().logout(),
          ),
          update: (_, repository, auth, previous) =>
              previous ??
              ItemsProvider(
                repository: repository,
                onUnauthorized: () => auth.logout(),
              ),
        ),
        ProxyProvider<ApiClient, ShoppingRepository>(
          update: (_, apiClient, _) => ShoppingRepository(apiClient: apiClient),
        ),
        ChangeNotifierProxyProvider2<ShoppingRepository, AuthProvider, ShoppingProvider>(
          create: (ctx) => ShoppingProvider(
            repository: ctx.read<ShoppingRepository>(),
            onUnauthorized: () => ctx.read<AuthProvider>().logout(),
          ),
          update: (_, repository, auth, previous) =>
              previous ??
              ShoppingProvider(
                repository: repository,
                onUnauthorized: () => auth.logout(),
              ),
        ),
      ],
      child: MaterialApp(
        title: 'Stockora',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthGate(),
      ),
    );
  }
}

/// AuthGate observes AuthProvider state and routes between:
/// - Loading/Splash screen while restoreSession runs
/// - Network error retry screen if server is unreachable
/// - AuthScreen if unauthenticated
/// - MainShellScreen if authenticated
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Restore session on app launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.initial:
      case AuthStatus.loading:
        return const _LoadingSplash();

      case AuthStatus.networkError:
        return _NetworkRetryScreen(
          onRetry: () => context.read<AuthProvider>().restoreSession(),
        );

      case AuthStatus.authenticated:
        return const MainShellScreen();

      case AuthStatus.unauthenticated:
        return const AuthScreen();
    }
  }
}

/// Short splash/loading screen while checking authentication status.
class _LoadingSplash extends StatelessWidget {
  const _LoadingSplash();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.kitchen_rounded,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Stockora',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error view shown when server cannot be reached during restoreSession,
/// preserving user session credentials and offering a retry button.
class _NetworkRetryScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const _NetworkRetryScreen({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 64,
                color: Color(0xFFEF5350),
              ),
              const SizedBox(height: 20),
              Text(
                'Connection Error',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Cannot reach the server, please check your connection and try again.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(160, 48),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
