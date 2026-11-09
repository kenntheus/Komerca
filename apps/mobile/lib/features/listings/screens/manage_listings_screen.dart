import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/listing.dart';
import '../providers/listings_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';

class ManageListingsScreen extends ConsumerWidget {
  const ManageListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(myListingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My listings')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/sell/create'),
        icon: const Icon(Icons.add),
        label: const Text('New listing'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: listings.when(
        data: (items) => items.isEmpty
            ? _EmptyState(
                onAdd: () => context.push('/sell/create'),
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.refresh(myListingsProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) => _ManageListingCard(
                    listing: items[i],
                    onDeleted: () => ref.invalidate(myListingsProvider),
                  ),
                ),
              ),
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _ManageListingCard extends ConsumerStatefulWidget {
  final Listing listing;
  final VoidCallback onDeleted;

  const _ManageListingCard({
    required this.listing,
    required this.onDeleted,
  });

  @override
  ConsumerState<_ManageListingCard> createState() =>
      _ManageListingCardState();
}

class _ManageListingCardState
    extends ConsumerState<_ManageListingCard> {
  bool _isDeleting = false;

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove listing?'),
        content: const Text(
            'This will permanently remove your listing.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.riskHighFg),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      final dio = ref.read(apiClientProvider);
      await dio.delete('/listings/${widget.listing.id}');
      widget.onDeleted();
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not remove listing')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _markSold() async {
    try {
      final dio = ref.read(apiClientProvider);
      await dio.post('/listings/${widget.listing.id}/sold');
      widget.onDeleted();
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = widget.listing;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: l.photos.isNotEmpty
                  ? Image.network(
                      l.photos.first.url,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const _PlaceholderPhoto(),
                    )
                  : const _PlaceholderPhoto(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    '₱${formatPrice(l.price)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _StatusChip(status: l.status),
                ],
              ),
            ),
            if (_isDeleting)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'delete') _confirmDelete();
                  if (v == 'sold') _markSold();
                },
                itemBuilder: (_) => [
                  if (l.status == 'ACTIVE')
                    const PopupMenuItem(
                      value: 'sold',
                      child: Text('Mark as sold'),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Remove'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  static const _labels = {
    'DRAFT': 'Draft',
    'ACTIVE': 'Active',
    'SOLD': 'Sold',
    'REMOVED': 'Removed',
  };

  static const _colors = {
    'DRAFT': Color(0xFF888888),
    'ACTIVE': AppColors.primaryGreen,
    'SOLD': AppColors.riskMediumFg,
    'REMOVED': AppColors.riskHighFg,
  };

  @override
  Widget build(BuildContext context) {
    final label = _labels[status] ?? status;
    final color = _colors[status] ?? AppColors.secondaryText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PlaceholderPhoto extends StatelessWidget {
  const _PlaceholderPhoto();

  @override
  Widget build(BuildContext context) => Container(
        width: 72,
        height: 72,
        color: AppColors.divider,
        child: const Icon(Icons.image_outlined,
            color: AppColors.secondaryText),
      );
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_outlined,
                size: 64, color: AppColors.secondaryText),
            const SizedBox(height: 16),
            Text('No listings yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Start selling by adding your first item.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.secondaryText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add listing'),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen),
            ),
          ],
        ),
      ),
    );
  }
}
