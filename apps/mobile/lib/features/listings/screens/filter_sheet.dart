import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/categories_provider.dart';
import '../providers/listings_provider.dart';
import '../../../shared/widgets/kom_button.dart';
import '../../../shared/widgets/kom_chip.dart';

class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late ListingsFilter _draft;

  static const _conditions = [
    ('NEW', 'New'),
    ('LIKE_NEW', 'Like New'),
    ('GOOD', 'Good'),
    ('FAIR', 'Fair'),
    ('FOR_PARTS', 'For Parts'),
  ];

  @override
  void initState() {
    super.initState();
    _draft = ref.read(listingsFilterProvider);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Filters', style: theme.textTheme.headlineSmall),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _draft = const ListingsFilter()),
                  child: const Text('Clear all'),
                ),
              ],
            ),
            const Divider(),
            Text('Category', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            categories.when(
              data: (cats) => Wrap(
                spacing: 8,
                runSpacing: 4,
                children: cats.map((cat) {
                  final isSelected = _draft.categoryId == cat.id;
                  return KomChip(
                    label: cat.name,
                    isSelected: isSelected,
                    onTap: () => setState(() {
                      _draft = _draft.copyWith(
                        categoryId: isSelected ? null : cat.id,
                        clearCategoryId: isSelected,
                      );
                    }),
                  );
                }).toList(),
              ),
              loading: () => const SizedBox(height: 40),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            Text('Condition', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _conditions.map((entry) {
                final (value, label) = entry;
                final isSelected = _draft.condition == value;
                return KomChip(
                  label: label,
                  isSelected: isSelected,
                  onTap: () => setState(() {
                    _draft = _draft.copyWith(
                      condition: isSelected ? null : value,
                      clearCondition: isSelected,
                    );
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            KomButton(
              label: 'Apply filters',
              onPressed: () {
                ref.read(listingsFilterProvider.notifier).state = _draft;
                Navigator.of(context).pop();
              },
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
