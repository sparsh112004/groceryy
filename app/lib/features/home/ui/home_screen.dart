import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_app/app_theme.dart';
import 'package:pantry_app/core/ui_helpers.dart';
import 'package:pantry_app/features/pantry/data/item_model.dart';
import 'package:pantry_app/features/pantry/state/items_provider.dart';
import 'package:pantry_app/features/pantry/ui/item_action_sheet.dart';
import 'package:pantry_app/features/shopping/state/shopping_provider.dart';
import 'package:pantry_app/router.dart';

/// Home screen with soothing sage-green aesthetic, summary grid, and Use First items.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemsProvider>().refreshAll();
      final shopping = context.read<ShoppingProvider>();
      if (shopping.items.isEmpty && !shopping.isLoading) {
        shopping.loadItems();
      }
    });
  }

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildDaysLeftPill(ItemModel item) {
    Color bgColor;
    Color textColor;

    if (item.expiryStatus == 'expired') {
      bgColor = AppTheme.statusExpiredContainer;
      textColor = AppTheme.statusExpired;
    } else if (item.expiryStatus == 'soon') {
      bgColor = AppTheme.statusSoonContainer;
      textColor = AppTheme.statusSoon;
    } else {
      bgColor = AppTheme.statusFreshContainer;
      textColor = AppTheme.statusFresh;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            item.daysLeftLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE5F3EA), Color(0xFFCDE9D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC0DEC9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Use what you have,\nWaste less',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Keep track of freshness at home',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: const Text('🥬', style: TextStyle(fontSize: 34)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required int count,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemsProvider = context.watch<ItemsProvider>();
    final shoppingCount =
        context.watch<ShoppingProvider>().unboughtItems.length;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              itemsProvider.refreshAll(),
              context.read<ShoppingProvider>().loadItems(),
            ]);
          },
          child: Builder(
            builder: (context) {
              if (itemsProvider.isLoading && itemsProvider.activeItems.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (itemsProvider.errorMessage != null &&
                  itemsProvider.activeItems.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 56,
                          color: AppTheme.statusExpired,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          itemsProvider.errorMessage!,
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => itemsProvider.refreshAll(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final useFirst = itemsProvider.useFirstItems;
              final weeklySaved = itemsProvider.usedBeforeExpiringThisWeekCount;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Greeting + My Pantry title
                    Text(
                      '${_greetingText()} 👋',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Icon(
                          Icons.home_rounded,
                          color: AppTheme.primaryGreen,
                          size: 28,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'My Pantry',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Quick search bar linking to Pantry tab
                    InkWell(
                      onTap: () => context.read<NavigationProvider>().setIndex(1),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: AppTheme.cardDecoration(radius: 14),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.search_rounded,
                              color: AppTheme.textSecondary,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Search items in your pantry...',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Hero Banner
                    _buildHeroBanner(),
                    const SizedBox(height: 14),

                    if (weeklySaved > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.statusFreshContainer,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFB7DFC2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.eco_rounded,
                              color: AppTheme.statusFresh,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$weeklySaved ${weeklySaved == 1 ? 'item' : 'items'} used before expiring this week',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryGreenDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 2x2 Summary Stat Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.inventory_2_outlined,
                            iconColor: AppTheme.primaryGreen,
                            iconBg: AppTheme.softMintTint,
                            count: itemsProvider.itemsAtHomeCount,
                            label: 'Items at home',
                            onTap: () =>
                                context.read<NavigationProvider>().setIndex(1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.access_time_rounded,
                            iconColor: AppTheme.statusSoon,
                            iconBg: AppTheme.statusSoonContainer,
                            count: itemsProvider.expiringSoonCount,
                            label: 'Expiring soon',
                            onTap: () =>
                                context.read<NavigationProvider>().setIndex(1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.cancel_outlined,
                            iconColor: AppTheme.statusExpired,
                            iconBg: AppTheme.statusExpiredContainer,
                            count: itemsProvider.expiredCount,
                            label: 'Expired',
                            onTap: () =>
                                context.read<NavigationProvider>().setIndex(1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.shopping_cart_outlined,
                            iconColor: AppTheme.primaryGreen,
                            iconBg: AppTheme.softMintTint,
                            count: shoppingCount,
                            label: 'In shopping list',
                            onTap: () =>
                                context.read<NavigationProvider>().setIndex(2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Use First Section
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Use First',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.read<NavigationProvider>().setIndex(1),
                          child: const Text(
                            'View all →',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Container(
                      decoration: AppTheme.cardDecoration(),
                      child: useFirst.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 24,
                                horizontal: 16,
                              ),
                              child: Text(
                                'No items expiring soon. Your pantry is fresh!',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppTheme.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Column(
                              children: [
                                for (int i = 0; i < useFirst.length; i++) ...[
                                  if (i > 0)
                                    const Divider(
                                      height: 1,
                                      indent: 16,
                                      endIndent: 16,
                                      color: AppTheme.borderSubtle,
                                    ),
                                  InkWell(
                                    onTap: () => showItemActionSheet(
                                      context,
                                      useFirst[i],
                                      allowEdit: false,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          ItemEmojiBadge(
                                            name: useFirst[i].name,
                                            category: useFirst[i].category,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  useFirst[i].displayTitle,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                ),
                                                if (useFirst[i].category !=
                                                    null)
                                                  Text(
                                                    useFirst[i].category!,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: AppTheme
                                                          .textSecondary,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          _buildDaysLeftPill(useFirst[i]),
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                            color: AppTheme.textSecondary,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
