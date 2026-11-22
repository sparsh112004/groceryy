import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


import 'package:pantry_app/core/api_client.dart';
import 'package:pantry_app/features/household/data/household_repository.dart';
import 'package:pantry_app/features/household/state/household_provider.dart';

import 'package:provider/provider.dart';
import 'package:pantry_app/features/auth/state/auth_provider.dart';



/// Household screen placeholder with a functional Log out action.
class HouseholdScreen extends StatelessWidget {
  const HouseholdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide HouseholdProvider locally since it's not registered globally.
    return ChangeNotifierProvider<HouseholdProvider>(
      create: (ctx) {
        final repo = HouseholdRepository(apiClient: ctx.read<ApiClient>());
        return HouseholdProvider(
          repository: repo,
          onUnauthorized: () => ctx.read<AuthProvider>().logout(),
        );
      },
      child: const _HouseholdScreenBody(),
    );
  }
}

/// Internal widget that consumes the provider and builds the UI.
class _HouseholdScreenBody extends StatefulWidget {
  const _HouseholdScreenBody({Key? key}) : super(key: key);

  @override
  State<_HouseholdScreenBody> createState() => _HouseholdScreenBodyState();
}

class _HouseholdScreenBodyState extends State<_HouseholdScreenBody> {
  @override
  void initState() {
    super.initState();
    // Load household data when the screen appears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HouseholdProvider>().load();
    });
  }

  Future<void> _refresh() async {
    await context.read<HouseholdProvider>().load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<HouseholdProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Household'),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(theme, auth, provider),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, AuthProvider auth, HouseholdProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Color(0xFFEF5350)),
              const SizedBox(height: 20),
              Text(
                provider.errorMessage!,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: provider.load,
                style: OutlinedButton.styleFrom(minimumSize: const Size(160, 48)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final household = provider.household;
    final user = auth.currentUser;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User greeting
            if (user != null) ...[
              Text('Hello, ${user.name}', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
            ],
            // Household card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      household?.name ?? 'Household',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('Shared pantry'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Members section
            Text('Members', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (household?.members.isNotEmpty ?? false)
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: household!.members
                        .map((m) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(m.name, style: theme.textTheme.bodyMedium),
                            ))
                        .toList(),
                  ),
                ),
              )
            else
              const Text('No members'),
            const SizedBox(height: 24),
            // Invite code card
            if (household?.inviteCode != null) ...[
              Text('Invite Code', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        household!.inviteCode,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: household.inviteCode));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Code copied')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(minimumSize: const Size(80, 48)),
                        child: const Text('Copy'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Log out button
            Center(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(160, 48),
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

