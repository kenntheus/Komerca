import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/kom_button.dart';

class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Enter your phone number';
    final cleaned = value.replaceAll(RegExp(r'\s'), '');
    final full = cleaned.startsWith('+63')
        ? cleaned
        : '+63${cleaned.replaceFirst(RegExp(r'^0'), '')}';
    if (!RegExp(r'^\+639\d{9}$').hasMatch(full)) {
      return 'Enter a valid PH number (09XXXXXXXXX)';
    }
    return null;
  }

  String _toE164(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'\s'), '');
    if (cleaned.startsWith('+63')) return cleaned;
    return '+63${cleaned.replaceFirst(RegExp(r'^0'), '')}';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final phone = _toE164(_controller.text);
    try {
      await ref.read(authProvider.notifier).requestOtp(phone);
      if (mounted) context.push('/auth/otp', extra: phone);
    } catch (_) {
      // Error is in auth state
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                Text(
                  'Komerca',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your everyday marketplace',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 48),
                Text('Enter your phone number',
                    style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'We\'ll send a one-time code to verify your number.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _controller,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: '09XX XXX XXXX',
                    prefixText: '+63 ',
                  ),
                  validator: _validatePhone,
                ),
                if (authState.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    authState.error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.riskHighFg,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                KomButton(
                  label: 'Send code',
                  onPressed: authState.isLoading ? null : _submit,
                  isLoading: authState.isLoading,
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
