import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum KomButtonVariant { primary, secondary }

class KomButton extends StatelessWidget {
  const KomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = KomButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final KomButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    final child = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == KomButtonVariant.primary
                  ? AppColors.sandBeige
                  : AppColors.primaryGreen,
            ),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 6),
                  Text(label),
                ],
              )
            : Text(label);

    final button = switch (variant) {
      KomButtonVariant.primary => ElevatedButton(
          onPressed: effectiveOnPressed,
          child: child,
        ),
      KomButtonVariant.secondary => OutlinedButton(
          onPressed: effectiveOnPressed,
          child: child,
        ),
    };

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
