import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/gallery/component_gallery_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: KomercaApp(),
    ),
  );
}

class KomercaApp extends StatelessWidget {
  const KomercaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Komerca',
      theme: AppTheme.light,
      themeMode: ThemeMode.light, // light theme only — no dark mode
      debugShowCheckedModeBanner: false,
      home: const ComponentGalleryScreen(),
    );
  }
}
