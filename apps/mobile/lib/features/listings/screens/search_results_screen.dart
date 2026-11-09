import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/listings_provider.dart';
import '../widgets/listing_card.dart';
import 'filter_sheet.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  final String query;

  const SearchResultsScreen({super.key, required this.query});

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
    // Apply query to filter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(listingsFilterProvider.notifier).state =
          ref.read(listingsFilterProvider).copyWith(q: widget.query);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String q) {
    final trimmed = q.trim();
    if (trimmed.isEmpty) return;
    ref.read(listingsFilterProvider.notifier).state =
        ref.read(listingsFilterProvider).copyWith(q: trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final listings = ref.watch(listingsProvider);
    final filter = ref.watch(listingsFilterProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () {
          ref.read(listingsFilterProvider.notifier).state =
              ref.read(listingsFilterProvider).copyWith(clearQ: true);
          context.pop();
        }),
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: _search,
          decoration: const InputDecoration(
            hintText: 'Search listings...',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'Filters',
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const FilterSheet(),
                ),
              ),
              if (filter.hasActiveFilters)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: listings.when(
        data: (items) => items.isEmpty
            ? const Center(child: Text('No results found'))
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) => ListingCard(
                  listing: items[i],
                  onTap: () => ctx.push('/listings/${items[i].id}'),
                ),
              ),
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
