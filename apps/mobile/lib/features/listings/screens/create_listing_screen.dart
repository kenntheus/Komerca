import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/kom_button.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _picker = ImagePicker();
  final List<File> _photos = [];
  bool _isCompressing = false;
  String? _error;

  Future<void> _pickPhotos() async {
    final picked = await _picker.pickMultiImage(limit: 10 - _photos.length);
    if (picked.isEmpty) return;

    setState(() => _isCompressing = true);
    final compressed = <File>[];
    for (final img in picked) {
      final result = await FlutterImageCompress.compressAndGetFile(
        img.path,
        '${img.path}_compressed.jpg',
        quality: 80,
        minWidth: 1024,
        minHeight: 1024,
      );
      if (result != null) compressed.add(File(result.path));
    }
    setState(() {
      _photos.addAll(compressed);
      _isCompressing = false;
    });
  }

  void _goToDetails() {
    context.push('/sell/details', extra: _photos);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add photos')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add up to 10 photos',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _photos.isEmpty
                  ? _AddPhotoButton(onTap: _pickPhotos)
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _photos.length + 1,
                      itemBuilder: (ctx, i) {
                        if (i == _photos.length) {
                          if (_photos.length >= 10) {
                            return const SizedBox.shrink();
                          }
                          return _AddPhotoButton(onTap: _pickPhotos);
                        }
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(_photos[i],
                                  fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() =>
                                    _photos.removeAt(i)),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.close,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.riskHighFg)),
            ],
            const SizedBox(height: 16),
            KomButton(
              label: 'Next: add details',
              onPressed: (_photos.isEmpty || _isCompressing) ? null : _goToDetails,
              isLoading: _isCompressing,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPhotoButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: AppColors.primaryGreen, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined,
                  size: 32, color: AppColors.primaryGreen),
              SizedBox(height: 4),
              Text('Add photos',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.primaryGreen)),
            ],
          ),
        ),
      );
}
