import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/kom_card.dart';
import '../../../shared/widgets/kom_chip.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback? onTap;

  const ListingCard({super.key, required this.listing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstPhoto =
        listing.photos.isNotEmpty ? listing.photos.first.url : null;

    return KomCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: firstPhoto != null
                  ? CachedNetworkImage(
                      imageUrl: firstPhoto,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const _PhotoPlaceholder(),
                    )
                  : const _PhotoPlaceholder(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  style: theme.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₱${formatPrice(listing.price)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.secondaryText,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        listing.city,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    KomChip(
                      label: conditionLabel(listing.condition),
                      isSelected: false,
                      onTap: null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.divider,
        child: const Center(
          child: Icon(Icons.image_outlined,
              size: 48, color: AppColors.secondaryText),
        ),
      );
}
