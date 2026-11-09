import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/category.dart';
import '../models/listing.dart';
import '../providers/listings_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/kom_button.dart';

class DraftListingScreen extends ConsumerStatefulWidget {
  final List<File> photos;

  DraftListingScreen({super.key, List<dynamic>? photos})
      : photos = photos?.cast<File>() ?? const [];

  @override
  ConsumerState<DraftListingScreen> createState() =>
      _DraftListingScreenState();
}

class _DraftListingScreenState extends ConsumerState<DraftListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  String _condition = 'LIKE_NEW';
  Category? _category;
  bool _isLoading = false;
  String? _error;

  static const _conditions = [
    ('NEW', 'New'),
    ('LIKE_NEW', 'Like New'),
    ('GOOD', 'Good'),
    ('FAIR', 'Fair'),
    ('FOR_PARTS', 'For Parts'),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCategory() async {
    final result = await context.push<Category>('/sell/categories');
    if (result != null) setState(() => _category = result);
  }

  Future<void> _saveAndPublish() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_category == null) {
      setState(() => _error = 'Please select a category');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = ref.read(apiClientProvider);
      final attributes = <String, dynamic>{};

      // Create the draft
      final createRes = await dio.post('/listings', data: {
        'categoryId': _category!.id,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': double.parse(_priceCtrl.text),
        'condition': _condition,
        'city': _cityCtrl.text.trim(),
        'attributes': attributes,
      });

      final listing =
          Listing.fromJson(createRes.data as Map<String, dynamic>);

      // Publish it
      await dio.post('/listings/${listing.id}/publish');

      ref.invalidate(listingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing published!')),
        );
        context.go('/sell/manage');
      }
    } on ApiError catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Something went wrong';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Listing details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category
              GestureDetector(
                onTap: _pickCategory,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _category?.name ?? 'Select category',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _category != null
                                ? AppColors.bodyText
                                : AppColors.secondaryText,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.secondaryText),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => (v?.trim().isEmpty ?? true)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Price (PHP)',
                  prefixText: '₱ ',
                ),
                validator: (v) {
                  if (v?.trim().isEmpty ?? true) return 'Price is required';
                  final n = double.tryParse(v!);
                  if (n == null || n <= 0) return 'Enter a valid price';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _condition,
                decoration:
                    const InputDecoration(labelText: 'Condition'),
                items: _conditions
                    .map((e) => DropdownMenuItem(
                          value: e.$1,
                          child: Text(e.$2),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _condition = v);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (v) => (v?.trim().isEmpty ?? true)
                    ? 'City is required'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration:
                    const InputDecoration(labelText: 'Description'),
                validator: (v) {
                  if (v?.trim().isEmpty ?? true) {
                    return 'Description is required';
                  }
                  if ((v?.trim().length ?? 0) < 10) {
                    return 'At least 10 characters';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.riskHighFg),
                ),
              ],
              const SizedBox(height: 24),
              KomButton(
                label: 'Save and publish',
                onPressed: _isLoading ? null : _saveAndPublish,
                isLoading: _isLoading,
                fullWidth: true,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
