import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/kom_avatar.dart';
import '../../shared/widgets/kom_badge.dart';
import '../../shared/widgets/kom_button.dart';
import '../../shared/widgets/kom_card.dart';
import '../../shared/widgets/kom_chip.dart';

class ComponentGalleryScreen extends StatefulWidget {
  const ComponentGalleryScreen({super.key});

  @override
  State<ComponentGalleryScreen> createState() => _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState extends State<ComponentGalleryScreen> {
  bool _chipSelected1 = false;
  bool _chipSelected2 = true;
  bool _chipSelected3 = false;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Component Gallery')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Buttons ────────────────────────────────────────────────────
            _Section(
              title: 'Buttons',
              children: [
                KomButton(label: 'Primary Button', onPressed: () {}),
                const SizedBox(height: 8),
                KomButton(
                  label: 'Secondary Button',
                  onPressed: () {},
                  variant: KomButtonVariant.secondary,
                ),
                const SizedBox(height: 8),
                KomButton(
                  label: 'Loading…',
                  onPressed: () {},
                  isLoading: true,
                ),
                const SizedBox(height: 8),
                KomButton(
                  label: 'With Icon',
                  onPressed: () {},
                  icon: Icons.add,
                ),
                const SizedBox(height: 8),
                const KomButton(label: 'Disabled', onPressed: null),
              ],
            ),

            // ── Chips ──────────────────────────────────────────────────────
            _Section(
              title: 'Chips',
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    KomChip(
                      label: 'Phones & Gadgets',
                      isSelected: _chipSelected1,
                      onTap: () => setState(() => _chipSelected1 = !_chipSelected1),
                    ),
                    KomChip(
                      label: 'Fashion',
                      isSelected: _chipSelected2,
                      onTap: () => setState(() => _chipSelected2 = !_chipSelected2),
                    ),
                    KomChip(
                      label: 'Books',
                      isSelected: _chipSelected3,
                      onTap: () => setState(() => _chipSelected3 = !_chipSelected3),
                    ),
                  ],
                ),
              ],
            ),

            // ── Badges ─────────────────────────────────────────────────────
            _Section(
              title: 'Listing-Check Badges',
              children: [
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    KomBadge(level: RiskLevel.low),
                    KomBadge(level: RiskLevel.medium),
                    KomBadge(level: RiskLevel.high),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Badges use color + icon + text — never color alone.',
                  style: tt.bodySmall,
                ),
              ],
            ),

            // ── Cards ──────────────────────────────────────────────────────
            _Section(
              title: 'Cards',
              children: [
                KomCard(
                  onTap: () {},
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.image_outlined,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('iPhone 14 Pro Max 256GB', style: tt.titleSmall),
                            const SizedBox(height: 2),
                            Text('₱35,000', style: tt.bodyLarge?.copyWith(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w700,
                            )),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('Quezon City', style: tt.bodySmall),
                                const SizedBox(width: 8),
                                const KomBadge(level: RiskLevel.low),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Avatars ────────────────────────────────────────────────────
            const _Section(
              title: 'Avatars',
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    KomAvatar(name: 'Juan dela Cruz', size: 40),
                    KomAvatar(name: 'Maria Santos', size: 56),
                    KomAvatar(size: 40),
                    KomAvatar(
                      name: 'JC',
                      size: 40,
                      imageUrl: 'https://i.pravatar.cc/150?u=gallery',
                    ),
                  ],
                ),
              ],
            ),

            // ── Color swatches ─────────────────────────────────────────────
            const _Section(
              title: 'Brand Color Tokens',
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ColorSwatch(color: AppColors.primaryGreen, label: 'Primary\nGreen'),
                    _ColorSwatch(color: AppColors.sandBeige, label: 'Sand\nBeige'),
                    _ColorSwatch(color: AppColors.pageBackground, label: 'Page\nBg'),
                    _ColorSwatch(color: AppColors.bodyText, label: 'Body\nText'),
                    _ColorSwatch(color: AppColors.secondaryText, label: 'Secondary\nText'),
                    _ColorSwatch(color: AppColors.divider, label: 'Divider'),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...children,
        const SizedBox(height: 8),
        const Divider(height: 32),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: AppColors.secondaryText),
        ),
      ],
    );
  }
}
