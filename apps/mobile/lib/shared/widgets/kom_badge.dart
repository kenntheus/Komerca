import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum RiskLevel { low, medium, high }

class KomBadge extends StatelessWidget {
  const KomBadge({super.key, required this.level});

  final RiskLevel level;

  @override
  Widget build(BuildContext context) {
    final config = _configs[level]!;
    return Semantics(
      label: '${config.label} risk listing',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: config.backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(config.icon, size: 13, color: config.foregroundColor),
            const SizedBox(width: 4),
            Text(
              config.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: config.foregroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _configs = {
    RiskLevel.low: _BadgeConfig(
      backgroundColor: AppColors.riskLowBg,
      foregroundColor: AppColors.riskLowFg,
      icon: Icons.check_circle_outline,
      label: 'Low Risk',
    ),
    RiskLevel.medium: _BadgeConfig(
      backgroundColor: AppColors.riskMediumBg,
      foregroundColor: AppColors.riskMediumFg,
      icon: Icons.warning_amber_outlined,
      label: 'Medium Risk',
    ),
    RiskLevel.high: _BadgeConfig(
      backgroundColor: AppColors.riskHighBg,
      foregroundColor: AppColors.riskHighFg,
      icon: Icons.error_outline,
      label: 'High Risk',
    ),
  };
}

class _BadgeConfig {
  const _BadgeConfig({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.label,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final String label;
}
