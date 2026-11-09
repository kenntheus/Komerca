import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/category.dart';
import '../providers/categories_provider.dart';
import '../../../core/theme/app_colors.dart';

class CategoryPickerScreen extends ConsumerWidget {
  const CategoryPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Choose category')),
      body: categories.when(
        data: (cats) => _CategoryGrid(categories: cats),
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<Category> categories;

  const _CategoryGrid({required this.categories});

  static const _iconMap = <String, IconData>{
    'smartphone': Icons.smartphone,
    'checkroom': Icons.checkroom,
    'chair': Icons.chair,
    'menu_book': Icons.menu_book,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: categories.length,
      itemBuilder: (ctx, i) {
        final cat = categories[i];
        final icon = _iconMap[cat.iconName] ?? Icons.category;
        return Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => ctx.pop(cat),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: 36, color: AppColors.primaryGreen),
                  const SizedBox(height: 8),
                  Text(cat.name,
                      style: theme.textTheme.titleSmall,
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
