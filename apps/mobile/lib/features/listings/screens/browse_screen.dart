import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/category.dart';
import '../providers/categories_provider.dart';
import '../providers/listings_provider.dart';
import '../widgets/listing_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/kom_chip.dart';
import 'filter_sheet.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmit(String q) {
    if (q.trim().isEmpty) return;
    context.push('/browse/search?q=${Uri.encodeComponent(q.trim())}');
  }

  void _selectCategory(Category? cat) {
    final current = ref.read(listingsFilterProvider);
    if (cat == null) {
      ref
          .read(listingsFilterProvider.notifier)
          .state = current.copyWith(clearCategoryId: true);
    } else {
      ref.read(listingsFilterProvider.notifier).state =
          current.copyWith(categoryId: cat.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listings = ref.watch(listingsProvider);
    final categories = ref.watch(categoriesProvider);
    final filter = ref.watch(listingsFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => context.push('/browse/search'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.secondaryText,
                    size: 18),
                const SizedBox(width: 8),
                Text(
                  'Search listings...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filters',
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(listingsProvider);
          await ref.read(listingsProvider.future);
        },
        child: CustomScrollView(
          slivers: [
            // Category chips
            SliverToBoxAdapter(
              child: categories.when(
                data: (cats) => _CategoryChips(
                  categories: cats,
                  selectedId: filter.categoryId,
                  onSelect: _selectCategory,
                ),
                loading: () => const SizedBox(height: 56),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            // Listings grid
            listings.when(
              data: (items) => items.isEmpty
                  ? const SliverFillRemaining(child: _EmptyState())
                  : SliverPadding(
                      padding: const EdgeInsets.all(12),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => ListingCard(
                            listing: items[i],
                            onTap: () =>
                                ctx.push('/listings/${items[i].id}'),
                          ),
                          childCount: items.length,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.72,
                        ),
                      ),
                    ),
              loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator())),
              error: (err, _) => SliverFillRemaining(
                child: Center(
                    child:
                        Text('Error loading listings: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const FilterSheet(),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<Category?> onSelect;

  const _CategoryChips({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 56,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: KomChip(
                label: 'All',
                isSelected: selectedId == null,
                onTap: () => onSelect(null),
              ),
            ),
            ...categories.map(
              (cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: KomChip(
                  label: cat.name,
                  isSelected: selectedId == cat.id,
                  onTap: () => onSelect(cat),
                ),
              ),
            ),
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 64, color: AppColors.secondaryText),
            const SizedBox(height: 16),
            Text(
              'No listings yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to sell something',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
            ),
          ],
        ),
      );
}

