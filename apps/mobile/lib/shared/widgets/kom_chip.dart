import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class KomChip extends StatelessWidget {
  const KomChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : AppColors.sandBeige,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.sandBeige : AppColors.bodyText,
          ),
        ),
      ),
    );
  }
}
