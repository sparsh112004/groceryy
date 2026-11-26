import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show Clipboard, ClipboardData, FilteringTextInputFormatter;
import 'package:provider/provider.dart';

import 'package:pantry_app/app_theme.dart';
import 'package:pantry_app/core/api_client.dart';
import 'package:pantry_app/core/notification_service.dart';
import 'package:pantry_app/features/auth/state/auth_provider.dart';
import 'package:pantry_app/features/household/data/household_repository.dart';
import 'package:pantry_app/features/household/state/household_provider.dart';
import 'package:pantry_app/features/pantry/state/items_provider.dart';
import 'package:pantry_app/features/shopping/state/shopping_provider.dart';

/// Household screen with curved forest-green header, member avatars, and invite code card.
class HouseholdScreen extends StatelessWidget {
  const HouseholdScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
  const _HouseholdScreenBody();

  @override
  State<_HouseholdScreenBody> createState() => _HouseholdScreenBodyState();
}

class _HouseholdScreenBodyState extends State<_HouseholdScreenBody> {
  final TextEditingController _joinCodeController = TextEditingController();
  bool _isSendingTestNotification = false;

  static const List<List<Color>> _avatarPalettes = [
    [Color(0xFFD8F0E1), Color(0xFF1B6B3A)],
    [Color(0xFFFFF0C7), Color(0xFF8A5A00)],
    [Color(0xFFE3E0FA), Color(0xFF45359C)],
    [Color(0xFFDDF0FA), Color(0xFF155E75)],
    [Color(0xFFFCE2E2), Color(0xFF9F1239)],
  ];

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HouseholdProvider>().load();
    });
  }

  Future<void> _refresh() async {
    await context.read<HouseholdProvider>().load();
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  String _spacedCode(String code) {
    return code.split('').join(' ');
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite code copied')),
    );
  }

  Future<void> _sendTestNotification() async {
    if (_isSendingTestNotification) return;
    setState(() => _isSendingTestNotification = true);
    try {
      await NotificationService.instance.init();
      final granted = await NotificationService.instance.requestPermission();
      if (granted) {
        await NotificationService.instance.showTestNotification();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission denied')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingTestNotification = false);
      }
    }
  }

  Future<void> _regenerateCode() async {
    final provider = context.read<HouseholdProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Regenerate invite code'),
        content: const Text('The old code will stop working. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await provider.regenerateCode();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'New code created' : provider.errorMessage ?? 'Failed',
          ),
        ),
      );
    }
    setState(() {});
  }

  Future<void> _joinHousehold() async {
    final provider = context.read<HouseholdProvider>();
    final code = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Enter invite code'),
        content: TextField(
          controller: _joinCodeController,
          maxLength: 6,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
          ],
          decoration: const InputDecoration(counterText: ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              c,
              _joinCodeController.text.trim().toUpperCase(),
            ),
            child: const Text('Next'),
          ),
        ],
      ),
    );
    if (code == null || code.isEmpty || !mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirm join household'),
        content: const Text(
          'If you are the only person in your current household, your items and shopping list will move with you. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final newToken = await provider.join(code);
    if (!mounted) return;
    if (newToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Join failed')),
      );
      return;
    }

    await context.read<AuthProvider>().saveNewAccessToken(newToken);
    if (!mounted) return;
    await context.read<HouseholdProvider>().load();
    if (!mounted) return;
    await context.read<ItemsProvider>().refreshAll();
    if (!mounted) return;
    await context.read<ShoppingProvider>().loadItems();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You joined the household')),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreenDark, AppTheme.primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: const [
            Icon(Icons.groups_rounded, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Text(
              'Household',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<HouseholdProvider>();

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.statusExpired,
                ),
                const SizedBox(height: 20),
                Text(
                  provider.errorMessage!,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: provider.load,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(160, 48),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final household = provider.household;
    final user = auth.currentUser;
    final members = household?.members ?? const [];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderBanner(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (user != null) ...[
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              color: AppTheme.primaryGreen,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hello,',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Household Name Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.cardDecoration(),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.softMintTint,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.home_work_outlined,
                              color: AppTheme.primaryGreen,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  household?.name ?? 'Household',
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Shared pantry',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Members Section
                    Row(
                      children: [
                        const Icon(
                          Icons.people_outline_rounded,
                          size: 20,
                          color: AppTheme.primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Members (${members.length})',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: AppTheme.cardDecoration(),
                      child: members.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No members',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            )
                          : Column(
                              children: [
                                for (int i = 0; i < members.length; i++) ...[
                                  if (i > 0)
                                    const Divider(
                                      height: 1,
                                      indent: 16,
                                      endIndent: 16,
                                      color: AppTheme.borderSubtle,
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 11,
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: _avatarPalettes[
                                              i % _avatarPalettes.length][0],
                                          child: Text(
                                            _initials(members[i].name),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: _avatarPalettes[
                                                  i % _avatarPalettes.length][1],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            members[i].name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (i == 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.softMintTint,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'Admin',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.primaryGreenDark,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                    const SizedBox(height: 20),

                    // Invite Code Section
                    if (household?.inviteCode != null) ...[
                      Row(
                        children: const [
                          Icon(
                            Icons.link_rounded,
                            size: 20,
                            color: AppTheme.primaryGreen,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Invite Code',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.softMintTint,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFB3D5BE),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _spacedCode(household!.inviteCode),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: provider.isSubmitting
                                  ? null
                                  : () => _copyCode(household.inviteCode),
                              icon: const Icon(
                                Icons.copy_rounded,
                                color: AppTheme.primaryGreen,
                              ),
                              tooltip: 'Copy code',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  provider.isSubmitting ? null : _regenerateCode,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('New code'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: provider.isSubmitting
                                  ? null
                                  : () => _copyCode(household.inviteCode),
                              icon: const Icon(Icons.share_rounded, size: 18),
                              label: const Text('Copy code'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed:
                              provider.isSubmitting ? null : _joinHousehold,
                          icon: const Icon(Icons.add_home_outlined, size: 20),
                          label: const Text('Join another household'),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (kDebugMode && !kIsWeb) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: _isSendingTestNotification
                              ? null
                              : _sendTestNotification,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.softMintTint,
                            foregroundColor: AppTheme.primaryGreenDark,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(
                            Icons.notifications_outlined,
                            size: 20,
                          ),
                          label: const Text('Send test notification'),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: () async =>
                            await context.read<AuthProvider>().logout(),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.statusExpiredContainer,
                          foregroundColor: AppTheme.statusExpired,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        label: const Text('Log out'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
