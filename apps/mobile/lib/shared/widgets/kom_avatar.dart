import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class KomAvatar extends StatelessWidget {
  const KomAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40,
  });

  final String? imageUrl;
  final String? name;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, _) => _placeholder,
          errorWidget: (_, _, _) => _placeholder,
        ),
      );
    }
    return _placeholder;
  }

  Widget get _placeholder {
    final initials = _extractInitials(name);
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primaryGreen,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: AppColors.sandBeige,
            fontSize: size * 0.36,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static String _extractInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .join();
  }
}
