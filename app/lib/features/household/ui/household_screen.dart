// Imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, FilteringTextInputFormatter;
import 'package:provider/provider.dart';

import 'package:pantry_app/core/api_client.dart';
import 'package:pantry_app/features/household/data/household_repository.dart';
import 'package:pantry_app/features/household/state/household_provider.dart';
import 'package:pantry_app/features/auth/state/auth_provider.dart';
import 'package:pantry_app/features/pantry/state/items_provider.dart';
import 'package:pantry_app/features/shopping/state/shopping_provider.dart';

/// Household screen with invite code management and join flow.
class HouseholdScreen extends StatelessWidget {
  const HouseholdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide HouseholdProvider locally (not registered globally).
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

class _HouseholdScreenBody extends StatefulWidget {
  const _HouseholdScreenBody({Key? key}) : super(key: key);

  @override
  State<_HouseholdScreenBody> createState() => _HouseholdScreenBodyState();
}

class _HouseholdScreenBodyState extends State<_HouseholdScreenBody> {
  final TextEditingController _joinCodeController = TextEditingController();

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

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

  // Regenerate invite code flow.
  Future<void> _regenerateCode() async {
    final provider = context.read<HouseholdProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Regenerate invite code'),
        content: const Text('The old code will stop working. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Continue')),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await provider.regenerateCode();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'New code created' : provider.errorMessage ?? 'Failed')),
      );
    }
    setState(() {}); // Refresh UI to show new code.
  }

  // Join another household flow.
  Future<void> _joinHousehold() async {
    final provider = context.read<HouseholdProvider>();
    // Step 1: ask for code.
    final code = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Enter invite code'),
        content: TextField(
          controller: _joinCodeController,
          maxLength: 6,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]'))],
          decoration: const InputDecoration(counterText: ''),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, null), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(c, _joinCodeController.text.trim().toUpperCase()), child: const Text('Next')),
        ],
      ),
    );
    if (code == null || code.isEmpty) return;
    // Step 2: confirm moving items.
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirm join household'),
        content: const Text('If you are the only person in your current household, your items and shopping list will move with you. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Continue')),
        ],
      ),
    );
    if (confirm != true) return;
    // Perform join.
    final newToken = await provider.join(code);
    if (!mounted) return;
    if (newToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Join failed')),
      );
      return;
    }
    // Save new token.
    await context.read<AuthProvider>().saveNewAccessToken(newToken);
    // Refresh related data.
    await context.read<HouseholdProvider>().load();
    await context.read<ItemsProvider>().refreshAll();
    await context.read<ShoppingProvider>().loadItems();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You joined the household')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<HouseholdProvider>();

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

    return Scaffold(
      appBar: AppBar(title: const Text('Household'), centerTitle: false),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user != null) ...[
                  Text('Hello, ${user.name}', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: Card(
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
                ),
                const SizedBox(height: 24),
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
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  title: Text(m.name, style: theme.textTheme.bodyLarge),
                                ))
                            .toList(),
                      ),
                    ),
                  )
                else
                  const Text('No members'),
                const SizedBox(height: 24),
                if (household?.inviteCode != null) ...[
                  Text('Invite Code', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Large code on its own line.
                          Text(
                            household!.inviteCode,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Copy + New code buttons, each taking half the width.
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: provider.isSubmitting
                                      ? null
                                      : () {
                                          // Copy invite code to clipboard.
                                          final data = ClipboardData(text: household.inviteCode);
                                          Clipboard.setData(data);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Invite code copied')),
                                          );
                                        },
                                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                                  icon: const Icon(Icons.copy, size: 18),
                                  label: const Text('Copy', style: TextStyle(fontSize: 16)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: provider.isSubmitting ? null : _regenerateCode,
                                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                                  child: const Text('New code', style: TextStyle(fontSize: 16)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Join another household — full-width below the card.
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: provider.isSubmitting ? null : _joinHousehold,
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                      child: const Text('Join another household', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () async => await context.read<AuthProvider>().logout(),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(160, 48), foregroundColor: theme.colorScheme.error, side: BorderSide(color: theme.colorScheme.error)),
                    icon: const Icon(Icons.logout),
                    label: const Text('Log out'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
