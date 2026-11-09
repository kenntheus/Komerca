import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/kom_avatar.dart';
import '../../../shared/widgets/kom_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline,
                    size: 64, color: AppColors.secondaryText),
                const SizedBox(height: 16),
                Text('Sign in to view your profile',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 24),
                KomButton(
                  label: 'Sign in',
                  onPressed: () => context.push('/auth/phone'),
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = auth.user!;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                KomAvatar(
                  imageUrl: user.avatarUrl,
                  name: user.name ?? user.phone,
                  size: 60,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name,
                          style: theme.textTheme.titleMedium),
                      Text(user.phone,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryText,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: const Text('My listings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/sell/manage'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.riskHighFg),
            title: const Text('Sign out',
                style: TextStyle(color: AppColors.riskHighFg)),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }
}
