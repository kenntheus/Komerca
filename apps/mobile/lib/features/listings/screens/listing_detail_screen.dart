import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/listing.dart';
import '../providers/listings_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/kom_avatar.dart';
import '../../../shared/widgets/kom_button.dart';
import '../../../shared/widgets/kom_chip.dart';

class ListingDetailScreen extends ConsumerWidget {
  final String id;

  const ListingDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listing = ref.watch(listingDetailProvider(id));
    return Scaffold(
      body: listing.when(
        data: (l) => _ListingDetail(listing: l),
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Scaffold(
          appBar: AppBar(),
          body: Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}

class _ListingDetail extends StatelessWidget {
  final Listing listing;

  const _ListingDetail({required this.listing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: listing.photos.isNotEmpty
                ? PageView.builder(
                    itemCount: listing.photos.length,
                    itemBuilder: (_, i) => CachedNetworkImage(
                      imageUrl: listing.photos[i].url,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const _PhotoError(),
                    ),
                  )
                : const _PhotoError(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(listing.title,
                        style: theme.textTheme.headlineMedium),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '₱${formatPrice(listing.price)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  KomChip(
                      label: conditionLabel(listing.condition),
                      isSelected: false,
                      onTap: null),
                  const SizedBox(width: 8),
                  const Icon(Icons.location_on_outlined,
                      size: 16, color: AppColors.secondaryText),
                  const SizedBox(width: 2),
                  Text(listing.city,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryText,
                      )),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              if (listing.seller != null) ...[
                Row(
                  children: [
                    KomAvatar(
                      imageUrl: listing.seller!.avatarUrl,
                      name: listing.seller!.name,
                      size: 44,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(listing.seller!.name,
                            style: theme.textTheme.titleSmall),
                        Text(
                          '${listing.seller!.completedDealCount} deals completed',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
              ],
              const SizedBox(height: 20),
              Text('Description', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(listing.description ?? '',
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 32),
              KomButton(
                label: 'Contact seller',
                onPressed: () {},
                fullWidth: true,
              ),
              const SizedBox(height: 12),
              KomButton(
                label: 'Make reservation',
                onPressed: () {},
                variant: KomButtonVariant.secondary,
                fullWidth: true,
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }
}

class _PhotoError extends StatelessWidget {
  const _PhotoError();

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.divider,
        child: const Center(
          child: Icon(Icons.image_outlined,
              size: 64, color: AppColors.secondaryText),
        ),
      );
}
